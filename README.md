# RTree

RTree is an on-disk, [`Codable`](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types) R*-Tree.

RTree is a port of the Rust crate [`Spade`](https://crates.io/crates/spade)'s N-Dimentional R*-Tree, modified to store the tree on disk rather than in memory. 

## Contents
- [Requirements](#requirements)
- [Installation](#installation)
- [Disclaimer & Warnings](#disclaimer--warnings)
- [Design](#design)
- [Usage](#usage)
    - [Getting Started](#getting-started)
- [Dependencies](#dependencies)
- [Contributing](#contributing)
- [Contact](#contact)
- [Acknowledgements](#acknowledgements)
- [License](#license)

## Requirements
- Swift 5.1+

## Installation

### Swift Package Manager
```swift
dependencies: [
    .package(url: "https://github.com/emma-k-alexandra/RTree.git", from: "2.0.1")
]
```

## Disclaimer & Warnings
RTree performs nearest neighbor searches at the expected speed of a R*-Tree. RTree uses far more space than expected on disk, and inserts are extemely inefficient. RTree does not currently support deletion or updating of records. 

## Design
This R*-Tree is designed to use exclusively Swift, and provide a general interface for doing nearest neighbor queries on N-dimensional objects.

Expect to a implement your own `SpatialObject`-implementing structure and `PointN`-implementing vector type in order to use RTree. For an example, see `RTreeTests.swift` or [Usage](#usage)

## Usage 

### Getting started
First, you need a SpatialObject-implementing type to store in the R-Tree. For demonstration purposes, I will implement a 2-dimensional vector and SpatialObject that will store a custom field.

2-dimensional vector:
```swift
import RTree

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
```

SpatialObject:
```swift
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
```

Then, I'm able to create an R*-Tree that stores `Elements` over `Point2D`:

```swift
var tree = try RTree<Element>(path: path)
let zerozero = Element(point: Point2D(x: 0, y: 0))
let oneone = Element(point: Point2D(x: 1, y: 1))
let threethree = Element(point: Point2D(x: 3, y: 3))

try tree.insert(oneone)
try tree.insert(threethree)

tree.nearestNeighbor(zerozero.point)! == oneone
```

## Dependencies
None

## Contact
Feel free to email questions and comments to [emma@emma.sh](mailto:emma@emma.sh). 

## Acknowledgements
- [Spade](https://crates.io/crates/spade)'s developers and contributors for making a very simple to understand R-Tree implementation that is also (Rust's equivalent to) `Codable`.

## License

RTree is released under the MIT license. [See LICENSE](https://github.com/emma-k-alexandra/RTree/blob/master/LICENSE) for details.
