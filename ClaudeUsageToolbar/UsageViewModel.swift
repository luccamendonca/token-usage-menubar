import Foundation
import SwiftUI

@MainActor
final class UsageViewModel: ObservableObject {
    @Published var menuBarTitle: String = "Claude …"
    @Published var detailLines: [String] = []
    @Published var lastError: String?
    @Published var lastUpdated: Date?

    private let client = UsageClient()
    private var pollTask: Task<Void, Never>?

    /// Poll interval (seconds). Plan suggested 60–300s; 120 is a reasonable default.
    private let pollIntervalSeconds: UInt64 = 120

    init() {
        Task { await refresh() }
        startPolling()
    }

    deinit {
        pollTask?.cancel()
    }

    func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [pollIntervalSeconds] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: pollIntervalSeconds * 1_000_000_000)
                if Task.isCancelled { break }
                await refresh()
            }
        }
    }

    func refresh() async {
        lastError = nil
        do {
            let u = try await client.fetch()
            lastUpdated = Date()
            menuBarTitle = Self.formatMenuBarLine(u)
            detailLines = Self.formatDetailLines(u)
        } catch {
            lastError = Self.describe(error)
            menuBarTitle = Self.fallbackTitle(for: error)
            detailLines = []
        }
    }

    /// Matches requested shape: "<5h>% (<reset>) <7d>% (<reset>)"
    static func formatMenuBarLine(_ u: ParsedUsage) -> String {
        let w = formatPct(u.fiveHourPct)
        let wr = formatResetCompact(u.fiveHourReset)
        let s = formatPct(u.sevenDayPct)
        let sr = formatResetCompact(u.sevenDayReset, showDate: true)
        return "\(w)% (\(wr)) | \(s)% (\(sr))"
    }

    private static func formatDetailLines(_ u: ParsedUsage) -> [String] {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let lines: [String] = [
            "5-hour window: \(formatPct(u.fiveHourPct))%",
            "  Resets at: \(u.fiveHourReset.map { iso.string(from: $0) } ?? "—")",
            "7-day window: \(formatPct(u.sevenDayPct))%",
            "  Resets at: \(u.sevenDayReset.map { iso.string(from: $0) } ?? "—")",
        ]
        return lines
    }

    private static func formatPct(_ v: Double?) -> String {
        guard let v else { return "—" }
        if abs(v - floor(v)) < 0.05 { return String(format: "%.0f", v) }
        return String(format: "%.1f", v)
    }

    private static func formatResetCompact(
        _ d: Date?, showTime: Bool = true, showDate: Bool = false
    ) -> String {
        guard let d else { return "—" }
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.timeZone = .autoupdatingCurrent
        f.dateStyle = showDate ? .short : .none
        f.timeStyle = showTime ? .short : .none
        return f.string(from: d)
    }

    private static func describe(_ error: Error) -> String {
        if let e = error as? KeychainCredentialsError {
            switch e {
            case .securityCommandFailed(let code, let stderr):
                let hint = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
                if code != 0, hint.isEmpty {
                    return
                        "Keychain: no Claude Code credentials (sign in with Claude Code on this Mac)."
                }
                return "Keychain error (\(code)): \(hint.isEmpty ? "no item?" : hint)"
            case .noData:
                return "Keychain returned empty credentials."
            case .decodeFailed:
                return "Could not parse Claude Code credentials JSON."
            }
        }
        if let e = error as? UsageClientError {
            switch e {
            case .http(let status, let snippet):
                if status == 401 || status == 403 {
                    return "Auth failed (\(status)). Re-open Claude Code or sign in again."
                }
                let tail = snippet.map { ": \($0)" } ?? ""
                return "API HTTP \(status)\(tail)"
            case .decode:
                return "Unexpected API response shape (schema may have changed)."
            case .network(let err):
                return "Network: \(err.localizedDescription)"
            }
        }
        return error.localizedDescription
    }

    private static func fallbackTitle(for error: Error) -> String {
        if let e = error as? KeychainCredentialsError {
            switch e {
            case .securityCommandFailed, .noData, .decodeFailed:
                return "Claude —"
            }
        }
        if let e = error as? UsageClientError {
            switch e {
            case .http(let status, _):
                if status == 401 || status == 403 { return "Claude auth" }
                return "Claude \(status)"
            case .decode:
                return "Claude API ?"
            case .network:
                return "Claude offline"
            }
        }
        return "Claude …"
    }
}
