# Microsoft Store Installer for Windows LTSC

A batch script to **restore the Microsoft Store and its dependencies** on Windows LTSC editions where it's missing.
Installs all required AppX and MSIX packages with the latest versions.

---

## ⚙️ Tested On

- **Windows 10 Enterprise LTSC 2019**
- **Windows 11 Enterprise N LTSC 24H2**

## 📦 Included Packages (Latest Versions)

- Microsoft WindowsStore: **22506.1401.9.0** (Msixbundle)
- Microsoft StorePurchaseApp: **22506.1401.3.0**
- Microsoft .NET Native Framework: **2.2.29512.0**
- Microsoft .NET Native Runtime: **2.2.28604.0**
- Microsoft VCLibs 140.00: **14.0.33519.0 / 14.0.33728.0**
- Microsoft UI Xaml: **8.2501.31001.0**
- Microsoft DesktopAppInstaller: **Downloaded from web (latest)**

---

## 🔧 Usage

**Zero-touch installation** - no user interaction required.

### Option 1: PowerShell Script (Recommended)

1. **Run as Administrator**:
   - Right-click `Add-Microsoft-Store.ps1` → **Run with PowerShell**
   - Or open PowerShell as Administrator and run:
     ```powershell
     Set-ExecutionPolicy Bypass -Scope Process -Force
     .\Add-Microsoft-Store.ps1
     ```

### Option 2: Batch Script (Legacy)

1. **Run as Administrator**:
   - Right-click `Add-Microsoft-Store.bat` → **Run as administrator**

Both scripts will automatically:
- Stop related processes
- Install all dependencies
- Install Microsoft Store
- Complete without prompts

**Why PowerShell?** Better error handling, cleaner code, and more maintainable.

---

## 🆘 Troubleshooting

### 1️⃣ Microsoft Store still doesn't work
- **Step 1:** Reboot your PC.
- **Step 2:** If it still doesn't work, open **Command Prompt as Administrator** and run:
```powershell
PowerShell -ExecutionPolicy Unrestricted -Command "& {$manifest = (Get-AppxPackage Microsoft.WindowsStore).InstallLocation + '\AppxManifest.xml' ; Add-AppxPackage -DisableDevelopmentMode -Register $manifest}"
```
- **Step 3:** Reboot again.

### 2️⃣ Clear Microsoft Store cache
1. Right-click Start
2. Select Run
3. Type: **WSReset.exe**
4. Press Enter — this will clear the Store cache

---

## 💬 Credits

- Original script by **abbodi1406**: https://forums.mydigitallife.net/threads/add-store-to-windows-10-enterprise-ltsc-LTSC.70741/page-30#post-1468779
- Updated packages from **czvv/LTSC-Add-MicrosoftStore-2025**
- Repository maintained by **lixuy**
