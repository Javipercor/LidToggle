import Foundation

enum PowerState: Equatable {
    case normal, blocked

    static func parse(_ output: String) -> PowerState? {
        let lines = output.split(separator: "\n")
        for line in lines {
            let fields = line.split(whereSeparator: { $0.isWhitespace })
            guard fields.first == "SleepDisabled" else { continue }
            guard fields.count == 2 else { return nil }
            switch fields[1] {
            case "0": return .normal
            case "1": return .blocked
            default: return nil
            }
        }
        // pmset omits SleepDisabled when no override has been saved.
        return output.contains("System-wide power settings:") && output.contains("Currently in use:")
            ? .normal : nil
    }

    static func read() -> PowerState? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0, let output = String(data: data, encoding: .utf8) else { return nil }
            return parse(output)
        } catch { return nil }
    }
}
