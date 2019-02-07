//
//  Flickr.swift
//  virtualtourist
//
//  Created by carloshenrique.carmo on 06/02/19.
//  Copyright © 2019 carloshpdoc. All rights reserved.
//

import Foundation
import MapKit

class Flickr: NSObject {
    
    var session = URLSession.shared
    var pageNumber = 0
    
    override init() {
        super.init()
        pageNumber += 1
    }


    func getPhotos(coordinate: CLLocationCoordinate2D, completionHandler: @escaping (_ sucess: Bool, _ photos: [AnyObject?], _ error: NSError)-> Void)-> Void {

        let parameters: [String:String] = [
            "api_key": "ea11b58e81bc8a3b25ec92f76fb786ba",
            "method": "flickr.photos.search",
            "format": "json",
            "nojsoncallback": "1",
            "lat": "\(coordinate.latitude)",
            "lon": "\(coordinate.longitude)",
            "per_page": "20",
            "page": "\(pageNumber)",
        ]
        
        print("parameters ===== \(parameters)")

        // Create session and request
        let session = URLSession.shared
        let request = createURLRequest(method: "GET", path: "/services/rest", parameters: parameters)
        
        // Create network request
        let task = session.dataTask(with: request) { data, response, error in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandler(false, [], NSError(domain: "getPhotos", code: 1, userInfo: userInfo))
            }

            
            /* GUARD: Was there an error? */
            guard error == nil else {
                sendError("There was an error with your request: \(error!)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }

            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }

            // Parse the data
            var parsedData: AnyObject! = nil
            
            do {
                parsedData =  try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
            }
            catch {
                 sendError("could not parse json parse")
                return
            }
            
            guard let photos = parsedData?["photos"] as? AnyObject,
                let photo = photos["photo"] as? [AnyObject]  else {
                    sendError("no photos attribute present")
                    return
            }
            
            // Photos URL
            let photos_url = photo.map(){ photo in
                "https://farm\(photo["farm"]!!).staticflickr.com/\(photo["server"]!!)/\(photo["id"]!!)_\(photo["secret"]!!)_s.jpg"
            }
            
            let userInfo = [NSLocalizedDescriptionKey : error]
            completionHandler(true, photos_url as [AnyObject], NSError(domain: "getPhotos", code: 1, userInfo: userInfo as [String : Any]))
        }
        task.resume()
    }
    
    // MARK: Helpers
    
    func createURLRequest(method: String , path: String , parameters: [String:String]) -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.flickr.com"
        components.path = path
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        return request
    }
    
    // MARK: Shared Instance
   static let shared = Flickr()
}
