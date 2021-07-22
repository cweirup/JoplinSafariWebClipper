//
//  Auth.swift
//  Joplin Clipper Extension
//
//  Created by Christopher Weirup on 2021-07-21.
//  Copyright © 2021 Christopher Weirup. All rights reserved.
//

import Foundation

struct AuthToken: Decodable {
    var auth_token: String?
}

struct AuthSuccessResponse: Decodable {
    var status: String?
    var token: String?
}

struct ErrorResponse: Decodable {
    var error: String
}

enum AuthResponse: Decodable {
    case success(AuthSuccessResponse)
    case failure(ErrorResponse)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            let authData = try container.decode(AuthSuccessResponse.self)
            self = .success(authData)
        } catch DecodingError.typeMismatch {
            let errorData = try container.decode(ErrorResponse.self)
            self = .failure(errorData)
        }
    }
}
