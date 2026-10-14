import Foundation

struct ImageGenerationRequest: Decodable, Sendable {
    let prompt: String
    let style: String?
    let n: Int?
}

struct ImageGenerationResponse: Encodable {
    struct Image: Encodable {
        let b64Json: String
    }

    let created = Int(Date().timeIntervalSince1970)
    let data: [Image]

    init(base64Images: [String]) {
        data = base64Images.map(Image.init)
    }
}
