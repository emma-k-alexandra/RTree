//
//  PointN.swift
//  
//
//  Created by Emma K Alexandra on 10/20/19.
//

import Foundation

public protocol PointN: Equatable, Codable {
    associatedtype Scalar: FloatingPoint, Codable
    
    func dimensions() -> Int
    
    static func from(value: Scalar) -> Self
    
    subscript(index: Int) -> Scalar { get set }
    
}

extension PointN {
    public init() {
        self = Self.from(value: 0)
        
    }
    
    public func add(_ rhs: Self) -> Self {
        self.componentWise(rhs) { lhs, rhs in
            lhs + rhs

        }

    }

    public func subtract(_ rhs: Self) -> Self {
        self.componentWise(rhs) { lhs, rhs in
            lhs - rhs

        }

    }
    
    public func divide(_ scalar: Self.Scalar) -> Self {
        self.map { x -> Self.Scalar in
            x / scalar
            
        }
        
    }
    
    public func multiply(_ scalar: Self.Scalar) -> Self {
        self.map { x -> Self.Scalar in
            x * scalar
            
        }
        
    }
    
    public func componentWise(_ rhs: Self, map: (Self.Scalar, Self.Scalar) -> Self.Scalar) -> Self {
        var newPoint = Self()
        
        for i in 0..<self.dimensions() {
            newPoint[i] = map(self[i], rhs[i])
            
        }
        
        return newPoint
        
    }
    
    public func map<T: PointN>(_ map: (Self.Scalar) -> T.Scalar) -> T {
        var newPoint = T()
        
        for i in 0..<self.dimensions() {
            newPoint[i] = map(self[i])
            
        }
        
        return newPoint
        
    }
    
    public func minPoint(_ rhs: Self) -> Self {
        self.componentWise(rhs) { a, b in
            a < b ? a : b
            
        }
        
    }
    
    public func maxPoint(_ rhs: Self) -> Self {
        self.componentWise(rhs) { a, b in
            a > b ? a : b
            
        }
        
    }
    
    public func fold<T>(_ acc: T, map: (T, Scalar) -> T) -> T {
        var newAcc = acc
        
        for i in 0..<self.dimensions() {
            newAcc = map(acc, self[i])
            
        }
        
        return newAcc
        
    }
    
    public func allComponentWise(_ rhs: Self, map: (Scalar, Scalar) -> Bool) -> Bool {
        for i in 0..<self.dimensions() {
            if !map(self[i], rhs[i]) {
                return false
                
            }
            
        }
        
        return true
        
    }
    
    public func dot(_ rhs: Self) -> Scalar {
        self.componentWise(rhs) { l, r in
            l * r
            
        }.fold(0) { acc, value in
            acc + value
            
        }
        
    }
    
    public func lengthSquared() -> Scalar {
        self.dot(self)
        
    }
    
    public func lexicalCompare(_ other: Self) -> Bool {
        for i in 0..<self.dimensions() {
            let left = self[i]
            let right = other[i]
            
            if left != right {
                return false
            }
        }
        
        return true
        
    }

}
