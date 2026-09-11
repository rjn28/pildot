import Foundation
import Testing
@testable import Pildot

@MainActor
struct LaunchAtLoginControllerTests {
    @Test
    func enablingCreatesAndLoadsAUserLaunchAgent() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        try fixture.controller.setEnabled(true)

        #expect(fixture.controller.isEnabled)
        #expect(fixture.launchctl.bootstrapURLs == [fixture.agentURL])

        let data = try Data(contentsOf: fixture.agentURL)
        let propertyList = try #require(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )
        #expect(propertyList["Label"] as? String == LaunchAtLoginController.agentLabel)
        #expect(propertyList["RunAtLoad"] as? Bool == true)
        #expect(
            propertyList["ProgramArguments"] as? [String]
                == ["/usr/bin/open", "-gja", fixture.applicationURL.path]
        )
    }

    @Test
    func disablingUnloadsAndRemovesTheLaunchAgent() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        try fixture.controller.setEnabled(true)
        try fixture.controller.setEnabled(false)

        #expect(!fixture.controller.isEnabled)
        #expect(fixture.launchctl.bootoutURLs == [fixture.agentURL])
        #expect(!FileManager.default.fileExists(atPath: fixture.agentURL.path))
    }

    @Test
    func failedRegistrationRemovesTheIncompleteLaunchAgent() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }
        fixture.launchctl.bootstrapError = TestFailure.registration

        #expect(throws: TestFailure.self) {
            try fixture.controller.setEnabled(true)
        }
        #expect(!fixture.controller.isEnabled)
        #expect(!FileManager.default.fileExists(atPath: fixture.agentURL.path))
    }

    private func makeFixture() throws -> Fixture {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let applicationURL = rootURL.appendingPathComponent("Pildot.app", isDirectory: true)
        let launchAgentsURL = rootURL.appendingPathComponent("LaunchAgents", isDirectory: true)
        let agentURL = launchAgentsURL
            .appendingPathComponent("\(LaunchAtLoginController.agentLabel).plist")
        try FileManager.default.createDirectory(
            at: applicationURL,
            withIntermediateDirectories: true
        )

        let launchctl = LaunchAgentControllerSpy()
        let controller = LaunchAtLoginController(
            applicationURL: applicationURL,
            launchAgentsDirectory: launchAgentsURL,
            launchAgentController: launchctl
        )
        return Fixture(
            rootURL: rootURL,
            applicationURL: applicationURL,
            agentURL: agentURL,
            launchctl: launchctl,
            controller: controller
        )
    }
}

@MainActor
private struct Fixture {
    let rootURL: URL
    let applicationURL: URL
    let agentURL: URL
    let launchctl: LaunchAgentControllerSpy
    let controller: LaunchAtLoginController
}

@MainActor
private final class LaunchAgentControllerSpy: LaunchAgentControlling {
    var bootstrapURLs: [URL] = []
    var bootoutURLs: [URL] = []
    var bootstrapError: (any Error)?

    func bootstrap(plistURL: URL) throws {
        bootstrapURLs.append(plistURL)
        if let bootstrapError {
            throw bootstrapError
        }
    }

    func bootout(plistURL: URL) throws {
        bootoutURLs.append(plistURL)
    }
}

private enum TestFailure: Error {
    case registration
}
