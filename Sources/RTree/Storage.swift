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
    private let encoder: JSONEncoder
    
    /// A JSON decoder
    private let decoder: JSONDecoder
    
    /// Length of a 64-bit int + \n
    private let lengthOfRecordSize = 19
    
    /// Length of a 64-bit int + \n
    private let rootRecordPointerSize = 19
    
    public init(
        path: URL,
        readOnly: Bool = false,
        encoder: JSONEncoder,
        decoder: JSONDecoder
    ) throws {
        self.encoder = encoder
        self.decoder = decoder
        self.path = path
        self.writeFilePath = URL(string: "\(path.absoluteString).tmp")!
        self.readOnly = readOnly
        
        do {
            if readOnly {
                file = try FileHandle(forReadingFrom: path)
            } else {
                file = try FileHandle(forUpdating: path)
                
                try "".write(to: writeFilePath, atomically: true, encoding: .utf8)
                let writeFile = try FileHandle(forUpdating: writeFilePath)
                try initialize(writeFile)
                self.writeFile = writeFile
            }
        } catch {
            if readOnly {
                throw StorageError.storageMarkedReadOnly
            }
            
            do {
                try "".write(to: self.path, atomically: true, encoding: .utf8)
                file = try FileHandle(forUpdating: path)

                try "".write(to: self.writeFilePath, atomically: true, encoding: .utf8)
                let writeFile = try FileHandle(forUpdating: writeFilePath)
                try initialize(writeFile)
                self.writeFile = writeFile
                
            } catch {
                throw StorageError.unableToCreateStorage
            }
        }
    }
    
    deinit {
        file.closeFile()
        
        if let _ = writeFile {
            try? FileManager.default.removeItem(at: writeFilePath)
        }
    }
    
    /// If the storage is empty, insert empty pointer to root element
    public func initialize(_ fileHandle: FileHandle) throws {
        if fileHandle.seekToEndOfFile() == 0 {
            let zeroes = 0.toPaddedString() + "\n"
            fileHandle.seek(toFileOffset: 0)
            fileHandle.write(zeroes.data(using: .utf8)!)
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
        file.seek(toFileOffset: offset)
        
        let recordSizeData = self.file.readData(ofLength: self.lengthOfRecordSize)
        
        guard let recordSizeString = String(data: recordSizeData, encoding: .utf8) else {
            throw RTreeError.invalidRecordSize
        }
        
        guard let recordSize = Int(recordSizeString) else {
            throw RTreeError.invalidRecordSize
        }
        
        let nodeData = file.readData(ofLength: recordSize)
                
        do {
            return try decoder.decode(RTree<T>.self, from: nodeData)
        } catch {
            throw RTreeError.invalidRecord
        }
    }
    
    /// Load a directory node
    public func loadDirectoryNodeData(withOffset offset: UInt64) throws -> DirectoryNodeData<T> {
        file.seek(toFileOffset: offset)
        
        let recordSizeData = self.file.readData(ofLength: self.lengthOfRecordSize)
        
        guard let recordSizeString = String(data: recordSizeData, encoding: .utf8) else {
            throw RTreeError.invalidRecordSize
        }
        
        guard let recordSize = Int(recordSizeString) else {
            throw RTreeError.invalidRecordSize
        }
        
        let nodeData = file.readData(ofLength: recordSize)
                
        do {
            var node = try decoder.decode(DirectoryNodeData<T>.self, from: nodeData)
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
        file.seek(toFileOffset: offset)
        
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
            return .directoryNode(try loadDirectoryNodeData(withOffset: offset))
        } catch {
            return .leaf(try loadSpatialObject(withOffset: offset))
        }
    }
    
    /// Save a directory node
    @discardableResult
    public func save(_ node: DirectoryNodeData<T>) throws -> UInt64 {
        guard let writeFile = writeFile else {
            throw StorageError.storageMarkedReadOnly
        }
        
        let nodeOffset = writeFile.seekToEndOfFile()
        
        let encodedNode = try encoder.encode(node)
        
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
        guard let writeFile = writeFile else {
            throw StorageError.storageMarkedReadOnly
        }
        
        let nodeOffset = writeFile.seekToEndOfFile()
        
        let encodedNode = try encoder.encode(spatialObject)
        
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
            return try save(t)
        }
    }
    
    /// Save an RTree
    @discardableResult
    public func save(_ tree: RTree<T>) throws -> UInt64 {
        guard let writeFile = writeFile else {
            throw StorageError.storageMarkedReadOnly
        }
        
        let nodeOffset = writeFile.seekToEndOfFile()
        
        let encodedTree = try encoder.encode(tree)
        
        var dataToWrite = Data()
        dataToWrite.append(encodedTree.count.toPaddedString().data(using: .utf8)!)
        dataToWrite.append(encodedTree)
        dataToWrite.append("\n".data(using: .utf8)!)
        
        writeFile.write(dataToWrite)
        
        writeFile.seek(toFileOffset: 0)
        writeFile.write((nodeOffset.toPaddedString() + "\n").data(using: .utf8)!)
        
        try FileManager.default.removeItem(at: path)
        try FileManager.default.copyItem(at: writeFilePath, to: path)
        try FileManager.default.removeItem(at: writeFilePath)
        
        file = try FileHandle(forUpdating: path)
        
        try "".write(to: self.writeFilePath, atomically: true, encoding: .utf8)
        let newWriteFile = try FileHandle(forUpdating: writeFilePath)
        self.writeFile = newWriteFile
        try initialize(newWriteFile)
        
        return nodeOffset
    }
    
    /// Checks if the current file is empty
    public func isEmpty() -> Bool {
        return file.seekToEndOfFile() == 0
    }
}

public enum StorageError: Error {
    case unableToCreateStorage
    case storageMarkedReadOnly
}
