import PackagePlugin
import Foundation

@main
struct GenerateModulePlugin: CommandPlugin {
    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) async throws {
        let tool = try context.tool(named: "ModuleGeneratorTool")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool.url.path())

        process.arguments = arguments + [
            "--package-path",
            context.package.directoryURL.path()
        ]
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw PluginError.failed(process.terminationStatus)
        }
    }
}

enum PluginError: Error {
    case failed(Int32)
}
