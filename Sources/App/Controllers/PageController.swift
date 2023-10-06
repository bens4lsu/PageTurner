//
//  File.swift
//  
//
//  Created by Ben Schultz on 2023-10-06.
//

import Foundation
import Vapor
import Fluent

extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
}

class PageController {
    
    static func loadPage(on db: Database, pageName: String, url: String) async throws {
        let page = try await Page(on: db, pageDescription: pageName, url: url)
        try await page.save(on: db)
    }
    
    static func test(on db: Database) async throws {
        let pagesToTest = try await Page.query(on: db)
            .filter(\.$isCurrent == true)
            .join(PageGroup.self, on: \Page.$pageId == \PageGroup.$pageId)
            .join(Group.self, on: \PageGroup.$groupId == \Group.$id)
            .filter(Group.self, \Group.$groupAction == .autoTest)
            .all()
        
        for page in pagesToTest {
            var testResult = TestResult.passed
            if let currentImage = try await page.url.urlToBase64Data() {
                if currentImage != page.imageBase64 {
                    testResult = .contentChanged
                }
            }
            else {
                testResult = .urlError
            }
            try await TestLog(pageId: page.pageId, version: page.version, testResult: testResult).save(on: db)
        }
    }
    
    static func loadPages(on db: Database) async throws {
        // HTML reports
        var loadThesePages:[(String, String)] = [
             ("C&J Expansion Master Red", "https://passports.candjinnovations.com/report/MjNkYmIyMGZiMTNl7H8ahl38OBbVhOR7DA4RPuQ%3D/MjNkYmIyMGZiMTNl6qFADZ%2F9EyNkJSRO%2BlSzzdHUe9Y%3D"),
             ("C&J Expansion Master Yellow", "https://passports.candjinnovations.com/report/MjNkYmIyMGZiMTNl7H8ahl38OBbVhOR7DA4RPuQ%3D/MjNkYmIyMGZiMTNl6qFADgZWbFGwcojLwZyyvGR6Ir0%3D"),
             
             
             ]
        
        // PDF reports
        loadThesePages += [
            ("C&J Expansion Master Red PDF", "https://passports.candjinnovations.com/pdfresult/report/MjNkYmIyMGZiMTNl7H8ahl38OBbVhOR7DA4RPuQ%3D/MjNkYmIyMGZiMTNl6qFADZ%2F9EyNkJSRO%2BlSzzdHUe9Y%3D"),
            ("C&J Expansion Master Yellow PDF", "https://passports.candjinnovations.com/pdfresult/report/MjNkYmIyMGZiMTNl7H8ahl38OBbVhOR7DA4RPuQ%3D/MjNkYmIyMGZiMTNl6qFADgZWbFGwcojLwZyyvGR6Ir0%3D"),
        
    
        
        ]
        
        for (pageName, url) in loadThesePages {
            try await loadPage(on: db, pageName: pageName, url: url)
        }
    }
    
}
