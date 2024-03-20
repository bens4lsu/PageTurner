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
            let crc = data.base64EncodedString().crc32()
            return crc
        }
        return nil
    }
}
