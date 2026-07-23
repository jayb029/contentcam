# ContentCam Documentation

ContentCam is a native macOS camera studio that turns your camera into a polished, content-ready feed for OBS and other video apps. Camera processing stays on your Mac.

## Getting started

1. Allow camera access when ContentCam asks for it.
2. Choose a camera from the Source section.
3. Pick a landscape, vertical, square, or custom canvas.
4. Adjust framing and choose a face effect if you want one.
5. Select **Open Clean Output**.
6. In OBS, add a **macOS Screen Capture** source and select `ContentCam — Clean Output`.
7. Start the OBS Virtual Camera, then select it in your meeting or recording app.

The in-app Guide offers a quick first-run setup. This document is the longer-term reference for using and troubleshooting ContentCam.

## Camera access

If the preview says **Camera blocked**, open **System Settings > Privacy & Security > Camera** and enable ContentCam. Return to ContentCam afterward; the app retries the camera when it becomes active.

If no camera appears, make sure another app is not holding exclusive access to it, reconnect external cameras, and reopen ContentCam.

## Clean Output

Clean Output is a transparent, borderless window intended for capture. Its rounded corners do not require a green screen or Chroma Key filter. Resize the window as needed; it retains the canvas aspect ratio selected in the Studio.

## Updates

Choose the Production or Nightly update channel in **ContentCam > Settings**. You can manually check with **Help > Check for Updates…**. Open **Help > Changelog…** or select **View Changelog…** in Settings to read Production and Nightly release history inside ContentCam.

- **Production** receives stable releases intended for everyday use.
- **Nightly** receives the newest in-progress build and may be less stable. Each Nightly is published as a separate prerelease so its notes and download remain available.

When an update is available, the update popup includes the changelog for the exact version ContentCam is offering to download.

Repository maintainers create Nightlies on demand from **Actions > Nightly Release** by entering the source branch to build. Any existing branch can be selected, including `main`; the update-metadata-only `nightly-feed` branch is excluded.

## Diagnostic logs

ContentCam keeps a bounded diagnostic log in memory while the app is running. It records app lifecycle, camera setup, output-window, guide, update, and Help-menu events. It does not include camera frames.

Nothing is written to disk automatically. To save a copy for troubleshooting, choose **Help > Export Logs…**, select any folder and filename in the macOS save panel, then click **Export**. Quitting ContentCam clears the in-memory log.

## Privacy

ContentCam processes camera frames locally with Apple system frameworks. It does not record or transmit video, and it does not include camera frames in exported diagnostic logs. The updater connects to this repository’s GitHub Releases files to check for and download updates. The changelog requests public release metadata and notes from GitHub’s API when you open it.

## More help

If the steps above do not resolve a problem, export a diagnostic log and include it when opening an issue in the [ContentCam repository](https://github.com/jayb029/contentcam/issues).
