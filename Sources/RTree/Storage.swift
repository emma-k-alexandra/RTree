//
//  Storage.swift
//  
//
//  Created by Emma K Alexandra on 10/27/19.
//

import Foundation

public class Storage<T>
where
    T: SpatialObject
{
    public let path: URL
    
    private let file: FileHandle
    
    private let encoder = JSONEncoder()
    
    private let decoder = JSONDecoder()
    
    private let lengthOfRecordSize = 19
    private let rootRecordPointerSize = 19
    
    public init(path: URL) throws {
        self.path = path
        
        do {
            self.file = try FileHandle(forUpdating: self.path)
            
        } catch {
            do {
                try "".write(to: self.path, atomically: true, encoding: .utf8)
                
                self.file = try FileHandle(forUpdating: self.path)
                
            } catch {
                throw StorageError.unableToCreateStorage
                
            }
            
        }
        
    }
    
    deinit {
        self.file.closeFile()
        
    }
    
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
            return try self.loadRTree(withOffset: rootRecordOffset)
            
        } catch {
            throw RTreeError.invalidRootRecord
            
        }
        
    }
    
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
    
    public func loadRTreeNode(withOffset offset: UInt64) throws -> RTreeNode<T> {
        do {
            return .directoryNode(try self.loadDirectoryNodeData(withOffset: offset))
            
        } catch {
            return .leaf(try self.loadSpatialObject(withOffset: offset))
            
        }

        
    }
    
    @discardableResult
    public func save(_ node: DirectoryNodeData<T>) throws -> UInt64 {
        let nodeOffset = self.file.seekToEndOfFile()
        
        let encodedNode = try self.encoder.encode(node)
        
        var dataToWrite = Data()
        dataToWrite.append(encodedNode.count.toPaddedString().data(using: .utf8)!)
        dataToWrite.append(encodedNode)
        dataToWrite.append("\n".data(using: .utf8)!)
        
        self.file.write(dataToWrite)
        
        return nodeOffset
        
    }
    
    public func save<S>(_ spatialObject: S) throws -> UInt64
    where
        S: SpatialObject
    {
        let nodeOffset = self.file.seekToEndOfFile()
        
        let encodedNode = try self.encoder.encode(spatialObject)
        
        var dataToWrite = Data()
        dataToWrite.append(encodedNode.count.toPaddedString().data(using: .utf8)!)
        dataToWrite.append(encodedNode)
        dataToWrite.append("\n".data(using: .utf8)!)
        
        self.file.write(dataToWrite)
        
        return nodeOffset
        
    }
    
    public func save(_ node: RTreeNode<T>) throws -> UInt64 {
        switch node {
        case .directoryNode(var data):
            return try data.save()
            
        case .leaf(let t):
            return try self.save(t)
            
        }
        
    }
    
    public func isEmpty() -> Bool {
        return self.file.seekToEndOfFile() == 0
        
    }
    
    @discardableResult
    public func save(_ tree: RTree<T>) throws -> UInt64 {
        if self.isEmpty() {
            let zeroes = 0.toPaddedString() + "\n"
            self.file.write(zeroes.data(using: .utf8)!)
            
        }
        
        let nodeOffset = self.file.seekToEndOfFile()
        
        let encodedTree = try self.encoder.encode(tree)
        
        var dataToWrite = Data()
        dataToWrite.append(encodedTree.count.toPaddedString().data(using: .utf8)!)
        dataToWrite.append(encodedTree)
        dataToWrite.append("\n".data(using: .utf8)!)
        
        self.file.write(dataToWrite)
        
        self.file.seek(toFileOffset: 0)
        self.file.write(nodeOffset.toPaddedString().data(using: .utf8)!)
        
        return nodeOffset
        
    }
    
}

public enum StorageError: Error {
    case unableToCreateStorage
}
