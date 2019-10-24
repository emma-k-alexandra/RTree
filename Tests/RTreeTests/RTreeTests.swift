import XCTest
@testable import RTree

struct Point2D: PointN {
    typealias Scalar = Double
    
    let x: Box<Scalar>
    let y: Box<Scalar>
    
    init(x: Scalar, y: Scalar) {
        self.x = Box(value: x)
        self.y = Box(value: y)
        
    }
    
    func dimensions() -> UInt {
        2
        
    }
    
    static func from(value: Double) -> Self {
        Point2D(x: value, y: value)
        
    }
    
    func nth(index: UInt) -> Box<Scalar> {
        if index == 0 {
            return self.x
            
        } else {
            return self.y
            
        }
        
    }
    
}

struct Element: SpatialObject {
    typealias Point = Point2D
        
    let point: Point
    let hello = "world"
    
    func minimumBoundingRectangle() -> BoundingRectangle<Point2D> {
        BoundingRectangle(lower: self.point, upper: self.point)
        
    }
    
    func distanceSquared(point: Point2D) -> Double {
        pow(self.point.x.value, 2) + pow(self.point.y.value, 2)
        
    }
    
}

final class RTreeTests: XCTestCase {
    func testInit() {
        let tree = RTree<Element>()
        
        XCTAssertEqual(tree.size, 0)
        
    }
    
    func testInsert() {
        var tree = RTree<Element>()
        
        tree.insert(Element(point: Point2D(x: 0, y: 0)))
        
    }
    
}
