//
//  Enums.swift
//  Figsty
//
//  Created by Dmitriy Petrusevich on 1/10/20.
//  Copyright © 2020 Dmitriy Petrusevich. All rights reserved.
//

import Foundation

enum NodeType: String, Codable {
    case DOCUMENT
    case CANVAS
    case FRAME
    case GROUP
    case VECTOR
    case BOOLEAN_OPERATION
    case STAR
    case LINE
    case ELLIPSE
    case REGULAR_POLYGON
    case RECTANGLE
    case TEXT
    case SLICE
    case COMPONENT
    case COMPONENT_SET
    case INSTANCE
}

enum EasingType: String, Codable {
    case EASE_IN
    case EASE_OUT
    case EASE_IN_AND_OUT
    case LINEAR
}

enum PaintType: String, Codable {
    case SOLID
    case GRADIENT_LINEAR
    case GRADIENT_RADIAL
    case GRADIENT_ANGULAR
    case GRADIENT_DIAMOND
    case IMAGE
    case EMOJI
}

enum StyleType: String, Codable {
    case FILL
    case TEXT
    case EFFECT
    case GRID
}
