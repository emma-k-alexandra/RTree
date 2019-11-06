//
//  SpatialObject.swift
//  
//
//  Created by Emma K Alexandra on 10/20/19.
//
/// Describes objects that can be located by r-trees.
public protocol SpatialObject: Codable {
    
    /// The object's point type
    associatedtype Point: PointN
    
    /// Returns the object's minimal bounding rectangle
    /// The minimal bounding rectangle is the smallest axis aligned rectangle that completely
    /// contains the object.
    /// _Note_: The rectangle must be as small as possible, otherwise some queries
    /// might fail.
    func minimumBoundingRectangle() -> BoundingRectangle<Point>
    
    /// Returns the squared euclidean distance from the object's contour.
    /// Returns a value samller than zero if the point is contained within the object.
    func distanceSquared(point: Point) -> Point.Scalar
    
    /// Returns true if the given point is contained in this project
    func contains(point: Point) -> Bool
    
}

extension SpatialObject {
    func contains(point: Point) -> Bool {
        self.distanceSquared(point: point) <= Point.Scalar.zero
        
    }
    
}
