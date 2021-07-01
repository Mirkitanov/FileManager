//
//  FileSystemObject.swift
//  FileManager
//
//  Created by Админ on 01.07.2021.
//

import Foundation

enum ContentType: Int {
    case up = 0
    case directory
    case file
}

struct FileSystemObject {
    var type: ContentType
    var name: String
    var url: URL
}
