//
//  BoundingRectangle.swift
//  
//
//  Created by Emma K Alexandra on 10/20/19.
//

import Foundation

/// An axis aligned minimal bounding rectangle (MBR)
/// An axis aligned minimal bounding rectangle is the smallest rectangle that completely
/// surrounds an object and is aligned along all axes. The vector type `V`'s dimension
/// determines if this is a rectangle, a box or a higher dimensional volume.
public struct BoundingRectangle<V>: Codable
where
    V: PointN
{
    /// Lower range of this MBR
    public var lower: V
    
    /// Upper range of this MBR
    public var upper: V
    
    /// Creates a bounding rectangle that contains exactly one point.
    ///
    /// This will create a bounding rectangle with `lower == upper == point`.
    public func from(point: V) -> Self {
        BoundingRectangle(lower: self.lower, upper: self.upper)
    }
    
    /// Create a bounding rectangle from a set of points
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
    
    /// Creates a bounding rectangle that contains two points
    public func fromCorners(_ firstCorner: V, _ secondCorner: V) -> BoundingRectangle<V> {
        BoundingRectangle(lower: firstCorner.minPoint(secondCorner), upper: firstCorner.maxPoint(secondCorner))
        
    }
    
    /// Checks if a point is contained within the bounding rectangle
    public func contains(point: V) -> Bool {
        self.lower.allComponentWise(point) { l, r in
            l <= r
            
        } && self.upper.allComponentWise(point) { l, r in
            r <= l
            
        }
    }
    
    /// Check if another bounding rectangle is completely contained within this rectangle
    public func contains(rectangle: BoundingRectangle<V>) -> Bool {
        self.lower.allComponentWise(rectangle.lower) { l, r in
            l <= r
            
        } && self.upper.allComponentWise(rectangle.upper) {l ,r in
            r <= l
            
        }
        
    }
    
    /// Enlarges this bounding rectangle to contain a point.
    /// If the point is already contained, nothing will be changed.
    /// Otherwise, this will enlarge `self` to be just large enough
    /// to contain the new point.
    public mutating func add(_ point: V) {
        self.lower = self.lower.minPoint(point)
        self.upper = self.upper.maxPoint(point)
        
    }
    
    /// Enlarges this bounding rectangle to contain a rectangle.
    ///
    /// If the rectangle is already contained, nothing will be changed.
    /// Otherwise, this will enlarge `self` to be just large enough
    /// to contain the new rectangle.
    public mutating func add(_ rectangle: BoundingRectangle<V>) {
        self.lower = self.lower.minPoint(rectangle.lower)
        self.upper = self.upper.maxPoint(rectangle.upper)
        
    }
    
    /// Returns the rectangle's area
    public func area() -> V.Scalar {
        let diagonal = self.upper.subtract(self.lower)
        return diagonal.fold(1) { (acc, value) -> V.Scalar in
            maxInline(acc * value, 0)
        
        }
        
    }
    
    /// Returns half of the rectangle's margin, thus `width + height`
    public func halfMargin() -> V.Scalar {
        let diagonal = self.upper.subtract(self.lower)
        
        return diagonal.fold(1) { (acc, value) -> V.Scalar in
            maxInline(acc + value, 0)
            
        }
        
    }
    
    /// Returns the rectangle's center
    public func center() -> V {
        let result = self.lower.add(self.upper.subtract(self.lower).divide(2))
        
        return result
        
    }
    
    /// Returns the intersection of this and another bounding rectangle.
    ///
    /// If the rectangles do not intersect, a bounding rectangle with an area and
    /// margin of zero is returned.
    public func intersect(_ other: BoundingRectangle<V>) -> BoundingRectangle<V> {
        BoundingRectangle(lower: self.lower.maxPoint(other.lower), upper: self.upper.minPoint(other.upper))
        
    }
    
    /// Returns true if this and another bounding rectangle intersect each other.
    /// If the rectangles just "touch" each other at one side, true is returned.
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
        
        var min = V()
        var max = V()
        
        for i in 0..<point.dimensions() {
            if abs(l[i]) < abs(u[i]) {
                min[i] = l[i]
                max[i] = u[i]
                
            } else {
                min[i] = u[i]
                max[i] = l[i]
                
            }
            
        }
        
        let result: V.Scalar = 0
        
        for i in 0..<point.dimensions() {
            var p = min
            
            p[i] = max[i]
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
