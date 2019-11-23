//
//  AlbumModel.swift
//  SharePhoto
//
//  Created by Admin on 11/23/19.
//  Copyright © 2019 Admin. All rights reserved.
//

import Foundation
import Photos

class AlbumModel {
    let name:String
    let count:Int
    let collection:PHAssetCollection
    
    init(name:String, count:Int, collection:PHAssetCollection) {
        self.name = name
        self.count = count
        self.collection = collection
    }
}
