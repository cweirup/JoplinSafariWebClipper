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
    let parent_id: String?
    let title: String?
}

struct TagsResource: APIResource {
    typealias ModelType = Tag
    let methodPath = "/tags"
}
