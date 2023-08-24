//
//  AssetManager.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 23.08.2023.
//

import Foundation
import UIKit


class AssetManager {
    
    private init() {}
    
    static let shared = AssetManager()
    
    private lazy var fileManager = FileManager.default
    private lazy var documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    
    func getUDAssetPath(for assetType: AssetTypes, assetId: Int) -> String? {
        let assetKey = "\(assetType.rawValue)-\(assetId)"
        guard let pathUD = UserDefaults.standard.string(forKey: assetKey) else { return nil}
        let assetURLString = "file://\(pathUD)"
        debugPrint("ASSETBDEBUG FROM UD: \(assetURLString)")
        return assetURLString
    }
    
    
    func saveAssetUDAndGetPath(from assetURL: URL, for assetType: AssetTypes, assetId: Int) -> String{
        let fileExtension = assetURL.pathExtension
        let destinationPath = getAssetPath(forAssetId: assetId, type: assetType.rawValue, extension: fileExtension)
        UserDefaults.standard.set(destinationPath, forKey: "\(assetType.rawValue)-\(assetId)")
        debugPrint("ASSETBDEBUG FROM FILEMANAGER: \(destinationPath)")
        return destinationPath
    }
    
    
    func getDirectoryPath(forType type: String) -> String {
        return documentsDirectory.appendingPathComponent(type).path
    }

    // Get the full path for an asset
    func getAssetPath(forAssetId assetId: Int, type: String, extension ext: String) -> String {
        return getDirectoryPath(forType: type).appending("/\(assetId).\(ext)")
    }
    
}
