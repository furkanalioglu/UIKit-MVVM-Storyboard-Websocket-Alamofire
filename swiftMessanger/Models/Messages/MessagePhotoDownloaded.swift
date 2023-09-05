//
//  MessagePhotoDownloaded.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 5.09.2023.
//

import Foundation


struct MessagePhotoModel : Codable {
    let imageData: Data
    let payloadDate: String
}
