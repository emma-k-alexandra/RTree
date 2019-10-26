//
//  BoundingRectangle.swift
//  
//
//  Created by Emma K Alexandra on 10/20/19.
//

import Foundation

public struct BoundingRectangle<V>: Codable
where
    V: PointN
{
    public var lower: V
    public var upper: V
    
    public func from(point: V) -> Self {
        BoundingRectangle(lower: self.lower, upper: self.upper)
    }
    
    public func from(points: AnyIterator<V>) -> Self {
        guard let firstElement = points.next() else {
            fatalError("Provided iterator of points was empty.")
        }
        
        var rect = self.from(point: firstElement)
        
        for point in points {
            rect.add(point)
            
        }
        
        return rect
        
    }
    
    public func fromCorners(_ firstCorner: V, _ secondCorner: V) -> BoundingRectangle<V> {
        BoundingRectangle(lower: firstCorner.minPoint(secondCorner), upper: firstCorner.maxPoint(secondCorner))
        
    }
    
    public func contains(point: V) -> Bool {
        self.lower.allComponentWise(point) { l, r in
            l <= r
            
        } && self.upper.allComponentWise(point) { l, r in
            r <= l
            
        }
    }
    
    public func contains(rectangle: BoundingRectangle<V>) -> Bool {
        self.lower.allComponentWise(rectangle.lower) { l, r in
            l <= r
            
        } && self.upper.allComponentWise(rectangle.upper) {l ,r in
            r <= l
            
        }
        
    }
    
    public mutating func add(_ point: V) {
        self.lower = self.lower.minPoint(point)
        self.upper = self.upper.maxPoint(point)
        
    }
    
    public mutating func add(_ rectangle: BoundingRectangle<V>) {
        self.lower = self.lower.minPoint(rectangle.lower)
        self.upper = self.upper.maxPoint(rectangle.upper)
        
    }
    
    public func area() -> V.Scalar {
        let diagonal = self.upper.subtract(self.lower)
        return diagonal.fold(1) { (acc, value) -> V.Scalar in
            maxInline(acc * value, 0)
        
        }
        
    }
    
    public func halfMargin() -> V.Scalar {
        let diagonal = self.upper.subtract(self.lower)
        
        return diagonal.fold(1) { (acc, value) -> V.Scalar in
            maxInline(acc + value, 0)
            
        }
        
    }
    
    public func center() -> V {
        self.lower.add(self.upper.subtract(self.lower).divide(2))
        
    }
    
    public func intersect(_ other: BoundingRectangle<V>) -> BoundingRectangle<V> {
        BoundingRectangle(lower: self.lower.maxPoint(other.lower), upper: self.upper.minPoint(other.upper))
        
    }
    
    public func intersects(_ other: BoundingRectangle<V>) -> Bool {
        self.lower.allComponentWise(other.upper) { (l, r) -> Bool in
            l <= r
        } && self.upper.allComponentWise(other.lower) { (l, r) -> Bool in
            l >= r
            
        }
        
    }
    
    public func min(point: V) -> V {
        self.upper.minPoint(self.lower.maxPoint(point))
        
    }
    
    public func minDistanceSquared(_ point: V) -> V.Scalar {
        self.min(point: point).subtract(point).lengthSquared()
        
    }
    
    public func maxDistanceSquared(_ point: V) -> V.Scalar {
        let d1: V = self.lower.subtract(point).map { (v) -> V.Scalar in
            abs(v)
        }
        
        let d2: V = self.upper.subtract(point).map { (v) -> V.Scalar in
            abs(v)
            
        }
        
        return d1.maxPoint(d2).lengthSquared()
        
    }
    
    public func minMaxDistanceSquared(_ point: V) -> V.Scalar {
        let l = self.lower.subtract(point)
        let u = self.upper.subtract(point)
        
        let min = V.new()
        let max = V.new()
        
        for i in 0..<point.dimensions() {
            if abs(l.nth(index: i).value) < abs(u.nth(index: i).value) {
                min.nth(index: i).value = l.nth(index: i).value
                max.nth(index: i).value = u.nth(index: i).value
                
            } else {
                min.nth(index: i).value = u.nth(index: i).value
                max.nth(index: i).value = l.nth(index: i).value
                
            }
            
        }
        
        let result: V.Scalar = 0
        
        for i in 0..<point.dimensions() {
            let p = min
            
            p.nth(index: i).value = max.nth(index: i).value
            let newDistance = p.lengthSquared()
            
            if newDistance < result || i == 0 {
                return newDistance
                
            }
            
        }
        
        return result
        
    }
    
}

extension BoundingRectangle: SpatialObject {
    public func minimumBoundingRectangle() -> BoundingRectangle<V> {
        self
        
    }
    
    public func distanceSquared(point: V) -> V.Scalar {
        self.minDistanceSquared(point)
        
    }
    
}

extension BoundingRectangle: Equatable {
    public static func == (lhs: BoundingRectangle<V>, rhs: BoundingRectangle<V>) -> Bool {
        lhs.contains(rectangle: rhs) && rhs.contains(rectangle: lhs)
        
    }
    
    
}
