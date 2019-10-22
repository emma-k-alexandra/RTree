public struct RTree<T>
where
    T: SpatialObject
{
    public let root: DirectoryNodeData<T>
    public let size: UInt
    
    static func new(with options: RTreeOptions) -> RTree<T> {
        RTree(root: DirectoryNodeData<T>(depth: 1, options: options), size: 0)
        
    }
    
    public func nearestNeighbor(_ queryPoint: T.Point) -> T? {
        let result = self.root.nearestNeighbor(queryPoint)
        
        if result == nil, self.size == 0 {
            // return self.nearestNeighborIterator(queryPoint).next()
        }
        
        return result
        
    }
    
}
