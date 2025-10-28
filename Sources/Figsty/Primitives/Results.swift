//
//  ResultStructs.swift
//  Figsty
//
//  Created by Dmitriy Petrusevich on 1/10/20.
//  Copyright © 2020 Dmitriy Petrusevich. All rights reserved.
//

import Foundation

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

// Contents.json
let assetCatalogFolderJSON = """
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "provides-namespace" : true
  }
}
"""

// Contents.json
let iconAssetJSONTemplate = """
{
  "images" : [
    {
      "filename" : "%@",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "template-rendering-intent" : "template"
  }
}
"""

// Contents.json
let iconAssetJSONOriginal = """
{
  "images" : [
    {
      "filename" : "%@",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "template-rendering-intent" : "original"
  }
}
"""
