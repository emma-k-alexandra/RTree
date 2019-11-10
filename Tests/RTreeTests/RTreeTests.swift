import XCTest
@testable import RTree

struct Point2D: PointN {
    typealias Scalar = Double
    
    var x: Scalar
    var y: Scalar
    
    init(x: Scalar, y: Scalar) {
        self.x = x
        self.y = y
        
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
                return self.x
                
            } else {
                return self.y
                
            }
            
        }
        set(newValue) {
            if index == 0 {
                self.x = newValue
                
            } else {
                self.y = newValue
                
            }
             
        }
        
    }
    
}

extension Point2D: Equatable {
    static func == (lhs: Point2D, rhs: Point2D) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y
        
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
        pow(self.point.x, 2) + pow(self.point.y, 2)
        
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
        
        try? FileManager.default.removeItem(at: path)
        
    }
    
    func testInsert() throws {
        var path = FileManager.default.temporaryDirectory
        path.appendPathComponent("testRTreeInsert.db")
        
        var tree = try RTree<Element>(path: path)
        
        try tree.insert(Element(point: Point2D(x: 0, y: 0)))
        try tree.insert(Element(point: Point2D(x: 1, y: 1)))
        
        try? FileManager.default.removeItem(at: path)
        
    }
    
    func testLotsOfInserts() throws {
        var path = FileManager.default.temporaryDirectory
        path.appendPathComponent("testRTreeLotsOfInserts.db")
        
        var tree = try RTree<Element>(path: path)
        
        for i in 0..<200 {
            try tree.insert(Element(point: Point2D(x: Double(i), y: Double(i))))
            
        }
        
        try? FileManager.default.removeItem(at: path)
        
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
        
        XCTAssertEqual(try tree.nearestNeighbor(zerozero.point)!, oneone)
        
        try? FileManager.default.removeItem(at: path)
        
    }
    
}
