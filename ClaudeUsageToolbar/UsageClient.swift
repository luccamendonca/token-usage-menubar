import Foundation

struct UsageBucket: Codable {
    let utilization: Double?
    let resetsAt: String?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}

struct UsageResponse: Codable {
    let fiveHour: UsageBucket?
    let sevenDay: UsageBucket?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
    }
}

struct ParsedUsage: Equatable {
    let fiveHourPct: Double?
    let fiveHourReset: Date?
    let sevenDayPct: Double?
    let sevenDayReset: Date?
}

enum UsageClientError: Error {
    case http(status: Int, bodySnippet: String?)
    case decode
    case network(Error)
}

final class UsageClient {
    private static let endpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private static let userAgent = "claude-code/2.0.32"

    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoPlain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    func fetch() async throws -> ParsedUsage {
        let token = try KeychainCredentials.loadAccessToken()

        var req = URLRequest(url: Self.endpoint)
        req.httpMethod = "GET"
        req.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            throw UsageClientError.network(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw UsageClientError.http(status: -1, bodySnippet: nil)
        }

        guard (200 ..< 300).contains(http.statusCode) else {
            let snippet = String(data: data.prefix(256), encoding: .utf8)
            throw UsageClientError.http(status: http.statusCode, bodySnippet: snippet)
        }

        let decoded: UsageResponse
        do {
            decoded = try JSONDecoder().decode(UsageResponse.self, from: data)
        } catch {
            throw UsageClientError.decode
        }

        return ParsedUsage(
            fiveHourPct: decoded.fiveHour?.utilization,
            fiveHourReset: Self.parseDate(decoded.fiveHour?.resetsAt),
            sevenDayPct: decoded.sevenDay?.utilization,
            sevenDayReset: Self.parseDate(decoded.sevenDay?.resetsAt)
        )
    }

    private static func parseDate(_ s: String?) -> Date? {
        guard let s, !s.isEmpty else { return nil }
        if let d = isoFractional.date(from: s) { return d }
        return isoPlain.date(from: s)
    }
}
