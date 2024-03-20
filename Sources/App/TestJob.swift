//
//  File.swift
//  
//
//  Created by Ben Schultz on 2023-10-06.
//

import Foundation
import Vapor
import Fluent
import QueuesFluentDriver
import Queues

//extension Sequence {
//    func asyncMap<T>(
//        _ transform: (Element) async throws -> T
//    ) async rethrows -> [T] {
//        var values = [T]()
//
//        for element in self {
//            try await values.append(transform(element))
//        }
//
//        return values
//    }
//}

class TestJob: AsyncScheduledJob {
    
    var settings: ConfigurationSettings
    var logger: Logger
    
    init(settings: ConfigurationSettings, logger: Logger) {
        self.settings = settings
        self.logger = logger
    }
    
    func run(context: Queues.QueueContext) async throws {
        let results = try await self.test(on: context.application.db)
            .filter {$0.result == .contentChanged || $0.result == .urlError}
        let _ = try await report(results: results, on: context.application.db(.emailDb))
    }
    
    private func test(on db: Database) async throws -> [MailerResult] {
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
                        self.logger.debug("Page \(page.pageDescription)\nURL\(page.url)\nResult = Not Tested\n")
                        return  MailerResult(result: .notTested, page: page)
                    }
                }
                
                else {
                    group.addTask {
                        guard let currentCrc = try await page.url.urlToCrc() else {
                            self.logger.notice("Page \(page.pageDescription)\nURL \(page.url)\nResult = URL Error\n")
                            return MailerResult(result: .urlError, page: page)
                        }
                        if page.crc != currentCrc {
                            self.logger.notice("Page \(page.pageDescription)\nURL\(page.url)\nResult = Content Changed\n")
                            return MailerResult(result: .contentChanged, page: page)
                        }
                        else {
                            self.logger.debug("Page \(page.pageDescription)\nURL\(page.url)\nResult = Passed\n")
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
    
    private func report(results: [MailerResult], on db: Database) async throws {
        return try await withThrowingTaskGroup(of: Void.self) { group in
            for result in results {
                for address in settings.email.toAddresses {
                    let mail = MailQueue(emailAddressFrom: settings.email.fromAddress, emailAddressTo: address, subject: "Attention Required: Automated Page Test Failure", body: result.emailText)
                    group.addTask {
                        let _ = try await mail.save(on: db)
                    }
                }
            }
            try await group.waitForAll()
        }
    }
        
}
