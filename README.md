# ContentCam

ContentCam is a native macOS camera studio for turning a normal camera into a content-ready feed. It processes every frame locally and gives OBS a clean window to capture.

## What it does

- Landscape (16:9), vertical (9:16), and square (1:1) output
- Mirrored camera preview and composition guides
- Face blur and pixelation for privacy
- Cat, dog, and bear face covers tracked with Apple Vision
- Rounded corners with transparent edges—no green screen or chroma key
- A borderless **Clean Output** window designed for OBS capture
- Signed in-app updates from GitHub, with Production and Nightly channels and a native changelog
- No uploads, accounts, or analytics

## Run it

1. Open `ContentCam.xcodeproj` in Xcode.
2. Choose the **ContentCam** scheme and **My Mac**.
3. Run the app and allow camera access.

ContentCam requires macOS 14 or newer.

The first-run guide lets you preview three practical starting points—**Meeting ready**, **Vertical creator**, and **Privacy first**—and choose Production or Nightly updates. You can change the update channel later in **ContentCam > Settings**, and open the release history from **Help > Changelog…** or Settings.

For usage, troubleshooting, update, and diagnostic-log details, open **Help > ContentCam Documentation** or read [the documentation](DOCUMENTATION.md).

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

All frame processing uses AVFoundation, Core Image, and Vision on your Mac. ContentCam does not record or transmit video. The updater contacts this repository's GitHub Releases files to check for and download signed app updates, and the changelog retrieves public release notes from the GitHub API; camera frames are never included in those requests.

## Releases

This repository uses two release channels:

- **Nightly** releases are created on demand from **Actions > Nightly Release**. The workflow asks for any existing source branch, including `main`, then publishes a new permanent prerelease tagged `nightly-<build number>`. It assigns the timestamp build number shown in parentheses in **ContentCam > About ContentCam**, commits that build number back to the selected source branch, and publishes a separate release instead of replacing an older Nightly. Its detailed notes identify the source, installation and compatibility details, and every commit since the previous Nightly. If that Nightly is not an ancestor, it compares against the latest Production release instead.
- `main` creates releases only when the **Main Release** workflow is run manually. The workflow asks for a version such as `1.0` or `1.2.3`, assigns a newer timestamp build number, commits the release version to `main`, builds the app, and publishes a tagged GitHub Release with installation instructions, compatibility and privacy details, build metadata, and generated change notes. Its release notes also identify every commit since the previous stable release by full commit SHA.

Both workflows build an unsigned universal macOS app inside a branded drag-to-Applications DMG, embed the detailed release notes in the signed Sparkle appcast, and attach the DMG and appcast to the GitHub Release. Sparkle shows that version-specific changelog inside its **update available** popup and verifies the update signature before installing it. Production uses GitHub’s latest stable-release feed; Nightly publishes the newest appcast to the dedicated `nightly-feed` branch so each actual Nightly release can remain permanent. The former rolling `nightly` release receives only a copy of that feed file so older installed builds can transition to the new channel address; its release notes and build artifact are no longer replaced. Apple code signing and notarization still require an Apple Developer certificate and are not configured in this repository.

### Promote dev changes to main

Use a pull request to move tested development work into the release branch:

1. Make and push changes on `dev` or another branch.
2. To create a test build, open **Actions > Nightly Release**, click **Run workflow**, and enter that branch’s name. You can also enter `main` when you want a Nightly from the production branch.
3. On GitHub, open **Pull requests**, click **New pull request**, set **base** to `main` and **compare** to your development branch, then create the pull request.
4. Review the changes and Nightly build, then merge the pull request. Merging updates `main`, but it does **not** publish a release.
5. When you are ready to publish, open **Actions > Main Release**, click **Run workflow**, choose `main`, enter the new version, and run it.

If GitHub reports that `dev` is behind `main` after a release, merge `main` back into `dev` before starting the next round of work:

```bash
git switch dev
git pull
git merge origin/main
git push
```
