//
//  SharedTimer.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 11/13/23.
//

import Foundation
import SwiftUI

class SharedTimer: ObservableObject {
    static let shared = SharedTimer()
    private init() {}

    private var timer: Timer?

    func startTimer(action: @escaping () -> Void) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            action()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
