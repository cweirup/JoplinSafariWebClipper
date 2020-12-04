//
//  Network.swift
//  Joplin Clipper Extension
//
//  Created by Christopher Weirup on 2020-04-09.
//  Copyright © 2020 Christopher Weirup. All rights reserved.
//

import Foundation

protocol APIResource {
    associatedtype ModelType: Decodable
    var methodPath: String { get }
    var queryItems: [URLQueryItem] { get }
}

extension APIResource{
    var queryItems: [URLQueryItem] {
         return [URLQueryItem(name: "as_tree", value: "1")]
    }
}

extension APIResource {
    var url: URL {
        var components = URLComponents(string: "http://localhost:41184")!
        components.path = methodPath
        components.queryItems = queryItems
        return components.url!
    }
}

class Network {
    private static func config() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 60
        return config
    }

    private static func session() -> URLSession {
        let session = URLSession(configuration: config())
        return session
    }

    private static func request(url: String, params: [String: Any]) -> URLRequest {
        var request = URLRequest(url: URL(string: url)!)
        // For now, going to comment this out. Looks like with iOS 13 and macOS 15,
        // using httpBody is not allowed for GET requests. You would need to append
        // any parameters as a query string to the URL. For now I don't need to
        // do any special parameters.
        // MORE INFO: https://stackoverflow.com/questions/56955595/1103-error-domain-nsurlerrordomain-code-1103-resource-exceeds-maximum-size-i
        // POTENTIAL FIX: https://stackoverflow.com/questions/27723912/swift-get-request-with-parameters
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
//        } catch let error {
//            print(error.localizedDescription)
//        }
        request.timeoutInterval = 60
        return request
    }

    private static func request<T: Encodable>(url: URL, object: T) -> URLRequest {
        var request = URLRequest(url: url)
        do {
            request.httpBody = try JSONEncoder().encode(object)
        } catch let error {
            print(error.localizedDescription)
        }
        request.timeoutInterval = 60
        return request
    }
    
    static func post( url: String, params: [String: Any] = [:], callback: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        var request: URLRequest = self.request(url: url, params: params)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        let task = session().dataTask(with: request, completionHandler: { (data, response, error) in
            DispatchQueue.main.async {
                callback(data, error)
            }
        })
        task.resume()
    }
    
   static func post<T: Encodable>( url: URL, object: T, callback: @escaping (_ data: Data?, _ error: Error?) -> Void) {
       var request: URLRequest = self.request(url: url, object: object)
       request.httpMethod = "POST"
       let task = session().dataTask(with: request, completionHandler: { (data, response, error) in
           DispatchQueue.main.async {
               callback(data, error)
           }
       })
       task.resume()
   }
    
    static func get( url: String, params: [String: Any] = [:], callback: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        var request: URLRequest = self.request(url: url, params: params)
        request.httpMethod = "GET"
        let task = session().dataTask(with: request, completionHandler: { (data, response, error) in
            DispatchQueue.main.async {
                callback(data, error)
            }
        })
        task.resume()
    }
}
