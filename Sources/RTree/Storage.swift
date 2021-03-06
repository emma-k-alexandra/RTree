//
//  Storage.swift
//  
//
//  Created by Emma K Alexandra on 10/27/19.
//

import Foundation

/// Engine for storing a tree on disk. Super wasteful rn.
public class Storage<T>
where
    T: SpatialObject
{
    /// The location to store the tree
    public let path: URL
    
    /// If this RTree is read only or allows for writing
    public let readOnly: Bool
    
    /// The file the tree is stored in
    private var file: FileHandle
    
    private var writeFilePath: URL
    
    private var writeFile: FileHandle? = nil
    
    /// A JSON encoder
    private let encoder = JSONEncoder()
    
    /// A JSON decoder
    private let decoder = JSONDecoder()
    
    /// Length of a 64-bit int + \n
    private let lengthOfRecordSize = 19
    
    /// Length of a 64-bit int + \n
    private let rootRecordPointerSize = 19
    
    public init(path: URL, readOnly: Bool = false) throws {
        self.path = path
        self.writeFilePath = URL(string: "\(path.absoluteString).tmp")!
        self.readOnly = readOnly
        
        do {
            if self.readOnly {
                self.file = try FileHandle(forReadingFrom: self.path)
                
            } else {
                self.file = try FileHandle(forUpdating: self.path)
                
                try "".write(to: self.writeFilePath, atomically: true, encoding: .utf8)
                self.writeFile = try FileHandle(forUpdating: self.writeFilePath)
                
                
            }
            
        } catch {
            if self.readOnly {
                throw StorageError.storageMarkedReadOnly
                
            }
            
            do {
                try "".write(to: self.path, atomically: true, encoding: .utf8)
                self.file = try FileHandle(forUpdating: self.path)

                try "".write(to: self.writeFilePath, atomically: true, encoding: .utf8)
                self.writeFile = try FileHandle(forUpdating: self.writeFilePath)
                
            } catch {
                throw StorageError.unableToCreateStorage
                
            }
            
        }
        
    }
    
    deinit {
        self.file.closeFile()
        
        if let _ = self.writeFile {
            try? FileManager.default.removeItem(at: self.writeFilePath)
            
        }
        
    }
    
    /// If the storage is empty, insert empty pointer to root element
    public func initialize() throws {
        if self.isEmpty() {
            let zeroes = 0.toPaddedString() + "\n"
            self.writeFile!.seek(toFileOffset: 0)
            self.writeFile!.write(zeroes.data(using: .utf8)!)
            
        }
        
    }
    
    /// Find and load the root element of the tree
    public func loadRoot() throws -> RTree<T> {
        self.file.seek(toFileOffset: 0)
        
        let rootRecordOffsetData = self.file.readData(ofLength: self.rootRecordPointerSize)
        
        guard let rootRecordOffsetString = String(data: rootRecordOffsetData, encoding: .utf8) else {
            throw RTreeError.invalidRootRecordOffset
            
        }
        
        guard let rootRecordOffset = UInt64(rootRecordOffsetString) else {
            throw RTreeError.invalidRootRecordOffset
            
        }
        
        do {
            var tree = try self.loadRTree(withOffset: rootRecordOffset)
            tree.path = self.path
            
            return tree
            
        } catch {
            throw RTreeError.invalidRootRecord
            
        }
        
    }
    
    /// Load the root element of the tree
    public func loadRTree(withOffset offset: UInt64) throws -> RTree<T> {
        self.file.seek(toFileOffset: offset)
        
        let recordSizeData = self.file.readData(ofLength: self.lengthOfRecordSize)
        
        guard let recordSizeString = String(data: recordSizeData, encoding: .utf8) else {
            throw RTreeError.invalidRecordSize
            
        }
        
        guard let recordSize = Int(recordSizeString) else {
            throw RTreeError.invalidRecordSize
            
        }
        
        let nodeData = self.file.readData(ofLength: recordSize)
                
        do {
            return try self.decoder.decode(RTree<T>.self, from: nodeData)
            
        } catch {
            throw RTreeError.invalidRecord
            
        }
        
    }
    
    /// Load a directory node
    public func loadDirectoryNodeData(withOffset offset: UInt64) throws -> DirectoryNodeData<T> {
        self.file.seek(toFileOffset: offset)
        
        let recordSizeData = self.file.readData(ofLength: self.lengthOfRecordSize)
        
        guard let recordSizeString = String(data: recordSizeData, encoding: .utf8) else {
            throw RTreeError.invalidRecordSize
            
        }
        
        guard let recordSize = Int(recordSizeString) else {
            throw RTreeError.invalidRecordSize
            
        }
        
        let nodeData = self.file.readData(ofLength: recordSize)
                
        do {
            var node = try self.decoder.decode(DirectoryNodeData<T>.self, from: nodeData)
            node.storage = self
            
            return node
            
        } catch {
            throw RTreeError.invalidRecord
            
        }
        
    }
    
    /// Load a spatial object
    public func loadSpatialObject<S>(withOffset offset: UInt64) throws -> S
    where
        S: SpatialObject
    {
        self.file.seek(toFileOffset: offset)
        
        let recordSizeData = self.file.readData(ofLength: self.lengthOfRecordSize)
        
        guard let recordSizeString = String(data: recordSizeData, encoding: .utf8) else {
            throw RTreeError.invalidRecordSize
            
        }
        
        guard let recordSize = Int(recordSizeString) else {
            throw RTreeError.invalidRecordSize
            
        }
        
        let nodeData = self.file.readData(ofLength: recordSize)
        
        do {
            return try self.decoder.decode(S.self, from: nodeData)
            
        } catch {
            throw RTreeError.invalidRecord
            
        }
        
    }
    
    /// Load an RTreeNode
    public func loadRTreeNode(withOffset offset: UInt64) throws -> RTreeNode<T> {
        do {
            return .directoryNode(try self.loadDirectoryNodeData(withOffset: offset))
            
        } catch {
            return .leaf(try self.loadSpatialObject(withOffset: offset))
            
        }

        
    }
    
    /// Save a directory node
    @discardableResult
    public func save(_ node: DirectoryNodeData<T>) throws -> UInt64 {
        guard let writeFile = self.writeFile else {
            throw StorageError.storageMarkedReadOnly
            
        }
        
        let nodeOffset = writeFile.seekToEndOfFile()
        
        let encodedNode = try self.encoder.encode(node)
        
        var dataToWrite = Data()
        dataToWrite.append(encodedNode.count.toPaddedString().data(using: .utf8)!)
        dataToWrite.append(encodedNode)
        dataToWrite.append("\n".data(using: .utf8)!)
        
        writeFile.write(dataToWrite)
        
        return nodeOffset
        
    }
    
    /// Save a spatial object
    public func save<S>(_ spatialObject: S) throws -> UInt64
    where
        S: SpatialObject
    {
        guard let writeFile = self.writeFile else {
            throw StorageError.storageMarkedReadOnly
            
        }
        
        let nodeOffset = writeFile.seekToEndOfFile()
        
        let encodedNode = try self.encoder.encode(spatialObject)
        
        var dataToWrite = Data()
        dataToWrite.append(encodedNode.count.toPaddedString().data(using: .utf8)!)
        dataToWrite.append(encodedNode)
        dataToWrite.append("\n".data(using: .utf8)!)
        
        writeFile.write(dataToWrite)
        
        return nodeOffset
        
    }
    
    /// Saves an RTreeNode
    public func save(_ node: RTreeNode<T>) throws -> UInt64 {
        switch node {
        case .directoryNode(var data):
            return try data.save()
            
        case .leaf(let t):
            return try self.save(t)
            
        }
        
    }
    
    /// Save an RTree
    @discardableResult
    public func save(_ tree: RTree<T>) throws -> UInt64 {
        guard let writeFile = self.writeFile else {
            throw StorageError.storageMarkedReadOnly
            
        }
        
        let nodeOffset = writeFile.seekToEndOfFile()
        
        let encodedTree = try self.encoder.encode(tree)
        
        var dataToWrite = Data()
        dataToWrite.append(encodedTree.count.toPaddedString().data(using: .utf8)!)
        dataToWrite.append(encodedTree)
        dataToWrite.append("\n".data(using: .utf8)!)
        
        writeFile.write(dataToWrite)
        
        writeFile.seek(toFileOffset: 0)
        writeFile.write((nodeOffset.toPaddedString() + "\n").data(using: .utf8)!)
        
        try FileManager.default.removeItem(at: self.path)
        try FileManager.default.copyItem(at: self.writeFilePath, to: self.path)
        try FileManager.default.removeItem(at: self.writeFilePath)
        
        self.file = try FileHandle(forUpdating: self.path)
        
        try "".write(to: self.writeFilePath, atomically: true, encoding: .utf8)
        self.writeFile = try FileHandle(forUpdating: self.writeFilePath)
        try self.initialize()
        
        return nodeOffset
        
    }
    
    /// Checks if the current file is empty
    public func isEmpty() -> Bool {
        return self.file.seekToEndOfFile() == 0
        
    }
    
}

public enum StorageError: Error {
    case unableToCreateStorage
    case storageMarkedReadOnly
}
