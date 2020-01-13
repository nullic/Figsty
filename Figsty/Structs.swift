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
