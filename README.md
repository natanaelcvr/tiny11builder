# tiny11builder
*Scripts to build a trimmed-down Windows 11 image - now in **PowerShell**!*

## Introduction :
Tiny11 builder, now completely overhauled. <br> After more than a year (for which I am so sorry) of no updates, tiny11 builder is now a much more complete and flexible solution - one script fits all. Also, it is a steppingstone for an even more fleshed-out solution.

You can now use it on ANY Windows 11 release (not just a specific build), as well as ANY language or architecture.
This is made possible thanks to the much-improved scripting capabilities of PowerShell, compared to the older Batch release.

This is a script created to automate the build of a streamlined Windows 11 image, similar to tiny10.
The script has also been updated to use DISM's recovery compression, resulting in a much smaller final ISO size, and no utilities from external sources. The only other executable included is **oscdimg.exe**, which is provided in the Windows ADK and it is used to create bootable ISO images. 
Also included is an unattended answer file, which is used to bypass the Microsoft Account on OOBE and to deploy the image with the `/compact` flag.
It's open-source, **so feel free to add or remove anything you want!** Feedback is also much appreciated.

Also, for the very first time, **introducing tiny11 core builder**! A more powerful script, designed for a quick and dirty development testbed. Just the bare minimum, none of the fluff. 
This script generates a significantly reduced Windows 11 image. However, **it's not suitable for regular use due to its lack of serviceability - you can't add languages, updates, or features post-creation**. tiny11 Core is not a full Windows 11 substitute but a rapid testing or development tool, potentially useful for VM environments.

---

## ⚠️ Script versions:
- **tiny11maker.ps1** : The regular script, which removes a lot of bloat but keeps the system serviceable. You can add languages, updates, and features post-creation. This is the recommended script for regular use.
- ⚠️ **tiny11coremaker.ps1** : The core script, which removes even more bloat but also removes the ability to service the image. You cannot add languages, updates, or features post-creation. This is recommended for quick testing or development use.

## Instructions:
1. Download Windows 11 from the [Microsoft website](https://www.microsoft.com/software-download/windows11) or [Rufus](https://github.com/pbatard/rufus).
2. Mount the downloaded ISO image using Windows Explorer.
3. Open **PowerShell 5.1 or newer** as Administrator.
4. (Optional) Temporarily relax the execution policy for the current session:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process
   ```
   The scripts can also adjust the policy automatically when `-AcceptEula` is used.
5. Extract the repository and open the folder in the same elevated PowerShell window.

### tiny11maker.ps1 (recomended)
```powershell
./tiny11maker.ps1 -ISO E -Scratch D -ImageIndex 6 -AcceptEula -AutoElevate -Verbose
```
- `-ISO`              → drive letter of the mounted Windows 11 ISO (required in non-interactive mode).
- `-Scratch`          → drive letter to host temporary files; defaults to the script directory.
- `-ImageIndex`       → index from `Get-WindowsImage`; if omitted, the script prompts for it.
- `-AcceptEula`       → automatically set ExecutionPolicy to RemoteSigned when required.
- `-AutoElevate`      → relaunches the script elevated if needed.
- `-NoPrompt`         → fail fast when required inputs are missing (ideal for CI).
- `-SkipCleanup`/`-SkipEject`/`-PreserveResources` → control artifact retention.
- Logs are written to `tiny11_yyyyMMdd_HHmmss.log` in the script folder by default; override with `-TranscriptDirectory`.

### tiny11Coremaker.ps1 (experimental)
```powershell
./tiny11Coremaker.ps1 -ISO E -ImageIndex 6 -Force -EnableNetFx3 -AcceptEula -AutoElevate
```
- Requires `-Force` unless you want an interactive confirmation; tiny11 core is **not serviceable** afterwards.
- Supports the same quality-of-life switches as the regular script plus `-EnableNetFx3` to pre-stage .NET 3.5.
- Produces `tiny11-core.iso` in the script directory when successful.

> Use `Get-Help .\tiny11maker.ps1 -Detailed` (and the equivalent for the core script) to review the full parameter set.

### Customising removals
All app/package/registry selections live in `config/Tiny11Builder.config.psd1`. Adjust the PSD1 and rerun the scripts to tailor the output image.

---

## What is removed:
<table>
  <tbody>
    <tr>
      <th>Tiny11maker</th>
      <th>Tiny11coremaker</th>
    </tr>
    <tr>
      <td>
        <ul>
          <li>Clipchamp</li>
          <li>News</li>
          <li>Weather</li>
          <li>Xbox</li>
          <li>GetHelp</li>
          <li>GetStarted</li>
          <li>Office Hub</li>
          <li>Solitaire</li>
          <li>PeopleApp</li>
          <li>PowerAutomate</li>
          <li>ToDo</li>
          <li>Alarms</li>
          <li>Mail and Calendar</li>
          <li>Feedback Hub</li>
          <li>Maps</li>
          <li>Sound Recorder</li>
          <li>Your Phone</li>
          <li>Media Player</li>
          <li>QuickAssist</li>
          <li>Internet Explorer</li>
          <li>Tablet PC Math</li>
          <li>Edge</li>
          <li>OneDrive</li>
        </ul>
      </td>
      <td>
        <ul>
          <li>all from regular tiny +</li>
          <li>Windows Component Store (WinSxS)</li>
          <li>Windows Defender (only disabled, can be enabled back if needed)</li>
          <li>Windows Update (wouldn't work without WinSxS, enabling it would put the system in a state of failure)</li>
          <li>WinRE</li>
        </ul>
      </td>
    </tr>
  </tbody>
</table>

Keep in mind that **you cannot add back features in tiny11 core**! <br>
You will be asked during image creation if you want to enable .net 3.5 support!

---

## Known issues:
- Although Edge is removed, there are some remnants in the Settings, but the app in itself is deleted. 
- You might have to update Winget before being able to install any apps, using Microsoft Store.
- Outlook and Dev Home might reappear after some time. This is an ongoing battle, though the latest script update tries to prevent this more aggressively.
- If you are using this script on arm64, you might see a glimpse of an error while running the script. This is caused by the fact that the arm64 image doesn't have OneDriveSetup.exe included in the System32 folder.

---

## Features to be implemented:
- ~~disabling telemetry~~ (Implemented in the 04-29-24 release!)
- ~~more ad suppression~~ (Partially implemented in the 09-06-25 release!)
- improved language and arch detection
- more flexibility in what to keep and what to delete
- maybe a GUI???

And that's pretty much it for now!
## ❤️ Support the Project

If this project has helped you, please consider showing your support! A small donation helps me dedicate more time to projects like this.
Thank you!

**[Patreon](http://patreon.com/ntdev) | [PayPal](http://paypal.me/ntdev2) | [Ko-fi](http://ko-fi.com/ntdev)**
Thanks for trying it and let me know how you like it!
