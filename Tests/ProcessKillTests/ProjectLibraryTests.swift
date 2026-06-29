import Foundation
import Testing
@testable import ProcessKill

@Suite("Project library detection")
struct ProjectLibraryTests {
    @Test("Detects package.json scripts")
    func detectsNodeScripts() throws {
        let folder = try makeTemporaryFolder()
        let package = """
        {
          "name": "demo-app",
          "scripts": {
            "dev": "vite --host 0.0.0.0",
            "build": "vite build"
          }
        }
        """
        try package.write(to: folder.appending(path: "package.json"), atomically: true, encoding: .utf8)

        let project = try ProjectLibrary.detectProject(at: folder)

        #expect(project.name == "demo-app")
        #expect(project.kind == .node)
        #expect(project.commands.contains { $0.name == "dev" && $0.command == "npm run dev" })
        #expect(project.commands.contains { $0.name == "build" && $0.command == "npm run build" })
    }

    @Test("Detects Flutter commands")
    func detectsFlutterCommands() throws {
        let folder = try makeTemporaryFolder()
        let pubspec = """
        name: mobile_demo
        description: Test app
        """
        try pubspec.write(to: folder.appending(path: "pubspec.yaml"), atomically: true, encoding: .utf8)

        let project = try ProjectLibrary.detectProject(at: folder)

        #expect(project.name == "mobile_demo")
        #expect(project.kind == .flutter)
        #expect(project.commands.contains { $0.command == "flutter pub get" })
        #expect(project.commands.contains { $0.command == "flutter run" })
    }

    @Test("Labels Vue package.json projects")
    func detectsVueProject() throws {
        let folder = try makeTemporaryFolder()
        let package = """
        {
          "name": "vue-demo",
          "scripts": {
            "dev": "vite --host 0.0.0.0"
          },
          "dependencies": {
            "vue": "^3.0.0"
          }
        }
        """
        try package.write(to: folder.appending(path: "package.json"), atomically: true, encoding: .utf8)

        let project = try ProjectLibrary.detectProject(at: folder)

        #expect(project.name == "vue-demo")
        #expect(project.kind == .vue)
        #expect(project.commands.contains { $0.name == "dev" && $0.command == "npm run dev" })
    }

    @Test("Detects .NET project commands")
    func detectsDotnetProject() throws {
        let folder = try makeTemporaryFolder()
        try "<Project Sdk=\"Microsoft.NET.Sdk.Web\"></Project>".write(
            to: folder.appending(path: "Api.csproj"),
            atomically: true,
            encoding: .utf8
        )

        let project = try ProjectLibrary.detectProject(at: folder)

        #expect(project.name == "Api")
        #expect(project.kind == .dotnet)
        #expect(project.commands.contains { $0.command == "dotnet restore Api.csproj" })
        #expect(project.commands.contains { $0.command == "dotnet run --project Api.csproj" })
        #expect(project.commands.contains { $0.command == "dotnet watch --project Api.csproj" })
    }

    @Test("Resolves manual command placeholders")
    func resolvesManualCommandPlaceholders() {
        let command = ProjectCommand(
            name: "migrate",
            command: "npm run migrate -- --tenant {{tenant}} --direction {{ direction }} --dry-run",
            source: "manual"
        )

        #expect(command.isManual)
        #expect(command.placeholders == ["tenant", "direction"])
        #expect(command.resolvedCommand(values: ["tenant": "acme", "direction": "up"]) == "npm run migrate -- --tenant acme --direction up --dry-run")
    }

    private func makeTemporaryFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}
