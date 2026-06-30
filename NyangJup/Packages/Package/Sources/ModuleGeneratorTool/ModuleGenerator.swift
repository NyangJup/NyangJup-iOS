import Foundation

struct ModuleGenerator {
    let packagePath: String

    func generate(_ spec: ModuleSpec) throws {
        try TemplateWriter(packagePath: packagePath).write(spec)
        try PackageManifestEditor(packagePath: packagePath).updateManifest(for: spec)
    }
}
