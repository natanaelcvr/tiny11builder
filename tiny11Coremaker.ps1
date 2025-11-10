<#
.SYNOPSIS
    Cria uma imagem "core" altamente reduzida do Windows 11 utilizando apenas ferramentas Microsoft.

.DESCRIPTION
    Automatiza a geração de uma imagem Windows 11 focada em ambientes de teste/VM, removendo uma grande
    quantidade de componentes, pacotes e tarefas. Inclui ajustes de registro, desativação de Windows
    Update/Defender e geração do ISO final. A execução padrão preserva a possibilidade de interação, mas
    parâmetros adicionais permitem o uso em cenários não interativos.

.PARAMETER ISO
    Letra (C-Z) da unidade onde o ISO original do Windows 11 está montado.

.PARAMETER Scratch
    Letra (C-Z) da unidade onde os arquivos temporários serão armazenados. Quando omitido, utiliza o
    drive do sistema operacional.

.PARAMETER ImageIndex
    Índice da imagem dentro do install.wim/esd que será processada.

.PARAMETER AcceptEula
    Aceita automaticamente a alteração da ExecutionPolicy para RemoteSigned quando necessário.

.PARAMETER AutoElevate
    Relança o script com privilégios administrativos caso necessário.

.PARAMETER NoPrompt
    Evita qualquer interação; parâmetros obrigatórios devem ser informados. Combine com -Force quando
    desejar dispensar o aviso de uso experimental.

.PARAMETER SkipCleanup
    Mantém os diretórios temporários após a execução, útil para depuração.

.PARAMETER SkipEject
    Não desmonta o ISO de origem ao final.

.PARAMETER EnableNetFx3
    Habilita o recurso .NET Framework 3.5 durante o preparo da imagem.

.PARAMETER PreserveResources
    Mantém os arquivos baixados (oscdimg.exe/autounattend.xml) ao término da execução.

.PARAMETER TranscriptDirectory
    Diretório onde o log da execução (transcript) será gravado.

.PARAMETER ConfigurationPath
    Caminho opcional para um arquivo PSD1 com configurações alternativas.

.PARAMETER ForceOscdimgDownload
    Obriga o download de oscdimg.exe mesmo que o ADK esteja instalado.

.PARAMETER Force
    Suprime o aviso de uso experimental da variante core.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param (
    [ValidatePattern('^[d-zD-Z]$')]
    [string]$ISO,

    [ValidatePattern('^[d-zD-Z]$')]
    [string]$Scratch,

    [int]$ImageIndex,

    [switch]$AcceptEula,
    [switch]$AutoElevate,
    [switch]$NoPrompt,
    [switch]$SkipCleanup,
    [switch]$SkipEject,
    [switch]$EnableNetFx3,
    [switch]$PreserveResources,

    [ValidateNotNullOrEmpty()]
    [string]$TranscriptDirectory = $PSScriptRoot,

    [string]$ConfigurationPath,
    [switch]$ForceOscdimgDownload,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'Tiny11Builder.psm1'
Import-Module -Name $modulePath -Force

$transcriptStarted = $false

try {
    Ensure-ExecutionPolicy -AcceptChange:$AcceptEula

    if (-not (Test-Administrator)) {
        if ($AutoElevate) {
            Start-ElevatedSelf -ScriptPath $PSCommandPath -BoundParameters $PSBoundParameters -UnboundArguments $MyInvocation.UnboundArguments
            return
        }

        throw 'Este script deve ser executado com privilégios administrativos. Utilize -AutoElevate para relançar automaticamente.'
    }

    if (-not $Force) {
        $warning = 'tiny11 core remove componentes críticos e gera uma imagem não suportada para uso cotidiano. Deseja continuar?'
        if ($NoPrompt) {
            throw 'Utilize -Force para assumir o risco inerente à criação do tiny11 core sem confirmação.'
        }

        if (-not $PSCmdlet.ShouldContinue($warning, 'Confirmar execução do tiny11 core')) {
            Write-Verbose 'Execução cancelada pelo usuário.'
            return
        }
    }

    foreach ($tool in @('dism', 'reg', 'takeown', 'icacls')) {
        Assert-ExternalTool -Tool $tool
    }

    $configPath = if ($ConfigurationPath) { $ConfigurationPath } else { Join-Path -Path $PSScriptRoot -ChildPath 'config/Tiny11Builder.config.psd1' }
    $configuration = Import-Tiny11Configuration -Path $configPath

    $autounattendLocal = Join-Path -Path $PSScriptRoot -ChildPath 'autounattend.xml'
    if (-not (Test-Path -Path $autounattendLocal)) {
        $autounattendUri = 'https://raw.githubusercontent.com/ntdevlabs/tiny11builder/refs/heads/main/autounattend.xml'
        Invoke-RestMethod -Uri $autounattendUri -OutFile $autounattendLocal
    }

    if (-not (Test-Path -Path $TranscriptDirectory)) {
        New-Item -ItemType Directory -Path $TranscriptDirectory -Force | Out-Null
    }

    $transcriptFile = Join-Path -Path $TranscriptDirectory -ChildPath ("tiny11core_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))
    Start-Transcript -Path $transcriptFile | Out-Null
    $transcriptStarted = $true

    $scratchRoot = if ($Scratch) {
        $scratchDrive = Resolve-DrivePath -DriveLetter $Scratch
        Join-Path -Path $scratchDrive -ChildPath 'tiny11core'
    } else {
        Join-Path -Path $env:SystemDrive -ChildPath 'tiny11core'
    }

    $workingDirectory = Join-Path -Path $scratchRoot -ChildPath 'tiny11'
    $mountDirectory = Join-Path -Path $scratchRoot -ChildPath 'scratchdir'

    New-Item -ItemType Directory -Path $workingDirectory -Force | Out-Null
    New-Item -ItemType Directory -Path $mountDirectory -Force | Out-Null

    $isoDrive = $null
    if (-not $ISO) {
        if ($NoPrompt) {
            throw 'O parâmetro -ISO é obrigatório quando -NoPrompt é utilizado.'
        }

        do {
            $input = Read-Host 'Informe a letra da unidade onde o ISO do Windows 11 está montado (C-Z)'
        } while (-not $input -or -not (Test-DriveLetter -InputObject $input))
        $isoDrive = Resolve-DrivePath -DriveLetter $input
    } else {
        $isoDrive = Resolve-DrivePath -DriveLetter $ISO
    }

    $isoSources = Join-Path -Path $isoDrive -ChildPath 'sources'
    $installWimSource = Join-Path -Path $isoSources -ChildPath 'install.wim'
    $installEsdSource = Join-Path -Path $isoSources -ChildPath 'install.esd'
    $bootWimSource = Join-Path -Path $isoSources -ChildPath 'boot.wim'

    if (-not (Test-Path -Path $bootWimSource)) {
        throw "O arquivo boot.wim não foi localizado em '$bootWimSource'."
    }

    $tempInstallWim = if (Test-Path -Path $installWimSource) {
        $installWimSource
    } elseif (Test-Path -Path $installEsdSource) {
        if (-not $ImageIndex) {
            if ($NoPrompt) {
                throw 'Informe -ImageIndex ao converter install.esd com -NoPrompt.'
            }
            Get-WindowsImage -ImagePath $installEsdSource | Format-Table ImageIndex, ImageName
            do {
                $inputIndex = Read-Host 'Informe o índice da imagem a ser exportada'
            } while (-not [int]::TryParse($inputIndex, [ref]$ImageIndex))
        }

        $convertedWim = Join-Path -Path $scratchRoot -ChildPath 'install_from_esd.wim'
        Export-WindowsImage -SourceImagePath $installEsdSource -SourceIndex $ImageIndex -DestinationImagePath $convertedWim -CompressionType Maximum -CheckIntegrity
        $convertedWim
    } else {
        throw "Nenhum arquivo install.wim ou install.esd foi localizado em '$isoSources'."
    }

    Copy-Item -Path (Join-Path -Path $isoDrive -ChildPath '*') -Destination $workingDirectory -Recurse -Force

    if ($tempInstallWim -and ($tempInstallWim -ne $installWimSource) -and (Test-Path -Path $tempInstallWim)) {
        Remove-Item -Path $tempInstallWim -Force -ErrorAction SilentlyContinue
    }

    $sourcesDirectory = Join-Path -Path $workingDirectory -ChildPath 'sources'
    $installWimPath = Join-Path -Path $sourcesDirectory -ChildPath 'install.wim'

    if ($tempInstallWim -ne $installWimPath) {
        Copy-Item -Path $tempInstallWim -Destination $installWimPath -Force
    }

    if (Test-Path -Path (Join-Path -Path $sourcesDirectory -ChildPath 'install.esd')) {
        Set-ItemProperty -Path (Join-Path -Path $sourcesDirectory -ChildPath 'install.esd') -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
        Remove-Item -Path (Join-Path -Path $sourcesDirectory -ChildPath 'install.esd') -Force -ErrorAction SilentlyContinue
    }

    $availableImages = Get-WindowsImage -ImagePath $installWimPath
    if (-not $ImageIndex) {
        if ($NoPrompt) {
            throw 'Informe -ImageIndex quando -NoPrompt estiver ativo.'
        }

        $availableImages | Format-Table ImageIndex, ImageName, Architecture
        do {
            $inputIndex = Read-Host 'Informe o índice da imagem desejada'
        } while (-not [int]::TryParse($inputIndex, [ref]$ImageIndex))
    }

    if ($availableImages.ImageIndex -notcontains $ImageIndex) {
        throw "O índice $ImageIndex não está presente no arquivo install.wim."
    }

    $adminSID = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')
    $adminGroup = $adminSID.Translate([System.Security.Principal.NTAccount])
    $adminGroupName = $adminGroup.Value

    Invoke-ExternalCommand -FilePath 'takeown' -ArgumentList '/F', $installWimPath
    Invoke-ExternalCommand -FilePath 'icacls' -ArgumentList $installWimPath, '/grant', "$adminGroupName:(F)"
    Set-ItemProperty -Path $installWimPath -Name IsReadOnly -Value $false

    $systemMounted = $false
    $systemHives = $null
    $languageCode = $null
    $architecture = $null

    try {
        Mount-WindowsImage -ImagePath $installWimPath -Index $ImageIndex -Path $mountDirectory -ErrorAction Stop
        $systemMounted = $true

        $intlOutput = & dism /English /Get-Intl "/Image:`"$mountDirectory`""
        foreach ($line in $intlOutput -split "`n") {
            if ($line -match 'Default system UI language : ([a-zA-Z]{2}-[a-zA-Z]{2})') {
                $languageCode = $matches[1]
                break
            }
        }

        $imageInfo = & dism /English /Get-WimInfo "/wimFile:`"$installWimPath`"" "/index:$ImageIndex"
        foreach ($line in $imageInfo -split "`r?`n") {
            if ($line -like '*Architecture : *') {
                $architecture = $line -replace 'Architecture : ', ''
                if ($architecture -eq 'x64') {
                    $architecture = 'amd64'
                }
                break
            }
        }

        Remove-ProvisionedAppxPackages -ImageRoot $mountDirectory -Prefixes $configuration.CoreProvisionedAppxPackagePrefixes
        Remove-SystemPackages -ImageRoot $mountDirectory -Patterns $configuration.SystemPackagePatterns.Core -LanguageCode $languageCode

        $enableNetFx3 = $EnableNetFx3.IsPresent
        if (-not $EnableNetFx3.IsPresent -and -not $NoPrompt) {
            $answer = Read-Host 'Deseja habilitar o .NET Framework 3.5? (s/n)'
            if ($answer -match '^[sSyY]') {
                $enableNetFx3 = $true
            }
        }

        if ($enableNetFx3) {
            $sxsSource = Join-Path -Path $sourcesDirectory -ChildPath 'sxs'
            Invoke-ExternalCommand -FilePath 'dism.exe' -ArgumentList "/image:`"$mountDirectory`"", '/enable-feature', '/featurename:NetFX3', '/All', "/source:`"$sxsSource`""
        }

        $edgePaths = @(
            'Program Files (x86)\Microsoft\Edge',
            'Program Files (x86)\Microsoft\EdgeUpdate',
            'Program Files (x86)\Microsoft\EdgeCore'
        )
        foreach ($relative in $edgePaths) {
            Remove-Item -Path (Join-Path -Path $mountDirectory -ChildPath $relative) -Recurse -Force -ErrorAction SilentlyContinue
        }

        $edgeWebView = Join-Path -Path $mountDirectory -ChildPath 'Windows\System32\Microsoft-Edge-Webview'
        if (Test-Path -Path $edgeWebView) {
            Invoke-ExternalCommand -FilePath 'takeown' -ArgumentList '/f', $edgeWebView, '/r'
            Invoke-ExternalCommand -FilePath 'icacls' -ArgumentList $edgeWebView, '/grant', "$adminGroupName:(F)", '/T', '/C'
            Remove-Item -Path $edgeWebView -Recurse -Force -ErrorAction SilentlyContinue
        }

        if (-not $architecture) {
            throw 'Não foi possível determinar a arquitetura da imagem.'
        }

        $edgeWinSxSPattern = switch ($architecture) {
            'amd64' { 'amd64_microsoft-edge-webview_31bf3856ad364e35*' }
            'arm64' { 'arm64_microsoft-edge-webview_31bf3856ad364e35*' }
            default { throw "Arquitetura não suportada: $architecture" }
        }

        $winSxsRoot = Join-Path -Path $mountDirectory -ChildPath 'Windows\WinSxS'
        $edgeFolders = Get-ChildItem -Path $winSxsRoot -Filter $edgeWinSxSPattern -Directory -ErrorAction SilentlyContinue
        foreach ($folder in $edgeFolders) {
            Invoke-ExternalCommand -FilePath 'takeown' -ArgumentList '/f', $folder.FullName, '/r'
            Invoke-ExternalCommand -FilePath 'icacls' -ArgumentList $folder.FullName, '/grant', "$adminGroupName:(F)", '/T', '/C'
            Remove-Item -Path $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }

        $winReFolder = Join-Path -Path $mountDirectory -ChildPath 'Windows\System32\Recovery'
        $winReFile = Join-Path -Path $winReFolder -ChildPath 'winre.wim'
        Invoke-ExternalCommand -FilePath 'takeown' -ArgumentList '/f', $winReFolder, '/r'
        Invoke-ExternalCommand -FilePath 'icacls' -ArgumentList $winReFolder, '/grant', 'Administrators:F', '/T', '/C'
        Remove-Item -Path $winReFile -Force -ErrorAction SilentlyContinue
        New-Item -ItemType File -Path $winReFile -Force | Out-Null

        $oneDriveSetup = Join-Path -Path $mountDirectory -ChildPath 'Windows\System32\OneDriveSetup.exe'
        if (Test-Path -Path $oneDriveSetup) {
            Invoke-ExternalCommand -FilePath 'takeown' -ArgumentList '/f', $oneDriveSetup
            Invoke-ExternalCommand -FilePath 'icacls' -ArgumentList $oneDriveSetup, '/grant', "$adminGroupName:(F)", '/T', '/C'
            Remove-Item -Path $oneDriveSetup -Force -ErrorAction SilentlyContinue
        }

        Invoke-ExternalCommand -FilePath 'takeown' -ArgumentList '/f', $winSxsRoot, '/r'
        Invoke-ExternalCommand -FilePath 'icacls' -ArgumentList $winSxsRoot, '/grant', "$adminGroupName:(F)", '/T', '/C'

        $winSxsEdit = Join-Path -Path (Join-Path -Path $mountDirectory -ChildPath 'Windows') -ChildPath 'WinSxS_edit'
        New-Item -ItemType Directory -Path $winSxsEdit -Force | Out-Null

        $winSxsPatterns = @{
            amd64 = @(
                'x86_microsoft.windows.common-controls_6595b64144ccf1df_*',
                'x86_microsoft.windows.gdiplus_6595b64144ccf1df_*',
                'x86_microsoft.windows.i..utomation.proxystub_6595b64144ccf1df_*',
                'x86_microsoft.windows.isolationautomation_6595b64144ccf1df_*',
                'x86_microsoft-windows-s..ngstack-onecorebase_31bf3856ad364e35_*',
                'x86_microsoft-windows-s..stack-termsrv-extra_31bf3856ad364e35_*',
                'x86_microsoft-windows-servicingstack_31bf3856ad364e35_*',
                'x86_microsoft-windows-servicingstack-inetsrv_*',
                'x86_microsoft-windows-servicingstack-onecore_*',
                'amd64_microsoft.vc80.crt_1fc8b3b9a1e18e3b_*',
                'amd64_microsoft.vc90.crt_1fc8b3b9a1e18e3b_*',
                'amd64_microsoft.windows.c..-controls.resources_6595b64144ccf1df_*',
                'amd64_microsoft.windows.common-controls_6595b64144ccf1df_*',
                'amd64_microsoft.windows.gdiplus_6595b64144ccf1df_*',
                'amd64_microsoft.windows.i..utomation.proxystub_6595b64144ccf1df_*',
                'amd64_microsoft.windows.isolationautomation_6595b64144ccf1df_*',
                'amd64_microsoft-windows-s..stack-inetsrv-extra_31bf3856ad364e35_*',
                'amd64_microsoft-windows-s..stack-msg.resources_31bf3856ad364e35_*',
                'amd64_microsoft-windows-s..stack-termsrv-extra_31bf3856ad364e35_*',
                'amd64_microsoft-windows-servicingstack_31bf3856ad364e35_*',
                'amd64_microsoft-windows-servicingstack-inetsrv_31bf3856ad364e35_*',
                'amd64_microsoft-windows-servicingstack-msg_31bf3856ad364e35_*',
                'amd64_microsoft-windows-servicingstack-onecore_31bf3856ad364e35_*',
                'Catalogs',
                'FileMaps',
                'Fusion',
                'InstallTemp',
                'Manifests',
                'x86_microsoft.vc80.crt_1fc8b3b9a1e18e3b_*',
                'x86_microsoft.vc90.crt_1fc8b3b9a1e18e3b_*'
            )
            arm64 = @(
                'arm64_microsoft-windows-servicingstack-onecore_31bf3856ad364e35_*',
                'Catalogs',
                'FileMaps',
                'Fusion',
                'InstallTemp',
                'Manifests',
                'SettingsManifests',
                'Temp',
                'x86_microsoft.vc80.crt_1fc8b3b9a1e18e3b_*',
                'x86_microsoft.vc90.crt_1fc8b3b9a1e18e3b_*',
                'x86_microsoft.windows.c..-controls.resources_6595b64144ccf1df_*',
                'x86_microsoft.windows.common-controls_6595b64144ccf1df_*',
                'x86_microsoft.windows.gdiplus_6595b64144ccf1df_*',
                'x86_microsoft.windows.i..utomation.proxystub_6595b64144ccf1df_*',
                'x86_microsoft.windows.isolationautomation_6595b64144ccf1df_*',
                'arm_microsoft.windows.c..-controls.resources_6595b64144ccf1df_*',
                'arm_microsoft.windows.common-controls_6595b64144ccf1df_*',
                'arm_microsoft.windows.gdiplus_6595b64144ccf1df_*',
                'arm_microsoft.windows.i..utomation.proxystub_6595b64144ccf1df_*',
                'arm_microsoft.windows.isolationautomation_6595b64144ccf1df_*',
                'arm64_microsoft.vc80.crt_1fc8b3b9a1e18e3b_*',
                'arm64_microsoft.vc90.crt_1fc8b3b9a1e18e3b_*',
                'arm64_microsoft.windows.c..-controls.resources_6595b64144ccf1df_*',
                'arm64_microsoft.windows.common-controls_6595b64144ccf1df_*',
                'arm64_microsoft.windows.gdiplus_6595b64144ccf1df_*',
                'arm64_microsoft.windows.i..utomation.proxystub_6595b64144ccf1df_*',
                'arm64_microsoft.windows.isolationautomation_6595b64144ccf1df_*',
                'arm64_microsoft-windows-servicing-adm_31bf3856ad364e35_*',
                'arm64_microsoft-windows-servicingcommon_31bf3856ad364e35_*',
                'arm64_microsoft-windows-servicing-onecore-uapi_31bf3856ad364e35_*',
                'arm64_microsoft-windows-servicingstack_31bf3856ad364e35_*',
                'arm64_microsoft-windows-servicingstack-inetsrv_31bf3856ad364e35_*',
                'arm64_microsoft-windows-servicingstack-msg_31bf3856ad364e35_*'
            )
        }

        $patternsToCopy = $winSxsPatterns[$architecture]
        if (-not $patternsToCopy) {
            throw "Não há padrões de WinSxS definidos para a arquitetura $architecture."
        }

        foreach ($pattern in $patternsToCopy) {
            $matchingDirectories = Get-ChildItem -Path $winSxsRoot -Filter $pattern -Directory -ErrorAction SilentlyContinue

            if (-not $matchingDirectories -and (Test-Path -Path (Join-Path -Path $winSxsRoot -ChildPath $pattern))) {
                $item = Get-Item -Path (Join-Path -Path $winSxsRoot -ChildPath $pattern) -ErrorAction SilentlyContinue
                if ($item) {
                    $matchingDirectories = @($item)
                }
            }

            foreach ($dir in $matchingDirectories) {
                $destination = Join-Path -Path $winSxsEdit -ChildPath $dir.Name
                Copy-Item -Path $dir.FullName -Destination $destination -Recurse -Force
            }
        }

        Remove-Item -Path $winSxsRoot -Recurse -Force
        Rename-Item -Path $winSxsEdit -NewName 'WinSxS'

        $systemHives = Load-RegistryHives -ImageRoot $mountDirectory
        try {
            Invoke-RegistryOperations -SetOperations $configuration.RegistryTweaks.SystemImage.Set -RemoveOperations $configuration.RegistryTweaks.SystemImage.Remove
            Invoke-RegistryOperations -SetOperations $configuration.WindowsUpdatePolicyValues
            Set-RunOnceCommands -Commands $configuration.WindowsUpdateRunOnceCommands
            Disable-WindowsDefenderServices -ServiceNames $configuration.DefenderServices
            Remove-Services -ServiceRegistryKeys $configuration.ServicesToDelete

            $autounattendDest = Join-Path -Path $mountDirectory -ChildPath 'Windows\System32\Sysprep\autounattend.xml'
            Copy-Item -Path $autounattendLocal -Destination $autounattendDest -Force

            $tasksPath = Join-Path -Path $mountDirectory -ChildPath 'Windows\System32\Tasks'
            Remove-ScheduledTasks -TasksRoot $tasksPath -RelativePaths $configuration.ScheduledTasksToRemove
        } finally {
            if ($systemHives) {
                Unload-RegistryHives -Hives $systemHives
            }
        }

        $cleanupArgs = @("/Image:`"$mountDirectory`"", '/Cleanup-Image', '/StartComponentCleanup', '/ResetBase')
        Invoke-ExternalCommand -FilePath 'dism.exe' -ArgumentList $cleanupArgs
    } finally {
        if ($systemMounted) {
            Dismount-WindowsImage -Path $mountDirectory -Save
        }
    }

    $installWimTempPath = Join-Path -Path $sourcesDirectory -ChildPath 'install2.wim'
    $exportArgs = @('/Export-Image', "/SourceImageFile:`"$installWimPath`"", "/SourceIndex:$ImageIndex", "/DestinationImageFile:`"$installWimTempPath`"", '/compress:max')
    Invoke-ExternalCommand -FilePath 'dism.exe' -ArgumentList $exportArgs
    Remove-Item -Path $installWimPath -Force
    Rename-Item -Path $installWimTempPath -NewName 'install.wim'
    $installWimPath = Join-Path -Path $sourcesDirectory -ChildPath 'install.wim'

    $bootWimPath = Join-Path -Path $sourcesDirectory -ChildPath 'boot.wim'
    Invoke-ExternalCommand -FilePath 'takeown' -ArgumentList '/F', $bootWimPath
    Invoke-ExternalCommand -FilePath 'icacls' -ArgumentList $bootWimPath, '/grant', "$adminGroupName:(F)"
    Set-ItemProperty -Path $bootWimPath -Name IsReadOnly -Value $false

    $bootMounted = $false
    $setupHives = $null
    try {
        Mount-WindowsImage -ImagePath $bootWimPath -Index 2 -Path $mountDirectory -ErrorAction Stop
        $bootMounted = $true
        $setupHives = Load-RegistryHives -ImageRoot $mountDirectory
        try {
            $setupOperations = @()
            if ($configuration.RegistryTweaks.SetupImage.Set) {
                $setupOperations += $configuration.RegistryTweaks.SetupImage.Set
            }
            if ($configuration.RegistryTweaks.CoreSetupImage.Set) {
                $setupOperations += $configuration.RegistryTweaks.CoreSetupImage.Set
            }

            $setupRemove = @()
            if ($configuration.RegistryTweaks.SetupImage.Remove) {
                $setupRemove += $configuration.RegistryTweaks.SetupImage.Remove
            }
            if ($configuration.RegistryTweaks.CoreSetupImage.Remove) {
                $setupRemove += $configuration.RegistryTweaks.CoreSetupImage.Remove
            }

            Invoke-RegistryOperations -SetOperations $setupOperations -RemoveOperations $setupRemove
        } finally {
            if ($setupHives) {
                Unload-RegistryHives -Hives $setupHives
            }
        }
    } finally {
        if ($bootMounted) {
            Dismount-WindowsImage -Path $mountDirectory -Save
        }
    }

    $installEsdPath = Join-Path -Path $sourcesDirectory -ChildPath 'install.esd'
    $exportEsdArgs = @('/Export-Image', "/SourceImageFile:`"$installWimPath`"", '/SourceIndex:1', "/DestinationImageFile:`"$installEsdPath`"", '/Compress:recovery')
    Invoke-ExternalCommand -FilePath 'dism.exe' -ArgumentList $exportEsdArgs
    Remove-Item -Path $installWimPath -Force

    Copy-Item -Path $autounattendLocal -Destination (Join-Path -Path $workingDirectory -ChildPath 'autounattend.xml') -Force

    $hostArchitecture = $Env:PROCESSOR_ARCHITECTURE
    $localOscdimg = Join-Path -Path $PSScriptRoot -ChildPath 'oscdimg.exe'
    $oscdimgPath = Get-OscdimgPath -HostArchitecture $hostArchitecture -LocalPath $localOscdimg -ForceDownload:$ForceOscdimgDownload

    $isoOutput = Join-Path -Path $PSScriptRoot -ChildPath 'tiny11-core.iso'
    if ($PSCmdlet.ShouldProcess($isoOutput, 'Criar imagem ISO do tiny11 core')) {
        $bootEtfsPath = Join-Path -Path (Join-Path -Path $workingDirectory -ChildPath 'boot') -ChildPath 'etfsboot.com'
        $efiPath = Join-Path -Path (Join-Path -Path $workingDirectory -ChildPath 'efi') -ChildPath 'microsoft'
        $efiBootPath = Join-Path -Path (Join-Path -Path $efiPath -ChildPath 'boot') -ChildPath 'efisys.bin'
        $bootData = "-bootdata:2#p0,e,b$bootEtfsPath#pEF,e,b$efiBootPath"
        Invoke-ExternalCommand -FilePath $oscdimgPath -ArgumentList '-m', '-o', '-u2', '-udfver102', $bootData, $workingDirectory, $isoOutput
    }

    if (-not $SkipCleanup) {
        Remove-Item -Path $workingDirectory -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $mountDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }

    if (-not $SkipEject) {
        try {
            $volume = Get-Volume -DriveLetter $isoDrive[0] -ErrorAction Stop
            $diskImage = $volume | Get-DiskImage -ErrorAction Stop
            $diskImage | Dismount-DiskImage -ErrorAction Stop
        } catch {
            Write-Verbose "Falha ao desmontar a imagem ISO de origem: $($_.Exception.Message)"
        }
    }

    if (-not $PreserveResources) {
        Remove-Item -Path $localOscdimg -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $autounattendLocal -Force -ErrorAction SilentlyContinue
    }

    Write-Verbose 'tiny11 core concluído com sucesso.'
}
catch {
    Write-Error $_
    exit 1
}
finally {
    if ($transcriptStarted -and $null -ne (Get-Command -Name 'Stop-Transcript' -ErrorAction SilentlyContinue)) {
        try {
            Stop-Transcript | Out-Null
        } catch {
            # Ignorar falhas ao finalizar o transcript
        }
    }
}
