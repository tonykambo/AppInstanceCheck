//
//  InstallationTimestampDetector.swift
//  UniqueDeviceCheck
//
//  Created by Tony Kambourakis on 19/5/2026.
//

import Foundation

class InstallationTimestampDetector {
    
    // MARK: - Multi-Source Timestamp Detection
    
    /// Get the most reliable installation timestamp by checking multiple sources
    /// Returns the most recent timestamp (most likely to be accurate)
    func getAppInstallationDate() -> InstallationTimestamps? {
        let documentsDate = getDocumentsDirectoryCreationDate()
        let libraryDate = getLibraryDirectoryCreationDate()
        let bundleDate = getAppBundleCreationDate()
        
        // Collect all valid dates
        let timestamps = InstallationTimestamps(
            documentsDirectory: documentsDate,
            libraryDirectory: libraryDate,
            appBundle: bundleDate
        )
        
        return timestamps.hasAnyTimestamp ? timestamps : nil
    }
    
    // MARK: - Individual Timestamp Sources
    
    /// Get Documents directory creation date
    /// This updates during Quick Start/restore
    func getDocumentsDirectoryCreationDate() -> Date? {
        guard let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }
        
        return getCreationDate(for: documentsURL)
    }
    
    /// Get Library directory creation date
    /// This also updates during Quick Start/restore
    func getLibraryDirectoryCreationDate() -> Date? {
        guard let libraryURL = FileManager.default.urls(
            for: .libraryDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }
        
        return getCreationDate(for: libraryURL)
    }
    
    /// Get App Bundle creation date
    /// This updates when app is installed/restored
    func getAppBundleCreationDate() -> Date? {
        let bundlePath = Bundle.main.bundlePath
        return getCreationDate(for: URL(fileURLWithPath: bundlePath))
    }
    
    // MARK: - Helper Methods
    
    private func getCreationDate(for url: URL) -> Date? {
        do {
            let attributes = try FileManager.default.attributesOfItem(
                atPath: url.path
            )
            return attributes[.creationDate] as? Date
        } catch {
            print("Error getting creation date for \(url.path): \(error)")
            return nil
        }
    }
    
    // MARK: - Quick Start Detection
    
    func detectQuickStartByTimestamp(
        registrationDate: Date
    ) -> TimestampDetectionResult {
        guard let timestamps = getAppInstallationDate() else {
            return .cannotDetermineInstallDate
        }
        
        // Use the most recent timestamp (most likely to be accurate)
        guard let installDate = timestamps.mostRecentDate else {
            return .cannotDetermineInstallDate
        }
        
        // Allow 1 hour buffer for timezone/clock differences
        let buffer: TimeInterval = 3600
        
        if installDate.timeIntervalSince(registrationDate) > buffer {
            // App installed AFTER registration = Quick Start copy
            let daysDiff = Calendar.current.dateComponents(
                [.day],
                from: registrationDate,
                to: installDate
            ).day ?? 0
            
            return .quickStartDetected(
                registrationDate: registrationDate,
                installDate: installDate,
                daysDifference: daysDiff,
                timestamps: timestamps
            )
        }
        
        return .likelyOriginalDevice(timestamps: timestamps)
    }
}

// MARK: - Data Structures

struct InstallationTimestamps {
    let documentsDirectory: Date?
    let libraryDirectory: Date?
    let appBundle: Date?
    
    var hasAnyTimestamp: Bool {
        documentsDirectory != nil || libraryDirectory != nil || appBundle != nil
    }
    
    /// Returns the most recent timestamp (most likely to be accurate)
    var mostRecentDate: Date? {
        let dates = [documentsDirectory, libraryDirectory, appBundle].compactMap { $0 }
        return dates.max()
    }
    
    /// Returns the oldest timestamp
    var oldestDate: Date? {
        let dates = [documentsDirectory, libraryDirectory, appBundle].compactMap { $0 }
        return dates.min()
    }
    
    /// Check if all timestamps are consistent (within 1 hour of each other)
    var areConsistent: Bool {
        guard let oldest = oldestDate, let newest = mostRecentDate else {
            return false
        }
        let difference = newest.timeIntervalSince(oldest)
        return difference < 3600 // 1 hour
    }
}

enum TimestampDetectionResult {
    case quickStartDetected(
        registrationDate: Date,
        installDate: Date,
        daysDifference: Int,
        timestamps: InstallationTimestamps
    )
    case likelyOriginalDevice(timestamps: InstallationTimestamps)
    case cannotDetermineInstallDate
}
