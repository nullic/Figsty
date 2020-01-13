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
    private(set) var colors: [ColorStyle]!

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
    }

    func generateIOS(output: URL, prefix: String?, supportScheme: Bool) throws {
        process()
        var strings: [String] = []
        strings.append(iOSSwiftFilePrefix)

        let structName = file.name.escaped.capitalizedFirstLetter
        strings.append("public struct \(structName) {")
        for color in colors {
            let colorName = ((prefix ?? "") + color.style.name.escaped.capitalizedFirstLetter).loweredFirstLetter
            strings.append("\(indent)let \(colorName) = \(color.color.uiColor)")
        }
        strings.append("}")

        if supportScheme == true {
            strings.append("")
            strings.append("public extension \(structName): ColorScheme {")
            strings.append("}")
        }

        let text = strings.joined(separator: "\n")
        try save(text: text, to: output)
    }

    func generateIOSSheme(output: URL, prefix: String?) throws {
        process()
        var strings: [String] = []
        strings.append(iOSSwiftFilePrefix)

        strings.append("public protocol ColorScheme {")
        for color in colors {
            let colorName = ((prefix ?? "") + color.style.name.escaped.capitalizedFirstLetter).loweredFirstLetter
            strings.append("\(indent)/// \(color.style.name)")
            strings.append("\(indent)var \(colorName): UIColor { get }")
        }
        strings.append("}\n")

        strings.append("public enum ColorName: String {")
        for color in colors {
            let colorName = ((prefix ?? "") + color.style.name.escaped.capitalizedFirstLetter).loweredFirstLetter
            strings.append("\(indent)case \(colorName)")
        }
        strings.append("}\n")

        strings.append("extension ColorScheme {")
        strings.append("\(indent)public subscript(colorName: ColorName) -> UIColor {")
        strings.append("\(indent)\(indent)switch colorName {")
        for color in colors {
            let colorName = ((prefix ?? "") + color.style.name.escaped.capitalizedFirstLetter).loweredFirstLetter
            strings.append("\(indent)\(indent)case .\(colorName): return \(colorName)")
        }
        strings.append("\(indent)\(indent)}")
        strings.append("\(indent)}")
        strings.append("}")

        let text = strings.joined(separator: "\n")
        try save(text: text, to: output)
    }

    func generateAndroid(output: URL, prefix: String?) throws {
        process()
        var strings: [String] = []

        strings.append(androidFilePrefix)
        for color in colors {
            let colorName = ((prefix ?? "") + color.style.name.escaped.capitalizedFirstLetter).loweredFirstLetter
            strings.append("\(indent)<!--\(color.style.name)-->")
            strings.append("\(indent)<color name=\"\(colorName)\">\(color.color.androidHexColor)</color>")
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
