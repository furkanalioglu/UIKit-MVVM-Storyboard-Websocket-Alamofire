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
    
    private var fileManager = FileManager.default
    private var documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    func getUDAssetPath(for assetType: AssetTypes, assetId: Int) -> String? {
        let assetKey = "\(assetType.rawValue)-\(assetId)"
        print("AssetDEBUG: trying to GET \(assetKey)")
        guard let pathUD = UserDefaults.standard.string(forKey: assetType.getPathKey(for: assetId)) else { return nil}
        let assetURLString = "file://\(pathUD)"
        print("AssetDEBUG: trying to GET \(assetURLString)")
        return assetURLString
    }
    
    
    func saveAssetToUDAndGetPath(from assetURL: URL, for assetType: AssetTypes, assetId: Int) -> String{
        let fileExtension = assetURL.pathExtension
        let destinationPath = getAssetPath(forAssetId: assetId, type: assetType.rawValue, extension: fileExtension)
        UserDefaults.standard.set(destinationPath, forKey: assetType.getPathKey(for: assetId))
        return destinationPath
    }
    
    
    func getDirectoryPath(forType type: String) -> String {
        return documentsDirectory.appendingPathComponent(type).path
    }

    func getAssetPath(forAssetId assetId: Int, type: String, extension ext: String) -> String {
        return getDirectoryPath(forType: type).appending("/\(assetId).\(ext)")
    }
    
}
