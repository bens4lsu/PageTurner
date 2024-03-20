//
//  File.swift
//  
//
//  Created by Ben Schultz on 2024-03-20.
//

import Foundation

enum TestResult: String, Codable {
    case notTested = "Not Tested"
    case passed = "Passed"
    case contentChanged = "Content Changed"
    case urlError = "URL Error"
}

class MailerResult {
    let result: TestResult
    let page: Page
    
    init(result: TestResult, page: Page) {
        self.result = result
        self.page = page
    }
    
    var emailText: String {
        "Result of \"\(result.rawValue)\" found on \"\(page.pageDescription)\" at url \"\(page.url)\""
    }
}
