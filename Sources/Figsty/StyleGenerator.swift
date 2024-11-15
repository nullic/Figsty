//
//  StyleGenerator.swift
//  Figsty
//
//  Created by Dmitriy Petrusevich on 1/13/20.
//  Copyright © 2020 Dmitriy Petrusevich. All rights reserved.
//

import Foundation

class StyleGenerator {
    private enum Constants {
        static let colorSchemeOptionsEnumName = "ColorSchemeOption"
        static let schemeProtocolName = "ColorScheme"
    }
    let file: File
    private var colors: [ColorStyle]!
    private var colorOptions: [String: [ColorStyle]] = [:]
    private var uniqueColors: [ColorStyle] {
        colorOptions.values.first ?? []
    }
    private var fonts: [FontStyle]!
    private var trimmedColorNamesCount: [String: Int] = [:]

    var trimEndingDigits: Bool = false
    var iosStructSupportScheme: Bool = false
    var useExtendedSRGBColorspace: Bool = false
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
        
        let colorSchemeOptionNames = file.document.children?
            .compactMap({$0.name})
            .filter({!$0.trimmingCharacters(in: .whitespaces).isEmpty}) ?? []
        
        colors = file.styles.compactMap { (key: String, value: Style) -> ColorStyle? in
            if let color = file.findColor(styleID: key) {
                let colorOptionPrefix = colorSchemeOptionNames.first(where: { value.name.contains("\($0)/") }) ?? ""
                let style = value.withTrimmedPrexixName(prefix: colorOptionPrefix)
                return ColorStyle(style: style, color: color, parentName: colorOptionPrefix)
            } else {
                return nil
            }
        }
        colors.sort { $0.style.name < $1.style.name }
        colorOptions = Dictionary(grouping: colors, by: { $0.parentName })

        fonts = file.styles.compactMap { (key: String, value: Style) -> FontStyle? in
            if let font = file.findFont(styleID: key) {
                return FontStyle(style: value, typeStyle: font)
            } else {
                return nil
            }
        }
        fonts.sort { $0.style.name < $1.style.name }

        regenerateTrimMap()
    }

    private func regenerateTrimMap() {
        guard colors != nil else {
            trimmedColorNamesCount = [:]
            return
        }

        var resultMap: [String: Int] = [:]
        for color in colors {
            let name = (colorPrefix + color.style.name.escaped.capitalizedFirstLetter).loweredFirstLetter.trimmingCharacters(in: .decimalDigits)
            resultMap[name] = (resultMap[name] ?? 0) + 1
        }

        trimmedColorNamesCount = resultMap
    }

    private func colorName(_ style: ColorStyle) -> String {
        let name = (colorPrefix + style.style.name.escaped.capitalizedFirstLetter).loweredFirstLetter
        guard trimEndingDigits == true else { return name }

        let trimmedName = name.trimmingCharacters(in: .decimalDigits)
        return trimmedColorNamesCount[trimmedName] == 1 ? trimmedName : name
    }

    private func fontName(_ style: FontStyle) -> String {
        let name = (style.style.name.escaped.capitalizedFirstLetter).loweredFirstLetter
        guard trimEndingDigits == true else { return name }

        let trimmedName = name.trimmingCharacters(in: .decimalDigits)
        return trimmedColorNamesCount[trimmedName] == 1 ? trimmedName : name
    }

    func generateIOSFonts(output: URL) throws {
        process()
        var strings: [String] = []
        strings.append(iOSSwiftFilePrefix)

        strings.append("public extension UIFont {")
        for font in fonts where font.style.styleType == .TEXT {
            strings.append("\(indent)// \(font.style.name)")
            strings.append("\(indent)static let \(fontName(font)) = \(font.typeStyle.uiFontSystem)")
        }
        strings.append("}\n")

        let text = strings.joined(separator: "\n")
        try save(text: text, to: output)
    }

    func generateIOS(output: URL) throws {
        process()
        var strings: [String] = []
        strings.append(iOSSwiftFilePrefix)

        let structName = output.deletingPathExtension().lastPathComponent.escaped.capitalizedFirstLetter
        let ext = iosStructSupportScheme ? ": \(Constants.schemeProtocolName)" : ""
        strings.append("public class \(structName)\(ext) {")
        strings.append("\(indent)public var option: \(Constants.colorSchemeOptionsEnumName)\n")
        uniqueColors.forEach { color in
            strings.append("\(indent)public var \(colorName(color)) = UIColor()")
        }

        strings.append("")
        
        strings.append("\(indent)public init(with option: \(Constants.colorSchemeOptionsEnumName)) {")
        strings.append("\(indent)\(indent)self.option = option")
        strings.append("\(indent)\(indent)switch option {")
        colorOptions.keys.sorted(by: { $0 < $1 }).forEach { option in
            strings.append("\(indent)\(indent)case .\(option.lowercased()):")
            strings.append("\(indent)\(indent)\(indent) setup\(option)\(Constants.colorSchemeOptionsEnumName)()")
        }
        strings.append("\(indent)\(indent)}")
        strings.append("\(indent)}")
        strings.append("")
        
        colorOptions.sorted(by: { $0.key < $1.key }).forEach { option, colors in
            generateSetupColorSchemeFunc(with: option, colors: colors, strings: &strings)
            strings.append("")
        }
        
        strings.append("}")

        let text = strings.joined(separator: "\n")
        try save(text: text, to: output)
    }
    
    private func generateSetupColorSchemeFunc(with option: String, colors: [ColorStyle], strings: inout [String]) {
        strings.append("\(indent)private func setup\(option)\(Constants.colorSchemeOptionsEnumName)() {")
        colors.forEach { color in
            strings.append("\(indent)\(indent)\(colorName(color)) = \(useExtendedSRGBColorspace ? color.color.colorspaceUIColor : color.color.uiColor)")
        }
        strings.append("\(indent)}")
    }

    func generateIOSSheme(output: URL) throws {
        process()
        var strings: [String] = []
        strings.append(iOSSwiftFilePrefix)
        
        strings.append("public enum \(Constants.colorSchemeOptionsEnumName): String {")
        colorOptions.keys.sorted(by: { $0 < $1 }).forEach { key in
            strings.append("\(indent)case \(key.lowercased())")
        }
        strings.append("}\n")

        strings.append("public protocol \(Constants.schemeProtocolName) {")
        strings.append("\(indent)var option: \(Constants.colorSchemeOptionsEnumName) { get }\n")
        for color in uniqueColors {
            strings.append("\(indent)/// \(color.style.name)")
            strings.append("\(indent)var \(colorName(color)): UIColor { get }")
        }
        strings.append("}\n")

        strings.append("public enum ColorName: String {")
        for color in uniqueColors {
            strings.append("\(indent)case \(colorName(color))")
        }
        strings.append("}\n")

        strings.append("extension \(Constants.schemeProtocolName) {")
        strings.append("\(indent)public subscript(colorName: ColorName) -> UIColor {")
        strings.append("\(indent)\(indent)switch colorName {")
        for color in uniqueColors {
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
