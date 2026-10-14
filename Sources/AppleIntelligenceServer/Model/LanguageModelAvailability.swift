import FoundationModels

enum LanguageModelAvailability: Equatable {
    case available
    case unavailable(reason: String)

    static var current: LanguageModelAvailability {
        switch SystemLanguageModel.default.availability {
        case .available: .available
        case .unavailable(let reason): .unavailable(reason: String(describing: reason))
        }
    }

    var isAvailable: Bool { self == .available }

    var unavailableReason: String? {
        if case .unavailable(let reason) = self { reason } else { nil }
    }

    var summary: String {
        unavailableReason.map { "model unavailable: \($0)" } ?? "model available"
    }

    /// Throws when the on-device model cannot be used right now.
    static func requireAvailable() throws {
        if let reason = current.unavailableReason { throw GenerationFailure.modelUnavailable(reason: reason) }
    }
}
