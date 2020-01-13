//
//  Extensions.swift
//  Figsty
//
//  Created by Dmitriy Petrusevich on 1/13/20.
//  Copyright © 2020 Dmitriy Petrusevich. All rights reserved.
//

import Foundation

extension File {
    func findColor(styleID: String) -> Color? {
        let node = document.nodeWith(styleID: styleID)
        return node?.fills?.first?.fixedOpacityColor
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
        return String(format:"#%02X%02X%02X%02X", a, r, g, b)
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
}

// MARK: -

extension String {
    func absoluteFileURL(baseURL: URL) -> URL {
        if hasPrefix("./") {
            return baseURL.appendingPathComponent(String(self.dropFirst().dropFirst()))
        } else {
            return URL(fileURLWithPath: self)
        }
    }

    static let trimSet = CharacterSet.punctuationCharacters.union(.decimalDigits).union(.whitespacesAndNewlines)

    var escaped: String {
        let edited  = self + "S"
        return edited.trimmingCharacters(in: String.trimSet).dropLast().filter { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    var capitalizedFirstLetter: String {
        guard self.isEmpty == false else { return self }
        return self.prefix(1).uppercased() + self.dropFirst()
    }

    var loweredFirstLetter: String {
        guard self.isEmpty == false else { return self }
        return self.prefix(1).lowercased() + self.dropFirst()
    }
}
