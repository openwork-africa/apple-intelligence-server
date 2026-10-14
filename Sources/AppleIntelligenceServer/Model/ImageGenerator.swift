import CoreGraphics
import Foundation
import ImageIO
import ImagePlayground
import UniformTypeIdentifiers

struct ImageGenerator: Sendable {
    static let largestBatch = 4

    /// Creates images with Image Playground and returns each as base64 PNG.
    func generate(prompt: String, styleName: String?, count: Int?) async throws -> [String] {
        let batchSize = min(max(count ?? 1, 1), ImageGenerator.largestBatch)
        var base64Images: [String] = []
        do {
            let creator = try await ImageCreator()
            for try await image in creator.images(for: [.text(prompt)], style: style(named: styleName), limit: batchSize) {
                if let encoded = base64PNG(image.cgImage) { base64Images.append(encoded) }
            }
        } catch {
            throw GenerationFailure.failed("Image Playground could not create the image: \(error)")
        }
        guard !base64Images.isEmpty else { throw GenerationFailure.noImages }
        return base64Images
    }

    private func style(named name: String?) -> ImagePlaygroundStyle {
        switch name?.lowercased() {
        case "illustration": .illustration
        case "sketch": .sketch
        default: .animation
        }
    }

    private func base64PNG(_ image: CGImage) -> String? {
        let encoded = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(encoded, UTType.png.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, nil)
        return CGImageDestinationFinalize(destination) ? (encoded as Data).base64EncodedString() : nil
    }
}
