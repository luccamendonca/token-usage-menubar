import Foundation

struct ClaudeCodeCredentials: Decodable {
    let claudeAiOauth: OAuthCreds

    struct OAuthCreds: Decodable {
        let accessToken: String
    }
}

enum KeychainCredentialsError: Error {
    case securityCommandFailed(exitCode: Int32, stderr: String)
    case noData
    case decodeFailed
}

enum KeychainCredentials {
    static let service = "Claude Code-credentials"

    static func loadAccessToken() throws -> String {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        proc.arguments = ["find-generic-password", "-s", service, "-w"]

        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = errPipe

        try proc.run()
        proc.waitUntilExit()

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        let stderr = String(data: errData, encoding: .utf8) ?? ""

        guard proc.terminationStatus == 0, !outData.isEmpty else {
            throw KeychainCredentialsError.securityCommandFailed(exitCode: proc.terminationStatus, stderr: stderr)
        }

        guard let str = String(data: outData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty else {
            throw KeychainCredentialsError.noData
        }

        do {
            let decoded = try JSONDecoder().decode(ClaudeCodeCredentials.self, from: Data(str.utf8))
            let token = decoded.claudeAiOauth.accessToken
            guard !token.isEmpty else { throw KeychainCredentialsError.decodeFailed }
            return token
        } catch {
            throw KeychainCredentialsError.decodeFailed
        }
    }
}
