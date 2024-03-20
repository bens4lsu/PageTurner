//
//  File.swift
//  
//
//  Created by Ben Schultz on 2023-10-06.
//

import Foundation
import CryptoSwift

extension String {
    func urlToCrc() async throws -> String? {
        if let url = URL(string: self),
            let (data, _) = try? await URLSession.shared.data(from: url)
        {
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
