import Foundation

enum JSON {
    /// Encodes a value with snake_case keys, the casing the OpenAI wire format uses.
    static func encode<Value: Encodable>(_ value: Value) -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return (try? encoder.encode(value)) ?? Data("{}".utf8)
    }

    /// Decodes a snake_case JSON body, or returns nil when it does not match the expected shape.
    static func decode<Value: Decodable>(_ type: Value.Type, from body: Data) -> Value? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try? decoder.decode(type, from: body)
    }
}
