//
//  File.swift
//  
//
//  Created by Ben Schultz on 2024-03-20.
//

import Foundation
import Vapor
import NIOSSL


class ConfigurationSettings: Decodable {
    
    struct Database: Decodable {
        let hostname: String
        let port: Int
        let username: String
        let password: String
        let database: String
        let certificateVerificationString: String
        let mailDb: String
    }
    
    struct Host: Decodable, Encodable {
        let listenOnPort: Int
        let proto: String
        let server: String
    }
    
    struct Email: Decodable {
        let fromName: String
        let fromAddress: String
        let enableEmailSend: Bool
        let toAddresses: [String]
    }
    
    let database: ConfigurationSettings.Database
    let logLevel: String
    let host: Host
    let email: Email
    
    var certificateVerification: CertificateVerification {
        if database.certificateVerificationString == "noHostnameVerification" {
            return .noHostnameVerification
        }
        else if database.certificateVerificationString == "fullVerification" {
            return .fullVerification
        }
        return .none
    }
    
    var loggerLogLevel: Logger.Level {
        Logger.Level(rawValue: logLevel) ?? .error
    }
    
    var baseString: String {
        var portStr = ":\(self.host.listenOnPort)"
        if self.host.server != "localhost" && self.host.server != "127.0.0.1" {
            portStr = ""
        }
        return  "\(self.host.proto)://\(self.host.server)\(portStr)"
    }

    
    init() {
        let path = DirectoryConfiguration.detect().resourcesDirectory
        let url = URL(fileURLWithPath: path).appendingPathComponent("Config.json")
        do {
            let data = try Data(contentsOf: url)
            let decoder = try JSONDecoder().decode(ConfigurationSettings.self, from: data)
            self.database = decoder.database
            self.logLevel = decoder.logLevel
            self.host = decoder.host
            self.email = decoder.email
        }
        catch {
            print ("Could not initialize app from Config.json. \n \(error)")
            exit(0)
        }
    }
}

