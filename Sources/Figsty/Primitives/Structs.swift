//
//  Structures.swift
//  Figsty
//
//  Created by Dmitriy Petrusevich on 1/10/20.
//  Copyright © 2020 Dmitriy Petrusevich. All rights reserved.
//

import Foundation

struct File: Codable {
    let name: String
    let version: String
    let document: Node

    let styles: [String: Style]
    let components: [String: Component]
}

struct Node: Codable {
    let id: String
    let name: String
    let type: NodeType

    let children: [Node]?

    let backgroundColor: Color?

    let style: TypeStyle?
    let styles: [String: String]?

    let fills: [Paint]?
    
    let componentId: String?
}

struct Color: Codable {
    let r: Double
    let g: Double
    let b: Double
    let a: Double
}

struct Style: Codable {
    let key: String
    let name: String
    let styleType: StyleType
    let description: String?
}

struct Component: Codable {
    let key: String
    let name: String
    let description: String?
}

struct TypeStyle: Codable {
    let fontFamily: String
    let fontWeight: Double
    let fontSize: Double
}

struct Paint: Codable {
    let type: PaintType
    let color: Color?
    let opacity: Double?
}

struct DownloadLinksInfo: Codable {
    let err: String?
    let images: [String: String?]
}

struct VariablesFile: Decodable {
    let id: String
    let name: String
    let modes: [String: String]
    let variableIds: [String]
    
    let variables: [Variable]
    
    func modeId(mode: String?) -> String? {
        guard let modeName = mode else { return nil }
        for (id, name) in modes {
            if name == modeName {
                return id
            }
        }
        return nil
    }
}

struct Variable: Decodable {
    enum Value: Decodable {
        case color(Color)
        case string(String)
        case float(Double)
        case alias(VariableAlias)
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let value = try? container.decode(Double.self) {
                self = .float(value)
            } else if let value = try? container.decode(String.self) {
                self = .string(value)
            } else if let value = try? container.decode(Color.self) {
                self = .color(value)
            } else {
                let value = try container.decode(VariableAlias.self)
                self = .alias(value)
            }
        }
        
        var color: Color? {
            guard case .color(let color) = self else { return nil }
            return color
        }
        
        var alias: VariableAlias? {
            guard case .alias(let alias) = self else { return nil }
            return alias
        }
    }
    
    let id: String
    let name: String
    let description: String?
    let type: VariableType
    let scopes: [String]?
    let valuesByMode: [String: Value]
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case description
        case type
        case scopes
        case valuesByMode
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.type = try container.decode(VariableType.self, forKey: .type)
        self.scopes = try container.decodeIfPresent([String].self, forKey: .scopes)
        self.valuesByMode = try container.decode([String : Variable.Value].self, forKey: .valuesByMode)
    }
}

struct VariableAlias: Decodable {
    let id: String
    let type: AliasType
}
