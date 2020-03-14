//
//  Note.swift
//  Joplin Clipper Extension
//
//  Created by Christopher Weirup on 2020-03-13.
//  Copyright © 2020 Christopher Weirup. All rights reserved.
//

import Foundation

struct Note: Codable {
    let base_url: String
    let title: String
    let url: String
    let body: String
}

extension Note {
    init(title: String, url: String) {
        self.title = title
        self.url = url
        self.base_url = ""
        self.body = ""
    }
    
    func saveToJoplin() {
        
    }
}
