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
    public var root: DirectoryNodeData<T>? = nil
    
    /// The number of elements in this tree
    public var size: Int = 0
    
    /// The storage path for this tree
    public var path: URL? = nil
    
    /// If this tree is read only or is available for inserts
    public var isReadOnly: Bool
    
    /// The storage for this tree
    private var storage: Storage<T>? = nil
    
    /// The offset of the root node of this tree
    private var rootOffset: UInt64 = 0
    
    /// Decoder to use for elements of the tree
    public var decoder = JSONDecoder()
    
    /// Encoder to use for elements of the tree
    public var encoder = JSONEncoder()
    
    public init(
        path: URL,
        readOnly: Bool = false,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) throws {
        self.encoder = encoder
        self.decoder = decoder
        
        let storage = try Storage<T>(
            path: path,
            readOnly: readOnly,
            encoder: encoder,
            decoder: decoder
        )
        
        if storage.isEmpty() {
            if readOnly {
                throw RTreeError.treeMarkedReadOnly
                
            }
            
            self.path = path
            self.storage = storage
            self.root = DirectoryNodeData(storage: storage)
            self.isReadOnly = readOnly
            
            try self.save()
            
        } else {
            self = try storage.loadRoot()
            self.isReadOnly = readOnly
            
        }
        
    }
    
}

extension RTree {
    /// Inserts a new element into the tree.
    ///
    /// This will require `O(log(n))` operations on average, where n is the number of
    /// elements contained in the tree.
    public mutating func insert(_ t: T) throws {
        if self.isReadOnly {
            throw RTreeError.treeMarkedReadOnly
            
        }
        
        if self.root == nil {
            try self.load()
            
        }
        
        var state = InsertionState(maxDepth: self.root!.depth + 1)
        var insertionStack = [RTreeNode.leaf(t)]
        
        while let next = insertionStack.popLast() {
            switch try self.root!.insert(next, state: &state)  {
            case .split(let node):
                let newDepth = self.root!.depth + 1
                let options = self.root!.options
                let oldRoot = self.root!
                
                self.root = DirectoryNodeData(depth: newDepth, options: options, storage: oldRoot.storage)
                
                var newChildren = [RTreeNode.directoryNode(oldRoot), node]
                self.root!.addChildren(&newChildren)
                
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
    public mutating func nearestNeighbor(_ queryPoint: T.Point) throws -> T? {
        if self.root == nil {
            try self.load()
            
        }
        
        let result = self.root!.nearestNeighbor(queryPoint)
        
        if result == nil, self.size > 0 {
            var iterator = try self.nearestNeighborIterator(queryPoint)
            
            return iterator.next()
            
        }
        
        return result
        
    }
    
    public mutating func nearestNeighborIterator(_ queryPoint: T.Point) throws -> NearestNeighborIterator<T> {
        if self.root == nil {
            try self.load()
            
        }
        
        return NearestNeighborIterator(root: self.root!, queryPoint: queryPoint)
        
    }
    
}

extension RTree {
    /// Saves this tree to disk
    mutating func save() throws {
        guard let storage = self.storage else {
            throw RTreeError.storageNotPresent
            
        }
        
        if self.root == nil {
            try self.load()
            
        }
        
        if storage.isEmpty() {
            try storage.initialize()
            
        }
        
        self.rootOffset = try self.root!.save()
        try storage.save(self)
        
    }
    
    mutating func load() throws {
        if self.storage == nil {
            self.storage = try Storage<T>(
                path: self.path!,
                readOnly: self.isReadOnly,
                encoder: encoder,
                decoder: decoder
            )
        }
        
        self.root = try self.storage!.loadDirectoryNodeData(withOffset: self.rootOffset)
        
    }
    
}

extension RTree: Codable {
    enum CodingKeys: CodingKey {
        case root
        case size
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.rootOffset.toPaddedString(), forKey: .root)
        try container.encode(self.size, forKey: .size)
        
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.size = try container.decode(Int.self, forKey: .size)
        
        let rootNodeOffsetString = try container.decode(String.self, forKey: .root)
        
        guard let rootNodeOffset = UInt64(rootNodeOffsetString) else {
            throw RTreeError.invalidRecord
            
        }
        
        self.rootOffset = rootNodeOffset
        
        self.isReadOnly = false
    }
}
