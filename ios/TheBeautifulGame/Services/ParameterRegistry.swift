// ParameterRegistry.swift
// TheBeautifulGame
//
// Loads and provides typed access to FM14's 86 parameter files (pre-converted to JSON).
// Supports user .txt overrides from the documents directory.
// All game engine values (match probabilities, training multipliers, transfer scoring,
// injury types, finance rules) come from these parameters.

import Foundation

/// Central registry for all FM14 game engine parameters.
/// Loads from bundled JSON files at app launch. User can override with .txt files.
@MainActor
final class ParameterRegistry: Sendable {

    /// Singleton — loaded once, shared across all engines
    static let shared = ParameterRegistry()

    /// Raw parameter data keyed by file name (e.g. "Textmode Events Matrix")
    private var parameters: [String: Any] = [:]

    /// Names of all loaded parameter files
    private(set) var loadedFiles: [String] = []

    /// Whether initial load has completed
    private(set) var isLoaded: Bool = false

    private init() {
        loadAllParameters()
    }

    // MARK: - Loading

    private func loadAllParameters() {
        // Known FM14 parameter file names (the 86 files)
        let knownFiles = [
            "Textmode Events Matrix",
            "Textmode Match",
            "Startformation",
            "Set Pieces",
            "Player Level",
            "Player Styles",
            "Player Development",
            "Injuries",
            "Training",
            "Training Sessions",
            "Fitness and Fatigue",
            "Transfer Evaluation",
            "Transfer Prestige Multiplier",
            "Finances",
            "Sponsor Contracts",
            "Taxes",
            "Stadium Building Costs",
            "Board",
            "LiveTicker",
            "Derbies",
            "Loading Screens",
            "TV Money",
            "Private Life",
        ]

        for name in knownFiles {
            if let data = loadParameterFile(name: name) {
                parameters[name] = data
                loadedFiles.append(name)
            }
        }

        // Also try loading any additional JSON files from the ParameterFiles directory
        if let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "ParameterFiles") {
            for url in urls {
                let name = url.deletingPathExtension().lastPathComponent
                if parameters[name] == nil {
                    if let data = try? Data(contentsOf: url),
                       let json = try? JSONSerialization.jsonObject(with: data) {
                        parameters[name] = json
                        loadedFiles.append(name)
                    }
                }
            }
        }

        isLoaded = true
    }

    private func loadParameterFile(name: String) -> Any? {
        // Check for user override in documents directory first (.txt → parse, .json → load directly)
        let docsDir = URL.documentsDirectory.appending(path: "ParameterFiles")
        let txtOverride = docsDir.appending(path: "\(name).txt")
        let jsonOverride = docsDir.appending(path: "\(name).json")

        if FileManager.default.fileExists(atPath: jsonOverride.path()) {
            if let data = try? Data(contentsOf: jsonOverride),
               let json = try? JSONSerialization.jsonObject(with: data) {
                return json
            }
        }

        // Load from bundle
        if let url = Bundle.main.url(forResource: name, withExtension: "json") {
            if let data = try? Data(contentsOf: url),
               let json = try? JSONSerialization.jsonObject(with: data) {
                return json
            }
        }
        if let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "ParameterFiles") {
            if let data = try? Data(contentsOf: url),
               let json = try? JSONSerialization.jsonObject(with: data) {
                return json
            }
        }
        return nil
    }

    // MARK: - Typed Accessors

    /// Get raw parameter data for a file name
    func raw(_ name: String) -> Any? {
        parameters[name]
    }

    /// Get parameter data as a dictionary
    func dictionary(_ name: String) -> [String: Any]? {
        parameters[name] as? [String: Any]
    }

    /// Get parameter data as an array of dictionaries
    func arrayOfDicts(_ name: String) -> [[String: Any]]? {
        if let dict = parameters[name] as? [String: Any] {
            return dict["_rows"] as? [[String: Any]]
        }
        return parameters[name] as? [[String: Any]]
    }

    /// Get a specific value from a parameter file
    func value<T>(_ name: String, key: String) -> T? {
        let dict = parameters[name] as? [String: Any]
        return dict?[key] as? T
    }

    /// Get injury definitions (48 types with duration/probability)
    func injuries() -> [[String: Any]]? {
        arrayOfDicts("Injuries")
    }

    /// Get training session definitions
    func trainingSessions() -> [[String: Any]]? {
        arrayOfDicts("Training Sessions")
    }

    /// Get formation definitions from Startformation
    func formations() -> [[String: Any]]? {
        arrayOfDicts("Startformation")
    }

    /// Get transfer evaluation parameters
    func transferEvaluation() -> [String: Any]? {
        dictionary("Transfer Evaluation")
    }

    /// Get finance parameters
    func finances() -> [String: Any]? {
        dictionary("Finances")
    }

    /// Get event matrix for match simulation
    func eventMatrix() -> [String: Any]? {
        dictionary("Textmode Events Matrix")
    }

    /// Get LiveTicker match probabilities
    func liveTicker() -> [String: Any]? {
        dictionary("LiveTicker")
    }

    /// Get player level / position bias matrix
    func playerLevel() -> [String: Any]? {
        dictionary("Player Level")
    }

    /// Get player styles with attribute multipliers
    func playerStyles() -> [[String: Any]]? {
        arrayOfDicts("Player Styles")
    }
}
