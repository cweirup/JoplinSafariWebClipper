//
//  Note.swift
//  Joplin Clipper Extension
//
//  Created by Christopher Weirup on 2020-03-13.
//  Copyright © 2020 Christopher Weirup. All rights reserved.
//

import Foundation

struct Note: Codable {
    let id: String?
    let base_url: String?
    let parent_id: String?
    let title: String?
    let url: String?
    let body: String?
}

extension Note {
    init(title: String, url: String) {
        self.title = title
        self.url = url
        self.id = ""
        self.base_url = ""
        self.parent_id = ""
        self.body = ""
    }

    init(title: String, url: String, parent: String) {
        self.title = title
        self.url = url
        self.parent_id = parent
        self.id = ""
        self.base_url = ""
        self.body = ""
    }
}
