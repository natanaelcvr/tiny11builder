@{
    ProvisionedAppxPackagePrefixes = @(
        'AppUp.IntelManagementandSecurityStatus',
        'Clipchamp.Clipchamp',
        'DolbyLaboratories.DolbyAccess',
        'DolbyLaboratories.DolbyDigitalPlusDecoderOEM',
        'Microsoft.BingNews',
        'Microsoft.BingSearch',
        'Microsoft.BingWeather',
        'Microsoft.Copilot',
        'Microsoft.Windows.CrossDevice',
        'Microsoft.GamingApp',
        'Microsoft.GetHelp',
        'Microsoft.Getstarted',
        'Microsoft.Microsoft3DViewer',
        'Microsoft.MicrosoftOfficeHub',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.MicrosoftStickyNotes',
        'Microsoft.MixedReality.Portal',
        'Microsoft.MSPaint',
        'Microsoft.Office.OneNote',
        'Microsoft.OfficePushNotificationUtility',
        'Microsoft.OutlookForWindows',
        'Microsoft.Paint',
        'Microsoft.People',
        'Microsoft.PowerAutomateDesktop',
        'Microsoft.SkypeApp',
        'Microsoft.StartExperiencesApp',
        'Microsoft.Todos',
        'Microsoft.Wallet',
        'Microsoft.Windows.DevHome',
        'Microsoft.Windows.Copilot',
        'Microsoft.Windows.Teams',
        'Microsoft.WindowsAlarms',
        'Microsoft.WindowsCamera',
        'microsoft.windowscommunicationsapps',
        'Microsoft.WindowsFeedbackHub',
        'Microsoft.WindowsMaps',
        'Microsoft.WindowsSoundRecorder',
        'Microsoft.WindowsTerminal',
        'Microsoft.Xbox.TCUI',
        'Microsoft.XboxApp',
        'Microsoft.XboxGameOverlay',
        'Microsoft.XboxGamingOverlay',
        'Microsoft.XboxIdentityProvider',
        'Microsoft.XboxSpeechToTextOverlay',
        'Microsoft.YourPhone',
        'Microsoft.ZuneMusic',
        'Microsoft.ZuneVideo',
        'MicrosoftCorporationII.MicrosoftFamily',
        'MicrosoftCorporationII.QuickAssist',
        'MSTeams',
        'MicrosoftTeams',
        'Microsoft.WindowsTerminal',
        'Microsoft.549981C3F5F10'
    )

    CoreProvisionedAppxPackagePrefixes = @(
        'Clipchamp.Clipchamp',
        'Microsoft.BingNews',
        'Microsoft.BingWeather',
        'Microsoft.GamingApp',
        'Microsoft.GetHelp',
        'Microsoft.Getstarted',
        'Microsoft.MicrosoftOfficeHub',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.People',
        'Microsoft.PowerAutomateDesktop',
        'Microsoft.Todos',
        'Microsoft.WindowsAlarms',
        'microsoft.windowscommunicationsapps',
        'Microsoft.WindowsFeedbackHub',
        'Microsoft.WindowsMaps',
        'Microsoft.WindowsSoundRecorder',
        'Microsoft.Xbox.TCUI',
        'Microsoft.XboxGamingOverlay',
        'Microsoft.XboxGameOverlay',
        'Microsoft.XboxSpeechToTextOverlay',
        'Microsoft.YourPhone',
        'Microsoft.ZuneMusic',
        'Microsoft.ZuneVideo',
        'MicrosoftCorporationII.MicrosoftFamily',
        'MicrosoftCorporationII.QuickAssist',
        'MicrosoftTeams',
        'Microsoft.549981C3F5F10',
        'Microsoft.Windows.Copilot',
        'MSTeams',
        'Microsoft.OutlookForWindows',
        'Microsoft.Windows.Teams',
        'Microsoft.Copilot'
    )

    SystemPackagePatterns = @{
        Core = @(
            'Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35',
            'Microsoft-Windows-Kernel-LA57-FoD-Package~31bf3856ad364e35~amd64',
            'Microsoft-Windows-LanguageFeatures-Handwriting-{0}-Package~31bf3856ad364e35',
            'Microsoft-Windows-LanguageFeatures-OCR-{0}-Package~31bf3856ad364e35',
            'Microsoft-Windows-LanguageFeatures-Speech-{0}-Package~31bf3856ad364e35',
            'Microsoft-Windows-LanguageFeatures-TextToSpeech-{0}-Package~31bf3856ad364e35',
            'Microsoft-Windows-MediaPlayer-Package~31bf3856ad364e35',
            'Microsoft-Windows-Wallpaper-Content-Extended-FoD-Package~31bf3856ad364e35',
            'Windows-Defender-Client-Package~31bf3856ad364e35~',
            'Microsoft-Windows-WordPad-FoD-Package~',
            'Microsoft-Windows-TabletPCMath-Package~',
            'Microsoft-Windows-StepsRecorder-Package~'
        )
    }

    RegistryTweaks = @{
        SystemImage = @{
            Set = @(
                @{ Path = 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache'; Name = 'SV1'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache'; Name = 'SV2'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache'; Name = 'SV1'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache'; Name = 'SV2'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zSYSTEM\Setup\LabConfig'; Name = 'BypassCPUCheck'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSYSTEM\Setup\LabConfig'; Name = 'BypassRAMCheck'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSYSTEM\Setup\LabConfig'; Name = 'BypassSecureBootCheck'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSYSTEM\Setup\LabConfig'; Name = 'BypassStorageCheck'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSYSTEM\Setup\LabConfig'; Name = 'BypassTPMCheck'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSYSTEM\Setup\MoSetup'; Name = 'AllowUpgradesWithUnsupportedTPMOrCPU'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'OemPreInstalledAppsEnabled'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'PreInstalledAppsEnabled'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SilentInstalledAppsEnabled'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableWindowsConsumerFeatures'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'ContentDeliveryAllowed'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zSOFTWARE\Microsoft\PolicyManager\current\device\Start'; Name = 'ConfigureStartPins'; Type = 'REG_SZ'; Value = '{"pinnedList": [{}]}' },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'FeatureManagementEnabled'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'PreInstalledAppsEverEnabled'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SoftLandingEnabled'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContentEnabled'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-310093Enabled'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-338388Enabled'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-338389Enabled'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-338393Enabled'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-353694Enabled'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-353696Enabled'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SystemPaneSuggestionsEnabled'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\PushToInstall'; Name = 'DisablePushToInstall'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\MRT'; Name = 'DontOfferThroughWUAU'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableConsumerAccountStateContent'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableCloudOptimizedContent'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE'; Name = 'BypassNRO'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager'; Name = 'ShippedWithReserves'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zSYSTEM\ControlSet001\Control\BitLocker'; Name = 'PreventDeviceEncryption'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Chat'; Name = 'ChatIcon'; Type = 'REG_DWORD'; Value = 3 },
                @{ Path = 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'SettingsPageVisibility'; Type = 'REG_SZ'; Value = 'hide:virus;windowsupdate' },
                @{ Path = 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarMn'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\OneDrive'; Name = 'DisableFileSyncNGSC'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; Name = 'Enabled'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Privacy'; Name = 'TailoredExperiencesWithDiagnosticDataEnabled'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy'; Name = 'HasAccepted'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\Input\TIPC'; Name = 'Enabled'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization'; Name = 'RestrictImplicitInkCollection'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization'; Name = 'RestrictImplicitTextCollection'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization\TrainedDataStore'; Name = 'HarvestContacts'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\Software\Microsoft\Personalization\Settings'; Name = 'AcceptedPrivacyPolicy'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name = 'AllowTelemetry'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zSYSTEM\ControlSet001\Services\dmwappushservice'; Name = 'Start'; Type = 'REG_DWORD'; Value = 4 },
                @{ Path = 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate'; Name = 'workCompleted'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate'; Name = 'workCompleted'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate'; Name = 'workCompleted'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsCopilot'; Name = 'TurnOffWindowsCopilot'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\Edge'; Name = 'HubsSidebarEnabled'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'DisableSearchBoxSuggestions'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\Teams'; Name = 'DisableInstallation'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Mail'; Name = 'PreventRun'; Type = 'REG_DWORD'; Value = 1 }
            )
            Remove = @(
                'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions',
                'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps',
                'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate',
                'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate',
                'HKEY_LOCAL_MACHINE\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge',
                'HKEY_LOCAL_MACHINE\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update'
            )
        }
        SetupImage = @{
            Set = @(
                @{ Path = 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache'; Name = 'SV1'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache'; Name = 'SV2'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache'; Name = 'SV1'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache'; Name = 'SV2'; Type = 'REG_DWORD'; Value = 0 },
                @{ Path = 'HKLM\zSYSTEM\Setup\LabConfig'; Name = 'BypassCPUCheck'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSYSTEM\Setup\LabConfig'; Name = 'BypassRAMCheck'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSYSTEM\Setup\LabConfig'; Name = 'BypassSecureBootCheck'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSYSTEM\Setup\LabConfig'; Name = 'BypassStorageCheck'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSYSTEM\Setup\LabConfig'; Name = 'BypassTPMCheck'; Type = 'REG_DWORD'; Value = 1 },
                @{ Path = 'HKLM\zSYSTEM\Setup\MoSetup'; Name = 'AllowUpgradesWithUnsupportedTPMOrCPU'; Type = 'REG_DWORD'; Value = 1 }
            )
            Remove = @()
        }
        CoreSetupImage = @{
            Set = @(
                @{ Path = 'HKEY_LOCAL_MACHINE\zSYSTEM\Setup'; Name = 'CmdLine'; Type = 'REG_SZ'; Value = 'X:\sources\setup.exe' }
            )
            Remove = @()
        }
    }

    ScheduledTasksToRemove = @(
        'Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser',
        'Microsoft\Windows\Customer Experience Improvement Program',
        'Microsoft\Windows\Application Experience\ProgramDataUpdater',
        'Microsoft\Windows\Chkdsk\Proxy',
        'Microsoft\Windows\Windows Error Reporting\QueueReporting'
    )

    DefenderServices = @(
        'WinDefend',
        'WdNisSvc',
        'WdNisDrv',
        'WdFilter',
        'Sense'
    )

    WindowsUpdateRunOnceCommands = @(
        @{ Name = 'StopWUPostOOBE1'; Value = 'net stop wuauserv' },
        @{ Name = 'StopWUPostOOBE2'; Value = 'sc stop wuauserv' },
        @{ Name = 'StopWUPostOOBE3'; Value = 'sc config wuauserv start= disabled' },
        @{ Name = 'DisableWUPostOOBE1'; Value = 'reg add HKLM\SYSTEM\CurrentControlSet\Services\wuauserv /v Start /t REG_DWORD /d 4 /f' },
        @{ Name = 'DisableWUPostOOBE2'; Value = 'reg add HKLM\SYSTEM\ControlSet001\Services\wuauserv /v Start /t REG_DWORD /d 4 /f' }
    )

    WindowsUpdatePolicyValues = @(
        @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; Name = 'DoNotConnectToWindowsUpdateInternetLocations'; Type = 'REG_DWORD'; Value = 1 },
        @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; Name = 'DisableWindowsUpdateAccess'; Type = 'REG_DWORD'; Value = 1 },
        @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; Name = 'WUServer'; Type = 'REG_SZ'; Value = 'localhost' },
        @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; Name = 'WUStatusServer'; Type = 'REG_SZ'; Value = 'localhost' },
        @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; Name = 'UpdateServiceUrlAlternate'; Type = 'REG_SZ'; Value = 'localhost' },
        @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'; Name = 'UseWUServer'; Type = 'REG_DWORD'; Value = 1 },
        @{ Path = 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE'; Name = 'DisableOnline'; Type = 'REG_DWORD'; Value = 1 },
        @{ Path = 'HKLM\zSYSTEM\ControlSet001\Services\wuauserv'; Name = 'Start'; Type = 'REG_DWORD'; Value = 4 },
        @{ Path = 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'; Name = 'NoAutoUpdate'; Type = 'REG_DWORD'; Value = 1 }
    )

    ServicesToDelete = @(
        'HKLM\zSYSTEM\ControlSet001\Services\WaaSMedicSVC',
        'HKLM\zSYSTEM\ControlSet001\Services\UsoSvc'
    )
}

