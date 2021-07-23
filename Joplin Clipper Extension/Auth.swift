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

struct AuthAcceptedResponse: Decodable {
    var status: String?
    var token: String?
}

struct AuthRejectedResponse: Decodable {
    var status: String?
}

struct AuthWaitingResponse: Decodable {
    var status: String?
}

struct ErrorResponse: Decodable {
    var error: String
}

enum AuthResponse: Decodable {
    case accepted(AuthAcceptedResponse)
    case waiting(AuthWaitingResponse)
    case rejected(AuthRejectedResponse)
    case failure(ErrorResponse)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            let authData = try container.decode(AuthAcceptedResponse.self)
            switch authData.status {
            case "accepted":
                self = .accepted(authData)
            case "waiting":
                self = .waiting(AuthWaitingResponse(status: authData.status))
            default:
                self = .rejected(AuthRejectedResponse(status: authData.status))
            }
        } catch DecodingError.typeMismatch {
            let errorData = try container.decode(ErrorResponse.self)
            self = .failure(errorData)
        }
    }
}
