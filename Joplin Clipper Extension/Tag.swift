//
//  Tag.swift
//  Joplin Clipper Extension
//
//  Created by Christopher Weirup on 2020-04-06.
//  Copyright © 2020 Christopher Weirup. All rights reserved.
//

import Foundation

struct Tag: Codable {
    let id: String?
    let title: String?
    let created_time: Int?
    let updated_time: Int?
    let user_created_time: Int?
    let user_updated_time: Int?
    let encryption_cipher_text: String?
    let encryption_applied: Int?
    let is_shared: Int?
}

struct TagsResource: APIResource {
    typealias ModelType = Tag
    let methodPath = "/tags"
}
