//
//  PointN.swift
//  
//
//  Created by Emma K Alexandra on 10/20/19.
//

import Foundation

public protocol PointN {
    associatedtype Scalar: FloatingPoint
    
    func dimensions() -> UInt;
    
    static func from(value: Scalar) -> Self;
    
    func nth(index: UInt) -> Box<Scalar>;
    
}

extension PointN {
    static func new() -> Self {
        Self.from(value: 0)
    }
    
    func add(_ rhs: Self) -> Self {
        self.componentWise(rhs) { lhs, rhs in
            lhs + rhs

        }

    }

    func subtract(_ rhs: Self) -> Self {
        self.componentWise(rhs) { lhs, rhs in
            lhs - rhs

        }

    }
    
    func divide(_ scalar: Self.Scalar) -> Self {
        self.map { (x) -> Self.Scalar in
            x / scalar
            
        }
        
    }
    
    func multiply(_ scalar: Self.Scalar) -> Self {
        self.map { (x) -> Self.Scalar in
            x * scalar
            
        }
        
    }
    
    func componentWise(_ rhs: Self, map: (Scalar, Scalar) -> Scalar) -> Self {
        let newPoint = self
        
        for i in 0..<self.dimensions() {
            newPoint.nth(index: i).value = map(self.nth(index: i).value, rhs.nth(index: i).value)
        }
        
        return newPoint
        
    }
    
    func map<T: PointN>(_ map: (Scalar) -> T.Scalar) -> T {
        let newPoint = T.new()
        
        for i in 0..<self.dimensions() {
            newPoint.nth(index: i).value = map(self.nth(index: i).value)
            
        }
        
        return newPoint
        
    }
    
    func minPoint(_ rhs: Self) -> Self {
        self.componentWise(rhs) { a, b in
            a < b ? a : b
        }
        
    }
    
    func maxPoint(_ rhs: Self) -> Self {
        self.componentWise(rhs) { a, b in
            a > b ? a : b
        }
        
    }
    
    func fold<T>(_ acc: T, map: (T, Scalar) -> T) -> T {
        var newAcc = acc
        
        for i in 0..<self.dimensions() {
            newAcc = map(acc, self.nth(index: i).value)
        }
        
        return newAcc
        
    }
    
    func allComponentWise(_ rhs: Self, map: (Scalar, Scalar) -> Bool) -> Bool {
        for i in 0..<self.dimensions() {
            if !map(self.nth(index: i).value, rhs.nth(index: i).value) {
                return false
            }
            
        }
        
        return true
        
    }
    
    func dot(_ rhs: Self) -> Scalar {
        self.componentWise(rhs) { l, r in
            l * r
            
        }.fold(0) { acc, value in
            acc + value
            
        }
        
    }
    
    func lengthSquared() -> Scalar {
        self.dot(self)
        
    }
    
    func lexicalCompare(_ other: Self) -> Bool {
        for i in 0..<self.dimensions() {
            let left = self.nth(index: i).value
            let right = other.nth(index: i).value
            
            if left != right {
                return false
            }
        }
        
        return true
        
    }

}

public final class Box<T> {
    var value: T
    
    init(value: T) {
        self.value = value
        
    }
    
}
