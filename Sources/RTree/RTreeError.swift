//
//  RTreeError.swift
//  
//
//  Created by Emma K Alexandra on 10/27/19.
//

import Foundation

/// Errors that can occur while using this tree
public enum RTreeError: Error {
    case nodeHasNoStorage
    case storageNotPresent
    case invalidRecord
    case invalidRecordSize
    case invalidRootRecordOffset
    case invalidRootRecord
}
