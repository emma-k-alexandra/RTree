//
//  Insertion.swift
//  
//
//  Created by Emma K Alexandra on 10/20/19.
//

import Foundation

/// Stores the reinsertion state
public struct InsertionState {
    public var reinsertions: [Bool]
    
    init(maxDepth: Int) {
        assert(maxDepth > -1, "maxDepth must be non-negative")
        self.reinsertions = [Bool](repeating: false, count: maxDepth)
        
    }
    
}

extension InsertionState {
    public func didReinsert(depth: Int) -> Bool {
        self.reinsertions[depth]
        
    }
    
    public mutating func markReinsertion(depth: Int) {
        self.reinsertions[depth] = true
        
    }
    
}

/// The result of an insertion
public enum InsertionResult<T>
where
    T: SpatialObject
{
    case complete
    case split(RTreeNode<T>)
    case reinsert([RTreeNode<T>])
    
}
