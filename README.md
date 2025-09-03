# GoPro Webcam Fix for Windows (HERO 8–13)

This project provides a simple fix for the issue where Windows detects your GoPro only as **MTP (storage device)** instead of a **UVC (USB Video Class) webcam**, which prevents the official **GoPro Webcam Utility** from working.

The included PowerShell script automatically installs the generic Windows UVC driver (`usbvideo.inf`) and restarts the GoPro Webcam Utility, so your GoPro HERO 8–13 can be used as a webcam in Zoom, Teams, OBS, Discord, and more.

---

## ✅ Requirements
- Windows 10 or Windows 11  
- GoPro HERO 8–13  
- USB-C **data cable** (not charge-only)  
- (Recommended) GoPro Webcam Utility installed  

---

## ▶️ Usage
1. **Download** this repository (Code → Download ZIP) or clone it.  
2. Open the `scripts/` folder.  
3. **Double click** `run-as-admin.bat`.  
   - This will launch the PowerShell script with administrator rights.  
4. Follow the on-screen instructions:  
   - The script forces the installation of the UVC driver (`usbvideo.inf`).  
   - It restarts the GoPro Webcam Utility if installed.  
5. Disconnect and reconnect your GoPro to a **USB 3.0 port** (direct connection recommended).  

---

## 🔍 Verification
- GoPro icon in the Windows tray should turn **blue**.  
- In **Device Manager**, the GoPro should appear under:  
  **Cameras / Imaging Devices → USB Video Device / GoPro Webcam**  
- In Zoom, Teams, OBS, Discord → select **GoPro Webcam** as your camera.  

---

## 🛠 Troubleshooting
- Use another **USB-C data cable** and try a different **USB 3.0 port**.  
- Update your GoPro firmware using the **GoPro Quik** mobile app.  
- Restart Windows after running the fix.  
- If the GoPro still appears as **MTP (Portable Device)**, run the script again.  

---

## 📜 License
MIT
