//
//  ResultStructs.swift
//  Figsty
//
//  Created by Dmitriy Petrusevich on 1/10/20.
//  Copyright © 2020 Dmitriy Petrusevich. All rights reserved.
//

import Foundation

enum CLIError: Error {
    case invalidArguments
}

struct ColorStyle: CustomStringConvertible {
    var description: String {
        return "\(style.name): \(color.androidHexColor)"
    }

    let style: Style
    let color: Color
}

struct FontStyle: CustomStringConvertible {
    var description: String {
        return "\(style.name): \(typeStyle.uiFontSystem)"
    }

    let style: Style
    let typeStyle: TypeStyle
}

// MARK: - Predefined strings

let indent = "    "

let androidFilePrefix =
"""
<?xml version="1.0" encoding="utf-8"?>
<resources>
"""

let androidFileSuffix =
"""
</resources>
"""

let iOSSwiftFilePrefix =
"""
// swiftformat:disable all
// swiftlint:disable all
// Generated file

import Foundation
import UIKit

"""
