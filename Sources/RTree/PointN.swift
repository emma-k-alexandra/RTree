//
//  PointN.swift
//  
//
//  Created by Emma K Alexandra on 10/20/19.
//

import Foundation

/// Protocol for vectors stored in the tree
public protocol PointN: Equatable, Codable {
    
    /// The point's internal scalar type
    associatedtype Scalar: FloatingPoint, Codable
    
    /// The (fixed) number of dimentions of this point type
    func dimensions() -> Int
    
    /// Creates a new point with all components set to a certain value
    static func from(value: Scalar) -> Self
    
    /// Get/set the nth element of this point
    subscript(index: Int) -> Scalar { get set }
    
}

extension PointN {
    /// Creates a new point with components initialized to zero.
    public init() {
        self = Self.from(value: 0)
        
    }
    
    /// Adds two points
    public func add(_ rhs: Self) -> Self {
        self.componentWise(rhs) { lhs, rhs in
            lhs + rhs

        }

    }

    /// Subtracts two points
    public func subtract(_ rhs: Self) -> Self {
        self.componentWise(rhs) { lhs, rhs in
            lhs - rhs

        }

    }
    
    /// Divides this point with a scalar value
    public func divide(_ scalar: Self.Scalar) -> Self {
        self.map { x -> Self.Scalar in
            x / scalar
            
        }
        
    }
    
    /// Multiplies this point with a scalar value
    public func multiply(_ scalar: Self.Scalar) -> Self {
        self.map { x -> Self.Scalar in
            x * scalar
            
        }
        
    }
    
    /// Applies a binary operation component wise
    public func componentWise(_ rhs: Self, map: (Self.Scalar, Self.Scalar) -> Self.Scalar) -> Self {
        var newPoint = Self()
        
        for i in 0..<self.dimensions() {
            newPoint[i] = map(self[i], rhs[i])
            
        }
        
        return newPoint
        
    }
    
    /// Maps a unary operations to all components
    public func map<T: PointN>(_ map: (Self.Scalar) -> T.Scalar) -> T {
        var newPoint = T()
        
        for i in 0..<self.dimensions() {
            newPoint[i] = map(self[i])
            
        }
        
        return newPoint
        
    }
    
    /// Returns a new point containing the minimum values of this and another point (component wise)
    public func minPoint(_ rhs: Self) -> Self {
        self.componentWise(rhs) { a, b in
            a < b ? a : b
            
        }
        
    }
    
    /// Returns a new point containing the maximum values of this and another point (component wise)
    public func maxPoint(_ rhs: Self) -> Self {
        self.componentWise(rhs) { a, b in
            a > b ? a : b
            
        }
        
    }
    
    /// Fold operation over all points components
    public func fold<T>(_ acc: T, map: (T, Scalar) -> T) -> T {
        var newAcc = acc
        
        for i in 0..<self.dimensions() {
            newAcc = map(acc, self[i])
            
        }
        
        return newAcc
        
    }
    
    /// Checks if a property holds for all components of this and another point.
    public func allComponentWise(_ rhs: Self, map: (Scalar, Scalar) -> Bool) -> Bool {
        for i in 0..<self.dimensions() {
            if !map(self[i], rhs[i]) {
                return false
                
            }
            
        }
        
        return true
        
    }
    
    /// Returns the point's dot product
    public func dot(_ rhs: Self) -> Scalar {
        self.componentWise(rhs) { l, r in
            l * r
            
        }.fold(0) { acc, value in
            acc + value
            
        }
        
    }
    
    /// Returns the point's squared length
    public func lengthSquared() -> Scalar {
        self.dot(self)
        
    }
    
    /// Lexically compares this point to a given one
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
