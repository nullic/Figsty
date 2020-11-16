//
//  main.swift
//  Figsty
//
//  Created by Dmitriy Petrusevich on 1/10/20.
//  Copyright © 2020 Dmitriy Petrusevich. All rights reserved.
//

import Foundation

let launchURL = URL(fileURLWithPath: CommandLine.arguments[0])
let homeDir = launchURL.deletingLastPathComponent()
let appName = launchURL.lastPathComponent

do {
    var figma_file_key: String!
    var personal_access_tokens: String?
    var andoid_output_file: String?
    var ios_output_file: String?
    var ios_scheme_output_file: String?
    var color_prefix: String?
    var trim_ending_digits: Bool = false
    var use_extended_srgb_colorspace: Bool = false

    var key: String?
    for (index, arg) in CommandLine.arguments.enumerated() {
        if index == 0 {
            continue
        } else if index == 1 {
            figma_file_key = arg
            continue
        } else if key == nil {
            switch arg {
            case "-ted": trim_ending_digits = true
            case "-exsrgb": use_extended_srgb_colorspace = true
            default: key = arg
            }
        } else {
            switch key {
            case "-a": personal_access_tokens = arg
            case "-oa": andoid_output_file = arg
            case "-oi": ios_output_file = arg
            case "-ois": ios_scheme_output_file = arg
            case "-prefix": color_prefix = arg
            default: throw CLIError.invalidArguments
            }
            key = nil
        }
    }
    guard figma_file_key != nil else {
        throw CLIError.invalidArguments
    }

    var request = URLRequest(url: URL(string: "https://api.figma.com/v1/files/\(figma_file_key!)/")!)
    request.httpMethod = "GET"
    if let personal_access_tokens = personal_access_tokens {
        request.addValue(personal_access_tokens, forHTTPHeaderField: "X-Figma-Token")
    }

    let semaphore = DispatchSemaphore(value: 0)
    var response: File!
    URLSession(configuration: .default).dataTask(with: request) { (data, _, error) in
        do {
            guard error == nil, let data = data else { throw error! }
            response = try JSONDecoder().decode(File.self, from: data)
        } catch {
            print(error)
        }
        semaphore.signal()
    }.resume()
    semaphore.wait()

    guard let file = response else { exit(-1) }

    let generator = StyleGenerator(file: file)
    generator.colorPrefix = color_prefix ?? ""
    generator.iosStructSupportScheme = ios_scheme_output_file != nil
    generator.trimEndingDigits = trim_ending_digits
    generator.useExtendedSRGBColorspace = use_extended_srgb_colorspace

    if let file = andoid_output_file {
        let output = file.absoluteFileURL(baseURL: homeDir)
        try generator.generateAndroid(output: output)
        print("Generate: \(output.path)")
    }

    if let file = ios_output_file {
        let output = file.absoluteFileURL(baseURL: homeDir)
        try generator.generateIOS(output: output)
        print("Generate: \(output.path)")
    }

    if let file = ios_scheme_output_file {
        let output = file.absoluteFileURL(baseURL: homeDir)
        try generator.generateIOSSheme(output: output)
        print("Generate: \(output.path)")
    }
} catch {
    print(error)
    print("\n\nUsage example:")
    print("\t\(appName) figma_file_key -a personal_access_token -tn -oi \"./Colors.swift\"")
    print("\nOptions:")
    print("\ta: Figma personal access token")
    print("\toa: Andoid Output file")
    print("\toi: iOS Output file")
    print("\tois: iOS 'ColorScheme' Output file")
    print("\tprefix: Generated Color Prefix")
    print("\tted: Trim ending digits")
    print("\texsrgb: Use extended sRGB color space (iOS)")
}
