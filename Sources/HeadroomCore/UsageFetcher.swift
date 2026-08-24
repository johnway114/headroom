import Foundation

public enum UsageError: LocalizedError, Sendable {
    case ompMissing
    case ompFailed(Int32, String)
    case emptyOutput

    public var errorDescription: String? {
        switch self {
        case .ompMissing:
            return "omp not found. Expected ~/.local/bin/omp"
        case .ompFailed(let code, let message):
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "omp usage failed (\(code))" : trimmed
        case .emptyOutput:
            return "omp usage returned no JSON"
        }
    }
}

public enum OmpPath {
    public static func resolve(
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        override: URL? = nil
    ) -> URL? {
        if let override, FileManager.default.isExecutableFile(atPath: override.path) {
            return override
        }
        if let stored = UserDefaults.standard.string(forKey: "ompPath"),
           FileManager.default.isExecutableFile(atPath: stored)
        {
            return URL(fileURLWithPath: stored)
        }
        let candidates = [
            home.appendingPathComponent(".local/bin/omp"),
            URL(fileURLWithPath: "/opt/homebrew/bin/omp"),
            URL(fileURLWithPath: "/usr/local/bin/omp"),
        ]
        if let hit = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0.path) }) {
            return hit
        }
        return whichOmp()
    }

    private static func whichOmp() -> URL? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lic", "command -v omp"]
        process.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }
        guard process.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let path = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !path.isEmpty, FileManager.default.isExecutableFile(atPath: path) else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }
}

public enum UsageFetcher {
    public static func fetchJSON(omp: URL, invalidate: Bool) throws -> Data {
        if invalidate {
            _ = try run(omp, ["usage", "invalidate"])
        }
        let data = try run(omp, ["usage", "--json"])
        if data.first(where: { $0 == UInt8(ascii: "{") }) == nil {
            throw UsageError.emptyOutput
        }
        return data
    }

    @discardableResult
    public static func run(_ executable: URL, _ arguments: [String]) throws -> Data {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        let home = FileManager.default.homeDirectoryForCurrentUser
        var env = ProcessInfo.processInfo.environment
        env["HOME"] = home.path
        let path = env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        if !path.split(separator: ":").contains(where: { $0 == "\(home.path)/.local/bin" }) {
            env["PATH"] = "\(home.path)/.local/bin:\(path)"
        }
        process.environment = env
        process.currentDirectoryURL = home
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        process.standardInput = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        let output = stdout.fileHandleForReading.readDataToEndOfFile()
        if process.terminationStatus != 0 {
            let err = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw UsageError.ompFailed(process.terminationStatus, err)
        }
        return output
    }
}
