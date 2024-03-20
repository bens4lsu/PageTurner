//
//  File.swift
//  
//
//  Created by Ben Schultz on 2024-03-20.
//

import Foundation

enum TestResult: Int, Codable {
    case notTested = 999
    case passed = 0
    case contentChanged = -1
    case urlError = -2
}

class MailerResult {
    let result: TestResult
    let page: Page
    
    init(result: TestResult, page: Page) {
        self.result = result
        self.page = page
    }
}
