//
//  main.swift
//  Figsty
//
//  Created by Dmitriy Petrusevich on 1/10/20.
//  Copyright © 2020 Dmitriy Petrusevich. All rights reserved.
//

import Foundation
import ArgumentParser


private let launchURL = URL(fileURLWithPath: CommandLine.arguments[0])
private let homeDir = launchURL.deletingLastPathComponent()
private let appName = launchURL.lastPathComponent


struct Figsty: ParsableCommand {
    @Argument(help: "Figma file key")
    var figma_file_key: String
    
    @Option(name: [.customShort("a"), .customLong("token")], parsing: .next, help: "Figma personal access token")
    var personal_access_tokens: String?
    
    @Option(name: .customLong("android-output"), parsing: .next, help: "Andoid Output File")
    var andoid_output_file: String?
    
    @Option(name: .customLong("ios-output"), parsing: .next, help: "iOS Output File")
    var ios_output_file: String?
    
    @Option(name: .customLong("ios-scheme-output"), parsing: .next, help: "iOS 'ColorScheme' Output File")
    var ios_scheme_output_file: String?
    
    @Option(name: .customLong("color-prefix"), parsing: .next, help: "Generated Color Prefix")
    var color_prefix: String?
    
    @Flag(name: .customLong("trim-ending"), help: "Trim ending digits")
    var trim_ending_digits: Bool = false
    
    @Flag(name: .customLong("use-srgb"), help: "Use extended sRGB color space (iOS)")
    var use_extended_srgb_colorspace: Bool = false
    
    func run() throws {
        var request = URLRequest(url: URL(string: "https://api.figma.com/v1/files/\(figma_file_key)/")!)
        request.httpMethod = "GET"
        if let personal_access_tokens = personal_access_tokens {
            request.addValue(personal_access_tokens, forHTTPHeaderField: "X-Figma-Token")
        }

        let semaphore = DispatchSemaphore(value: 0)
        var response: File!
        var responseError: Error?
        URLSession(configuration: .default).dataTask(with: request) { (data, _, error) in
            do {
                guard error == nil, let data = data else { throw error! }
                response = try JSONDecoder().decode(File.self, from: data)
            } catch {
                responseError = error
            }
            semaphore.signal()
        }.resume()
        semaphore.wait()

        guard let file = response else { throw responseError! }

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
    }
}

Figsty.main()
