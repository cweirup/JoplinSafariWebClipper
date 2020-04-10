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
}

extension APIResource {
    var url: URL {
        var components = URLComponents(string: "http://localhost:41184")!
        components.path = methodPath
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
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        } catch let error {
            print(error.localizedDescription)
        }
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
