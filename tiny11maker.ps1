<#
.SYNOPSIS
    Cria uma imagem reduzida do Windows 11 utilizando apenas ferramentas Microsoft.

.DESCRIPTION
    Automatiza a preparação de uma imagem personalizada do Windows 11, removendo aplicativos e componentes,
    aplicando ajustes de registro e gerando um ISO inicializável. O script privilegia execuções não interativas,
    possui tratamento de erros aprimorado e garante limpeza mesmo em caso de falhas.

.PARAMETER ISO
    Letra (C-Z) da unidade onde o ISO original do Windows 11 está montado.

.PARAMETER Scratch
    Letra (C-Z) da unidade que receberá os arquivos temporários. Se omitido, utiliza uma pasta local.

.PARAMETER ImageIndex
    Índice da imagem dentro do install.wim/esd a ser utilizada. Se ausente, será solicitado.

.PARAMETER AcceptEula
    Aceita automaticamente a alteração da ExecutionPolicy para RemoteSigned quando necessário.

.PARAMETER AutoElevate
    Reabre o script elevado (RunAs) caso não esteja sendo executado como administrador.

.PARAMETER NoPrompt
    Falha imediatamente caso uma entrada obrigatória esteja ausente, em vez de solicitar interação.

.PARAMETER SkipCleanup
    Mantém os diretórios temporários após a conclusão (útil para depuração).

.PARAMETER SkipEject
    Evita desmontar a imagem ISO de origem ao final.

.PARAMETER PreserveResources
    Preserva arquivos baixados (oscdimg.exe/autounattend.xml) ao final da execução.

.PARAMETER TranscriptDirectory
    Diretório onde o arquivo de log (transcript) será criado. Padrão: pasta do script.

.PARAMETER ConfigurationPath
    Caminho opcional para um arquivo PSD1 de configuração alternativo.

.PARAMETER ForceOscdimgDownload
    Obriga o download de oscdimg.exe mesmo que o ADK esteja disponível.
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
    [switch]$PreserveResources,

    [ValidateNotNullOrEmpty()]
    [string]$TranscriptDirectory = $PSScriptRoot,

    [string]$ConfigurationPath,
    [switch]$ForceOscdimgDownload
)

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'Tiny11Builder.psm1'
Import-Module -Name $modulePath -Force

try {
    Ensure-ExecutionPolicy -AcceptChange:$AcceptEula

    if (-not (Test-Administrator)) {
        if ($AutoElevate) {
            Start-ElevatedSelf -ScriptPath $PSCommandPath -BoundParameters $PSBoundParameters -UnboundArguments $MyInvocation.UnboundArguments
            return
        }

        throw 'Este script deve ser executado com privilégios administrativos. Utilize -AutoElevate para relançar automaticamente.'
    }

    foreach ($tool in @('dism', 'reg', 'takeown', 'icacls')) {
        Assert-ExternalTool -Tool $tool
    }

    $configPathToUse = if ($ConfigurationPath) {
        $ConfigurationPath
    } else {
        Join-Path -Path $PSScriptRoot -ChildPath 'config/Tiny11Builder.config.psd1'
    }

    $configuration = Import-Tiny11Configuration -Path $configPathToUse

    if (-not (Test-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'autounattend.xml'))) {
        $autounattendUri = 'https://raw.githubusercontent.com/ntdevlabs/tiny11builder/refs/heads/main/autounattend.xml'
        Invoke-RestMethod -Uri $autounattendUri -OutFile (Join-Path -Path $PSScriptRoot -ChildPath 'autounattend.xml')
    }

    if (-not (Test-Path -Path $TranscriptDirectory)) {
        New-Item -ItemType Directory -Path $TranscriptDirectory -Force | Out-Null
    }

    $transcriptPath = Join-Path -Path $TranscriptDirectory -ChildPath ("tiny11_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))
    $transcriptStarted = $false
    Start-Transcript -Path $transcriptPath | Out-Null
    $transcriptStarted = $true

    $hostSID = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')
    $adminGroup = $hostSID.Translate([System.Security.Principal.NTAccount])

    $hostArchitecture = $Env:PROCESSOR_ARCHITECTURE
    $scratchRoot = if ($Scratch) {
        $drive = Resolve-DrivePath -DriveLetter $Scratch
        Join-Path -Path $drive -ChildPath 'tiny11builder'
    } else {
        Join-Path -Path $PSScriptRoot -ChildPath 'tiny11builder'
    }

    $workingDirectory = Join-Path -Path $scratchRoot -ChildPath 'tiny11'
    $mountDirectory = Join-Path -Path $scratchRoot -ChildPath 'scratchdir'
    New-Item -ItemType Directory -Path $workingDirectory -Force | Out-Null

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

    $installImagePath = if (Test-Path -Path $installWimSource) {
        $installWimSource
    } elseif (Test-Path -Path $installEsdSource) {
        Write-Verbose 'Convertendo install.esd para install.wim.'
        $tempWim = Join-Path -Path $scratchRoot -ChildPath 'sources\install.wim'

        if (-not $ImageIndex) {
            if ($NoPrompt) {
                throw 'Informe -ImageIndex ao converter install.esd com -NoPrompt.'
            }
            Get-WindowsImage -ImagePath $installEsdSource | Format-Table ImageIndex, ImageName
            $ImageIndex = [int](Read-Host 'Informe o índice da imagem a ser exportada')
        }

        Export-WindowsImage -SourceImagePath $installEsdSource -SourceIndex $ImageIndex -DestinationImagePath $tempWim -CompressionType Maximum -CheckIntegrity
        $tempWim
    } else {
        throw "Nenhum arquivo install.wim ou install.esd foi localizado em '$isoSources'."
    }

    Write-Verbose 'Copiando arquivos do Windows para o diretório de trabalho.'
    Copy-Item -Path (Join-Path -Path $isoDrive -ChildPath '*') -Destination $workingDirectory -Recurse -Force

    $sourcesDirectory = Join-Path -Path $workingDirectory -ChildPath 'sources'
    $installWimPath = Join-Path -Path $sourcesDirectory -ChildPath 'install.wim'
    if (Test-Path -Path (Join-Path -Path $workingDirectory -ChildPath 'sources\install.esd')) {
        Set-ItemProperty -Path (Join-Path -Path $workingDirectory -ChildPath 'sources\install.esd') -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
        Remove-Item -Path (Join-Path -Path $workingDirectory -ChildPath 'sources\install.esd') -Force -ErrorAction SilentlyContinue
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

    $adminGroupName = $adminGroup.Value
    Invoke-ExternalCommand -FilePath 'takeown' -ArgumentList '/F', $installWimPath
    Invoke-ExternalCommand -FilePath 'icacls' -ArgumentList $installWimPath, '/grant', "$adminGroupName:(F)"
    Set-ItemProperty -Path $installWimPath -Name IsReadOnly -Value $false
    New-Item -ItemType Directory -Path $mountDirectory -Force | Out-Null

    $mounted = $false
    $systemHives = $null
    try {
        Mount-WindowsImage -ImagePath $installWimPath -Index $ImageIndex -Path $mountDirectory -ErrorAction Stop
        $mounted = $true

        $intlOutput = & dism /English /Get-Intl "/Image:`"$mountDirectory`""
        $languageCode = $null
        foreach ($line in $intlOutput -split "`n") {
            if ($line -match 'Default system UI language : ([a-zA-Z]{2}-[a-zA-Z]{2})') {
                $languageCode = $matches[1]
                break
            }
        }

        $imageInfo = & dism /English /Get-WimInfo "/wimFile:`"$installWimPath`"" "/index:$ImageIndex"
        $architecture = $null
        foreach ($line in $imageInfo -split "`r?`n") {
            if ($line -like '*Architecture : *') {
                $architecture = $line -replace 'Architecture : ', ''
                if ($architecture -eq 'x64') {
                    $architecture = 'amd64'
                }
                break
            }
        }

        Remove-ProvisionedAppxPackages -ImageRoot $mountDirectory -Prefixes $configuration.ProvisionedAppxPackagePrefixes

        $edgePaths = @(
            'Program Files (x86)\Microsoft\Edge',
            'Program Files (x86)\Microsoft\EdgeUpdate',
            'Program Files (x86)\Microsoft\EdgeCore'
        )
        foreach ($relative in $edgePaths) {
            $fullPath = Join-Path -Path $mountDirectory -ChildPath $relative
            Remove-Item -Path $fullPath -Recurse -Force -ErrorAction SilentlyContinue
        }

        $webViewPath = Join-Path -Path $mountDirectory -ChildPath 'Windows\System32\Microsoft-Edge-Webview'
        if (Test-Path -Path $webViewPath) {
            Invoke-ExternalCommand -FilePath 'takeown' -ArgumentList '/f', $webViewPath, '/r'
            Invoke-ExternalCommand -FilePath 'icacls' -ArgumentList $webViewPath, '/grant', "$adminGroupName:(F)", '/T', '/C'
            Remove-Item -Path $webViewPath -Recurse -Force -ErrorAction SilentlyContinue
        }

        $oneDriveSetup = Join-Path -Path $mountDirectory -ChildPath 'Windows\System32\OneDriveSetup.exe'
        if (Test-Path -Path $oneDriveSetup) {
            Invoke-ExternalCommand -FilePath 'takeown' -ArgumentList '/f', $oneDriveSetup
            Invoke-ExternalCommand -FilePath 'icacls' -ArgumentList $oneDriveSetup, '/grant', "$adminGroupName:(F)", '/T', '/C'
            Remove-Item -Path $oneDriveSetup -Force -ErrorAction SilentlyContinue
        }

        $systemHives = Load-RegistryHives -ImageRoot $mountDirectory
        try {
            Invoke-RegistryOperations -SetOperations $configuration.RegistryTweaks.SystemImage.Set -RemoveOperations $configuration.RegistryTweaks.SystemImage.Remove

            $autounattendSource = Join-Path -Path $PSScriptRoot -ChildPath 'autounattend.xml'
            $autounattendDest = Join-Path -Path $mountDirectory -ChildPath 'Windows\System32\Sysprep\autounattend.xml'
            Copy-Item -Path $autounattendSource -Destination $autounattendDest -Force

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
        if ($mounted) {
            Dismount-WindowsImage -Path $mountDirectory -Save
        }
    }

    $installWimTempPath = Join-Path -Path $sourcesDirectory -ChildPath 'install2.wim'
    $exportArgs = @('/Export-Image',
        "/SourceImageFile:`"$installWimPath`"",
        "/SourceIndex:$ImageIndex",
        "/DestinationImageFile:`"$installWimTempPath`"",
        '/Compress:recovery')
    Invoke-ExternalCommand -FilePath 'dism.exe' -ArgumentList $exportArgs
    Remove-Item -Path $installWimPath -Force
    Rename-Item -Path $installWimTempPath -NewName 'install.wim'

    $bootWimPath = Join-Path -Path $sourcesDirectory -ChildPath 'boot.wim'
    Invoke-ExternalCommand -FilePath 'takeown' -ArgumentList '/F', $bootWimPath
    Invoke-ExternalCommand -FilePath 'icacls' -ArgumentList $bootWimPath, '/grant', "$adminGroupName:(F)"
    Set-ItemProperty -Path $bootWimPath -Name IsReadOnly -Value $false

    $setupHives = $null
    $bootMounted = $false
    try {
        Mount-WindowsImage -ImagePath $bootWimPath -Index 2 -Path $mountDirectory -ErrorAction Stop
        $bootMounted = $true
        $setupHives = Load-RegistryHives -ImageRoot $mountDirectory
        try {
            Invoke-RegistryOperations -SetOperations $configuration.RegistryTweaks.SetupImage.Set -RemoveOperations $configuration.RegistryTweaks.SetupImage.Remove
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

    Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'autounattend.xml') -Destination (Join-Path -Path $workingDirectory -ChildPath 'autounattend.xml') -Force

    $localOscdimg = Join-Path -Path $PSScriptRoot -ChildPath 'oscdimg.exe'
    $oscdimgPath = Get-OscdimgPath -HostArchitecture $hostArchitecture -LocalPath $localOscdimg -ForceDownload:$ForceOscdimgDownload

    $isoOutput = Join-Path -Path $PSScriptRoot -ChildPath 'tiny11.iso'
    if ($PSCmdlet.ShouldProcess($isoOutput, 'Criar imagem ISO')) {
        $bootEtfsPath = Join-Path -Path (Join-Path -Path $workingDirectory -ChildPath 'boot') -ChildPath 'etfsboot.com'
        $efiDirectory = Join-Path -Path (Join-Path -Path $workingDirectory -ChildPath 'efi') -ChildPath 'microsoft'
        $efiBootPath = Join-Path -Path (Join-Path -Path $efiDirectory -ChildPath 'boot') -ChildPath 'efisys.bin'
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
        Remove-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'autounattend.xml') -Force -ErrorAction SilentlyContinue
    }

    Write-Verbose 'Processo concluído com sucesso.'
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
