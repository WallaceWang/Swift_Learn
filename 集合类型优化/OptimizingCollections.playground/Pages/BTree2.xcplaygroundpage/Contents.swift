/*:
 [Previous page](@previous)

 # 额外优化
 
 在本章中，我们将集中讨论一下如何进一步优化 `BTree.insert`，并努力将代码最后的潜力挖掘出来。
 
 我们会创建另外三种 `SortedSet` 的实现，并“开创性”地将它们命名为 `BTree2`，`BTree3` 和 `BTree4`。为了让本书保持在合理的长度，我们将不会把这三个版本的 B 树的完整代码写出来，只会通过一些具有代表性的代码片段来描述发生的改变。如果你想要参考所有三个版本的 B 树的完整源码，可以去看一看本书的 [GitHub 仓库][bookrepo]。
 
 [bookrepo]: https://github.com/objcio/OptimizingCollections
 
 如果你已经对 `SortedSet` 感到厌倦了，跳过本章也没问题。因为这里描述的一些进阶技巧在日常的 app 开发中很少会被用到。
 
 ## 内联 `Array` 方法
 
 
 `BTree` 将元素和 `Node` 的子节点存储在标准的 `Array` 中。在上一章里，这使得代码相对容易理解，也对我们认识 B 树起到了帮助。然而，`Array` 中包含了索引验证和写时复制的逻辑，这和 `BTree` 中的相关逻辑重复了。如果我们的代码没有任何问题，那么 `BTree` 将永远不会使用越界的下标访问数组，而且 B 树自己也实现了写时复制的行为。
 
 看看我们的
 插入性能测试图表，
 可以看到，当集合尺寸相对较小时，虽然 `BTree.insert` 已经十分接近 `SortedArray.insert` 了，但它们之间仍然有 10%-20% 的性能差距。消除 `Array` 的 (微小) 开销是否足以填补这个性能差距？让我们试试看吧！
 
 ![图 7.1: 对比五种不同 `SortedSet.insert` 实现的性能。](Images/Insertion5.png)
 
 Swift 标准库中包含了 `UnsafeMutablePointer` 和 `UnsafeMutableBufferPointer` 类型，我们可以用它们来实现我们自己的存储缓冲区。它们的名字有些可怕，但却名符其实。和这些类型打交道只比和 C 指针打交道好那么一点点，代码上差之毫厘，往往导致结果谬以千里，稍有不慎可能就会造成难以调试的内存污染，内存泄漏，甚至是更糟糕的问题。换个角度来看，如果我们能够细心谨慎地使用这些类型，也许可以通过使用这些类型让我们的性能得到稍许提升。
 
 <!-- begin-exclude-from-preview -->
 
 那么让我们开始写 `BTree2` 吧，这是我们第二次尝试实现 B 树。作为开始的是一些人畜无害的代码：
*/
public struct BTree2<Element: Comparable> {
    fileprivate var root: Node

    public init(order: Int) {
        self.root = Node(order: order)
    }
}
extension BTree2 {
    public init() {
        let order = (cacheSize ?? 32768) / (4 * MemoryLayout<Element>.stride)
        self.init(order: Swift.max(16, order))
    }
}
/*:
 不过这次，在 `Node` 中，我们将 `elements` 数组转换为了一个不安全的可变指针，这个指针指向一个手动申请的缓冲区的起始位置。因为指针并不会自己去追踪计数，所以我们还需要添加一个存储属性，用来表示当前缓冲区内的元素个数：
*/
extension BTree2 {
    class Node {
        let order: Int
        var mutationCount: Int64 = 0
        var elementCount: Int = 0
        let elements: UnsafeMutablePointer<Element>
        var children: ContiguousArray<Node> = []
/*:
 在 `BTree2` 中，我们不打算动 `children`，它将保持依然是一个数组。虽然我们将 `children` 的类型从 `Array` 改成了有时候会稍微快一些的 `ContiguousArray`，但本质上它依然是数组。因为绝大多数元素都存在于叶子节点中，所以加速中间节点很可能无法得到站在全局可以观察到的改进，我们最好不要在优化中间节点上花太大力气。
 
 `Node` 的指定初始化方法 (designated initializer) 负责为我们的元素缓冲区申请内存。我们会申请能存放下 `order` 个数元素的空间，这样，缓冲区能够持有的元素个数将会比我们允许的最大尺寸多一。这非常重要，如此一来，在我们对节点进行分割之前，就可以让节点暂时超出最大个数这一限制：
*/
        init(order: Int) {
            self.order = order
            self.elements = .allocate(capacity: order)
        }
/*:
 在前面的章节中，我们没有使用 `Array.reserveCapacity(_:)` 来预先为我们的两个数组申请存储空间，而是依赖了 `Array` 的自动存储管理。这会让代码简单一些，但同时也导致了两个不太理想的结果。第一，当我们将一个新的元素插入到 `BTree` 节点中时，有时候 `Array` 会需要申请一个全新且更大的缓冲区，并将已经存在的元素移动到新的缓冲区里去。这会给插入操作带来一些额外的开销。第二，`Array` 在扩大存储缓冲区时，是以 2 的幂次关系递增的，也就是说，有可能树的阶仅仅只是“稍微”比某个值大了一点，但 `Array` 申请的空间却了比整份代码所需要的多出了 50%。可以通过申请正好和结点的最大尺寸相同的缓冲区，来同时避免这两个问题。
 
 因为我们是手动申请的缓冲区，自然还需要在某个时间点手动释放它们。自定义的 `deinit` 方法是进行这个操作最好的地方：
*/
        deinit {
            elements.deinitialize(count: elementCount)
            elements.deallocate(capacity: order)
        }
    }
}
/*:
 注意，我们必须对元素占用的内存进行明确的逆初始化 (deinitialize)，即，在回收内存之前将缓冲区恢复到最初的未初始化状态。这可以保证在 `Element` 值中可能存在的引用被正确释放，甚至可能让那些仅由缓冲区持有的值被正确回收。要是没有逆初始化这些值，有可能会导致内存泄漏：
*/
extension BTree2 {
    public func forEach(_ body: (Element) throws -> Void) rethrows {
        try root.forEach(body)
    }
}

extension BTree2.Node {
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

extension BTree2.Node {
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

extension BTree2 {
    public func contains(_ element: Element) -> Bool {
        return root.contains(element)
    }
}

extension BTree2.Node {
    func contains(_ element: Element) -> Bool {
        let slot = self.slot(of: element)
        if slot.match { return true }
        guard !children.isEmpty else { return false }
        return children[slot.index].contains(element)
    }
}

extension BTree2 {
    fileprivate mutating func makeRootUnique() -> Node {
        if isKnownUniquelyReferenced(&root) { return root }
        root = root.clone()
        return root
    }
}
/*:
 对节点的复制操作可以很好地诠释 `elements` 缓冲区的用法。我们调用 `initialize(from:count:)` 方法来将数据在缓冲区之间进行复制，它会在需要的时候负责更新引用计数。如果节点是一个内部节点，我们也可以通过在新的节点的 `children` 数组上调用 `reserveCapacity(_:)` 来预先申请足够的空间，以容纳我们可能会需要的子节点。如果不是内部节点，我们将会保持 `children` 为空，这样就不会因为永远不会用到的存储而浪费内存空间了：
  
*/
extension BTree2.Node {
    func clone() -> BTree2<Element>.Node {
        let node = BTree2<Element>.Node(order: order)
        node.elementCount = self.elementCount
        node.elements.initialize(from: self.elements, count: self.elementCount)
        if !isLeaf {
            node.children.reserveCapacity(order + 1)
            node.children += self.children
        }
        return node
    }
}
extension BTree2.Node {
    func makeChildUnique(at slot: Int) -> BTree2<Element>.Node {
        guard !isKnownUniquelyReferenced(&children[slot]) else {
            return children[slot]
        }
        let clone = children[slot].clone()
        children[slot] = clone
        return clone
    }
}

extension BTree2.Node {
    var maxChildren: Int { return order }
    var minChildren: Int { return (maxChildren + 1) / 2 }
    var maxElements: Int { return maxChildren - 1 }
    var minElements: Int { return minChildren - 1 }

    var isLeaf: Bool { return children.isEmpty }
    var isTooLarge: Bool { return elementCount > maxElements }
}

extension BTree2 {
    struct Splinter {
        let separator: Element
        let node: Node
    }
}
/*:
 在插入中我们所需要的 `split()` 操作也能受益于 `UnsafeMutablePointer` 对移动初始化 (move initialization) 的支持。在原来的代码里，为了移动元素，我们需要两个步骤：首先将它们复制到新的数组中，然后再将它们从原来的数组中删除。当 `Element` 包含带有引用计数的值的时候，这种合二为一的移动操作会快得多。(不过对于像是 `Int` 这样的简单值类型来说，产生的性能影响是微乎其微的。)
*/
extension BTree2.Node {
    func split() -> BTree2<Element>.Splinter {
        let count = self.elementCount
        let middle = count / 2
        
        let separator = elements[middle]
        let node = BTree2<Element>.Node(order: self.order)
        
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
/*:
 要将一个新元素插入到缓冲区的中间，我们需要实现与 `Array.insert` 等效的方法。要做到这一点，我们首先要从插入点开始，将已有的元素向右移动一个位置，为新元素腾出空间：
*/
extension BTree2.Node {
    fileprivate func _insertElement(_ element: Element, at slot: Int) {
        assert(slot >= 0 && slot <= elementCount)
        (elements + slot + 1).moveInitialize(from: elements + slot, count: elementCount - slot)
        (elements + slot).initialize(to: element)
        elementCount += 1
    }
}
/*:
 为了让原来的 `insert` 代码在 `BTree2` 中也可以使用，我们需要做一些适配工作：
*/
extension BTree2.Node {
    func insert(_ element: Element) -> (old: Element?, splinter: BTree2<Element>.Splinter?) {
        let slot = self.slot(of: element)
        if slot.match {
            // 元素已经在树中
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

extension BTree2 {
    @discardableResult
    public mutating func insert(_ element: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        let root = makeRootUnique()
        let (old, splinter) = root.insert(element)
        if let s = splinter {
            let root = BTree2<Element>.Node(order: root.order)
            root.elementCount = 1
            root.elements.initialize(to: s.separator)
            root.children = [self.root, s.node]
            self.root = root
        }
        return (inserted: old == nil, memberAfterInsert: old ?? element)
    }
}
extension BTree2 {
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

extension BTree2 {
    public struct Index: Comparable {
        fileprivate weak var root: Node?
        fileprivate let mutationCount: Int64

        fileprivate var path: [UnsafePathElement]
        fileprivate var current: UnsafePathElement

        init(startOf tree: BTree2) {
            self.root = tree.root
            self.mutationCount = tree.root.mutationCount
            self.path = []
            self.current = UnsafePathElement(tree.root, 0)
            while !current.isLeaf { push(0) }
        }

        init(endOf tree: BTree2) {
            self.root = tree.root
            self.mutationCount = tree.root.mutationCount
            self.path = []
            self.current = UnsafePathElement(tree.root, tree.root.elementCount)
        }
    }
}

extension BTree2.Index {
    fileprivate func validate(for root: BTree2<Element>.Node) {
        precondition(self.root === root)
        precondition(self.mutationCount == root.mutationCount)
    }

    fileprivate static func validate(_ left: BTree2<Element>.Index, _ right: BTree2<Element>.Index) {
        precondition(left.root === right.root)
        precondition(left.mutationCount == right.mutationCount)
        precondition(left.root != nil)
        precondition(left.mutationCount == left.root!.mutationCount)
    }
}

extension BTree2.Index {
    fileprivate mutating func push(_ slot: Int) {
        path.append(current)
        let child = current.node.children[current.slot]
        current = BTree2<Element>.UnsafePathElement(child, slot)
    }

    fileprivate mutating func pop() {
        current = self.path.removeLast()
    }
}

extension BTree2.Index {
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

extension BTree2.Index {
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

extension BTree2.Index {
    public static func ==(left: BTree2<Element>.Index, right: BTree2<Element>.Index) -> Bool {
        BTree2<Element>.Index.validate(left, right)
        return left.current == right.current
    }

    public static func <(left: BTree2<Element>.Index, right: BTree2<Element>.Index) -> Bool {
        BTree2<Element>.Index.validate(left, right)
        switch (left.current.value, right.current.value) {
        case let (a?, b?): return a < b
        case (nil, _): return false
        default: return true
        }
    }
}

extension BTree2: SortedSet {
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

extension BTree2 {
    public var count: Int {
        return root.count
    }
}

extension BTree2.Node {
    var count: Int {
        return children.reduce(elementCount) { $0 + $1.count }
    }
}

extension BTree2 {
    public struct Iterator: IteratorProtocol {
        let tree: BTree2
        var index: Index

        init(_ tree: BTree2) {
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
 要创建一个 `BTree2`，原则上我们要将 `Array` 的实现从标准库中拿出来，移除掉不需要的功能，并把它内嵌到我们的 B 树代码中。
 
 性能测试的结果如下图所示。
 插入操作的速度稳定地提升了 10-20%。我们填补上了 B 树和 `SortedArray` 之间最后的性能差距：至此，`BTree2.insert` 在全范围内的性能持平或是超越了所有之前的 `SortedSet` 实现。
 
 ![图 7.2: 对比六种 `SortedSet` 实现的插入性能。](Images/Insertion6.png)
 
 作为额外收益，移除 `Array` 的索引验证检查，让迭代的性能也提高了两倍；
 参见下图。
 `BTree2.for-in` 现在只比 `SortedArray` 慢四倍了；这是一个很显著的进步！
 
 ![图 7.3: 对比六种 `SortedSet` 实现的迭代性能。](Images/Iteration6.png)
 
 <!-- end-exclude-from-preview -->

 [Next page](@next)
*/