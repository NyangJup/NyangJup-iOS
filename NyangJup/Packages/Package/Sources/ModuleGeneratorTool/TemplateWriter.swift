import Foundation

struct TemplateWriter {
    let packagePath: String

    func write(_ spec: ModuleSpec) throws {
        let rootURL = URL(fileURLWithPath: packagePath)
        let moduleURL = rootURL.appendingPathComponent(spec.modulePath)

        if spec.layer.hasInterface {
            try writeSourceFile(
                at: moduleURL.appendingPathComponent(ModuleTarget.interface.sourcePathComponent),
                fileName: "\(spec.targetPrefix)Interface.swift",
                contents: "public protocol \(spec.targetPrefix)Interface {}\n"
            )
        }

        try writeSourceFile(
            at: moduleURL.appendingPathComponent(ModuleTarget.feature.sourcePathComponent),
            fileName: "\(spec.targetPrefix).swift",
            contents: "public struct \(spec.targetPrefix) {}\n"
        )

        try writeSourceFile(
            at: moduleURL.appendingPathComponent(ModuleTarget.testing.sourcePathComponent),
            fileName: "\(spec.targetPrefix)Testing.swift",
            contents: "public struct \(spec.targetPrefix)Testing {}\n"
        )

        try writeSourceFile(
            at: moduleURL.appendingPathComponent(ModuleTarget.tests.sourcePathComponent),
            fileName: "\(spec.targetPrefix)Tests.swift",
            contents: """
                import Testing
                @testable import \(spec.targetPrefix)
                
                @Test
                func testExample() {}
                """
        )
    }

    private func writeSourceFile(
        at directoryURL: URL,
        fileName: String,
        contents: String
    ) throws {
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        let fileURL = directoryURL.appendingPathComponent(fileName)
        guard !FileManager.default.fileExists(atPath: fileURL.path) else {
            throw TemplateWriterError.fileAlreadyExists(fileURL.path)
        }

        try contents.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}

enum TemplateWriterError: Error {
    case fileAlreadyExists(String)
}
