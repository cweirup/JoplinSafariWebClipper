//
//  Note.swift
//  Joplin Clipper Extension
//
//  Created by Christopher Weirup on 2020-03-13.
//  Copyright © 2020 Christopher Weirup. All rights reserved.
//

import Foundation

struct Note: Codable {
    var id: String?
    var base_url: String?
    var parent_id: String?
    var title: String?
    var url: String?
    var body: String?
    var body_html: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case base_url
        case parent_id
        case title
        case url = "source_url"
        case body
        case body_html
    }
}

extension Note {
    init(title: String, url: String) {
        self.title = title
        self.url = url
        self.id = ""
        self.base_url = ""
        self.parent_id = ""
        self.body = ""
        self.body_html = ""
    }

    init(title: String, url: String, parent: String) {
        self.title = title
        self.url = url
        self.parent_id = parent
        self.id = ""
        self.base_url = ""
        self.body = ""
        self.body_html = ""
    }
}
