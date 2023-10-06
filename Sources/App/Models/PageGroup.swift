//
//  File.swift
//  
//
//  Created by Ben Schultz on 2023-10-06.
//

import Foundation
import Vapor
import Fluent

final class PageGroup: Model, Content {
    typealias IDValue = UUID
    static var schema = "TestPageGroups"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "GroupId")
    var groupId: UUID
    
    @Field(key: "PageId")
    var pageId: Int
    
    required init() {
        
    }
}
