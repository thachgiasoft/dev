//
//  HLDataProvider.swift
//  MinkoPlayer
//
//  Created by Matthew Homer on 4/8/19.
//  Copyright © 2019 Matthew Homer. All rights reserved.
//

import UIKit

protocol HLDataProviderProtocol {
    func JSONDownloadCompleted(result: Any)
    func JSONDownloadFailed(error: String)
}


class HLDataProvider: NSObject {

//  singleton class
    static let sharedInstance = HLDataProvider()
    var session: URLSession?

    let timeoutLimit = 4.0
    let baseURL = "https://raw.seeotter.tv/api/index.php/appletv/"
    //let baseURL = "https://test.minko.int/api/index.php/appletv/"
//    let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
    let appName = "martha"
    let tempAppVer = "0.1.2.3"
    let count = 20
    let offset = 0
    let command = "app_videos_new"
    var requestVideosCommand: HLRequestVideosCommand?
    
//https://raw.seeotter.tv/api/index.php/appletv/martha/channel/2/0/20/0.5.3123
//https://raw.seeotter.tv/api/index.php/appletv/app_videos_new/martha/0/20/0.1.2.3

    func requestDataPost(delegate: HLDataProviderProtocol)  {
        let url = URL(string: baseURL + "\(command)/\(appName)/\(offset)/\(count)/" + tempAppVer)!

        let request = NSMutableURLRequest(url: url)
        let session = URLSession.shared
        request.httpMethod = "POST"

        let params = ["x-api-key":"9037af91-05b7-488f-8bef-2677d56558bf"] as Dictionary<String, String>

        request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            print("Response: \(String(describing: response))")})

        task.resume()
    }

    func requestData(delegate: HLDataProviderProtocol)  {
        let url = URL(string: baseURL + "\(command)/\(appName)/\(offset)/\(count)/" + tempAppVer)!

        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error == nil {
                if let dt = data {
         //           let str = String(data: dt, encoding: .utf8)
         //           print("data1: \(String(describing: str))")
                    
                    
                    do {
                        let decoder = JSONDecoder()
                        self.requestVideosCommand = try decoder.decode(HLRequestVideosCommand.self, from: dt     )
             //           print("requestVideosCommand:  \(self.requestVideosCommand).")
             //           print("requestVideosCommanddata:  \(self.requestVideosCommand!.data).")

                        DispatchQueue.main.async { [unowned self] in
                            delegate.JSONDownloadCompleted(result: self.requestVideosCommand as Any)
                        }

                }
                    catch {
                        print("Serious Error: no data.")
                        delegate.JSONDownloadFailed(error: "Serious Error: no data.")
                    }
                    
                }
            }
        }
        
        task.resume()
    }

    private override init()  {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutLimit
        session = URLSession(configuration: config)
    }

 }