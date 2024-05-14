//
//  QuoteFetcher.swift
//  Sober Since
//
//  Created by Alex Raskin on 5/13/24.
//

import Foundation
import SwiftUI
import Combine

class TimerManager: ObservableObject {
    @Published var currentDateTime: Date = Date()
    var timerSubscription: AnyCancellable?

    init() {
        startTimer()
    }
    
    func startTimer() {
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] date in
            self?.currentDateTime = date
        }
    }
    
    deinit {
        timerSubscription?.cancel()
    }
}
