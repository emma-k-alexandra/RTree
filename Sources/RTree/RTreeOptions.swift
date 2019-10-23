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
    
    public func build<T: SpatialObject>() -> RTree<T> {
        RTree(options: self)
        
    }
    
}
