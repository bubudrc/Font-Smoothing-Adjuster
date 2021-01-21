//
//  DefaultsProcessRunner.swift
//  Big Sur Font Smoothing Toggler
//
//  Created by Alastair Byrne on 21/01/2021.
//

import Foundation

class DefaultsProcessRunner {
    private let defaultsUrl = URL(fileURLWithPath: "/usr/bin/defaults")
    private let domainDefaultPairDoesNotExistText = "The domain/default pair of (kCFPreferencesAnyApplication, AppleFontSmoothing) does not exist"
    
    private let setFontSmoothingStateArguments: [FontSmoothingOptions : [String]] = [
        .defaultFontSmoothing : ["-currentHost", "delete", "-g", "AppleFontSmoothing"],
        .noFontSmoothing : ["-currentHost", "write", "-g", "AppleFontSmoothing", "-int", "0"],
        .lightFontSmoothing : ["-currentHost", "write", "-g", "AppleFontSmoothing", "-int", "1"],
        .mediumFontSmoothing : ["-currentHost", "write", "-g", "AppleFontSmoothing", "-int", "2"],
        .heavyFontSmoothing : ["-currentHost", "write", "-g", "AppleFontSmoothing", "-int", "3"],
    ]
    
    private let getFontSmoothingStateArguments = ["-currentHost", "read", "Apple Global Domain", "AppleFontSmoothing"]
    
    enum FontSmoothingOptions {
        case defaultFontSmoothing
        case lightFontSmoothing
        case mediumFontSmoothing
        case heavyFontSmoothing
        case noFontSmoothing
    }
    
    struct DefaultsResult {
        let output: String
        let error: String
    }
    
    private enum FontSmoothingDefaultsError: Error {
        case unknownError
    }
    
    func setFontSmoothing(option: FontSmoothingOptions) throws {
        guard let args = setFontSmoothingStateArguments[option] else {
            fatalError("Unsupported set font smoothing arguments option.")
        }
        
        do {
            let result = try runDefaultsCommand(with: args)
            
            if result.output != "" || result.error != "" {
                throw FontSmoothingDefaultsError.unknownError
            }
        } catch {
            if !error.localizedDescription.contains(domainDefaultPairDoesNotExistText) {
                throw error
            }
        }
    }
    
    func isFontSmoothingEnabled() throws -> Bool {
        do {
            let result = try runDefaultsCommand(with: getFontSmoothingStateArguments)
            
            if result.output == "0\n" {
                return false
            }
            
            if result.output.contains(domainDefaultPairDoesNotExistText) || result.error.contains(domainDefaultPairDoesNotExistText) {
                return true
            }
            
            throw FontSmoothingDefaultsError.unknownError
        } catch {
            if error.localizedDescription.contains(domainDefaultPairDoesNotExistText) {
                return true
            } else {
                throw error
            }
        }
    }
    
    private func runDefaultsCommand(with arguments: [String]) throws -> DefaultsResult {
        let task = Process()
        
        task.executableURL = defaultsUrl
        task.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        try task.run()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let output = String(decoding: outputData, as: UTF8.self)
        let error = String(decoding: errorData, as: UTF8.self)
        
        let result = DefaultsResult(output: output, error: error)
        return result
    }
}