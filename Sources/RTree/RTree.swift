public struct RTree<T>
where
    T: SpatialObject
{
    public var root: DirectoryNodeData<T>
    public var size: UInt
    
    init() {
        self.root = DirectoryNodeData()
        self.size = 0
        
    }
    
    public func nearestNeighbor(_ queryPoint: T.Point) -> T? {
        let result = self.root.nearestNeighbor(queryPoint)
        
        if result == nil, self.size == 0 {
            var iterator =  self.nearestNeighborIterator(queryPoint)
            
            return iterator.next()
            
        }
        
        return result
        
    }
    
    public func nearestNeighborIterator(_ queryPoint: T.Point) -> NearestNeighborIterator<T> {
        NearestNeighborIterator(root: self.root, queryPoint: queryPoint)
        
    }
    
    public mutating func insert(_ t: T) {
        var state = InsertionState(maxDepth: self.root.depth + 1)
        var insertionStack = [RTreeNode.leaf(t)]
        
        while let next = insertionStack.popLast() {
            switch self.root.insert(next, state: &state) {
            case .split(let node):
                let newDepth = self.root.depth + 1
                let options = self.root.options
                let oldRoot = self.root
                
                self.root = DirectoryNodeData(depth: newDepth, options: options)
                
                var newChildren = [RTreeNode.directoryNode(oldRoot), node]
                self.root.addChildren(&newChildren)
                
            case .reinsert(let nodes):
                insertionStack.append(contentsOf: nodes)
            
            default:
                return
                
            }
            
        }
        
        self.size += 1
        
    }
    
}
