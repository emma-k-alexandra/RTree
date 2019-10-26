//
//  SpatialObject.swift
//  
//
//  Created by Emma K Alexandra on 10/20/19.
//

public protocol SpatialObject: Codable {
    associatedtype Point: PointN
    
    func minimumBoundingRectangle() -> BoundingRectangle<Point>
    
    func distanceSquared(point: Point) -> Point.Scalar
    
    func contains(point: Point) -> Bool
    
}

extension SpatialObject {
    func contains(point: Point) -> Bool {
        self.distanceSquared(point: point) <= Point.Scalar.zero
        
    }
    
}
