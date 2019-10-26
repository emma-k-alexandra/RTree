//
//  RTreeNodeDistanceWrapper.swift
//  
//
//  Created by Emma K Alexandra on 10/26/19.
//

import Foundation

public struct RTreeNodeDistanceWrapper<T>: Comparable
where
    T: SpatialObject
{
    public let node: RTreeNode<T>
    public let distance: T.Point.Scalar
    
    public static func < (lhs: RTreeNodeDistanceWrapper<T>, rhs: RTreeNodeDistanceWrapper<T>) -> Bool {
        lhs.distance < rhs.distance
        
    }
    
    public static func == (lhs: RTreeNodeDistanceWrapper<T>, rhs: RTreeNodeDistanceWrapper<T>) -> Bool {
        lhs.distance == rhs.distance
        
    }
    
}
