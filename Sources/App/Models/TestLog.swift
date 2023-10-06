//
//  File.swift
//  
//
//  Created by Ben Schultz on 2023-10-06.
//

import Foundation
import Vapor
import Fluent

enum TestResult: Int, Codable {
    case passed = 0
    case contentChanged = -1
    case urlError = -2
}


final class TestLog: Model, Content {
    typealias IDValue = UUID
    static var schema = "TestLog"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "PageId")
    var pageId: Int
    
    @Field(key: "Version")
    var version: Int
    
    @Field(key: "TestDateTime")
    var testDateTime: Date
    
    @Field(key: "TestResult")
    var testResult: TestResult
    
    required init() {
        
    }
    
    init(pageId: Int, version: Int, testResult: TestResult) {
        self.pageId = pageId
        self.version = version
        self.testDateTime = Date()
        self.testResult = testResult
    }
}
