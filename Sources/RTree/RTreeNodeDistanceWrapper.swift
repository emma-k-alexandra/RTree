//
//  RTreeNodeDistanceWrapper.swift
//  
//
//  Created by Emma K Alexandra on 10/26/19.
//

import Foundation

/// A small wrapper for a distance and node
public struct RTreeNodeDistanceWrapper<T>: Comparable
where
    T: SpatialObject
{
    /// Stored node
    public let node: RTreeNode<T>
    
    /// The distance of the stored node from some point
    public let distance: T.Point.Scalar
    
    public static func < (lhs: RTreeNodeDistanceWrapper<T>, rhs: RTreeNodeDistanceWrapper<T>) -> Bool {
        lhs.distance < rhs.distance
        
    }
    
    public static func == (lhs: RTreeNodeDistanceWrapper<T>, rhs: RTreeNodeDistanceWrapper<T>) -> Bool {
        lhs.distance == rhs.distance
        
    }
    
}
