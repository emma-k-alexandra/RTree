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
    
    func dimensions() -> Int {
        2
        
    }
    
    static func from(value: Double) -> Self {
        Point2D(x: value, y: value)
        
    }
    
    subscript(index: Int) -> Scalar {
        get {
            if index == 0 {
                return self.x.value
                
            } else {
                return self.y.value
                
            }
            
        }
        set(newValue) {
            if index == 0 {
                self.x.value = newValue
                
            } else {
                self.y.value = newValue
                
            }
             
        }
        
    }
    
}

extension Point2D: Equatable {
    static func == (lhs: Point2D, rhs: Point2D) -> Bool {
        lhs.x.value == rhs.x.value && lhs.y.value == rhs.y.value
        
    }
    
}

struct Element: SpatialObject {
    typealias Point = Point2D
        
    let point: Point
    let hello = "world"
    
    func minimumBoundingRectangle() -> BoundingRectangle<Point2D> {
        return BoundingRectangle(lower: self.point, upper: self.point)
        
    }
    
    func distanceSquared(point: Point2D) -> Double {
        pow(self.point.x.value, 2) + pow(self.point.y.value, 2)
        
    }
    
}

extension Element: Equatable {
    static func == (lhs: Element, rhs: Element) -> Bool {
        lhs.point == rhs.point && lhs.hello == rhs.hello
        
    }
    
}

@available(OSX 10.12, *)
final class RTreeTests: XCTestCase {
    func testInit() throws {
        var path = FileManager.default.temporaryDirectory
        path.appendPathComponent("testRTreeInit.db")
        
        let tree = try RTree<Element>(path: path)
        
        XCTAssertEqual(tree.size, 0)
        
    }
    
    func testInsert() throws {
        var path = FileManager.default.temporaryDirectory
        path.appendPathComponent("testRTreeInsert.db")
        
        var tree = try RTree<Element>(path: path)
        
        try tree.insert(Element(point: Point2D(x: 0, y: 0)))
        try tree.insert(Element(point: Point2D(x: 1, y: 1)))
        
    }
    
    func testLotsOfInserts() throws {
        var path = FileManager.default.temporaryDirectory
        path.appendPathComponent("testRTreeLotsOfInserts.db")
        
        var tree = try RTree<Element>(path: path)
        
        for i in 2..<200 {
            try tree.insert(Element(point: Point2D(x: Double(i), y: Double(i))))
            
        }
        
    }
    
    func testNearestNeighbor() throws {
        var path = FileManager.default.temporaryDirectory
        path.appendPathComponent("testRTreeNearestNeighbor.db")
        
        var tree = try RTree<Element>(path: path)
        let zerozero = Element(point: Point2D(x: 0, y: 0))
        let oneone = Element(point: Point2D(x: 1, y: 1))
        let threethree = Element(point: Point2D(x: 3, y: 3))
        
        try tree.insert(oneone)
        try tree.insert(threethree)
        
        XCTAssertEqual(tree.nearestNeighbor(zerozero.point)!, oneone)
        
    }
    
}
