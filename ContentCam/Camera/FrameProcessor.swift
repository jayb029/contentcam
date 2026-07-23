import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision

final class FrameProcessor {
    private let context = CIContext(options: [
        .cacheIntermediates: false,
        .priorityRequestLow: false
    ])
    private var frameNumber = 0
    private var trackedFaces: [VNFaceObservation] = []
    private var emojiCache: [String: CIImage] = [:]

    func process(pixelBuffer: CVPixelBuffer, settings: FrameSettings) -> CGImage? {
        var image = normalized(CIImage(cvPixelBuffer: pixelBuffer))

        if settings.isMirrored {
            image = mirror(image)
        }

        image = crop(
            image,
            to: settings.outputAspectRatio,
            scale: settings.cropScale,
            offset: settings.cropOffset
        )

        if settings.faceEffect != .none {
            updateFaces(in: image)
            image = applyFaceEffect(settings.faceEffect, to: image, padding: settings.facePadding)
        } else {
            trackedFaces = []
        }

        return context.createCGImage(image, from: image.extent)
    }

    private func normalized(_ image: CIImage) -> CIImage {
        image.transformed(by: CGAffineTransform(
            translationX: -image.extent.origin.x,
            y: -image.extent.origin.y
        ))
    }

    private func mirror(_ image: CIImage) -> CIImage {
        image.transformed(by: CGAffineTransform(
            translationX: image.extent.width,
            y: 0
        ).scaledBy(x: -1, y: 1))
    }

    private func crop(
        _ image: CIImage,
        to targetAspect: CGFloat,
        scale: CGFloat,
        offset: CGSize
    ) -> CIImage {
        let source = image.extent
        let sourceAspect = source.width / source.height
        let baseSize: CGSize

        if sourceAspect > targetAspect {
            let width = source.height * targetAspect
            baseSize = CGSize(width: width, height: source.height)
        } else {
            let height = source.width / targetAspect
            baseSize = CGSize(width: source.width, height: height)
        }

        let safeScale = min(max(scale, 1), 4)
        let cropSize = CGSize(
            width: baseSize.width / safeScale,
            height: baseSize.height / safeScale
        )
        let maximumShiftX = max(0, (source.width - cropSize.width) / 2)
        let maximumShiftY = max(0, (source.height - cropSize.height) / 2)
        let horizontalPosition = min(max(offset.width, -1), 1)
        let verticalPosition = min(max(offset.height, -1), 1)
        let rect = CGRect(
            x: source.midX - cropSize.width / 2 - horizontalPosition * maximumShiftX,
            y: source.midY - cropSize.height / 2 + verticalPosition * maximumShiftY,
            width: cropSize.width,
            height: cropSize.height
        )

        return normalized(image.cropped(to: rect))
    }

    private func updateFaces(in image: CIImage) {
        frameNumber += 1
        guard frameNumber % 4 == 1 || trackedFaces.isEmpty else { return }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(ciImage: image, orientation: .up)
        do {
            try handler.perform([request])
            trackedFaces = request.results ?? []
        } catch {
            trackedFaces = []
        }
    }

    private func applyFaceEffect(_ effect: FaceEffect, to image: CIImage, padding: CGFloat) -> CIImage {
        guard !trackedFaces.isEmpty else { return image }

        if let emoji = effect.emoji {
            return trackedFaces.reduce(image) { current, observation in
                overlayEmoji(emoji, on: current, face: faceRect(observation, in: image.extent, padding: padding))
            }
        }

        let mask = trackedFaces.reduce(CIImage.empty()) { current, observation in
            let rect = faceRect(observation, in: image.extent, padding: padding)
            let generator = CIFilter.roundedRectangleGenerator()
            generator.extent = rect
            generator.radius = Float(min(rect.width, rect.height) / 2)
            generator.color = CIColor.white
            return generator.outputImage!.composited(over: current)
        }.cropped(to: image.extent)

        let effected: CIImage
        switch effect {
        case .blur:
            let filter = CIFilter.gaussianBlur()
            filter.inputImage = image.clampedToExtent()
            filter.radius = Float(max(20, image.extent.width * 0.025))
            effected = filter.outputImage!.cropped(to: image.extent)
        case .pixelate:
            let filter = CIFilter.pixellate()
            filter.inputImage = image
            filter.scale = Float(max(24, image.extent.width * 0.025))
            effected = filter.outputImage!.cropped(to: image.extent)
        default:
            return image
        }

        let blend = CIFilter.blendWithMask()
        blend.inputImage = effected
        blend.backgroundImage = image
        blend.maskImage = mask
        return blend.outputImage!.cropped(to: image.extent)
    }

    private func faceRect(_ observation: VNFaceObservation, in extent: CGRect, padding: CGFloat) -> CGRect {
        let box = observation.boundingBox
        var rect = CGRect(
            x: box.minX * extent.width,
            y: box.minY * extent.height,
            width: box.width * extent.width,
            height: box.height * extent.height
        )
        let insetX = rect.width * padding
        let insetY = rect.height * (padding + 0.08)
        rect = rect.insetBy(dx: -insetX, dy: -insetY)
        return rect.intersection(extent)
    }

    private func overlayEmoji(_ emoji: String, on image: CIImage, face rect: CGRect) -> CIImage {
        guard rect.width > 4, rect.height > 4 else { return image }
        let source = emojiImage(emoji)
        let scale = max(rect.width / source.extent.width, rect.height / source.extent.height)
        let scaled = source.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let translated = scaled.transformed(by: CGAffineTransform(
            translationX: rect.midX - scaled.extent.midX,
            y: rect.midY - scaled.extent.midY
        ))
        return translated.composited(over: image).cropped(to: image.extent)
    }

    private func emojiImage(_ emoji: String) -> CIImage {
        if let cached = emojiCache[emoji] { return cached }

        let size = CGSize(width: 256, height: 256)
        let image = NSImage(size: size)
        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "AppleColorEmoji", size: 190) ?? NSFont.systemFont(ofSize: 190)
        ]
        let string = NSAttributedString(string: emoji, attributes: attributes)
        let stringSize = string.size()
        string.draw(at: CGPoint(
            x: (size.width - stringSize.width) / 2,
            y: (size.height - stringSize.height) / 2
        ))
        image.unlockFocus()

        guard let data = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data),
              let cgImage = bitmap.cgImage else {
            return CIImage.empty()
        }
        let result = CIImage(cgImage: cgImage)
        emojiCache[emoji] = result
        return result
    }

}
