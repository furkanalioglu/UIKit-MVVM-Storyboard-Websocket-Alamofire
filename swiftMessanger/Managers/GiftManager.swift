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
    
//    struct Static {
//        fileprivate static var instance: GiftManager?
//    }
//    
//    class var shared: GiftManager {
//        if let currentInstance = Static.instance {
//            return currentInstance
//        } else {
//            Static.instance = GiftManager()
//            return Static.instance!
//        }
//    }
    
    init() {
        print("GIFT MANAGER 11 CREATED")
    }
    
    deinit {
        print("GIFT MANAGER 11 DELETED")
    }
    
    public func removePlayerView() {
        playerView?.isLoopingEnabled = false
        playerView?.removeFromSuperview()
        playerView?.player?.pause()
        self.playerView = nil
    }
        
    private var playerView: AVPlayerView?
    private lazy var fileManager = FileManager.default
    private lazy var documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    

    public func playSuperAnimation(view: UIView, videoURLString: String, _ completion: @escaping () -> Void) {
        guard let url = URL(string: videoURLString)
        else { debugPrint("Could not find URL") ; return }
        
        //UIScreen bounds verince animasyon küçük geldi.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
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
                     player.play()
                    print("PLAYING VIDEOO")
                    
                }
            }
        }
    }
    
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

    
    private func createTransparentItem(url: URL?) -> AVPlayerItem {
        guard let url = url else { fatalError("Could not get url") }
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
                return request.finish(with: outputImage, context: nil)
            } catch {
                return request.finish(with: error)
            }
        })

        composition.renderSize = asset.videoSize.applying(CGAffineTransform(scaleX: 1.0, y: 0.5))
        return composition
    }
}
