//
//  StyleGenerator.swift
//  Figsty
//
//  Created by Dmitriy Petrusevich on 1/13/20.
//  Copyright © 2020 Dmitriy Petrusevich. All rights reserved.
//

import Foundation

class StyleGenerator {
    let file: File
    private var colors: [ColorStyle]!
    private var trimmedNamesCount: [String: Int] = [:]

    var trimEndingDigits: Bool = false
    var iosStructSupportScheme: Bool = false
    var colorPrefix: String = "" {
        didSet {
            regenerateTrimMap()
        }
    }

    init(file: File) {
        self.file = file
    }

    private func process() {
        guard colors == nil else {
            return
        }

        colors = file.styles.compactMap { (key: String, value: Style) -> ColorStyle? in
            if let color = file.findColor(styleID: key) {
                return ColorStyle(style: value, color: color)
            } else {
                return nil
            }
        }
        colors.sort { $0.style.name < $1.style.name }
        regenerateTrimMap()
    }

    private func regenerateTrimMap() {
        guard colors != nil else {
            trimmedNamesCount = [:]
            return
        }

        var resultMap: [String: Int] = [:]
        for color in colors {
            let name = (colorPrefix + color.style.name.escaped.capitalizedFirstLetter).loweredFirstLetter.trimmingCharacters(in: .decimalDigits)
            resultMap[name] = (resultMap[name] ?? 0) + 1
        }

        trimmedNamesCount = resultMap
    }

    private func colorName(_ style: ColorStyle) -> String {
        let name = (colorPrefix + style.style.name.escaped.capitalizedFirstLetter).loweredFirstLetter
        guard trimEndingDigits == true else { return name }

        let trimmedName = name.trimmingCharacters(in: .decimalDigits)
        return trimmedNamesCount[trimmedName] == 1 ? trimmedName : name
    }

    func generateIOS(output: URL) throws {
        process()
        var strings: [String] = []
        strings.append(iOSSwiftFilePrefix)

        let structName = output.deletingPathExtension().lastPathComponent.escaped.capitalizedFirstLetter
        let ext = iosStructSupportScheme ? ": ColorScheme" : ""
        strings.append("public struct \(structName)\(ext) {")
        for color in colors {
            strings.append("\(indent)public let \(colorName(color)) = \(color.color.uiColor)")
        }

        strings.append("")
        strings.append("\(indent)public init() {}")
        strings.append("")
        strings.append("}")

        let text = strings.joined(separator: "\n")
        try save(text: text, to: output)
    }

    func generateIOSSheme(output: URL) throws {
        process()
        var strings: [String] = []
        strings.append(iOSSwiftFilePrefix)

        strings.append("public protocol ColorScheme {")
        for color in colors {
            strings.append("\(indent)/// \(color.style.name)")
            strings.append("\(indent)var \(colorName(color)): UIColor { get }")
        }
        strings.append("}\n")

        strings.append("public enum ColorName: String {")
        for color in colors {
            strings.append("\(indent)case \(colorName(color))")
        }
        strings.append("}\n")

        strings.append("extension ColorScheme {")
        strings.append("\(indent)public subscript(colorName: ColorName) -> UIColor {")
        strings.append("\(indent)\(indent)switch colorName {")
        for color in colors {
            strings.append("\(indent)\(indent)case .\(colorName(color)): return \(colorName(color))")
        }
        strings.append("\(indent)\(indent)}")
        strings.append("\(indent)}")
        strings.append("}")

        let text = strings.joined(separator: "\n")
        try save(text: text, to: output)
    }

    func generateAndroid(output: URL) throws {
        process()
        var strings: [String] = []

        strings.append(androidFilePrefix)
        for color in colors {
            strings.append("\(indent)<!--\(color.style.name)-->")
            strings.append("\(indent)<color name=\"\(colorName(color))\">\(color.color.androidHexColor)</color>")
        }
        strings.append(androidFileSuffix)

        let text = strings.joined(separator: "\n")
        try save(text: text, to: output)
    }

    private func save(text: String, to file: URL) throws {
        try? FileManager.default.removeItem(at: file)
        try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        try text.data(using: .utf8)?.write(to: file)
    }
}
