//
//  RTree.swift
//
//
//  Created by Emma K Alexandra on 10/26/19.
//

import Foundation

public struct RTree<T>
where
    T: SpatialObject
{
    /// The root node of this tree
    public var root: DirectoryNodeData<T>
    
    /// The number of elements in this tree
    public var size: UInt = 0
    
    /// The storage path for this tree
    public let path: URL
    
    /// The storage for this tree
    private let storage: Storage<T>
    
    /// The offset of the root node of this tree
    private var rootOffset: UInt64 = 0
    
    init(path: URL) throws {
        let storage = try Storage<T>(path: path)
        
        if storage.isEmpty() {
            self.path = path
            self.storage = storage
            self.root = DirectoryNodeData(storage: storage)
            
            try self.save()
            
        } else {
            self = try storage.loadRoot()
            
        }
        
    }
    
}

extension RTree {
    /// Inserts a new element into the tree.
    ///
    /// This will require `O(log(n))` operations on average, where n is the number of
    /// elements contained in the tree.
    public mutating func insert(_ t: T) throws {
        var state = InsertionState(maxDepth: self.root.depth + 1)
        var insertionStack = [RTreeNode.leaf(t)]
        
        while let next = insertionStack.popLast() {
            switch try self.root.insert(next, state: &state)  {
            case .split(let node):
                let newDepth = self.root.depth + 1
                let options = self.root.options
                let oldRoot = self.root
                
                self.root = DirectoryNodeData(depth: newDepth, options: options, storage: oldRoot.storage)
                
                var newChildren = [RTreeNode.directoryNode(oldRoot), node]
                self.root.addChildren(&newChildren)
                
            case .reinsert(let nodes):
                insertionStack.append(contentsOf: nodes)
            
            case .complete:
                continue
                
            }
            
        }
        
        self.size += 1
        
        try self.save()
        
    }
    
}

extension RTree {
    /// Finds the nearest neighbor to the given point. `nil` if tree is empty.
    public mutating func nearestNeighbor(_ queryPoint: T.Point) -> T? {
        let result = self.root.nearestNeighbor(queryPoint)
        
        if result == nil, self.size > 0 {
            var iterator = self.nearestNeighborIterator(queryPoint)
            
            return iterator.next()
            
        }
        
        return result
        
    }
    
    public func nearestNeighborIterator(_ queryPoint: T.Point) -> NearestNeighborIterator<T> {
        NearestNeighborIterator(root: self.root, queryPoint: queryPoint)
        
    }
    
}

extension RTree {
    /// Saves this tree to disk
    mutating func save() throws {
        if self.storage.isEmpty() {
            try self.storage.initialize()
            
        }
        
        self.rootOffset = try self.root.save()
        try self.storage.save(self)
        
    }
    
}

extension RTree: Codable {
    enum CodingKeys: CodingKey {
        case root
        case size
        case path
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.rootOffset.toPaddedString(), forKey: .root)
        try container.encode(self.size, forKey: .size)
        try container.encode(self.path, forKey: .path)
        
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.size = try container.decode(UInt.self, forKey: .size)
        self.path = try container.decode(URL.self, forKey: .path)
        
        self.storage = try Storage(path: self.path)
        
        let rootNodeOffsetString = try container.decode(String.self, forKey: .root)
        
        guard let rootNodeOffset = UInt64(rootNodeOffsetString) else {
            throw RTreeError.invalidRecord
            
        }
        
        self.root = try self.storage.loadDirectoryNodeData(withOffset: rootNodeOffset)
        
    }
    
}
