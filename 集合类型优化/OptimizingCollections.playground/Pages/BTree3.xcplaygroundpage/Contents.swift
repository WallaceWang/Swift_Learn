/*:
 [Previous page](@previous)

 ## 优化对共享存储的插入
 
 
 到目前为止，每当测量插入性能时，我们总是假设我们的有序集合的存储是完全独立的。但是我们从没有测试过如果我们将元素插入使用共享存储的集合中时，会发生什么。
 
 为了了解将数据插入共享存储的性能，让我们来设计一种新的性能测量方式吧！一种办法是在每次插入元素后都对整个集合进行复制，然后测量插入一系列元素所花费的时间：

```swift
extension SortedSet {
    func sharedInsertBenchmark(_ input: [Element]) {
        var set = Self()
        var copy = set
        for value in input {
            set.insert(value)
            copy = set
        }
        _ = copy // 避免变量没有被读取的警告。
    }
}
```

 下图
 展示了对我们到目前为止所实现的 `SortedSet` 进行这一新的性能测试所得到的结果。
 
 ![图 7.4: 向共享存储中进行一次插入操作的平摊时间。](Images/SharedInsertion.png)
 
 显然，我们对 `NSOrderedSet` 的封装并不是为了针对这种滥用的情况而存在的。一旦元素数量达到几千，它的性能就会比 `SortedArray` 慢大约一千倍。不过 `SortedArray` 也没有好多少：为了将存储和复制分离，这两种基于数组的有序集合都需要对存储于其中的每一个值进行完全复制。这不会改变它们的插入操作的渐进性能 (依然是 $O(n)$ )，但却会为其附加上一个相当可观的常数系数。对 `SortedArray` 来说，`sharedInsert` 性能测试要比普通的 `insert` 慢大约 3.5 倍。
 
 两种红黑树的实现表现得好很多：对于每一次插入操作，它们只需要对落在新插入元素的路径上的节点进行复制。`RedBlackTree` 不论何时都会这么做：它的插入性能只和节点是否被共享相关。但是 `RedBlackTree2` 无法使用原地变更：所有的 `isKnownUniquelyReferenced` 的调用都会返回 `false`，所以在这个特别的性能测试中，它比 `RedBlackTree` 要稍微慢一些。
 
 `BTree2` 最初性能相当好，但是在大约 64,000 个元素时，它突然就变慢了。在这个阶段，树即将增长到三层，它的 (第二层) 根节点中包含了太多的元素，以致于创建一份复制的耗时简直可以和插入操作相提并论。随着树变为三层，这个情况将愈发严重，最后它的性能要比红黑树慢 6 倍左右。(`BTree.insert` 的平摊性能保持在  $O(\log n)$，变慢只是因为添加了一个巨大的常数系数。)
 
 我们希望我们的 B 树在所有图里的速度都遥遥领先于红黑树。那我们能做些什么来防止在共享存储的情况下的这种性能衰退吗？问得好，我们当然有办法！
 
 我们推测，变慢是由于大量的内部节点所导致的。我们也知道，树中绝大部分的值都是存储在叶子节点中的，所以内部节点**通常**来说并不会对 B 树性能造成很大影响。在这个前提下，我们可以按照我们的想法来任意改造内部节点，而不必担心它会对性能图表产生什么巨大影响。那么，如果我们大幅限制中间节点的最大尺寸，同时保持叶子节点的尺寸不变，会怎么样呢？
*/
public struct BTree3<Element: Comparable> {
    fileprivate var root: Node

    public init(order: Int) {
        self.root = Node(order: order)
    }
}

extension BTree3 {
    public init() {
        let order = (cacheSize ?? 32768) / (4 * MemoryLayout<Element>.stride)
        self.init(order: Swift.max(16, order))
    }
}

extension BTree3 {
    class Node {
        let order: Int
        var mutationCount: Int64 = 0
        var elementCount: Int = 0
        let elements: UnsafeMutablePointer<Element>
        var children: ContiguousArray<Node> = []

        init(order: Int) {
            self.order = order
            self.elements = .allocate(capacity: order)
        }

        deinit {
            elements.deinitialize(count: elementCount)
            elements.deallocate(capacity: order)
        }
    }
}

extension BTree3 {
    public func forEach(_ body: (Element) throws -> Void) rethrows {
        try root.forEach(body)
    }
}

extension BTree3.Node {
    func forEach(_ body: (Element) throws -> Void) rethrows {
        if isLeaf {
            for i in 0 ..< elementCount {
                try body(elements[i])
            }
        }
        else {
            for i in 0 ..< elementCount {
                try children[i].forEach(body)
                try body(elements[i])
            }
            try children[elementCount].forEach(body)
        }
    }
}

extension BTree3.Node {
    internal func slot(of element: Element) -> (match: Bool, index: Int) {
        var start = 0
        var end = elementCount
        while start < end {
            let mid = start + (end - start) / 2
            if elements[mid] < element {
                start = mid + 1
            }
            else {
                end = mid
            }
        }
        let match = start < elementCount && elements[start] == element
        return (match, start)
    }
}

extension BTree3 {
    public func contains(_ element: Element) -> Bool {
        return root.contains(element)
    }
}

extension BTree3.Node {
    func contains(_ element: Element) -> Bool {
        let slot = self.slot(of: element)
        if slot.match { return true }
        guard !children.isEmpty else { return false }
        return children[slot.index].contains(element)
    }
}

extension BTree3 {
    fileprivate mutating func makeRootUnique() -> Node {
        if isKnownUniquelyReferenced(&root) { return root }
        root = root.clone()
        return root
    }
}

extension BTree3.Node {
    func clone() -> BTree3<Element>.Node {
        let node = BTree3<Element>.Node(order: order)
        node.elementCount = self.elementCount
        node.elements.initialize(from: self.elements, count: self.elementCount)
        if !isLeaf {
            node.children.reserveCapacity(order + 1)
            node.children += self.children
        }
        return node
    }
}

extension BTree3.Node {
    func makeChildUnique(at slot: Int) -> BTree3<Element>.Node {
        guard !isKnownUniquelyReferenced(&children[slot]) else {
            return children[slot]
        }
        let clone = children[slot].clone()
        children[slot] = clone
        return clone
    }
}

extension BTree3.Node {
    var maxChildren: Int { return order }
    var minChildren: Int { return (maxChildren + 1) / 2 }
    var maxElements: Int { return maxChildren - 1 }
    var minElements: Int { return minChildren - 1 }

    var isLeaf: Bool { return children.isEmpty }
    var isTooLarge: Bool { return elementCount > maxElements }
}

extension BTree3 {
    struct Splinter {
        let separator: Element
        let node: Node
    }
}

extension BTree3.Node {
    func split() -> BTree3<Element>.Splinter {
        let count = self.elementCount
        let middle = count / 2
        
        let separator = elements[middle]
        let node = BTree3<Element>.Node(order: self.order)
        
        let c = count - middle - 1
        node.elements.moveInitialize(from: self.elements + middle + 1, count: c)
        node.elementCount = c
        self.elementCount = middle
        
        if !isLeaf {
            node.children.reserveCapacity(self.order + 1)
            node.children += self.children[middle + 1 ... count]
            self.children.removeSubrange(middle + 1 ... count)
        }
        return .init(separator: separator, node: node)
    }
}

extension BTree3.Node {
    fileprivate func _insertElement(_ element: Element, at slot: Int) {
        assert(slot >= 0 && slot <= elementCount)
        (elements + slot + 1).moveInitialize(from: elements + slot, count: elementCount - slot)
        (elements + slot).initialize(to: element)
        elementCount += 1
    }
}

extension BTree3.Node {
    func insert(_ element: Element) -> (old: Element?, splinter: BTree3<Element>.Splinter?) {
        let slot = self.slot(of: element)
        if slot.match {
            // 元素已经在树中。
            return (self.elements[slot.index], nil)
        }
        mutationCount += 1
        if self.isLeaf {
            _insertElement(element, at: slot.index)
            return (nil, self.isTooLarge ? self.split() : nil)
        }
        let (old, splinter) = makeChildUnique(at: slot.index).insert(element)
        guard let s = splinter else { return (old, nil) }
        _insertElement(s.separator, at: slot.index)
        self.children.insert(s.node, at: slot.index + 1)
        return (old, self.isTooLarge ? self.split() : nil)
    }
}
/*:
 要实现这个其实非常简单，我们只需要在 `BTree2.insert` 中进行一行很小的改动即可：
*/
extension BTree3 {
    @discardableResult
    public mutating func insert(_ element: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        let root = makeRootUnique()
        let (old, splinter) = root.insert(element)
        if let s = splinter {
            let root = BTree3<Element>.Node(order: 16) // <--
            root.elementCount = 1
            root.elements.initialize(to: s.separator)
            root.children = [self.root, s.node]
            self.root = root
        }
        return (inserted: old == nil, memberAfterInsert: old ?? element)
    }
}
/*:
 代码块中被标记出来的一行，为树添加了一个新层。我们用来作为新的根节点的阶的数字，也会被用作所有对它进行分割后所得到的节点的阶数。在这里，通过使用一个小的阶数来代替 `self.order`，我们确保了**所有的**内部节点都以这个阶数进行初始化，而不是以原来初始化 `BTree` 时所用的阶数。(新的叶子节点总是由已存在的叶子节点分割而成，所以这个值不会应用于叶子节点。)
*/
extension BTree3 {
    struct UnsafePathElement: Equatable {
        unowned(unsafe) let node: Node
        var slot: Int

        init(_ node: Node, _ slot: Int) {
            self.node = node
            self.slot = slot
        }
        
        var isLeaf: Bool { return node.isLeaf }
        var isAtEnd: Bool { return slot == node.elementCount }
        var value: Element? {
            guard slot < node.elementCount else { return nil }
            return node.elements[slot]
        }
        var child: Node {
            return node.children[slot]
        }

        static func ==(left: UnsafePathElement, right: UnsafePathElement) -> Bool {
            return left.node === right.node && left.slot == right.slot
        }
    }
}

extension BTree3 {
    public struct Index: Comparable {
        fileprivate weak var root: Node?
        fileprivate let mutationCount: Int64

        fileprivate var path: [UnsafePathElement]
        fileprivate var current: UnsafePathElement

        init(startOf tree: BTree3) {
            self.root = tree.root
            self.mutationCount = tree.root.mutationCount
            self.path = []
            self.current = UnsafePathElement(tree.root, 0)
            while !current.isLeaf { push(0) }
        }

        init(endOf tree: BTree3) {
            self.root = tree.root
            self.mutationCount = tree.root.mutationCount
            self.path = []
            self.current = UnsafePathElement(tree.root, tree.root.elementCount)
        }
    }
}

extension BTree3.Index {
    fileprivate func validate(for root: BTree3<Element>.Node) {
        precondition(self.root === root)
        precondition(self.mutationCount == root.mutationCount)
    }

    fileprivate static func validate(_ left: BTree3<Element>.Index, _ right: BTree3<Element>.Index) {
        precondition(left.root === right.root)
        precondition(left.mutationCount == right.mutationCount)
        precondition(left.root != nil)
        precondition(left.mutationCount == left.root!.mutationCount)
    }
}

extension BTree3.Index {
    fileprivate mutating func push(_ slot: Int) {
        path.append(current)
        let child = current.node.children[current.slot]
        current = BTree3<Element>.UnsafePathElement(child, slot)
    }

    fileprivate mutating func pop() {
        current = self.path.removeLast()
    }
}

extension BTree3.Index {
    fileprivate mutating func formSuccessor() {
        precondition(!current.isAtEnd, "Cannot advance beyond endIndex")
        current.slot += 1
        if current.isLeaf {
            while current.isAtEnd, current.node !== root {
                pop()
            }
        }
        else {
            while !current.isLeaf {
                push(0)
            }
        }
    }
}

extension BTree3.Index {
    fileprivate mutating func formPredecessor() {
        if current.isLeaf {
            while current.slot == 0, current.node !== root {
                pop()
            }
            precondition(current.slot > 0, "Cannot go below startIndex")
            current.slot -= 1
        }
        else {
            while !current.isLeaf {
                let c = current.child
                push(c.isLeaf ? c.elementCount - 1 : c.elementCount)
            }
        }
    }
}

extension BTree3.Index {
    public static func ==(left: BTree3<Element>.Index, right: BTree3<Element>.Index) -> Bool {
        BTree3<Element>.Index.validate(left, right)
        return left.current == right.current
    }

    public static func <(left: BTree3<Element>.Index, right: BTree3<Element>.Index) -> Bool {
        BTree3<Element>.Index.validate(left, right)
        switch (left.current.value, right.current.value) {
        case let (a?, b?): return a < b
        case (nil, _): return false
        default: return true
        }
    }
}

extension BTree3: SortedSet {
    public var startIndex: Index { return Index(startOf: self) }
    public var endIndex: Index { return Index(endOf: self) }

    public subscript(index: Index) -> Element {
        get {
            index.validate(for: root)
            return index.current.value!
        }
    }

    public func formIndex(after i: inout Index) {
        i.validate(for: root)
        i.formSuccessor()
    }

    public func index(after i: Index) -> Index {
        i.validate(for: root)
        var i = i
        i.formSuccessor()
        return i
    }

    public func formIndex(before i: inout Index) {
        i.validate(for: root)
        i.formPredecessor()
    }

    public func index(before i: Index) -> Index {
        i.validate(for: root)
        var i = i
        i.formPredecessor()
        return i
    }
}

extension BTree3 {
    public var count: Int {
        return root.count
    }
}

extension BTree3.Node {
    var count: Int {
        return children.reduce(elementCount) { $0 + $1.count }
    }
}

extension BTree3 {
    public struct Iterator: IteratorProtocol {
        let tree: BTree3
        var index: Index

        init(_ tree: BTree3) {
            self.tree = tree
            self.index = tree.startIndex
        }

        public mutating func next() -> Element? {
            guard let result = index.current.value else { return nil }
            index.formSuccessor()
            return result
        }
    }

    public func makeIterator() -> Iterator {
        return Iterator(self)
    }
}
/*:
 我们将这个新版本的 B 树命名为 `BTree3`，运行性能测试，可以得到
 下图中的结果。
 上面的推测是正确的；通过限制内部节点的尺寸，性能得到了很大提升！`BTree3` 现在即使在大数据集的情况下，也比 `RedBlackTree` 快上 2-2.5 倍。(通过这种费力的方式创建一棵含有四百万个元素的 `BTree3` 只需要 15 秒；而 `BTree2` 做同样的事要花 10 倍的时间。)
 
 ![图 7.5: 向共享存储中进行单次插入的平摊时间。](Images/SharedInsertion2.png)
 
 限制内部节点的尺寸通常会增加树的高度，这确实会影响到一部分 B 树的操作。不过，大部分的影响都是可以忽略的：它只会使 `contains` 和原地的 `insert` 变慢约 10%，而且它对迭代方法完全没有影响。比如，
 下图
 比较了 `BTree3` 和我们的其他实现的原地插入操作的性能。
 
 ![图 7.6: 向共享存储中进行单次插入的平摊时间。](Images/Insertion7.png)
 
 比想象的要简单不少，对吧？

 [Next page](@next)
*/