import SwiftUI

enum OutputFormat: String, CaseIterable, Identifiable {
    case landscape
    case portrait
    case square

    var id: String { rawValue }

    var title: String {
        switch self {
        case .landscape: "Landscape"
        case .portrait: "Vertical"
        case .square: "Square"
        }
    }

    var ratioLabel: String {
        switch self {
        case .landscape: "16:9"
        case .portrait: "9:16"
        case .square: "1:1"
        }
    }

    var aspectRatio: CGFloat {
        switch self {
        case .landscape: 16 / 9
        case .portrait: 9 / 16
        case .square: 1
        }
    }

    var symbol: String {
        switch self {
        case .landscape: "rectangle"
        case .portrait: "rectangle.portrait"
        case .square: "square"
        }
    }
}

enum FaceEffect: String, CaseIterable, Identifiable {
    case none
    case blur
    case pixelate
    case cat
    case dog
    case bear

    var id: String { rawValue }

    var title: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .none: "person.crop.circle"
        case .blur: "drop.halffull"
        case .pixelate: "square.grid.3x3.fill"
        case .cat: "🐱"
        case .dog: "🐶"
        case .bear: "🐻"
        }
    }

    var emoji: String? {
        switch self {
        case .cat: "🐱"
        case .dog: "🐶"
        case .bear: "🐻"
        default: nil
        }
    }

}

struct FrameSettings {
    var outputFormat: OutputFormat = .landscape
    var faceEffect: FaceEffect = .none
    var isMirrored = true
    var facePadding: CGFloat = 0.18
    var cropScale: CGFloat = 1
    var cropOffset: CGSize = .zero
}
