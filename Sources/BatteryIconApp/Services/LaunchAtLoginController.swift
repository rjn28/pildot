import Darwin
import Foundation

@MainActor
protocol LaunchAtLoginManaging: AnyObject {
    var isEnabled: Bool { get }

    func setEnabled(_ isEnabled: Bool) throws
}

@MainActor
protocol LaunchAgentControlling {
    func bootstrap(plistURL: URL) throws
    func bootout(plistURL: URL) throws
}

enum LaunchAtLoginError: LocalizedError {
    case invalidApplicationBundle(URL)
    case launchctlFailed(arguments: [String], status: Int32, output: String)
    case rollbackFailed(registrationError: String, cleanupError: String)

    var errorDescription: String? {
        switch self {
        case .invalidApplicationBundle(let url):
            "L’application doit être lancée depuis un bundle .app valide : \(url.path)"
        case .launchctlFailed(let arguments, let status, let output):
            "launchctl \(arguments.joined(separator: " ")) a échoué (code \(status)) : \(output)"
        case .rollbackFailed(let registrationError, let cleanupError):
            "L’activation a échoué (\(registrationError)) et le fichier temporaire n’a pas pu être supprimé (\(cleanupError))."
        }
    }
}

@MainActor
struct LaunchctlController: LaunchAgentControlling {
    private let domainTarget: String

    init(userID: uid_t = getuid()) {
        domainTarget = "gui/\(userID)"
    }

    func bootstrap(plistURL: URL) throws {
        try run(arguments: ["bootstrap", domainTarget, plistURL.path])
    }

    func bootout(plistURL: URL) throws {
        try run(arguments: ["bootout", domainTarget, plistURL.path])
    }

    private func run(arguments: [String]) throws {
        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(decoding: outputData, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw LaunchAtLoginError.launchctlFailed(
                arguments: arguments,
                status: process.terminationStatus,
                output: output.isEmpty ? "aucun détail fourni" : output
            )
        }
    }
}

@MainActor
final class LaunchAtLoginController: LaunchAtLoginManaging {
    static let agentLabel = "com.rjn28.BatteryIconApp.login"

    private let applicationURL: URL
    private let agentURL: URL
    private let fileManager: FileManager
    private let launchAgentController: any LaunchAgentControlling

    var isEnabled: Bool {
        fileManager.fileExists(atPath: agentURL.path)
    }

    init(
        applicationURL: URL = Bundle.main.bundleURL,
        launchAgentsDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true),
        fileManager: FileManager = .default,
        launchAgentController: any LaunchAgentControlling = LaunchctlController()
    ) {
        self.applicationURL = applicationURL.resolvingSymlinksInPath()
        agentURL = launchAgentsDirectory.appendingPathComponent("\(Self.agentLabel).plist")
        self.fileManager = fileManager
        self.launchAgentController = launchAgentController
    }

    func setEnabled(_ isEnabled: Bool) throws {
        if isEnabled {
            try enable()
        } else {
            try disable()
        }
    }

    private func enable() throws {
        guard !isEnabled else {
            return
        }

        var isDirectory = ObjCBool(false)
        guard
            applicationURL.pathExtension == "app",
            fileManager.fileExists(atPath: applicationURL.path, isDirectory: &isDirectory),
            isDirectory.boolValue
        else {
            throw LaunchAtLoginError.invalidApplicationBundle(applicationURL)
        }

        try fileManager.createDirectory(
            at: agentURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let propertyList: [String: Any] = [
            "Label": Self.agentLabel,
            "LimitLoadToSessionType": "Aqua",
            "ProcessType": "Interactive",
            "ProgramArguments": ["/usr/bin/open", "-gja", applicationURL.path],
            "RunAtLoad": true
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: propertyList,
            format: .xml,
            options: 0
        )
        try data.write(to: agentURL, options: .atomic)

        do {
            try launchAgentController.bootstrap(plistURL: agentURL)
        } catch {
            do {
                try fileManager.removeItem(at: agentURL)
            } catch let cleanupError {
                throw LaunchAtLoginError.rollbackFailed(
                    registrationError: error.localizedDescription,
                    cleanupError: cleanupError.localizedDescription
                )
            }
            throw error
        }
    }

    private func disable() throws {
        guard isEnabled else {
            return
        }

        try launchAgentController.bootout(plistURL: agentURL)
        try fileManager.removeItem(at: agentURL)
    }
}
