//
//  DownloadManager.swift
//  Fun2Lite
//
//  Created by Güney Köse on 30.03.2023.
//

import Foundation
import UIKit


class DownloadManager {
    
    private init() {}
    
    static let shared = DownloadManager()
    
    func didDownloadVideo(from urlString: String, assetString: AssetTypes, forAsset assetId: Int, completion: @escaping (Bool, Error?) -> Void) {
        guard let videoUrl = URL(string: urlString) else {
            completion(false, nil)
            return
        }
        
        let destinationPath = AssetManager.shared.getAssetPath(forAssetId: assetId, type: assetString.rawValue, extension: videoUrl.pathExtension)
        let destinationURL = URL(fileURLWithPath: destinationPath)
        
        if FileManager.default.fileExists(atPath: destinationPath) {
            UserDefaults.standard.set(destinationPath, forKey: assetString.getPathKey(for: assetId))
            print("AssetDEBUG: Existed path: \(destinationPath)")
            completion(true, nil)
            return
        }
        
        let session = URLSession.shared
        let downloadTask = session.downloadTask(with: videoUrl) { localURL, response, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            guard let localURL = localURL else {
                completion(false, nil)
                return
            }
            
            do {
                let directoryPath = AssetManager.shared.getDirectoryPath(forType: assetString.rawValue)
                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.copyItem(at: localURL, to: destinationURL)
                
                let createdPath = AssetManager.shared.saveAssetToUDAndGetPath(from: destinationURL, for: assetString, assetId: assetId)
                UserDefaults.standard.set(createdPath, forKey: assetString.getPathKey(for: assetId))
                print("AssetDEBUG: Downloaded path: \(createdPath)")
                completion(true, nil)
            } catch {
                completion(false, error)
            }
        }
        downloadTask.resume()
    }
}
