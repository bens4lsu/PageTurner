//
//  File.swift
//  
//
//  Created by Ben Schultz on 2023-10-06.
//

import Foundation

extension String {
    func urlToBase64Data() async throws -> String? {
        if let url = URL(string: self),
            let (data, _) = try? await URLSession.shared.data(from: url)
        {
            return data.base64EncodedString()
        }
        return nil
    }
}
