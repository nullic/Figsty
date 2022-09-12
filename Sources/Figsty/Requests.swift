//
//  File.swift
//  
//
//  Created by Dmitriy Petrusevich on 7.02.21.
//

import Foundation

extension URLSession  {
    class func getData<T: Codable>(at url: URL, figmaToken: String?, cachePath: URL?) throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let figmaToken = figmaToken {
            request.addValue(figmaToken, forHTTPHeaderField: "X-Figma-Token")
        }

        let semaphore = DispatchSemaphore(value: 0)
        var response: T!
        var resultError: Error?
        
        if let cachePath = cachePath, let data = try? Data(contentsOf: cachePath) {
            response = try JSONDecoder().decode(T.self, from: data)
        }
        else {
            URLSession(configuration: .default).dataTask(with: request) { (data, _, error) in
                do {
                    guard error == nil, let data = data else { throw error! }
                    if let cachePath = cachePath {
                        try data.write(to: cachePath)
                        print("Save response: \(cachePath.path)")
                    }
                    response = try JSONDecoder().decode(T.self, from: data)
                } catch {
                    resultError = error
                }
                semaphore.signal()
            }.resume()
            semaphore.wait()
        }

        guard let data = response else { throw resultError! }
        return data
    }
    
    class func download(file sourceURL: URL, to destinationURL: URL) throws {
        let semaphore = DispatchSemaphore(value: 0)
        var resultError: Error?
        
        URLSession(configuration: .default).downloadTask(with: sourceURL) { (tempURL, _, error) in
            do {
                guard error == nil, let tempURL = tempURL else { throw error! }
                
                let folder = destinationURL.deletingLastPathComponent()
                if FileManager.default.fileExists(atPath: folder.path, isDirectory: nil) == false {
                    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                }
                
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
            } catch {
                resultError = error
            }
            semaphore.signal()
        }.resume()
        semaphore.wait()

        if let resultError = resultError {
            throw resultError
        }
    }
}
