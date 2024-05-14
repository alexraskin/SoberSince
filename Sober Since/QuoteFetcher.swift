//
//  QuoteFetcher.swift
//  Sober Since
//
//  Created by Alex Raskin on 5/13/24.
//

import Foundation
import SwiftUI
import Combine

class QuoteFetcher: ObservableObject {
    @Published var quote: String = "Loading quote..."
    @Published var fetchError: Bool = false

    func fetchQuote(completion: ((String?) -> Void)? = nil) {
        guard let url = URL(string: "https://api.quotable.io/random") else {
            completion?(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(QuoteResponse.self, from: data) {
                    DispatchQueue.main.async {
                        let quoteText = "\(decodedResponse.content) — \(decodedResponse.author)"
                        self.quote = quoteText
                        self.fetchError = false
                        completion?(quoteText)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.fetchError = true
                        completion?(nil)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.fetchError = true
                    completion?(nil)
                }
            }
        }.resume()
    }
}

struct QuoteResponse: Codable {
    var content: String
    var author: String
}
