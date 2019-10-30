//
//  RTreeOptions.swift
//  
//
//  Created by Emma K Alexandra on 10/20/19.
//

import Foundation

public struct RTreeOptions: Codable {
    public let maxSize: Int
    public let minSize: Int
    public let reinsertionCount: Int
    
    public init() {
        self.maxSize = 6
        self.minSize = 3
        self.reinsertionCount = 2
        
    }
    
    public init(maxSize: Int, minSize: Int, reinsertionCount: Int) {
        assert(maxSize > -1 && minSize > -1 && reinsertionCount > -1, "All parameters of options must be non-negative")
        
        self.maxSize = maxSize
        self.minSize = minSize
        self.reinsertionCount = reinsertionCount
        
    }
    
}
