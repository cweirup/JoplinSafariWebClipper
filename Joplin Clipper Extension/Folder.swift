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
    let parent_id: String?
    let title: String?
    let type_: Int?
    let note_count: Int?
    let children: [Folder]?
    //let created_time: Int?
    //let updated_time: Int?
    //let user_created_time: Int?
    //let user_updated_time: Int?
    //let encryption_cipher_text: String?
    //let encryption_applied: Int?
    //let is_shared: Int?
}

struct FoldersResource: APIResource {
    typealias ModelType = Folder
    let methodPath = "/folders"
    let queryItems = [URLQueryItem(name: "as_tree", value: "1")]
}

