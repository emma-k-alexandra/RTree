//
//  RTreeNode.swift
//  
//
//  Created by Emma K Alexandra on 10/20/19.
//

import Foundation

public enum RTreeNode<T>
where
    T: SpatialObject
{
    case leaf(T)
    case directoryNode(DirectoryNodeData<T>)
}

extension RTreeNode {
    public func minimumBoundingRectangle() -> BoundingRectangle<T.Point> {
        switch self {
        case .directoryNode(let data):
            return data.boundingBox!
        case .leaf(let t):
            return t.minimumBoundingRectangle()
            
        }
        
    }
    
    public func depth() -> UInt {
        switch self {
        case .directoryNode(let data):
            return data.depth
        default:
            return 0
        }
        
    }
    
    public func nearestNeighbors(_ point: T.Point, nearestDistance: inout T.Point.Scalar?, result: inout [T]) -> T.Point.Scalar? {
        switch self {
        case .directoryNode(let data):
            return data.nearestNeighbors(point, nearestDistance: &nearestDistance, result: &result)
        case .leaf(let t):
            let distance = t.distanceSquared(point: point)
            
            if let nearest = nearestDistance {
                if distance <= nearest {
                    if distance < nearest {
                        result.removeAll()
                        
                    }
                    
                    result.append(t)
                    return distance
                    
                } else {
                    return nil
                    
                }
                
            } else {
                result.append(t)
                return distance
                
            }
            
        }
        
    }
    
}

extension RTreeNode: Equatable {
    public static func == (lhs: RTreeNode<T>, rhs: RTreeNode<T>) -> Bool {
        lhs.minimumBoundingRectangle() == rhs.minimumBoundingRectangle() && lhs.depth() == rhs.depth()
    }
    
}

struct RTreeNodeDistanceWrapper<T>: Comparable
where
    T: SpatialObject
{
    let node: RTreeNode<T>
    let distance: T.Point.Scalar
    
    public static func < (lhs: RTreeNodeDistanceWrapper<T>, rhs: RTreeNodeDistanceWrapper<T>) -> Bool {
        lhs.distance < rhs.distance
    }
    
    public static func == (lhs: RTreeNodeDistanceWrapper<T>, rhs: RTreeNodeDistanceWrapper<T>) -> Bool {
        lhs.distance == rhs.distance
    }
    
}
