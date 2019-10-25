import XCTest
@testable import RTree

struct Point2D: PointN {
    typealias Scalar = Double
    
    let x: Box<Scalar>
    let y: Box<Scalar>
    
    init(x: Scalar, y: Scalar) {
        self.x = Box(x)
        self.y = Box(y)
        
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
    
    static func == (lhs: Point2D, rhs: Point2D) -> Bool {
        lhs.x.value == rhs.x.value && lhs.y.value == rhs.y.value
    }
    
}

struct Element: SpatialObject, Equatable {
    typealias Point = Point2D
        
    let point: Point
    let hello = "world"
    
    func minimumBoundingRectangle() -> BoundingRectangle<Point2D> {
        BoundingRectangle(lower: self.point, upper: self.point)
        
    }
    
    func distanceSquared(point: Point2D) -> Double {
        pow(self.point.x.value, 2) + pow(self.point.y.value, 2)
        
    }
    
    static func == (lhs: Element, rhs: Element) -> Bool {
        lhs.point == rhs.point && lhs.hello == rhs.hello
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
        tree.insert(Element(point: Point2D(x: 1, y: 1)))
        
    }
    
    func testLotsOfInserts() {
        var tree = RTree<Element>()
        
        for i in 0..<200 {
            tree.insert(Element(point: Point2D(x: Double(i), y: Double(i))))
            
        }
        
    }
    
    func testNearestNeighbor() {
        var tree = RTree<Element>()
        let zerozero = Element(point: Point2D(x: 0, y: 0))
        let oneone = Element(point: Point2D(x: 1, y: 1))
        
        tree.insert(oneone)
        
        XCTAssertEqual(tree.nearestNeighbor(zerozero.point)!, oneone)
        
    }
    
}
