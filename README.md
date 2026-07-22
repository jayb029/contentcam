# ContentCam

ContentCam is a native macOS camera studio for turning a normal camera into a content-ready feed. It processes every frame locally and gives OBS a clean window to capture.

## What it does

- Landscape (16:9), vertical (9:16), and square (1:1) output
- Mirrored camera preview and composition guides
- Face blur and pixelation for privacy
- Cat, dog, and bear face covers tracked with Apple Vision
- Rounded corners with transparent edges—no green screen or chroma key
- A borderless **Clean Output** window designed for OBS capture
- No uploads, accounts, analytics, or third-party dependencies

## Run it

1. Open `ContentCam.xcodeproj` in Xcode.
2. Choose the **ContentCam** scheme and **My Mac**.
3. Run the app and allow camera access.

ContentCam requires macOS 14 or newer.

The first-run guide lets you preview three practical starting points—**Meeting ready**, **Vertical creator**, and **Privacy first**—and applies the one you choose. Open the guide again anytime with the **Guide** button in the Studio toolbar or `Command-/`.

## Use it with OBS and other camera apps

1. Configure your canvas, face cover, and corner radius in ContentCam.
2. Click **Open Clean Output**.
3. In OBS, add a **macOS Screen Capture** source and choose the `ContentCam — Clean Output` window.
4. Click **Start Virtual Camera** in OBS.
5. In Zoom, Meet, FaceTime, or another camera app, choose **OBS Virtual Camera**.

Good starting points:

- **Meetings and streams:** Landscape (16:9), light corner radius, guides off
- **Short-form video:** Vertical (9:16), composition guides on
- **Private calls:** Landscape (16:9) with blur, pixelation, or a tracked face cover

Clean Output uses a transparent, borderless window, so its rounded corners do not need a green screen or Chroma Key filter. The title bar, traffic-light controls, window shadow, and title-bar sharing control are removed from that window.

## Privacy

All frame processing uses AVFoundation, Core Image, and Vision on your Mac. ContentCam does not record or transmit video.

## Releases

This repository uses two long-lived branches:

- `dev` creates a new **Nightly** prerelease on every push. The workflow increments the build number shown in parentheses in **ContentCam > About ContentCam**, commits that change to `dev`, builds the app, and replaces the `nightly` prerelease.
- `main` creates releases only when the **Main Release** workflow is run manually. The workflow asks for a version such as `1.0` or `1.2.3`, commits that marketing version to `main` when it changed, builds the app, and publishes a tagged GitHub Release.

Both workflows build an unsigned universal macOS app and attach a ZIP to the workflow run and GitHub Release. Code signing and notarization require an Apple Developer certificate and are not configured in this repository.
