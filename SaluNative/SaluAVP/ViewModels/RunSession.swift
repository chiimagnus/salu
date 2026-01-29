//
//  RunSession.swift
//  SaluAVP
//
//  Created by chii_magnus on 2026/1/29.
//

import Foundation
import SwiftUI

import GameCore

@MainActor
@Observable
final class RunSession {
    var seedText: String = ""
    var lastError: String?
    var runState: RunState?

    func startNewRun() {
        let seed: UInt64
        if seedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            seed = Self.generateSeed()
        } else if let parsed = UInt64(seedText.trimmingCharacters(in: .whitespacesAndNewlines)) {
            seed = parsed
        } else {
            lastError = "Invalid seed. Please enter a UInt64 number."
            return
        }

        runState = RunState.newRun(seed: seed)
        seedText = String(seed)
        lastError = nil
    }

    private static func generateSeed() -> UInt64 {
        UInt64(Date().timeIntervalSince1970 * 1000)
    }
}

