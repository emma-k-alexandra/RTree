//
//  Utilities.swift
//  
//
//  Created by Emma K Alexandra on 10/20/19.
//

import Foundation

func maxInline<T: FloatingPoint>(_ a: T, _ b: T) -> T {
    if a < b {
        return a
        
    } else {
        return b
        
    }
    
}

func minInline<T: FloatingPoint>(_ a: T, _ b: T) -> T {
    if a > b {
        return a
        
    } else {
        return b
        
    }
    
}

/// To convert large unsigned ints to 0 padded strings
extension UInt64 {
    func toPaddedString() -> String {
        return String(format: "%019ld", self)
        
    }
    
}

/// To convert ints to 0 padded strings
extension Int {
    func toPaddedString() -> String {
        return String(format: "%019d", self)
        
    }
    
}

extension Array {
    mutating func mutatingAppend(_ array: inout Array) {
        self.append(contentsOf: array)
        array = []
        
    }
    
    func splitAt(_ middle: Int) -> (Array, Array) {
        let left = Array(self[...middle])
        let right = Array(self[middle...])
        
        return (left, right)
        
    }
    
    mutating func splitOff(at: Int) -> Array {
        assert(at <= self.count, "`at` is out of bounds")
        
        let other = Array(self[at...])
        
        self = Array(self[...at])
        
        return other
        
    }
    
}
