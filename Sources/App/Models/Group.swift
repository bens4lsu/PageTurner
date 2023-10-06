//
//  File.swift
//  
//
//  Created by Ben Schultz on 2023-10-06.
//

import Foundation
import Fluent
import Vapor

enum GroupAction: Int, Codable {
    case autoTest = 1
    case generateOnPrompt = 2
}

final class Group: Model, Content {
    typealias IDValue = UUID
    static var schema = "TestGroups"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "GroupName")
    var groupName: String
    
    @Field(key: "GroupAction")
    var groupAction: GroupAction
    
    required init() {
        
    }
}
