//
//  ImageManager.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 31.08.2023.
//

import Foundation
import Moya
import UIKit

class ImageManager {
 
    private init() {}
    
    static let instance = ImageManager()
    
    
    func convertUIImage(image: UIImage?,compressionQuality: CGFloat, completion: @escaping(Error?, MultipartFormBodyPart?) -> Void) {
        guard let image = image else { return }
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            print("IMAGEDEBUG: Could not convert image to data ")
            completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"]), nil)
            return
        }
        
        let imageName = UUID().uuidString + ".jpg"
        
        let imagePart = MultipartFormBodyPart(provider: .data(imageData),
                                              name: "image",
                                              fileName: "image.jpeg", mimeType: "image/jpeg")
        
        completion(nil, imagePart)
    }

}
