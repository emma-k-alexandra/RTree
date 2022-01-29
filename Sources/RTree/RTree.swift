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
        
        size += 1
        
        try save()
    }
}

extension RTree {
    /// Finds the nearest neighbor to the given point. `nil` if tree is empty.
    public mutating func nearestNeighbor(_ queryPoint: T.Point) throws -> T? {
        if root == nil {
            try load()
        }
        
        let result = root!.nearestNeighbor(queryPoint)
        
        if result == nil, size > 0 {
            var iterator = try nearestNeighborIterator(queryPoint)
            
            return iterator.next()
        }
        
        return result
    }
    
    public mutating func nearestNeighborIterator(_ queryPoint: T.Point) throws -> NearestNeighborIterator<T> {
        if root == nil {
            try load()
        }
        
        return NearestNeighborIterator(root: root!, queryPoint: queryPoint)
    }
}

extension RTree {
    /// Saves this tree to disk
    mutating func save() throws {
        guard let storage = storage else {
            throw RTreeError.storageNotPresent
        }
        
        if root == nil {
            try load()
        }
        
//        if storage.isEmpty() {
//            try storage.initialize()
//        }
        
        self.rootOffset = try root!.save()
        try storage.save(self)
    }
    
    mutating func load() throws {
        if storage == nil {
            storage = try Storage<T>(
                path: path!,
                readOnly: isReadOnly,
                encoder: encoder,
                decoder: decoder
            )
        }
        
        root = try storage!.loadDirectoryNodeData(withOffset: rootOffset)
    }
}

extension RTree: Codable {
    enum CodingKeys: CodingKey {
        case root
        case size
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(rootOffset.toPaddedString(), forKey: .root)
        try container.encode(size, forKey: .size)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        size = try container.decode(Int.self, forKey: .size)
        
        let rootNodeOffsetString = try container.decode(String.self, forKey: .root)
        
        guard let rootNodeOffset = UInt64(rootNodeOffsetString) else {
            throw RTreeError.invalidRecord
        }
        
        rootOffset = rootNodeOffset
        
        isReadOnly = false
    }
}
