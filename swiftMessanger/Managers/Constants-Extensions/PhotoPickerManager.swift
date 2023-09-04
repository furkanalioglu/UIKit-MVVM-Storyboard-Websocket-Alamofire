import Foundation
import UIKit

protocol PhotoPickerDelegate: AnyObject {
    func didPickImageData(_ image: UIImage)
    func didCancelPicking()
}

class PhotoPickerManager: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    weak var delegate: PhotoPickerDelegate?
    
    private var imagePickerController: UIImagePickerController?

    func presentPhotoPicker(from viewController: UIViewController) {
        if imagePickerController == nil {
            imagePickerController = UIImagePickerController()
        }

        imagePickerController!.delegate = self
        imagePickerController!.sourceType = .photoLibrary
        viewController.present(imagePickerController!, animated: true, completion: nil)
    }

    // UIImagePickerControllerDelegate methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            guard let compressedImage = resizeImage(image: pickedImage) else { return }
            delegate?.didPickImageData(compressedImage)
        }
        cleanupPicker(picker)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        delegate?.didCancelPicking()
        cleanupPicker(picker)
    }
    
    private func cleanupPicker(_ picker: UIImagePickerController) {
        picker.delegate = nil
        picker.dismiss(animated: true) { [weak self] in
            self?.imagePickerController = nil
        }
    }
    
    public func resizeImage(image: UIImage) -> UIImage? { // MARK:  Resize Height to 1600px

          let ratio = 2048 / image.size.height
          var newSize: CGSize
          if (image.size.height > 2048) {
              newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
          } else {
              newSize = image.size
          }
          let rect = CGRect(origin: .zero, size: newSize)
          
          UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
          image.draw(in: rect)
          let newImage = UIGraphicsGetImageFromCurrentImageContext()
          UIGraphicsEndImageContext()
          return newImage
      }
}
