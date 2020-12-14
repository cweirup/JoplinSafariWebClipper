//
//  Response.swift
//  Joplin Clipper Extension
//
//  Created by Christopher Weirup on 2020-12-04.
//  Copyright © 2020 Christopher Weirup. All rights reserved.
//

import Foundation

struct Response: Codable {
    var items: [Tag]?
    var has_more: Bool?
}
