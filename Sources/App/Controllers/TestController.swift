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

class TestController {
    
    static func test(on db: Database) async throws -> [MailerResult] {
        let pagesToTest = try await Page.query(on: db)
            .filter(\.$isCurrent == true)
            .all()
        
        return try await withThrowingTaskGroup(of: MailerResult.self) { group in
            
            for page in pagesToTest {
                if page.crc == nil || page.crc == "" {
                    group.addTask {
                        page.crc = try await page.url.urlToCrc()
                        page.version = page.version + 1
                        try await page.save(on: db)
                        return  MailerResult(result: .notTested, page: page)
                    }
                }
                
                else {
                    group.addTask {
                        guard let currentCrc = try await page.url.urlToCrc() else {
                            return MailerResult(result: .urlError, page: page)
                        }
                        if page.crc != currentCrc {
                            return MailerResult(result: .contentChanged, page: page)
                        }
                        else {
                            return MailerResult(result: .passed, page: page)
                        }
                    }
                }
            }
                
            var results = [MailerResult]()
            for try await value in group {
                results.append(value)
            }
            return results
            
        }
    }
    
    static func report(on db: Database) async throws {
        
    }
        
}
