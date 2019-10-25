//
//  File.swift
//  
//
//  Created by Emma K Alexandra on 10/23/19.
//

import Foundation

public struct NearestNeighborIterator<T>
    where T: SpatialObject
{
    var nodes: Heap<RTreeNodeDistanceWrapper<T>>
    let queryPoint: T.Point
    
    init(nodes: Heap<RTreeNodeDistanceWrapper<T>>, queryPoint: T.Point) {
        self.nodes = nodes
        self.queryPoint = queryPoint
    }
    
    init(root: DirectoryNodeData<T>, queryPoint: T.Point) {
        var result = NearestNeighborIterator(nodes: Heap(sort: <), queryPoint: queryPoint)
        
        result.extendHeap(root.children)
        
        self = result
        
    }
    
}

extension NearestNeighborIterator {
    mutating func extendHeap(_ children: [RTreeNode<T>]) {
        let distanceWrappers = children.map({ (child) -> RTreeNodeDistanceWrapper<T> in
            var distance: T.Point.Scalar = 0
            
            switch child {
            case .directoryNode(let data):
                distance = data.boundingBox!.minDistanceSquared(self.queryPoint)
            case .leaf(let t):
                distance = t.distanceSquared(point: self.queryPoint)
            }
            
            return RTreeNodeDistanceWrapper(node: child, distance: distance)
            
        })
        
        for child in distanceWrappers {
            self.nodes.insert(child)
            
        }
        
    }
    
}

extension NearestNeighborIterator: IteratorProtocol {    
    public typealias Element = T
    
    public mutating func next() -> T? {
        while let current = self.nodes.remove() {
            switch current.node {
            case .directoryNode(let data):
                self.extendHeap(data.children)
            case .leaf(let t):
                return t
            }
            
        }
        
        return nil
        
    }
    
}
