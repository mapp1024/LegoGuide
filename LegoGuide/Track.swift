//
//  Track.swift
//  HalfTunes
//
//  Created by Ken Toh on 13/7/15.
//  Copyright (c) 2015 Ken Toh. All rights reserved.
//

class Track {
    var name: String?
    var previewUrl: String?
    var productid: String?

    init(name: String?, previewUrl: String?, productid: String?) {
        self.name = name
        self.previewUrl = previewUrl
        self.productid = productid
    }
}
