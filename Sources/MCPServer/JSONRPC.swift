import Foundation

// MARK: - JSON-RPC Message Classification

/// Classifies a raw JSON-RPC message for routing purposes.
///
/// Used by transports to determine where to route outgoing messages:
/// - Responses are routed to the originating request's stream
/// - Notifications and server requests are routed to the standalone GET stream
package enum JSONRPCMessageKind {
    case request(id: String, method: String)
    case notification(method: String)
    case response(id: String)

    /// Attempts to classify raw JSON-RPC data.
    /// Returns `nil` if the data cannot be parsed or classified.
    package init?(data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let id = Self.extractID(from: json)

        if let method = json["method"] as? String {
            if let id {
                self = .request(id: id, method: method)
            } else {
                self = .notification(method: method)
            }
        } else if json["result"] != nil || json["error"] != nil {
            guard let id else { return nil }
            self = .response(id: id)
        } else {
            return nil
        }
    }

    /// Whether this message is a JSON-RPC response (success or error).
    var isResponse: Bool {
        if case .response = self { return true }
        return false
    }

    /// Whether this message is an `initialize` request.
    package var isInitializeRequest: Bool {
        if case .request(_, let method) = self {
            return method == "initialize"
        }
        return false
    }

    private static func extractID(from json: [String: Any]) -> String? {
        if let stringID = json["id"] as? String {
            return stringID
        } else if let intID = json["id"] as? Int {
            return String(intID)
        }
        return nil
    }
}

