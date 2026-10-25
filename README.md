# ⚡ SonicPulse Android — Mobile YouTube MP3 Downloader

A modern Flutter application for Android to download YouTube songs and full playlists directly into your phone's storage.

---

## 📱 Features

- **🚀 Direct Mobile Extraction**: Powered by pure Dart (`youtube_explode_dart`) with zero external binary or Python requirements.
- **🎵 Playlist Batch Downloads**: Paste any playlist link to download all songs in sequence directly into `/storage/emulated/0/Download/SonicPulse/`.
- **⚡ Android Share Menu**: Tap "Share" on any YouTube video in the official YouTube app and choose **SonicPulse** to paste automatically!
- **🎧 High Fidelity Audio**: Downloads highest available bitrate audio stream.
- **🖼️ Video Thumbnails & Live Progress**: Real-time download progress bar and album thumbnail previews.
- **☁️ Cloud Compilation**: Includes a pre-configured GitHub Actions workflow that builds the installable `.apk` automatically in the cloud for free!

---

## 🛠️ How to Build Your APK in 3 Minutes (Free Cloud Build)

You do **not** need Android Studio or Flutter installed on your PC. GitHub builds it for you!

### Step 1: Create a GitHub Repository
1. Go to [github.com/new](https://github.com/new).
2. Name your repository (e.g. `sonicpulse-android`).
3. Leave it Public or Private and click **Create repository**.

### Step 2: Push This Folder to GitHub
Open PowerShell in this folder:
```powershell
cd C:\Users\wbenm\Desktop\sonicpulse-android
git init
git add .
git commit -m "Initial commit for SonicPulse Android"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/sonicpulse-android.git
git push -u origin main
```

### Step 3: Download Your APK!
1. In your GitHub repository, click on the **Actions** tab at the top.
2. You'll see the **"Build Android APK"** workflow running automatically.
3. Once it finishes (around 2–3 minutes):
   - Click on the completed run ➔ Scroll to **Artifacts** ➔ Download **`SonicPulse-Release-APK`**.
   - Or check the **Releases** tab on GitHub for direct `.apk` downloads!
4. Send the `.apk` file to your phone or your friends' phones, tap it, and install!

---

## 📂 Project Structure
- `lib/main.dart`: App entry point with custom dark Material 3 theme.
- `lib/services/youtube_downloader.dart`: Pure Dart streaming & Android storage manager.
- `lib/screens/home_screen.dart`: Sleek mobile UI with playlist batching.
- `.github/workflows/build_apk.yml`: Automated CI/CD cloud APK compilation.
- `assets/logo.png`: Official SonicPulse logo icon.
