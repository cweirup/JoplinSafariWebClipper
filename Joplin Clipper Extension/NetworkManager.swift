//
//  NetworkManager.swift
//  Joplin Clipper Extension
//
//  Created by Christopher Weirup on 2020-03-21.
//  Copyright © 2020 Christopher Weirup. All rights reserved.
//

import Foundation

enum HttpMethod<Body> {
    case get
    case post(Body)
}

extension HttpMethod {
    var method: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        }
    }
}

struct Resource<A> {
    var urlRequest: URLRequest
    let parse: (Data) -> A?
}

extension Resource {
    func map<B>(_ transform: @escaping (A) -> B) -> Resource<B> {
    return Resource<B>(urlRequest: urlRequest) { self.parse($0).map(transform) }
    }
}

extension Resource where A: Decodable {
    init(get url: URL) {
        self.urlRequest = URLRequest(url: url)
        self.parse = { data in
            try? JSONDecoder().decode(A.self, from: data)
        }
    }
    
    init<Body: Encodable>(url:URL, method: HttpMethod<Body>) {
        var components = URLComponents(string: url.absoluteString)
        let queryItem = [URLQueryItem(name: "token", value: "fd6eb4000ddcc2b5ddf3de0606ecc058faf1702e9df563f0ae53444b654a9acbb9aceee2f0505e0f75c87269af7820e5350d0d582a3fcaa6c05147df5b358fe6")]
        components?.queryItems = queryItem
        
        urlRequest = URLRequest(url: (components?.url!)!)
        //urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.method
        switch method {
        case .get: ()
        case .post(let body):
            self.urlRequest.httpBody = try! JSONEncoder().encode(body)
        }
        self.parse = { data in
            try? JSONDecoder().decode(A.self, from: data)
        }
    }
    
    init<Body: Encodable>(url:URL, params: [String: Any], method: HttpMethod<Body>) {
        var components = URLComponents(string: url.absoluteString)
        //let queryItem = [URLQueryItem(name: "token", value: "fd6eb4000ddcc2b5ddf3de0606ecc058faf1702e9df563f0ae53444b654a9acbb9aceee2f0505e0f75c87269af7820e5350d0d582a3fcaa6c05147df5b358fe6")]
        
        NSLog("BLEH - Resource.init params = \(params)")
        if (!params.isEmpty) {
            components?.queryItems = params.map { (key, value) in
                URLQueryItem(name: key, value: (value as! String))
            }
        }
        
        urlRequest = URLRequest(url: (components?.url!)!)
        
        urlRequest.httpMethod = method.method
        switch method {
        case .get: ()
        case .post(let body):
            self.urlRequest.httpBody = try! JSONEncoder().encode(body)
        }
        self.parse = { data in
            try? JSONDecoder().decode(A.self, from: data)
        }
    }
}

extension URLSession {
    func load<A>(_ resource: Resource<A>, completion: @escaping (A?) -> ()) {
        dataTask(with: resource.urlRequest) { data, _, _ in
            completion(data.flatMap(resource.parse))
        }.resume()
    }
}


