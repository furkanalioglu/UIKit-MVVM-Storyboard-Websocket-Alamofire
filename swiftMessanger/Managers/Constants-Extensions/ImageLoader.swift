//
//  ImageLoader.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 5.09.2023.
//

import Foundation
import UIKit

class ImageLoader {

    // Shared instance to make it act as a singleton
    static let shared = ImageLoader()

    private init() {}

    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }

    func downloadImage(from url: URL, completion: @escaping (UIImage?) -> ()) {
        print("Download Started")
        getData(from: url) { data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() {
                completion(image)
            }
        }
    }
}

extension UIImageView {
    func downloaded(from url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        contentMode = mode
        ImageLoader.shared.downloadImage(from: url) { [weak self] image in
            guard let strongSelf = self, let downloadedImage = image else { return }
            DispatchQueue.main.async() {
                strongSelf.image = downloadedImage
            }
        }
    }
    
    func downloaded(from link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode)
    }
}

// Usage:

// In a UIViewController:
// override func viewDidLoad() {
//     super.viewDidLoad()
//     imageView.downloaded(from: "https://cdn.arstechnica.net/wp-content/uploads/2018/06/macOS-Mojave-Dynamic-Wallpaper-transition.jpg")
// }
