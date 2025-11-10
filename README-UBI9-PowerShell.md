# Red Hat UBI 9 Container with PowerShell

This directory contains the necessary files to create a container based on Red Hat Universal Base Image 9 (UBI9) with PowerShell 7.5.4 installed, following Microsoft's official instructions.

## 📦 Files

- `Dockerfile.ubi9-powershell` - Dockerfile to build the image
- `run-ubi9-powershell.sh` - Helper script to build and run the container

## 🚀 How to Use

### Option 1: Use the automated script

```bash
./run-ubi9-powershell.sh
```

This script will:
1. Build the container image
2. Run the container interactively
3. Start PowerShell automatically

### Option 2: Manual commands

#### Build the image:

```bash
podman build -f Dockerfile.ubi9-powershell -t ubi9-powershell:latest .
```

#### Run interactively:

```bash
podman run -it --rm ubi9-powershell:latest
```

#### Run a specific command:

```bash
podman run --rm ubi9-powershell:latest pwsh -Command "Get-Host"
```

#### Run in background:

```bash
podman run -d --name ubi9-pwsh ubi9-powershell:latest sleep infinity
podman exec -it ubi9-pwsh pwsh
```

## 📝 Installation Details

The installation follows the **direct download** method recommended by Microsoft for RHEL/UBI:

- **PowerShell Version**: 7.5.4
- **Installation URL**: https://github.com/PowerShell/PowerShell/releases/download/v7.5.4/powershell-7.5.4-1.rh.x86_64.rpm
- **Base Image**: Red Hat Universal Base Image 9 (UBI9) - `registry.access.redhat.com/ubi9/ubi:latest`
- **Base System**: Red Hat Enterprise Linux 9 (compatible)
- **Documentation**: [Microsoft Learn - Install PowerShell on RHEL](https://learn.microsoft.com/en-us/powershell/scripting/install/install-rhel?view=powershell-7.5)

## 🔍 Verify Installation

Inside the container, you can verify the PowerShell version:

```bash
pwsh --version
```

Or run PowerShell commands:

```bash
pwsh -Command "\$PSVersionTable"
```

## 📚 PowerShell Paths in the Container

- **$PSHOME**: `/opt/microsoft/powershell/7/`
- **User profile**: `~/.config/powershell/profile.ps1`
- **User modules**: `~/.local/share/powershell/Modules`
- **History**: `~/.local/share/powershell/PSReadLine/ConsoleHost_history.txt`

## 🔧 Customization

To add custom modules or scripts, you can:

1. Mount a volume when running the container:
   ```bash
   podman run -it --rm -v ~/my-scripts:/scripts:Z ubi9-powershell:latest
   ```

2. Create a new Dockerfile based on this image:
   ```dockerfile
   FROM ubi9-powershell:latest
   COPY my-script.ps1 /opt/scripts/
   ```

## 🧹 Cleanup

To remove the image:

```bash
podman rmi ubi9-powershell:latest
```

To remove stopped containers:

```bash
podman container prune
```

## 📖 References

- [Microsoft Learn - Install PowerShell on RHEL](https://learn.microsoft.com/en-us/powershell/scripting/install/install-rhel?view=powershell-7.5)
- [PowerShell on GitHub](https://github.com/PowerShell/PowerShell)
- [Red Hat Universal Base Images](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)
