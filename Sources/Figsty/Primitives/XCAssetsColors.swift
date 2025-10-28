import Foundation

struct XCAssetsColors: Encodable {
    struct Info: Encodable {
        let author = "xcode"
        let version = 1
    }
    
    struct ColorSet: Encodable {
        struct ColorSetColor: Encodable {
            enum CodingKeys: String, CodingKey {
                case colorSpace = "color-space"
                case components
            }
            
            let colorSpace: String = "srgb"
            let components: [String: String]
            
            init(_ color: Color?) {
                guard let color else {
                    components = [:]
                    return
                }

                components = [
                    "alpha" : "\(color.a)",
                    "blue" : "\(color.b.hexString)",
                    "green" : "\(color.g.hexString)",
                    "red" : "\(color.r.hexString)"
                ]
            }
        }
        
        struct ColorSetAppearance: Encodable {
            enum Value: String, Encodable {
                case dark
                case light
            }
            
            let appearance: String = "luminosity"
            let value: Value
        }
        
        let color: ColorSetColor
        let idiom: String = "universal"
        let appearances: [ColorSetAppearance]?
        
        init(_ color: Color?, value: ColorSetAppearance.Value?) {
            self.color = ColorSetColor(color)
            self.appearances = value.map { [ColorSetAppearance(value: $0)] }
        }
    }
    
    let colors: [ColorSet]
    let info: Info = Info()
    
    init(anyColor: Color?, lightColor: Color?, darkColor: Color?) {
        let any: ColorSet?
        let light: ColorSet?
        let dark: ColorSet?
        
        switch (anyColor, lightColor, darkColor) {
        case (.some(let a), .none, .none):
            any = ColorSet(a, value: nil)
            light = nil
            dark = nil
        case (.none, .some(let l), .none):
            any = ColorSet(l, value: nil)
            light = nil
            dark = nil
            
        case (.some(let a), .none, .some(let d)):
            any = ColorSet(a, value: nil)
            light = nil
            dark = ColorSet(d, value: .dark)
            
        case (.none, .some(let l), .some(let d)):
            any = ColorSet(l, value: nil)
            light = nil
            dark = ColorSet(d, value: .dark)
            
        case (.some(let a), .some(let l), .none):
            any = ColorSet(a, value: nil)
            light = ColorSet(l, value: .light)
            dark = ColorSet(nil, value: .dark)

        case (.some(let a), .some(let l), .some(let d)):
            any = ColorSet(a, value: nil)
            light = ColorSet(l, value: .light)
            dark = ColorSet(d, value: .dark)
            
        case (.none, .none,  .some(let d)):
            any = ColorSet(nil, value: nil)
            light = nil
            dark = ColorSet(d, value: .dark)
            
        case (.none, .none, .none):
            any = ColorSet(nil, value: nil)
            light = nil
            dark = nil
        }

        self.colors = [any, light, dark].compactMap(\.self)
    }
}
