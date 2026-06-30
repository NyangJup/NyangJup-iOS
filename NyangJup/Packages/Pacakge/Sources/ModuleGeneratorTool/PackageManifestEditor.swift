import Foundation

struct PackageManifestEditor {
    let packagePath: String

    func updateManifest(for spec: ModuleSpec) throws {
        let packageURL = URL(fileURLWithPath: packagePath)
            .appendingPathComponent("Package.swift")

        var contents = try String(contentsOf: packageURL, encoding: .utf8)

        contents = try insertEnumCase(for: spec, into: contents)
        contents = try insertProduct(for: spec, into: contents)
        contents = try insertTargets(for: spec, into: contents)

        try contents.write(to: packageURL, atomically: true, encoding: .utf8)
    }

    private func insertEnumCase(for spec: ModuleSpec, into contents: String) throws -> String {
        let marker = "    enum \(spec.layer.rawValue): String {"
        let newCase = "        case \(spec.enumCaseName) = \"\(spec.name)\""
        
        guard !contents.contains(newCase) else {
            return contents
        }
        
        return try contents.inserting("\(newCase)\n", afterLineContaining: marker)
        
    }

    private func insertProduct(for spec: ModuleSpec, into contents: String) throws -> String {
        let marker = "        // MARK: - \(spec.layer.rawValue) Products"
        let targets = spec.productTargets.map { "\"\($0)\"" }.joined(separator: ", ")
        let product = """
        .library(
            name: "\(spec.targetPrefix)",
            targets: [\(targets)]
        ),
"""

        guard !contents.contains("name: \"\(spec.targetPrefix)\",\n            targets:") else {
            return contents
        }

        return try contents.inserting("\(product)\n", afterLineContaining: marker)
    }

    private func insertTargets(for spec: ModuleSpec, into contents: String) throws -> String {
        let marker = "        // MARK: - \(spec.layer.rawValue) Targets"
        let targets = buildTargetDeclarations(for: spec)

        guard !contents.contains("path: \"\(spec.modulePath)/\(ModuleTarget.feature.sourcePathComponent)\"") else {
            return contents
        }

        return try contents.inserting("\(targets)\n", afterLineContaining: marker)
    }

    private func buildTargetDeclarations(for spec: ModuleSpec) -> String {
        var declarations: [String] = []
        var implementationDependencies: [String] = []
        
        if spec.layer.hasInterface {
            declarations.append(
                targetDeclaration(
                    type: ".target",
                    name: "\(spec.targetPrefix)Interface",
                    dependencies: [],
                    path: "\(spec.modulePath)/\(ModuleTarget.interface.sourcePathComponent)"
                )
            )
            implementationDependencies.append(
                ".\(spec.layer.dependencyHelperName)(module: .\(spec.enumCaseName), target: .interface)"
            )
        }
        
        declarations.append(
            targetDeclaration(
                type: ".target",
                name: spec.targetPrefix,
                dependencies: implementationDependencies,
                path: "\(spec.modulePath)/\(ModuleTarget.feature.sourcePathComponent)"
            )
        )
        
        if spec.layer.hasTesting {
            declarations.append(
                targetDeclaration(
                    type: ".target",
                    name: "\(spec.targetPrefix)Testing",
                    dependencies: [],
                    path: "\(spec.modulePath)/\(ModuleTarget.testing.sourcePathComponent)"
                )
            )
        }
        
        
        declarations.append(
            targetDeclaration(
                type: ".testTarget",
                name: "\(spec.targetPrefix)Tests",
                dependencies: [
                    ".\(spec.layer.dependencyHelperName)(module: .\(spec.enumCaseName), target: .testing)"
                ],
                path: "\(spec.modulePath)/\(ModuleTarget.tests.sourcePathComponent)"
            )
        )

        return declarations.joined(separator: "\n")
    }

    private func targetDeclaration(
        type: String,
        name: String,
        dependencies: [String],
        path: String
    ) -> String {
        let dependenciesText: String

        if dependencies.isEmpty {
            dependenciesText = "[]"
        } else {
            dependenciesText = "[\n\(dependencies.map { "                \($0)" }.joined(separator: ",\n"))\n            ]"
        }

        return """
        \(type)(
            name: "\(name)",
            dependencies: \(dependenciesText),
            path: "\(path)"
        ),
"""
    }
}

enum ManifestEditorError: Error {
    case missingMarker(String)
}

private extension String {
    func inserting(_ newContents: String, afterLineContaining marker: String) throws -> String {
        var contents = self

        guard let markerRange = contents.range(of: marker) else {
            throw ManifestEditorError.missingMarker(marker)
        }

        guard let lineEnd = contents[markerRange.upperBound...].firstIndex(of: "\n") else {
            throw ManifestEditorError.missingMarker(marker)
        }

        contents.insert(
            contentsOf: newContents,
            at: contents.index(after: lineEnd)
        )

        return contents
    }

    func inserting(_ newContents: String, before marker: String) throws -> String {
        var contents = self

        guard let markerRange = contents.range(of: marker) else {
            throw ManifestEditorError.missingMarker(marker)
        }

        contents.insert(
            contentsOf: newContents,
            at: markerRange.lowerBound
        )

        return contents
    }
}
