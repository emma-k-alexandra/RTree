//
//  RTreeOptions.swift
//  
//
//  Created by Emma K Alexandra on 10/20/19.
//

import Foundation

public struct RTreeOptions {
    public let maxSize: UInt
    public let minSize: UInt
    public let reinsertionCount: UInt
    
    public init() {
        self.maxSize = 6
        self.minSize = 3
        self.reinsertionCount = 2
        
    }
    
    public init(maxSize: UInt, minSize: UInt, reinsertionCount: UInt) {
        self.maxSize = maxSize
        self.minSize = minSize
        self.reinsertionCount = reinsertionCount
        
    }
    
}
