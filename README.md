# 📸 ExternCamera – Save Photos & Videos Directly to External USB on Jailbroken iPhone

> A custom camera app for **jailbroken iOS devices** that allows you to **save photos and videos directly to external USB storage** via Lightning (using Camera Connection Kit). Perfect for devices with limited internal storage — like the **iPhone SE (2016) with 16GB**.

🚀 No more worrying about running out of space.  
💾 Just plug in a USB drive and shoot — files go straight to external memory.

---

## 🎯 Why This App?

The stock iOS Camera app **always saves to internal storage first**, and there's no way to redirect it — even with jailbreak.

But with **ExternCam**, you get full control:
- Choose where to save: **Internal** or **External USB**
- Bypass the 16GB limit
- Use USB flash drives like a **memory card**
- Built with native AVFoundation for smooth, iOS-like experience

Perfect for photographers, travelers, or anyone with a low-storage iPhone!

---

## 🌟 Features

✅ **Save directly to USB** (no internal storage used)  
✅ **Jailbreak required** (tested on checkra1n, iOS 15.8.2)  
✅ **iOS-native UI** – looks and feels like the default Camera app  
✅ **Supports photo & video capture**  
✅ **Timer, flash, zoom, grid, front/back camera toggle**  
✅ **Auto-detects USB drives** (FAT32 formatted)  
✅ **No App Store needed** – sideload via Xcode  
✅ **Open source & customizable**

---

## 📦 Requirements

| Component | Notes |
|---------|-------|
| **iPhone** | iPhone SE (2016) or any jailbroken iOS device |
| **iOS Version** | 15.0 to 15.8.2 (checkra1n compatible) |
| **Jailbreak** | ✅ Required (using **checkra1n**) |
| **Apple CCK** | Camera Connection Kit (original recommended) |
| **OTG Adapter** | Lightning to USB-A |
| **USB Flash Drive** | Formatted as **FAT32** (max 32GB, <4GB per file) |
| **Mac + Xcode** | To build and install |
| **Apple ID** | Free account for code signing |

> ⚠️ NTFS/exFAT not supported. FAT32 only.

## 🖼️ How It Works

[User] -> [Open ExternCamera] -> [App detects USB drive (if connected)] -> [Choose: Save to Internal or USB] -> [Take photo / Record video] -> [File saved DIRECTLY to USB drive]


#📁 Path on device:  
`/private/var/mobile/Media/USBDRIVE/`

---

## 🚀 How to Use

1. 🔌 Connect USB drive via CCK + OTG
2. 📱 Open **ExternCamera**
3. 💬 Choose: _"Save to Internal"_ or _"Save to External"_
4. 📸 Take photos or record videos
5. 💾 Files saved instantly to your USB
6. 🖥️ Eject & view on PC/Mac

> Your internal storage stays clean!

---

## 📦 How to Build & Install (Step by Step)

Follow these steps to **build the app and install it on your jailbroken iPhone**, even without a paid Apple Developer account.

---

### 1. Prerequisites

- ✅ **Mac** (macOS)
- ✅ **Xcode** (Download from Mac App Store)
- ✅ **iPhone connected via USB**
- ✅ **Apple ID** (free account is enough)
- ✅ **Jailbroken iPhone** (checkra1n, iOS 15.8.2)
- ✅ **Trust This Computer** enabled on iPhone

---

### 2. Open Project in Xcode

1. Open `KameraCustom.xcodeproj` in Xcode.
2. Wait for Xcode to index the project.

---

### 3. Configure Code Signing

1. Click on the project name (`ExternCamera`) in the left sidebar.
2. Under **Target**, select `ExternCamera`.
3. Go to **Signing & Capabilities**.
4. Check: ✅ **Automatically manage signing**
5. In **Team**, select your **Apple ID**.
   - If not added: Click "Add Account" and sign in.

> Xcode will automatically create a free provisioning profile.

---

### 4. Select Your iPhone Device

1. In the top toolbar, next to the ▶️ Run button, select your connected iPhone:
   - Instead of "Generic iOS Device", choose:
     ```
     iPhone (Your Name)
     ```
2. Make sure you see a ✅ green dot.

---

### 5. Build & Run (Install via Xcode)

1. Click the ▶️ **Run button**.
2. Xcode will:
   - Compile the app
   - Sign it with your Apple ID
   - Install it on your iPhone

> First time? You may see: _"Unable to install ‘ExternCamera’"_ — just tap **Try Again**.

---

### 6. Trust the App on iPhone

After install, open:
- **Settings** → **General** → **VPN & Device Management**
- Tap your **Apple ID profile** (e.g., "Apple Development: YOUR_EMAIL")
- Tap **"Trust [Your Email]"**

Now go back and open the **ExternCamera** app.

---

### 7. How to Export as `.ipa` File (Optional)

If you want to **save the app as .ipa** for backup or share (without Xcode), follow this:

#### Method: Using Xcode Archive

1. In Xcode, go to:
   - **Product** → **Destination** → **Generic iOS Device**
2. Go to:
   - **Product** → **Archive**
3. When archive finishes, the **Organizer** window opens.
4. Select the archive → Click **Distribute App**
5. Choose:
   - **Development** → **Your Apple ID Team** → **Export as .ipa**
6. Save the `.ipa` file to your Mac.

> File location: e.g., `~/Desktop/ExternCamera.ipa`

---

### 8. Re-Install `.ipa` Without Xcode (Using Sideloadly or AltStore)

You can install the `.ipa` again without Xcode using free tools:

#### Option A: Sideloadly (Windows/Mac)
- Download: [https://sideloadly.io](https://sideloadly.io)
- Connect iPhone
- Drag & drop `.ipa` into Sideloadly
- Click "Start"
- Trust app in **Settings** (same as above)

#### Option B: AltStore (Mac/Windows)
- Download: [https://altstore.io](https://altstore.io)
- Install AltServer on Mac
- Connect iPhone → Open AltServer → Install `.ipa`
- App will appear on home screen

> AltStore requires iPhone to be connected to Mac every 7 days for re-signing (free).

---

### 9. Use with USB Drive (CCK + OTG)

1. Plug in **USB flash drive** via:
   - **Apple Camera Connection Kit (CCK)**
   - **OTG Adapter (Lightning to USB-A)**
2. Make sure USB is **formatted as FAT32**
3. Open **ExternCamera**
4. When taking a photo/video:
   - Choose: **"Save to External"**
5. File is saved directly to:
   /private/var/mobile/Media/USBDRIVE/

> You can safely eject the USB and view files on PC/Mac.

---

## 🧪 Troubleshooting

| Issue | Solution |
|------|----------|
| ❌ "Code Signing Error" | Make sure Apple ID is set in **Team**, and internet is on |
| ❌ App crashes on launch | Check console in Xcode; may need to re-trust developer |
| ❌ USB not detected | Reboot iPhone, reconnect USB, use original CCK |
| ❌ Can't install .ipa | Use Sideloadly or AltStore; free Apple ID only allows 3 apps at a time |
| ❌ Video not recording | Make sure `NSMicrophoneUsageDescription` is in `Info.plist` |

---

## 🎯 Final Result

✅ You now have a **fully working camera app**  
✅ That **saves directly to USB**  
✅ Runs on your **jailbroken iPhone SE (16GB)**  
✅ Without needing paid Apple Developer Program

You’ve turned your old iPhone into a **camera with external memory support** — just like a DSLR with an SD card! 📸💾

---

## 🤝 Want to Improve It?

Feel free to:
- Add auto-sync
- Support exFAT via jailbreak tweaks
- Add cloud backup
- Implement file browser inside the app

PRs are welcome!

---

## 📢 Disclaimer

This app is designed **only for jailbroken devices**.  
Use at your own risk.  
Not affiliated with Apple Inc.

---

## 🎉 Credits

Built with ❤️ for the jailbreak community.  
Special thanks to the checkra1n team and iOS open-source developers.

📸 **Shoot freely. Store bigger.**
