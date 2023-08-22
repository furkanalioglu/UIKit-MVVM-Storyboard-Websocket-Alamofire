//
//  DownloadManager.swift
//  Fun2Lite
//
//  Created by Güney Köse on 30.03.2023.
//

import Foundation
import CoreText
import UIKit
//import ZIPFoundation

enum DownloadType {
    case Font, BlockedWords, None
}

class DownloadManager {
    private var queue: [FileToDownload] = []
    private var isDownloading = false
    
    struct Static {
        fileprivate static var instance: DownloadManager?
    }
    
    class var shared: DownloadManager {
        if let currentInstance = Static.instance {
            return currentInstance
        } else {
            Static.instance = DownloadManager()
            return Static.instance!
        }
    }
    
    public func dispose() {
        if self.queue.isEmpty {
            DownloadManager.Static.instance = nil
        }
    }
    
    public func queueNewFile(priority: DownloadPriority, url: String?, type: DownloadType? = .none) {
        guard let url = url else { return }
        let isDownloaded = UserDefaults.standard.bool(forKey: url)
//        if isDownloaded {
//            if type == .Font {
//                self.registerFonts {
//                    NotificationCenter.default.post(name: .criticalAssetsDownloaded, object: nil)
//                }
//            } else if type == .BlockedWords {
//                FilesDownloader.shared.downloadBlockedWords()
//            }
//            return
//        }
        let item = FileToDownload(priority: priority.rawValue, url: url, type: type)
        queue.append(item)
        downloadNext()
    }
    
    private func downloadNext() {
        guard !isDownloading else { return }
        queue = queue.sorted(by: {($0.priority) > ($1.priority)})
        guard let nextItem = queue.first else { return }
        isDownloading = true
        if nextItem.type == .Font {
            downloadFonts(from: nextItem) { success in
                self.handleDownload(success, nextItem.url)
            }
        } else {
            downloadFile(from: nextItem) { success in
                self.handleDownload(success, nextItem.url)
            }
        }
    }
    
    private func handleDownload(_ success: Bool, _ key: String) {
        if success {
            UserDefaults.standard.set(true, forKey: key)
        }
        
        self.queue.removeFirst()
        self.isDownloading = false
        self.downloadNext()
        
//        if !queue.contains(where: { $0.priority == DownloadPriority.critical.rawValue }) {
//            NotificationCenter.default.post(name: .criticalAssetsDownloaded, object: nil)
//        }
        
        if queue.isEmpty {
            self.dispose()
        }
    }
    
    private func downloadFile(from file: FileToDownload, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: file.url) else { return }
        debugPrint("Download started...\(file.url)")
        self.isDownloading = true
        let task = URLSession.shared.downloadTask(with: url) { (tempLocalUrl, response, error) in
            if let error = error {
                debugPrint("Error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                debugPrint("Error: Invalid response")
                completion(false)
                return
            }
            
            guard let tempLocalUrl = tempLocalUrl else {
                debugPrint("Error: Temporary file location is nil")
                completion(false)
                return
            }
            
            do {
                let documentsUrl = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
                try FileManager.default.moveItem(at: tempLocalUrl, to: destinationUrl)
                UserDefaults.standard.set(destinationUrl, forKey: url.lastPathComponent)
//                self.savePathToUserLater(url: file.url, path: destinationUrl)
                completion(true)
            } catch {
                debugPrint("Error: \(error.localizedDescription)")
                completion(false)
            }
        }
        task.resume()
    }
    
    /**
     Save paths to UserDefaults if needed
     */
//    private func savePathToUserLater(url: String, path: URL) {
//        if let ringTone = AppConfig.config?.config?.ringTone,
//           ringTone == url {
//            UserDefaults.setRingToneUrl(filePath: path)
//
//        } else if let giftSound = AppConfig.config?.config?.giftSound,
//                  giftSound == url {
//            UserDefaults.setGiftSoundUrl(filePath: path)
//
//        }
////        else if let blockedWords = AppConfig.config?.config?.blockedTextsUrl,
////                  blockedWords == url {
////            UserDefaults.setBlockedWordsUrl(filePath: path)
////        }
//    }
    
    /**
     Downloads multiple fonts.
     */
    private func downloadFonts(from file: FileToDownload, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: file.url)
        else { completion(false) ; return }
        debugPrint("Font resources are downloading...")
        let session = URLSession.shared
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folderURL = documentsDirectoryURL.appendingPathComponent("fonts", isDirectory: true)
        let fileURL = folderURL.appendingPathComponent(url.lastPathComponent)
        
        do { //Creates folder.
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            let task = session.downloadTask(with: url) { (tempLocalURL, response, error) in
                guard let tempLocalURL = tempLocalURL, error == nil else { completion(false) ; return }
                
                do { //Moves data to created folder.
                    try FileManager.default.moveItem(at: tempLocalURL, to: fileURL)
                    debugPrint("ZIP File saved to: \(fileURL.path)")
                    do { //Unzips zip file.
//                        try FileManager.default.unzipItem(at: fileURL, to: folderURL)
                        
                        //Install fonts to the project.
                        let fontFiles = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
                        for fontFile in fontFiles {
                            let fontPath = folderURL.appendingPathComponent(fontFile).path
                            let fontURL = URL(fileURLWithPath: fontPath)
                            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
                            //                        print("\(fontFile) installed.")
                        }
                        completion(true)
                        do { //Try to delete zip file.
                            try FileManager.default.removeItem(at: fileURL)
                            debugPrint("ZIP file deleted at:", fileURL)
                        } catch {
                            debugPrint("Could not delete ZIP file with error: \(error.localizedDescription)", fileURL)
                            completion(false)
                        }
                    } catch {
                        debugPrint("Extraction of ZIP archive failed with error:\(error)")
                        completion(false)
                    }
                } catch {
                    debugPrint("Could not move item: \(error.localizedDescription)")
                    completion(false)
                }
            }
            task.resume()
        } catch {
            debugPrint("Could not create directory: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    /**
     Register fonts.
     */
    private func registerFonts(completion: @escaping () -> Void) {
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folderURL = documentsDirectoryURL.appendingPathComponent("fonts", isDirectory: true)
        
        do {
            let fontFiles = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
            for fontFile in fontFiles {
                let fontPath = folderURL.appendingPathComponent(fontFile).path
                let fontURL = URL(fileURLWithPath: fontPath)
                CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
                //                print("\(fontFile) installed.")
            }
            completion()
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }
    
    /**
     Downloads a single font.
     */
    private func downloadFont(from file: FileToDownload) {
        guard let url = URL(string: file.url) else { return }
        debugPrint("Downloading fonts...")
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let task = session.dataTask(with: request) { data, response, error in
            if let error {
                debugPrint(error.localizedDescription)
            } else { //Success
                if let fontData = data,
                   let dataProvider = CGDataProvider(data: fontData as CFData),
                   let cgFont = CGFont(dataProvider) {
                    
                    var error: Unmanaged<CFError>?
                    
                    if !CTFontManagerRegisterGraphicsFont(cgFont, &error) {
                        debugPrint("Error loading Font!")
                    } else {
                        let fontName = cgFont.postScriptName
                        let fontNameString = String(describing: fontName)
                        debugPrint("Font saved!, \(fontNameString)")
                    }
                } else {
                    debugPrint("Could not find font data!")
                }
            }
        }
        task.resume()
    }
    
    //MUCAHIT: download fonskiyonunu düzenle
    
    /**
     Download Ml Model to identify NSFW Objects
     */
    func downloadNsfwMlKit() {
        guard let url = URL(string: "https://fun2lite-app-assets.s3.eu-central-1.amazonaws.com/config/NSFW.mlmodel.zip"),
              UserDefaults.standard.bool(forKey: "NsfwMlKitModelDownloaded") == false
        else {
            return
        }
        debugPrint("NsfwKit is downloading...")
        let session = URLSession.shared
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folderURL = documentsDirectoryURL.appendingPathComponent("MLModel", isDirectory: true)
        let fileURL = folderURL.appendingPathComponent(url.lastPathComponent)
        
        do { // Creates folder.
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            debugPrint("Could not create directory: \(error.localizedDescription)")
        }
        
        let task = session.downloadTask(with: url) { tempLocalURL, _, error in
            guard let tempLocalURL = tempLocalURL, error == nil else { return }
            
            do { // Moves data to created folder.
                try FileManager.default.moveItem(at: tempLocalURL, to: fileURL)
                debugPrint("ZIP File saved to: \(fileURL.path)")
                do { // Unzips zip file.
//                    try FileManager.default.unzipItem(at: fileURL, to: folderURL)
                    do { // Try to delete zip file.
                        try FileManager.default.removeItem(at: fileURL)
                        UserDefaults.standard.set(true, forKey: "NsfwMlKitModelDownloaded")
                        debugPrint("ZIP file deleted at:", fileURL)
                    } catch {
                        debugPrint("Could not delete ZIP file with error: \(error.localizedDescription)", fileURL)
                    }
                } catch {
                    debugPrint("Extraction of ZIP archive failed with error:\(error)")
                }
            } catch {
                debugPrint("Could not move item: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
    
}

struct FileToDownload {
    let priority: Int
    let url: String
    let type: DownloadType
    
    init(priority: Int, url: String, type: DownloadType?) {
        self.priority = priority
        self.url = url
        self.type = type ?? .None
    }
}

enum DownloadPriority: Int {
    case low, medium, high, critical
}
