//
//  Folder.swift
//  Joplin Clipper Extension
//
//  Created by Christopher Weirup on 2020-03-21.
//  Copyright © 2020 Christopher Weirup. All rights reserved.
//

import Foundation

struct Folder: Codable {
    let id: String?
    let title: String?
    let created_time: Int?
    let updated_time: Int?
    let user_created_time: Int?
    let user_updated_time: Int?
    let encryption_cipher_text: String?
    let encryption_applied: Int?
    let parent_id: String?
    let children: [Folder]?
    let is_shared: Int?
}

struct FoldersResource: APIResource {
    typealias ModelType = Folder
    let methodPath = "/folders"
}

