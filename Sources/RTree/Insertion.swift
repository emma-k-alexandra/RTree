//
//  Insertion.swift
//  
//
//  Created by Emma K Alexandra on 10/20/19.
//

import Foundation

public struct InsertionState {
    public var reinsertions: [Bool]
    
    init(maxDepth: UInt) {
        self.reinsertions = [Bool](repeating: false, count: Int(maxDepth))
        
    }
    
}

extension InsertionState {
    public func didReinsert(depth: UInt) -> Bool {
        self.reinsertions[Int(depth)]
        
    }
    
    public mutating func markReinsertion(depth: UInt) {
        self.reinsertions[Int(depth)] = true
        
    }
    
}

public enum InsertionResult<T>
where
    T: SpatialObject
{
    case complete
    case split(RTreeNode<T>)
    case reinsert([RTreeNode<T>])
    
}
