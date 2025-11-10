Set-StrictMode -Version Latest

function Import-Tiny11Configuration {
    [CmdletBinding()]
    param(
        [Parameter()][string]$Path = (Join-Path -Path $PSScriptRoot -ChildPath 'config/Tiny11Builder.config.psd1')
    )

    if (-not (Test-Path -Path $Path)) {
        throw "Arquivo de configuração não encontrado em '$Path'."
    }

    Import-PowerShellDataFile -Path $Path
}

function Test-DriveLetter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InputObject
    )

    return $InputObject -match '^[d-zD-Z]$'
}

function Resolve-DrivePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DriveLetter
    )

    if (-not (Test-DriveLetter -InputObject $DriveLetter)) {
        throw "A letra de unidade '$DriveLetter' é inválida. Utilize C-Z."
    }

    "{0}:" -f $DriveLetter.ToUpper()
}

function Ensure-ExecutionPolicy {
    [CmdletBinding()]
    param(
        [switch]$AcceptChange
    )

    $current = Get-ExecutionPolicy -Scope CurrentUser
    if ($current -eq 'Restricted') {
        if ($AcceptChange) {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            return
        }

        throw 'A política de execução está definida como Restricted. Utilize -AcceptEula para permitir a alteração automática ou ajuste manualmente a política antes de prosseguir.'
    }
}

function Test-Administrator {
    [CmdletBinding()]
    param()

    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Start-ElevatedSelf {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ScriptPath,
        [Parameter()][System.Collections.IDictionary]$BoundParameters,
        [Parameter()][string[]]$UnboundArguments
    )

    $psExecutable = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh' } else { 'powershell' }
    $argumentList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$ScriptPath`"")

    if ($BoundParameters) {
        foreach ($entry in $BoundParameters.GetEnumerator()) {
            $name = "-$($entry.Key)"
            $value = $entry.Value
            if ($null -eq $value -or $value -is [switch]) {
                if ($value) {
                    $argumentList += $name
                }
            } elseif ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
                foreach ($item in $value) {
                    $argumentList += $name
                    $argumentList += "`"$item`""
                }
            } else {
                $argumentList += $name
                $argumentList += "`"$value`""
            }
        }
    }

    if ($UnboundArguments) {
        foreach ($arg in $UnboundArguments) {
            $argumentList += "`"$arg`""
        }
    }

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo -Property @{
        FileName = $psExecutable
        Arguments = $argumentList -join ' '
        Verb = 'runas'
        UseShellExecute = $true
    }

    [System.Diagnostics.Process]::Start($startInfo) | Out-Null
}

function Assert-ExternalTool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Tool
    )

    $null = Get-Command -Name $Tool -ErrorAction Stop
}

function Invoke-ExternalCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter()][string[]]$ArgumentList = @(),
        [switch]$IgnoreErrors,
        [string]$ErrorMessage
    )

    Write-Verbose ("Executando {0} {1}" -f $FilePath, ($ArgumentList -join ' '))
    $null = & $FilePath @ArgumentList
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0 -and -not $IgnoreErrors) {
        $message = if ($ErrorMessage) { $ErrorMessage } else { "O comando '$FilePath' retornou código $exitCode." }
        throw $message
    }

    return $exitCode
}

function Get-ProvisionedAppxToRemove {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$ExistingPackages,
        [Parameter(Mandatory)][string[]]$Prefixes
    )

    foreach ($package in $ExistingPackages) {
        foreach ($prefix in $Prefixes) {
            if ($package -like "*$prefix*") {
                $package
                break
            }
        }
    }
}

function Remove-ProvisionedAppxPackages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ImageRoot,
        [Parameter(Mandatory)][string[]]$Prefixes
    )

    $packages = & dism /English "/image:$ImageRoot" '/Get-ProvisionedAppxPackages' |
        ForEach-Object {
            if ($_ -match 'PackageName : (.*)') {
                $matches[1]
            }
        }

    if (-not $packages) {
        Write-Verbose 'Nenhum pacote provisionado encontrado.'
        return
    }

    $packagesToRemove = Get-ProvisionedAppxToRemove -ExistingPackages $packages -Prefixes $Prefixes
    foreach ($package in $packagesToRemove | Sort-Object -Unique) {
        Write-Verbose "Removendo AppX provisionado: $package"
        Invoke-ExternalCommand -FilePath 'dism' -ArgumentList @('/English', "/image:$ImageRoot", '/Remove-ProvisionedAppxPackage', "/PackageName:$package")
    }
}

function Remove-SystemPackages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ImageRoot,
        [Parameter(Mandatory)][string[]]$Patterns,
        [Parameter()][string]$LanguageCode = ''
    )

    $packagesOutput = & dism /English "/image:$ImageRoot" '/Get-Packages' '/Format:Table'
    $packageLines = $packagesOutput -split "`n" | Select-Object -Skip 1

    foreach ($pattern in $Patterns) {
        $resolvedPattern = if ($LanguageCode) {
            $pattern -replace '\{0\}', $LanguageCode
        } else {
            $pattern
        }

        $packagesToRemove = $packageLines | Where-Object { $_ -like "$resolvedPattern*" }
        foreach ($packageLine in $packagesToRemove) {
            $packageIdentity = ($packageLine -split '\s+')[0]
            Write-Verbose "Removendo pacote: $packageIdentity"
            Invoke-ExternalCommand -FilePath 'dism' -ArgumentList @('/English', "/image:$ImageRoot", '/Remove-Package', "/PackageName:$packageIdentity")
        }
    }
}

function Load-RegistryHives {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ImageRoot
    )

    $hives = @(
        @{ Key = 'HKLM\zCOMPONENTS'; Path = Join-Path -Path $ImageRoot -ChildPath 'Windows\System32\config\COMPONENTS' },
        @{ Key = 'HKLM\zDEFAULT'; Path = Join-Path -Path $ImageRoot -ChildPath 'Windows\System32\config\default' },
        @{ Key = 'HKLM\zNTUSER'; Path = Join-Path -Path $ImageRoot -ChildPath 'Users\Default\ntuser.dat' },
        @{ Key = 'HKLM\zSOFTWARE'; Path = Join-Path -Path $ImageRoot -ChildPath 'Windows\System32\config\SOFTWARE' },
        @{ Key = 'HKLM\zSYSTEM'; Path = Join-Path -Path $ImageRoot -ChildPath 'Windows\System32\config\SYSTEM' }
    )

    foreach ($hive in $hives) {
        Write-Verbose "Carregando hive $($hive.Key) de $($hive.Path)"
        reg load $hive.Key $hive.Path | Out-Null
    }

    return $hives
}

function Unload-RegistryHives {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IEnumerable]$Hives
    )

    foreach ($hive in $Hives) {
        $key = if ($hive -is [string]) { $hive } else { $hive.Key }
        if ($key) {
            Write-Verbose "Descarregando hive $key"
            reg unload $key | Out-Null
        }
    }
}

function Invoke-RegistryOperations {
    [CmdletBinding()]
    param(
        [Parameter()][System.Collections.IEnumerable]$SetOperations,
        [Parameter()][string[]]$RemoveOperations
    )

    if ($SetOperations) {
        foreach ($operation in $SetOperations) {
            $propertyType = switch ($operation.Type.ToUpperInvariant()) {
                'REG_DWORD' { 'DWord' }
                'REG_QWORD' { 'QWord' }
                'REG_SZ' { 'String' }
                'REG_EXPAND_SZ' { 'ExpandString' }
                'REG_MULTI_SZ' { 'MultiString' }
                default { throw "Tipo de registro não suportado: $($operation.Type)" }
            }

            $value = switch ($propertyType) {
                'DWord' { [int]$operation.Value }
                'QWord' { [long]$operation.Value }
                'MultiString' {
                    if ($operation.Value -is [string]) { @($operation.Value) } else { $operation.Value }
                }
                default { $operation.Value }
            }

            $registryPath = "Registry::{0}" -f $operation.Path
            try {
                New-ItemProperty -Path $registryPath -Name $operation.Name -Value $value -PropertyType $propertyType -Force | Out-Null
                Write-Verbose ("Definido {0}\{1} = {2}" -f $operation.Path, $operation.Name, $value)
            } catch {
                throw "Falha ao definir o valor de registro $($operation.Path)\$($operation.Name): $_"
            }
        }
    }

    if ($RemoveOperations) {
        foreach ($keyPath in $RemoveOperations) {
            try {
                Remove-Item -Path ("Registry::{0}" -f $keyPath) -Recurse -Force -ErrorAction Stop
                Write-Verbose ("Removido {0}" -f $keyPath)
            } catch {
                Write-Verbose ("Não foi possível remover {0}: {1}" -f $keyPath, $_.Exception.Message)
            }
        }
    }
}

function Remove-ScheduledTasks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TasksRoot,
        [Parameter(Mandatory)][string[]]$RelativePaths
    )

    foreach ($relativePath in $RelativePaths) {
        $fullPath = Join-Path -Path $TasksRoot -ChildPath $relativePath
        if (Test-Path -Path $fullPath) {
            Write-Verbose "Removendo tarefa agendada $relativePath"
            Remove-Item -Path $fullPath -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            Write-Verbose "Tarefa agendada $relativePath não encontrada."
        }
    }
}

function Disable-WindowsDefenderServices {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$ServiceNames
    )

    foreach ($service in $ServiceNames) {
        try {
            Set-ItemProperty -Path "Registry::HKLM\zSYSTEM\ControlSet001\Services\$service" -Name 'Start' -Value 4 -ErrorAction Stop
            Write-Verbose "Serviço $service configurado como desabilitado."
        } catch {
            Write-Verbose "Falha ao configurar o serviço $service: $($_.Exception.Message)"
        }
    }
}

function Set-RunOnceCommands {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IEnumerable]$Commands
    )

    foreach ($command in $Commands) {
        New-ItemProperty -Path 'Registry::HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name $command.Name -Value $command.Value -PropertyType 'String' -Force | Out-Null
        Write-Verbose "RunOnce '$($command.Name)' configurado."
    }
}

function Remove-Services {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$ServiceRegistryKeys
    )

    foreach ($key in $ServiceRegistryKeys) {
        try {
            Remove-Item -Path ("Registry::{0}" -f $key) -Recurse -Force -ErrorAction Stop
            Write-Verbose "Chave de serviço removida: $key"
        } catch {
            Write-Verbose "Falha ao remover chave de serviço $key: $($_.Exception.Message)"
        }
    }
}

function Get-OscdimgPath {
    [CmdletBinding()]
    param(
        [Parameter()][string]$HostArchitecture,
        [Parameter()][string]$LocalPath,
        [Parameter()][switch]$ForceDownload
    )

    $adkBase = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools'
    $arch = if ($HostArchitecture) { $HostArchitecture } else { $Env:PROCESSOR_ARCHITECTURE }
    $adkCandidate = Join-Path -Path $adkBase -ChildPath (Join-Path -Path $arch -ChildPath 'Oscdimg\oscdimg.exe')

    if (-not $ForceDownload -and (Test-Path -Path $adkCandidate)) {
        Write-Verbose "Utilizando oscdimg do ADK: $adkCandidate"
        return $adkCandidate
    }

    if (-not $LocalPath) {
        throw 'Caminho local para oscdimg.exe não informado.'
    }

    if (-not (Test-Path -Path $LocalPath) -or $ForceDownload) {
        $url = 'https://msdl.microsoft.com/download/symbols/oscdimg.exe/3D44737265000/oscdimg.exe'
        Write-Verbose "Baixando oscdimg.exe de $url"
        Invoke-WebRequest -Uri $url -OutFile $LocalPath -UseBasicParsing
    } else {
        Write-Verbose "Utilizando oscdimg.exe existente em $LocalPath"
    }

    return $LocalPath
}

Export-ModuleMember -Function *

