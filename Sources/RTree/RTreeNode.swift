//
//  RTreeNode.swift
//  
//
//  Created by Emma K Alexandra on 10/20/19.
//

import Foundation

/// If a node is a leaf or a directory node
public enum RTreeNode<T>
where
    T: SpatialObject
{
    case leaf(T)
    case directoryNode(DirectoryNodeData<T>)
}

extension RTreeNode {
    /// The MBR for this node
    public func minimumBoundingRectangle() -> BoundingRectangle<T.Point> {
        switch self {
        case .directoryNode(let data):
            return data.boundingBox!
            
        case .leaf(let t):
            return t.minimumBoundingRectangle()
            
        }
        
    }
    
    /// The depth of this node
    public func depth() -> Int {
        switch self {
        case .directoryNode(let data):
            return data.depth
            
        case .leaf:
            return 0
            
        }
        
    }
    
}

extension RTreeNode: Equatable {
    public static func == (lhs: RTreeNode<T>, rhs: RTreeNode<T>) -> Bool {
        lhs.minimumBoundingRectangle() == rhs.minimumBoundingRectangle() && lhs.depth() == rhs.depth()
        
    }
    
}

extension RTreeNode: Codable {
    enum CodingKeys: CodingKey {
        case leaf
        case directoryNode
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .directoryNode(let data):
            try container.encode(data, forKey: .directoryNode)
            
        case .leaf(let t):
            try container.encode(t, forKey: .leaf)
            
        }
        
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            self = .directoryNode(try DirectoryNodeData(from: decoder))
            
        } catch {
            self = .leaf(try container.decode(T.self, forKey: .leaf))
            
        }
        
    }
    
}
