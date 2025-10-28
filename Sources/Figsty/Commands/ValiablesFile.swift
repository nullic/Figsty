import ArgumentParser
import Foundation
import PathKit

private let launchURL = URL(fileURLWithPath: CommandLine.arguments[0])
private let homeDir = launchURL.deletingLastPathComponent()
private let appName = launchURL.lastPathComponent

struct ValiablesFile: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "valiables-json")
    
    @Option(name: [.customShort("o"), .customLong("output")], help: "Output .xcassets folder", completion: .file(extensions: ["xcassets"]))
    var outputPath: Path

    @Argument(help: "Path to json file with variables.", completion: .file(extensions: ["json"]))
    var files: [Path]
    
    @Option(name: .customLong("dark-mode-name"), help: "Dark theme mode name")
    var darkModeName: String?
    
    @Option(name: .customLong("light-mode-name"), help: "Light theme mode name")
    var lightModeName: String?
    
    func run() throws {
        let parsedFiles: [VariablesFile] = try files.compactMap {
            guard let data = try String(contentsOf: $0.url).data(using: .utf8) else { return nil }
            return try JSONDecoder().decode(VariablesFile.self, from: data)
        }
        
        let variables = parsedFiles.flatMap { $0.variables }
        let folderMarker = assetCatalogFolderJSON.data(using: .utf8)
        
        let lightMode = parsedFiles.compactMap { $0.modeId(mode: lightModeName) }.first
        let darkMode = parsedFiles.compactMap { $0.modeId(mode: darkModeName) }.first
        
        try? FileManager.default.createDirectory(at: outputPath.url, withIntermediateDirectories: true, attributes: nil)
        
        let rootContent = outputPath.url.appendingPathComponent("Contents.json")
        if FileManager.default.fileExists(atPath: rootContent.path) == false {
            try folderMarker?.write(to: rootContent)
        }
        
        for variable in variables where variable.type == .COLOR {
            let comps = variable.name.components(separatedBy: "/").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            var folder = self.outputPath.absolute()
            
            for (index, comp) in comps.enumerated() {
                folder = folder + comp

                if index != (comps.count - 1) {
                    if FileManager.default.fileExists(atPath: folder.url.path) == false {
                        try FileManager.default.createDirectory(at: folder.url, withIntermediateDirectories: true, attributes: nil)
                    }
                    
                    let rootContent = folder.url.appendingPathComponent("Contents.json")
                    if FileManager.default.fileExists(atPath: rootContent.path) == false {
                        try folderMarker?.write(to: rootContent)
                    }
                }
            }
            
            let colorset = Path(folder.absolute().url.path + ".colorset")
            let contents = colorset + "Contents.json"
            
            if FileManager.default.fileExists(atPath: colorset.url.path) {
                try FileManager.default.removeItem(at: colorset.url)
            }
            
            try FileManager.default.createDirectory(at: colorset.url, withIntermediateDirectories: true, attributes: nil)
            
            let string = try variable.xcassetsString(allVariables: variables, lightMode: lightMode, darkMode: darkMode)
            try string.data(using: .utf8)?.write(to: contents.url)
            print("Generate: \(colorset.abbreviate())")
        }
    }
}

extension Array where Element == Variable {
    func color(id: String, mode: String) -> Color? {
        for element in self where element.id == id {
            if case .color(let value) = element.valuesByMode[mode] {
                return value
            } else if element.valuesByMode.values.count == 1 {
                if case .color(let value) = element.valuesByMode.values.first! {
                    return value
                }
            }
        }
        return nil
    }
}

extension Variable {
    func xcassetsString(allVariables: [Variable], lightMode: String?, darkMode: String?) throws -> String {
        assert(type == .COLOR)
        
        let colorsByMode = colorsByMode(allVariables: allVariables)
        let otherMode = colorsByMode.keys.first(where: { $0 != lightMode && $0 != darkMode })
        
        let anyColor = otherMode != nil ? colorsByMode[otherMode!] : nil
        let lightColor = lightMode != nil ? colorsByMode[lightMode!] : nil
        let darkColor = darkMode != nil ? colorsByMode[darkMode!] : nil
        
        let asset = XCAssetsColors(anyColor: anyColor, lightColor: lightColor, darkColor: darkColor)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(asset)
        return String(data: data, encoding: .utf8)!
    }
    
    func colorsByMode(allVariables: [Variable]) -> [String: Color] {
        var result: [String: Color] = [:]
        for (mode, value) in valuesByMode {
            if let color = value.color {
                result[mode] = color
            } else if let alias = value.alias, let color = allVariables.color(id: alias.id, mode: mode) {
                result[mode] = color
            } else {
                preconditionFailure("Could not find color for variable \(self)")
            }
        }
        return result
    }
}
