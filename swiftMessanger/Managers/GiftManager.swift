//
//  GiftManager.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 22.08.2023.
//

import Foundation
import AVFoundation
import UIKit
import CoreImage


final class GiftManager {
    
    struct Static {
        fileprivate static var instance: GiftManager?
    }
    
    class var shared: GiftManager {
        if let currentInstance = Static.instance {
            return currentInstance
        } else {
            Static.instance = GiftManager()
            return Static.instance!
        }
    }

    public func dispose() {
        GiftManager.Static.instance = nil
        self.playerView?.removeFromSuperview()
        self.playerView = nil
    }
        
    private var playerView: AVPlayerView?
    private lazy var fileManager = FileManager.default
    private lazy var documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    

    public func playSuperAnimation(view: UIView, videoURLString: String, _ completion: @escaping () -> Void) {
        guard let url = URL(string: videoURLString)
        else { debugPrint("Could not find URL") ; return }
        
        //UIScreen bounds verince animasyon küçük geldi.
        let videoSize = CGSize(width: (view.frame.width * 2), height: (view.frame.width * 2))
        
        self.playerView = AVPlayerView(frame: CGRect(origin: .zero, size: videoSize))
        guard let playerView = self.playerView else { return }
        
        if !view.contains(playerView) {
            view.addSubview(playerView)
            view.bringSubviewToFront(playerView)
        }
        
        // Use Auto Layout anchors to center our playerView
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.widthAnchor.constraint(equalToConstant: videoSize.width).isActive = true
        playerView.heightAnchor.constraint(equalToConstant: videoSize.height).isActive = true
        playerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        playerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        // Setup our playerLayer to hold a pixel buffer format with "alpha"
        let playerLayer: AVPlayerLayer = playerView.playerLayer
        playerLayer.pixelBufferAttributes = [
            (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
        
        let playerItem = createTransparentItem(url: url)
        
        playerView.loadPlayerItem(playerItem) { result in
            switch result {
            case .failure(let error):
                completion()
                return print("Something went wrong when loading our video:", error.localizedDescription, url)
            case .success(let player):
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { (_) in
                     player.seek(to: CMTime.zero)
                     player.play()
                 }

                 // Start playing
                 player.play()
            }
        }
    }
    
    func didDownloadVideo(from urlString: String, assetString: String, forAsset assetId: Int, completion: @escaping (Bool, Error?) -> Void) {
        guard let videoUrl = URL(string: urlString) else {
            completion(false, nil)
            return
        }
        
        let fileExtension = videoUrl.pathExtension
        let destinationPath = getAssetPath(forAssetId: "\(assetId)", type: assetString, extension: fileExtension)
        let destinationURL = URL(fileURLWithPath: destinationPath)
        
        // Check if file already exists
        if FileManager.default.fileExists(atPath: destinationPath) {
//            print("metaldebug:File for \(assetString) \(assetId) already exists at DestinationURL: \(destinationPath)")
            let fixedPath = "file://\(destinationPath)"
            print("File for \(fixedPath)")
            UserDefaults.standard.set(fixedPath, forKey: "\(assetString)-\(assetId)")
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
                // Ensure the directory exists
                let directoryPath = self.getDirectoryPath(forType: assetString)
                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
                
                try FileManager.default.copyItem(at: localURL, to: destinationURL)
                print("metaldebug:Saved \(assetString) \(assetId) to DestinationURL:  \(destinationURL)")
                UserDefaults.standard.set(destinationPath, forKey: "\(assetString)-\(assetId)")
                completion(true, nil)
            } catch {
                completion(false, error)
            }
        }
        downloadTask.resume()
    }

    // Get the directory path for a specific asset type
    func getDirectoryPath(forType type: String) -> String {
        return documentsDirectory.appendingPathComponent(type).path
    }

    // Get the full path for an asset
    func getAssetPath(forAssetId assetId: String, type: String, extension ext: String) -> String {
        return getDirectoryPath(forType: type).appending("/\(assetId).\(ext)")
    }

    
//    func getAudioPath(forCarId id: String, extension fileExtension: String) -> String {
//        let fileManager = FileManager.default
//        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
//        return documentDirectory.appendingPathComponent(id).appendingPathExtension(fileExtension).path
//    }
    
    private func createTransparentItem(url: URL?) -> AVPlayerItem {
        guard let url = url else {fatalError("Could not get url")}
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.seekingWaitsForVideoCompositionRendering = true
        playerItem.videoComposition = createVideoComposition(for: asset)

        return playerItem
    }
    
    private func createVideoComposition(for asset: AVAsset) -> AVVideoComposition {
        let filter = AlphaFrameFilter(renderingMode: .builtInFilter)
        let composition = AVMutableVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
            do {
                let (inputImage, maskImage) = request.sourceImage.verticalSplit()
                let outputImage = try filter.process(inputImage, mask: maskImage) //CIImage
                //self.saveVideoToLibrary(image: outputImage)
                return request.finish(with: outputImage, context: nil)
            } catch {
                return request.finish(with: error)
            }
        })

        composition.renderSize = asset.videoSize.applying(CGAffineTransform(scaleX: 1.0, y: 0.5))
        return composition
    }
}
