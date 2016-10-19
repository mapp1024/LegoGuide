//
//  Download.swift
//  HalfTunes
//
//  Created by Andy Obusek on 9/19/15.
//  Copyright © 2015 Ken Toh. All rights reserved.
//

import Foundation

class DownloadInfo: NSObject {

    var url: String
    var isDownloading = false
    var progress: Float = 0.0

    var downloadTask: URLSessionDownloadTask!
    var resumeData: Data?
    
    
    
    

    init(url: String) {
        self.url = url
        print("url ==>",url )
        print("isDownloading ==>",isDownloading)
        print("progress ==>",progress)
        
    }
}
