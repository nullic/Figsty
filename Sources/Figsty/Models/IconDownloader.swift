//
//  IconDownloader.swift
//  Figsty
//
//  Created by Dmitriy Petrusevich on 7.02.21.
//  Copyright © 2020 Dmitriy Petrusevich. All rights reserved.
//

import ArgumentParser
import Foundation

final class IconDownloader {
    let file: File
    let fileKey: String
    let accessToken: String?
    var docPaths: [String]?
    var dropCanvaName: Bool = false
    var iconsAsTemplate: Bool = false
    var useAbsoluteBounds: Bool = false
    
    private var missedAssets: [URL: Node] = [:] // key: destination, value: component
    
    init(file: File, fileKey: String, accessToken: String?) {
        self.file = file
        self.fileKey = fileKey
        self.accessToken = accessToken
    }
    
    func downloadPDFs(output: URL) throws {
        for (key, _) in file.components {
            guard let pair = file.findComponent(componentID: key) else {
                continue
            }
            
            guard pair.0.name.contains("/") == false else {
                print("Skip component with id: \(pair.0.id) ... invalid name: \(pair.0.name)")
                continue
            }
            
            let fullName = pair.1.joined(separator: "/")
            let assetRelatedPath = (dropCanvaName ? pair.1.dropFirst().joined(separator: "/") : fullName) + ".imageset"

            guard docPaths?.contains(where: { fullName.hasPrefix($0) }) ?? true else {
                continue
            }

            let assetURL = output.appendingPathComponent(assetRelatedPath)
            guard FileManager.default.fileExists(atPath: assetURL.path, isDirectory: nil) == false else {
                continue
            }
            
            missedAssets[assetURL] = pair.0
        }
        
        let ids = missedAssets.map { $0.value.id }
        
        guard ids.isEmpty == false else { return }
        
        let info = try getDownloadInfo(ids: ids, format: "pdf")
        try downloadMissedPDFs(links: info)
        
        try Set(missedAssets.map { $0.key.deletingLastPathComponent() }).forEach {
            try placeContentJSON(folder: $0, topLevel: output)
        }
    }
    
    private func getDownloadInfo(ids: [String], format: String) throws -> DownloadLinksInfo {
        let components = NSURLComponents(string: "https://api.figma.com/v1/images/\(fileKey)/")!
        components.queryItems = [
            URLQueryItem(name: "format", value: format),
            URLQueryItem(name: "use_absolute_bounds", value: useAbsoluteBounds ? "true" : "false"),
            URLQueryItem(name: "ids", value: ids.joined(separator: ",")),
        ]
        
        return try URLSession.getData(at: components.url!, figmaToken: accessToken, cachePath: nil)
    }
    
    private func downloadMissedPDFs(links: DownloadLinksInfo) throws {
        for (url, component) in missedAssets {
            let fileName = "\(component.name).pdf"
            let fullURL = url.appendingPathComponent(fileName)
            guard let source = links.images[component.id] as? String, let sourceURL = URL(string: source) else {
                continue
            }
            
            print("Download: \(component.name)")
            try URLSession.download(file: sourceURL, to: fullURL)
            
            let metaJSON = url.appendingPathComponent("Contents.json")
            let template = iconsAsTemplate ? iconAssetJSONTemplate : iconAssetJSONOriginal
            try String(format: template, fileName).write(to: metaJSON, atomically: true, encoding: .utf8)
        }
    }
    
    private func placeContentJSON(folder: URL, topLevel: URL) throws {
        guard topLevel.path != folder.path else { return }
        
        let fileURL = folder.appendingPathComponent("Contents.json")
        if FileManager.default.fileExists(atPath: fileURL.path) == false {
            try assetCatalogFolderJSON.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        try placeContentJSON(folder: folder.deletingLastPathComponent(), topLevel: topLevel)
    }
}
