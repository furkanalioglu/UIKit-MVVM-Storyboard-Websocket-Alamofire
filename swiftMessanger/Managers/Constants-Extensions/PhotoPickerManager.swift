//
//  PhotoPickerManager.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 31.08.2023.
//

import Foundation
import UIKit


protocol PhotoPickerDelegate: AnyObject {
    func didPickImageData(_ image: UIImage)
    func didCancelPicking()
}

class PhotoPickerManager: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    static let shared = PhotoPickerManager()

    weak var delegate: PhotoPickerDelegate?
    
    func presentPhotoPicker(from viewController: UIViewController) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        viewController.present(imagePickerController, animated: true, completion: nil)
    }

    // UIImagePickerControllerDelegate methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage{
            delegate?.didPickImageData(pickedImage)
        }
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        delegate?.didCancelPicking()
        picker.dismiss(animated: true, completion: nil)
    }
}


