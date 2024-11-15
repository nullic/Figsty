//
//  Extensions.swift
//  Figsty
//
//  Created by Dmitriy Petrusevich on 1/13/20.
//  Copyright © 2020 Dmitriy Petrusevich. All rights reserved.
//

import Foundation

extension Array where Element == String {
    static func csv(_ string: String?) -> [String]? {
        guard let string = string else { return nil }
        return string.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}

typealias NameComponent = String
extension File {
    func findColor(styleID: String) -> Color? {
        let node = document.nodeWith(styleID: styleID)
        return node?.fills?.first?.fixedOpacityColor
    }

    func findFont(styleID: String) -> TypeStyle? {
        let node = document.nodeWith(styleID: styleID)
        return node?.style
    }
    
    func findComponent(componentID: String) -> (Node, [NameComponent])? {
        guard let pair = document.findWith(componentID: componentID) else { return nil }
        let components = Array(pair.1.dropFirst())
        return (pair.0, components)
    }
}

extension Style {
    func withTrimmedPrexixName(prefix: String) -> Style {
        let name = name.replacingOccurrences(of: "\(prefix)/", with: "")
        return .init(key: key, name: name, styleType: styleType, description: description)
    }
}

extension Node {
    func nodeWith(styleID id: String) -> Node? {
        if styles?.values.contains(id) == true {
            return self
        } else {
            var result: Node?
            for ch in children ?? [] {
                result = ch.nodeWith(styleID: id)
                if result != nil {
                    break
                }
            }
            return result
        }
    }
    
    func findWith(componentID id: String) -> (Node, [NameComponent])? {
        if componentId == id {
            return (self, [name])
        } else {
            for ch in children ?? [] {
                if let pair = ch.findWith(componentID: id) {
                    var components = pair.1
                    components.insert(name, at: 0)
                    return (pair.0, components)
                }
            }
            return nil
        }
    }
}

extension Paint {
    var fixedOpacityColor: Color? {
        guard let color = color, let opacity = opacity else {
            return self.color
        }
        return Color(r: color.r, g: color.g, b: color.b, a: color.a * opacity)
    }
}

extension Color {
    var androidHexColor: String {
        let r = Int(min(255, max(0, round(self.r * 255))))
        let g = Int(min(255, max(0, round(self.g * 255))))
        let b = Int(min(255, max(0, round(self.b * 255))))
        let a = Int(min(255, max(0, round(self.a * 255))))
        return String(format: "#%02X%02X%02X%02X", a, r, g, b)
    }

    var rgba255: String {
        let r = Int(min(255, max(0, round(self.r * 255))))
        let g = Int(min(255, max(0, round(self.g * 255))))
        let b = Int(min(255, max(0, round(self.b * 255))))
        let a = Int(min(255, max(0, round(self.a * 255))))
        return "\(r), \(g), \(b), \(a)"
    }

    var rgba: String {
        return "\(r), \(g), \(b), \(a)"
    }

    var uiColor: String {
        return "UIColor(red: \(Float(r)), green: \(Float(g)), blue: \(Float(b)), alpha: \(Float(a)))"
    }
    
    var colorspaceUIColor: String {
        return "UIColor(cgColor: CGColor(colorSpace: CGColorSpace(name: CGColorSpace.extendedSRGB)!, components: [\(Float(r)), \(Float(g)), \(Float(b)), \(Float(a))])!)"
    }
}

extension TypeStyle {
    enum Weight: Int {
        case thin = 100 // Thin (Hairline)
        case extraLight = 200 // Extra Light (Ultra Light)
        case light = 300 // Light
        case normal = 400 // Normal (Regular)
        case medium = 500 // Medium
        case semiBold = 600 // Semi Bold (Demi Bold)
        case bold = 700 // Bold
        case extraBold = 800 // Extra Bold (Ultra Bold)
        case black = 900 // Black (Heavy)

        var iosName: String {
            switch self {
            case .thin: return "ultraLight"
            case .extraLight: return "thin"
            case .light: return "light"
            case .normal: return "regular"
            case .medium: return "medium"
            case .semiBold: return "semibold"
            case .bold: return "bold"
            case .extraBold: return "heavy"
            case .black: return "black"
            }
        }
    }

    var estimatedWeight: Weight {
        return Weight(rawValue: Int(fontWeight))!
    }

    var uiFontSystem: String {
        return "UIFont.systemFont(ofSize: \(fontSize), weight: .\(estimatedWeight.iosName))"
    }
}

// MARK: -

extension String {
    func absoluteFileURL(baseURL: URL) -> URL {
        if hasPrefix("./") {
            return baseURL.appendingPathComponent(String(dropFirst().dropFirst()))
        } else {
            return URL(fileURLWithPath: self)
        }
    }

    static let trimSet = CharacterSet.punctuationCharacters.union(.decimalDigits).union(.whitespacesAndNewlines)

    var escaped: String {
        let edited = self + "S"
        return edited.trimmingCharacters(in: String.trimSet).dropLast().filter { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    var capitalizedFirstLetter: String {
        guard isEmpty == false else { return self }
        return prefix(1).uppercased() + dropFirst()
    }

    var loweredFirstLetter: String {
        guard isEmpty == false else { return self }
        return prefix(1).lowercased() + dropFirst()
    }
}
