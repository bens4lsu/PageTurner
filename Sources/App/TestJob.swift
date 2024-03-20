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
import CryptoSwift

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
        let results = try await self.test(on: context)
        //    .filter {$0.result == .contentChanged || $0.result == .urlError}
        let _ = try await report(results: results, on: context.application.db(.emailDb))
    }
    
    private func test(on context: Queues.QueueContext) async throws -> [MailerResult] {
        let pagesToTest = try await Page.query(on: context.application.db)
            .filter(\.$isCurrent == true)
            .all()
        
        return try await withThrowingTaskGroup(of: MailerResult.self) { group in
            
            for page in pagesToTest {
                
                if page.crc == nil || page.crc == "" {
                    group.addTask {
                        page.crc = try await self.crc(context.application, url: page.url)
                        page.version = page.version + 1
                        try await page.save(on: context.application.db)
                        self.logger.debug("Page \(page.pageDescription)\nURL\(page.url)\nResult = Not Tested\n")
                        return  MailerResult(result: .notTested, page: page)
                    }
                }
                
                else {
                    group.addTask {
                        guard let currentCrc = try await self.crc(context.application, url: page.url) else {
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
    
    private func crc(_ app: Application, url: String) async throws -> String? {
        let eventLoopFuture = app.http.client.shared.get(url: url)
        var response = try await eventLoopFuture.get()
        
        if let bytes = response.body?.readableBytes,
           let data = response.body?.readData(length: bytes) {
        
            let string = String(data: data, encoding: .utf8) ?? ""
            
            // have to remove the instance thing from the Q&A, because it's different every time
            let regexForInstanceOnPassportQA = try Regex("<input type=\"text\" name=\"instance\" id=\"instance\" value=\".+\">")
            let encoded = string.replacing(regexForInstanceOnPassportQA, with: "").base64String()
            
            let crc = encoded.crc32()
            return crc
        }
        return nil
    }
        
}
