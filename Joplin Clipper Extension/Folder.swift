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
}

struct FoldersResource: APIResource {
    typealias ModelType = Folder
    let methodPath = "/folders"
    let queryItems = [URLQueryItem(name: "as_tree", value: "1")]
}

