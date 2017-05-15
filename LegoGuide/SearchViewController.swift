//
//  SearchViewController.swift
//  HalfTunes
//
//  Created by Ken Toh on 13/7/15.
//  Copyright (c) 2015 Ken Toh. All rights reserved.
//

import UIKit
import MediaPlayer


class SearchViewController: UIViewController {
    var activeDownloads = [String: DownloadInfo]()

    // 1
    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var pdfView: UIWebView!

    @IBOutlet weak var webToolBar: UIToolbar!
    @IBOutlet weak var lastPageButton: UIBarButtonItem!
    
    
    var searchResults = [Track]()
    
    lazy var tapRecognizer: UITapGestureRecognizer = {
        var recognizer = UITapGestureRecognizer(target:self, action: #selector(SearchViewController.dismissKeyboard))
        return recognizer
    }()

    lazy var downloadsSession: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "bgSessionConfiguration")
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()

    
    // MARK: View controller methods
    override func viewDidLoad() {
        super.viewDidLoad()
        webToolBar.isHidden = true
        
        tableView.tableFooterView = UIView()
        _ = self.downloadsSession
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: Handling Search Results

    // This helper method helps parse response JSON NSData into an array of Track objects.
    func updateSearchResults(data: Data?) {
        searchResults.removeAll()
        do {
            var totalManualCount: Int?
             if let data = data, let response = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions(rawValue:0)) as? [String: Any] {
                if let array: Any = response["products"] {
                    /* 先抓有幾筆說明書資料 */
                    for trackDictonary in array as! [Any] {
                        if let trackDictonary = trackDictonary as? [String: Any] {
                            let buildingInstructions : NSArray = (trackDictonary["buildingInstructions"] as! NSArray)
                            totalManualCount = buildingInstructions.count
                            for subDictonary in buildingInstructions as! [Any] {
                                if let subDictonary = subDictonary as? [String: Any], let pdfLocation = subDictonary["pdfLocation"] as? String {
                                    let description = subDictonary["description"] as? String
                                    //擷取description內容，並以空白字元為分格符號{.components(separatedBy: " ")}，找出最後一碼為V29/V.29/v.29/v29
                                    // http://stackoverflow.com/questions/32243963/filter-json-object-value
                                    let filter_desc = description?.components(separatedBy: " ")
                                    let search_reslut = (filter_desc?[(filter_desc?.count)!-1])!
                                    if (search_reslut == "V39") { totalManualCount=totalManualCount!-1 }
                                }else{ print("subData NOT a dictonary") }
                            }
                        } else {
                            print("Not a dictionary")
                        }
                    }
                    /* 先抓有幾筆說明書資料 END*/
                    print("the end of totalManualCount ==> ",totalManualCount)
                    /* parse JSON data */
                    for trackDictonary in array as! [Any] {
                        if let trackDictonary = trackDictonary as? [String: Any], let name = trackDictonary["productName"] as? String {
                            let productid = trackDictonary["productId"] as? String
                            let productImage = trackDictonary["productImage"] as? String
                            
                            if totalManualCount == 1
                            {
                                let productImage = trackDictonary["productImage"] as? String
                                print("productImage ==> ",productImage)
                            }else{ print("total Manual Count not eq 1 !") }
                            
                            let buildingInstructions : NSArray = (trackDictonary["buildingInstructions"] as! NSArray)
                            for subDictonary in buildingInstructions as! [Any] {
                                if let subDictonary = subDictonary as? [String: AnyObject], let pdfLocation = subDictonary["pdfLocation"] as? String {
                                    
                                    let description = subDictonary["description"] as? String
                                    //擷取description內容，並以空白字元為分格符號{.components(separatedBy: " ")}，找出最後一碼為V29/V.29/v.29/v29
                                    // http://stackoverflow.com/questions/32243963/filter-json-object-value
                                    let filter_desc = description?.components(separatedBy: " ")
                                    let search_reslut = (filter_desc?[(filter_desc?.count)!-1])!
                                    if (search_reslut == "V39")
                                    {
                                        print ("Don't show V39 version manual!")
                                    }else{
                                        let pdfLocation = subDictonary["pdfLocation"] as? String
                                        let downloadSize = subDictonary["downloadSize"] as? String
                                        if totalManualCount! > 1
                                        {
                                            let productImage = subDictonary["frontpageInfo"] as? String
                                            print("name  ==> ",name)
                                            print("description ==> ",description)
                                            print("pdfLocation ==> ",pdfLocation)
                                            print("productImage ==> ",productImage)
                                            
                                            //searchResults.append(Track(name: name, previewUrl: pdfLocation, productid: productid, imageUrl: productImage))

                                        } else { print("total Manual Count not > 1 !") }
                                      searchResults.append(Track(name: name, previewUrl: pdfLocation, productid: productid, imageUrl: productImage))
                                    

                                        
                                    }
                                }else{ print("subData NOT a dictonary") }
                            }
                            /* parse JSON data  END*/
                        } else {
                            print("Not a dictionary")
                        }
                    }

                    
                    
                    
                    

                } else {
                    print("Results key not found in dictionary")
                }
            } else {
                print("JSON Error")
            }
        } catch let error as NSError {
            print("Error parsing results: \(error.localizedDescription)")
        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        }

    }

    // MARK: Keyboard dismissal
    func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }

    // MARK: Download methods

    // Called when the Download button for a track is tapped
    func startDownload(track: Track) {
        if let urlString = track.previewUrl, let url =  URL(string: urlString) {
            print("download url ==>",url)
            // 1
            let download = DownloadInfo(url: urlString)
            // 2
            download.downloadTask = downloadsSession.downloadTask(with: url)
            // 3
            download.downloadTask!.resume()
            // 4
            download.isDownloading = true
            print("download progress ==>",download.isDownloading)
            // 5
            activeDownloads[download.url] = download            
        }
    }

    // Called when the Pause button for a track is tapped
    func pauseDownload(track: Track) {
        if let urlString = track.previewUrl,
            let download = activeDownloads[urlString] {
            if(download.isDownloading) {
                download.downloadTask?.cancel { data in
                    if data != nil {
                        download.resumeData = data
                    }
                }
                download.isDownloading = false
            }
        }
    }

    // Called when the Cancel button for a track is tapped
    func cancelDownload(track: Track) {
        if let urlString = track.previewUrl,
            let download = activeDownloads[urlString] {
            download.downloadTask?.cancel()
            activeDownloads[urlString] = nil
        }
    }

    // Called when the Resume button for a track is tapped
    func resumeDownload(track: Track) {
        if let urlString = track.previewUrl,
            let download = activeDownloads[urlString] {
            if let resumeData = download.resumeData {
                download.downloadTask = downloadsSession.correctedDownloadTask(withResumeData: resumeData)
                download.downloadTask!.resume()
                download.isDownloading = true
            } else if let url = URL(string: download.url) {
                download.downloadTask = downloadsSession.downloadTask(with: url)
                download.downloadTask!.resume()
                download.isDownloading = true
            }
        }
    }

    // This method attempts to play the local file (if it exists) when the cell is tapped
    /*
    func playDownload(track: Track) {
        if let urlString = track.previewUrl, let url = localFilePathForUrl(previewUrl: urlString) {
            let moviePlayer: MPMoviePlayerViewController! = MPMoviePlayerViewController(contentURL: url)
            presentMoviePlayerViewControllerAnimated(moviePlayer)
        }
    }
    */
     
    //This method attempts to show the local pdf file (if it exists) when the call is tapped
    func showDownload(track: Track){
        if let urlString = track.previewUrl, let url = localFilePathForUrl(previewUrl: urlString) {

            //let lastPathComponent = url.lastPathComponent
            //let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
            //let fullPath = documentsPath.appendingPathComponent(lastPathComponent)
            
            let request = URLRequest(url: url)
            pdfView.loadRequest(request)
            super.view.bringSubview(toFront: webToolBar)
            webToolBar.isHidden = false
            pdfView.isHidden = false
            super.view.bringSubview(toFront: pdfView)
            
        }
    }
    
    
    @IBAction func goBackSearchPage(_ sender: UIBarButtonItem) {
        webToolBar.isHidden = true
        pdfView.isHidden = true
        let blankpage = URL( string: "about:blank" )
        let request = URLRequest(url:blankpage!)
        pdfView.loadRequest(request)
    }

    // MARK: Download helper methods

    // This method generates a permanent local file path to save a track to by appending
    // the lastPathComponent of the URL (i.e. the file name and extension of the file)
    // to the path of the app’s Documents directory.
    func localFilePathForUrl(previewUrl: String) -> URL? {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        if let url = URL(string: previewUrl) {
            let lastPathComponent = url.lastPathComponent
            let fullPath = documentsPath.appendingPathComponent(lastPathComponent)
            return URL(fileURLWithPath:fullPath)
        }

        return nil
    }

    // This method checks if the local file exists at the path generated by localFilePathForUrl(_:)
    func localFileExistsForTrack(track: Track) -> Bool {
        if let urlString = track.previewUrl, let localUrl = localFilePathForUrl(previewUrl: urlString) {
            var isDir : ObjCBool = false
            let path = localUrl.path
            return FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        }
        return false
    }

    func trackIndexForDownloadTask(downloadTask: URLSessionDownloadTask) -> Int? {
        if let url = downloadTask.originalRequest?.url?.absoluteString {
            for (index, track) in searchResults.enumerated() {
                if url == track.previewUrl! {
                    return index
                }
            }
        }
        return nil
    }
}



// MARK: - NSURLSessionDelegate

extension SearchViewController: URLSessionDelegate {

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                appDelegate.backgroundSessionCompletionHandler = nil
                DispatchQueue.main.async {
                    completionHandler()
                }
            }
        }
    }
}

// MARK: - NSURLSessionDownloadDelegate

extension SearchViewController: URLSessionDownloadDelegate {
    
    

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // 1
        if let originalURL = downloadTask.originalRequest?.url?.absoluteString,
            let destinationURL = localFilePathForUrl(previewUrl: originalURL) {

            print(destinationURL)

            // 2
            let fileManager = FileManager.default
            do {
                try fileManager.removeItem(at: destinationURL)
            } catch {
                // Non-fatal: file probably doesn't exist
            }
            do {
                try fileManager.copyItem(at: location, to: destinationURL)
            } catch let error as NSError {
                print("Could not copy file to disk: \(error.localizedDescription)")
            }
        }

        // 3
        if let url = downloadTask.originalRequest?.url?.absoluteString {
            activeDownloads[url] = nil
            // 4
            if let trackIndex = trackIndexForDownloadTask(downloadTask: downloadTask) {
                DispatchQueue.main.async {
                    self.tableView.reloadRows(at: [IndexPath(row: trackIndex, section: 0)], with: .none)
                }
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {

        // 1
        if let downloadUrl = downloadTask.originalRequest?.url?.absoluteString,
            let download = activeDownloads[downloadUrl] {
            // 2
            download.progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
            // 3
            let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: ByteCountFormatter.CountStyle.binary)
            // 4
            if let trackIndex = trackIndexForDownloadTask(downloadTask: downloadTask), let trackCell = tableView.cellForRow(at: IndexPath(row: trackIndex, section: 0)) as? TrackCell {
                DispatchQueue.main.async {
                    trackCell.progressView.progress = download.progress
                    trackCell.progressLabel.text =  String(format: "%.1f%% of %@",  download.progress * 100, totalSize)
                }
            }
        }
    }
}

// MARK: - UISearchBarDelegate

extension SearchViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyboard()

        if !searchBar.text!.isEmpty {
            // 1
            if dataTask != nil {
                dataTask?.cancel()
            }
            // 2
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            // 3
            let expectedCharSet = CharacterSet.urlQueryAllowed
            if let searchTerm = searchBar.text!.addingPercentEncoding(withAllowedCharacters: expectedCharSet) {

                print(searchTerm)

                // 4
                let url = URL(string: "https://wwwsecure.us.lego.com//service/biservice/search?fromIndex=0&locale=en-US&onlyAlternatives=false&prefixText=\(searchTerm)")

                

                // 5
                dataTask = defaultSession.dataTask(with: url!) {
                    data, response, error in
                    // 6
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                    // 7
                    if let error = error {
                        print(error.localizedDescription)
                    } else if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 200 {
                            self.updateSearchResults(data: data)
                        }
                    }
                }

                // 8
                dataTask?.resume()
            }
        }
    }

    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        view.addGestureRecognizer(tapRecognizer)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        view.removeGestureRecognizer(tapRecognizer)
    }
}

// MARK: TrackCellDelegate

extension SearchViewController: TrackCellDelegate {
    func pauseTapped(cell: TrackCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let track = searchResults[indexPath.row]
            pauseDownload(track: track)
            tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .none)
        }
    }

    func resumeTapped(cell: TrackCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let track = searchResults[indexPath.row]
            resumeDownload(track: track)
            tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .none)
        }
    }

    func cancelTapped(cell: TrackCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let track = searchResults[indexPath.row]
            cancelDownload(track: track)
            tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .none)
        }
    }

    func downloadTapped(cell: TrackCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let track = searchResults[indexPath.row]
            startDownload(track: track)
            tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .none)
        }
    }
}

// MARK: UITableViewDataSource

extension SearchViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath) as! TrackCell

        // Delegate cell button tap events to this view controller
        cell.delegate = self
        
        print("cell.productImage.frame.height ==> ",cell.productImage.frame.height)
        print("cell.productImage.frame.width ==> ",cell.productImage.frame.width)
        let track = searchResults[indexPath.row]

        // Configure title and productid labels
        cell.titleLabel.text = track.name
        cell.productidLabel.text = track.productid
        
        let productImageUrl = URL(string: track.imageUrl!)
        let imageData = NSData(contentsOf: productImageUrl!)
        //cell.productImage.image = ResizeImage(image: UIImage(data: imageData as! Data)!)
        cell.productImage.image = UIImage(data: imageData as! Data)
        //cell.productImage.contentMode = .scaleAspectFill
        print("Image Height ==> ",cell.productImage.image?.size.height)
        print("Image Width ==> ",cell.productImage.image?.size.width)
        print("UIImageView Height ==> ", cell.productImage.frame.height)
        print("UIImageView Width ==> ", cell.productImage.frame.width)
        
        var showDownloadControls = false
        if let download = activeDownloads[track.previewUrl!] {
            showDownloadControls = true

            cell.progressView.progress = download.progress
            cell.progressLabel.text = (download.isDownloading) ? "Downloading..." : "Paused"

            let title = (download.isDownloading) ? "Pause" : "Resume"
            cell.pauseButton.setTitle(title, for: UIControlState.normal)
        }
        cell.progressView.isHidden = !showDownloadControls
        cell.progressLabel.isHidden = !showDownloadControls

        // If the track is already downloaded, enable cell selection and hide the Download button
        let downloaded = localFileExistsForTrack(track: track)
        cell.selectionStyle = downloaded ? UITableViewCellSelectionStyle.gray : UITableViewCellSelectionStyle.none
        cell.downloadButton.isHidden = downloaded || showDownloadControls

        cell.pauseButton.isHidden = !showDownloadControls
        cell.cancelButton.isHidden = !showDownloadControls

        return cell
    }

    
    // resize Image
    //https://iosdevcenters.blogspot.com/2015/12/how-to-resize-image-in-swift-in-ios.html
    func ResizeImage(image: UIImage) -> UIImage {
        let size = image.size
        
        let widthRatio  = 80/image.size.width
        let heightRatio = 80/image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width*heightRatio, height: size.height*heightRatio)
        } else {
            newSize = CGSize(width: size.width*widthRatio, height: size.height*widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x:0, y:0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }

}

// MARK: UITableViewDelegate

extension SearchViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 62.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let track = searchResults[indexPath.row]

        if localFileExistsForTrack(track: track) {
            //playDownload(track: track)
            showDownload(track: track)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}

func correct(requestData data: Data?) -> Data? {
    guard let data = data else {
        return nil
    }
    if NSKeyedUnarchiver.unarchiveObject(with: data) != nil {
        return data
    }
    guard let archive = (try? PropertyListSerialization.propertyList(from: data, options: [.mutableContainersAndLeaves], format: nil)) as? NSMutableDictionary else {
        return nil
    }
    // Rectify weird __nsurlrequest_proto_props objects to $number pattern
    var k = 0
    while ((archive["$objects"] as? NSArray)?[1] as? NSDictionary)?.object(forKey: "$\(k)") != nil {
        k += 1
    }
    var i = 0
    while ((archive["$objects"] as? NSArray)?[1] as? NSDictionary)?.object(forKey: "__nsurlrequest_proto_prop_obj_\(i)") != nil {
        let arr = archive["$objects"] as? NSMutableArray
        if let dic = arr?[1] as? NSMutableDictionary, let obj = dic["__nsurlrequest_proto_prop_obj_\(i)"] {
            dic.setObject(obj, forKey: "$\(i + k)" as NSString)
            dic.removeObject(forKey: "__nsurlrequest_proto_prop_obj_\(i)")
            arr?[1] = dic
            archive["$objects"] = arr
        }
        i += 1
    }
    if ((archive["$objects"] as? NSArray)?[1] as? NSDictionary)?.object(forKey: "__nsurlrequest_proto_props") != nil {
        let arr = archive["$objects"] as? NSMutableArray
        if let dic = arr?[1] as? NSMutableDictionary, let obj = dic["__nsurlrequest_proto_props"] {
            dic.setObject(obj, forKey: "$\(i + k)" as NSString)
            dic.removeObject(forKey: "__nsurlrequest_proto_props")
            arr?[1] = dic
            archive["$objects"] = arr
        }
    }

    // Rectify weird "NSKeyedArchiveRootObjectKey" top key to NSKeyedArchiveRootObjectKey = "root"
    if let obj = (archive["$top"] as? NSMutableDictionary)?.object(forKey: "NSKeyedArchiveRootObjectKey") as AnyObject? {
        (archive["$top"] as? NSMutableDictionary)?.setObject(obj, forKey: NSKeyedArchiveRootObjectKey as NSString)
        (archive["$top"] as? NSMutableDictionary)?.removeObject(forKey: "NSKeyedArchiveRootObjectKey")
    }
    // Reencode archived object
    let result = try? PropertyListSerialization.data(fromPropertyList: archive, format: PropertyListSerialization.PropertyListFormat.binary, options: PropertyListSerialization.WriteOptions())
    return result
}

func getResumeDictionary(_ data: Data) -> NSMutableDictionary? {
    // In beta versions, resumeData is NSKeyedArchive encoded instead of plist
    var iresumeDictionary: NSMutableDictionary? = nil
    if #available(iOS 10.0, OSX 10.12, *) {
        var root : AnyObject? = nil
        let keyedUnarchiver = NSKeyedUnarchiver(forReadingWith: data)

        do {
            root = try keyedUnarchiver.decodeTopLevelObject(forKey: "NSKeyedArchiveRootObjectKey") ?? nil
            if root == nil {
                root = try keyedUnarchiver.decodeTopLevelObject(forKey: NSKeyedArchiveRootObjectKey)
            }
        } catch {}
        keyedUnarchiver.finishDecoding()
        iresumeDictionary = root as? NSMutableDictionary

    }

    if iresumeDictionary == nil {
        do {
            iresumeDictionary = try PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.ReadOptions(), format: nil) as? NSMutableDictionary;
        } catch {}
    }

    return iresumeDictionary
}

func correctResumeData(_ data: Data?) -> Data? {
    let kResumeCurrentRequest = "NSURLSessionResumeCurrentRequest"
    let kResumeOriginalRequest = "NSURLSessionResumeOriginalRequest"

    guard let data = data, let resumeDictionary = getResumeDictionary(data) else {
        return nil
    }

    resumeDictionary[kResumeCurrentRequest] = correct(requestData: resumeDictionary[kResumeCurrentRequest] as? Data)
    resumeDictionary[kResumeOriginalRequest] = correct(requestData: resumeDictionary[kResumeOriginalRequest] as? Data)
    
    let result = try? PropertyListSerialization.data(fromPropertyList: resumeDictionary, format: PropertyListSerialization.PropertyListFormat.xml, options: PropertyListSerialization.WriteOptions())
    return result
}


extension URLSession {
    func correctedDownloadTask(withResumeData resumeData: Data) -> URLSessionDownloadTask {
        let kResumeCurrentRequest = "NSURLSessionResumeCurrentRequest"
        let kResumeOriginalRequest = "NSURLSessionResumeOriginalRequest"
        
        let cData = correctResumeData(resumeData) ?? resumeData
        let task = self.downloadTask(withResumeData: cData)
        
        // a compensation for inability to set task requests in CFNetwork.
        // While you still get -[NSKeyedUnarchiver initForReadingWithData:]: data is NULL error,
        // this section will set them to real objects
        if let resumeDic = getResumeDictionary(cData) {
            if task.originalRequest == nil, let originalReqData = resumeDic[kResumeOriginalRequest] as? Data, let originalRequest = NSKeyedUnarchiver.unarchiveObject(with: originalReqData) as? NSURLRequest {
                task.setValue(originalRequest, forKey: "originalRequest")
            }
            if task.currentRequest == nil, let currentReqData = resumeDic[kResumeCurrentRequest] as? Data, let currentRequest = NSKeyedUnarchiver.unarchiveObject(with: currentReqData) as? NSURLRequest {
                task.setValue(currentRequest, forKey: "currentRequest")
            }
        }
        
        return task
    }
}

