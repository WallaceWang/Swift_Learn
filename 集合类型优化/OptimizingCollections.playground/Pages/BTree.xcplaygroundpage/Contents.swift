/*:
 [Previous page](@previous)

 # B 树
 
 
 小尺寸 `SortedArray` 的原生性能看起来几乎不可能挑战。所以我们也就不再争取了，不如另辟蹊径，尝试通过这些高性能的小尺寸有序数组来构建一个有序集合！
 
 一开始非常简单：我们只需要将元素插入到单个数组，直到达到预先规定的元素上限。比如说我们想要将数组的长度保持在四以内，而现在已经插入了四个元素：
 
 ![](Images/BTree1@3x.png)
 
 如果我们此时需要插入 10，那么数组长度就会超过规定：
 
 ![](Images/BTree2@3x.png)
 
 我们需要采取一些行动来避免这样的事情发生。一种选择是将数组分割为两半，然后使用中间的那个元素作为两边的分隔元素：
 
 ![](Images/BTree3@3x.png)
 
 现在，我们有了一个小巧的树形结构，它的叶子节点包含了小尺寸的有序数组。看起来这是一种很有前途的方式：它将有序数组和搜索树合并到了一个统合的数据结构中，这有希望给在小尺寸时给我们带来数组那样超级快的插入操作，同时在大数据集中保持树那样的对数性能。
 
 让我们看看如果继续添加更多元素会发生什么。我们将继续向两个叶子数组中添加新值，直到某一个再次超过范围：
 
 ![](Images/BTree4@3x.png)
 
 当这种情况发生时，我们需要再进行一次分割，这将给我们带来三个数组以及两个分隔的元素：
 
 ![](Images/BTree5@3x.png)
 
 对这两个分隔的值，我们应该做些什么呢？我们已经将其他所有元素放在有序数组中了，所以看起来把分隔值也放到它们自己的有序数组里会是个明智的选择：
 
 ![](Images/BTree6@3x.png)
 
 很显然，新的混合数组树中的每个节点都持有一个小尺寸有序数组。到目前为止，我很喜欢这个想法，它优雅而且一致。
 
 接下来，如果我们想要插入 20 这个值的话，会怎么样呢？它会被放到最右侧的数组中去，不过那里已经有四个元素了，所以我们需要再进行一次分割，将中间值 16 提取出来，成为新的分隔元素。小菜一碟，我们只要将它插入到顶端的数组里就行了：
 
 ![](Images/BTree7@3x.png)
 
 很好，让我们继续，在插入 25、26 和 27 之后，最右侧的数组又溢出了，于是我们再次提取新的分隔元素，这次是 25:
 
 ![](Images/BTree8@3x.png)
 
 不过，现在顶端的数组也满了。如果我们接着插入 18、21 和 22，等待我们的便是下面的情况：
 
 ![](Images/BTree9@3x.png)
 
 接下来怎么办呢？我们可不能放任这个分隔数组就这样膨胀下去。之前，我们通过分割溢出的数组来解决这个问题，这里我们完全可以如法炮制。
 
 ![](Images/BTree10@3x.png)
 
 
 哈，完美：通过分割第二层的数组，我们可以在树上添加第三层数组。这让我们可以无限地添加新的元素，当第三层的数组被填满时，我们将添加第四层，以此类推，以至无穷：
 
 ![](Images/BTree11@3x.png)
 
 我们刚刚发明了一种全新的数据结构！这是历史性的时刻！
 
 但是高兴得太早了，其实 Rudolf Bayer 和 Ed McCreight 早在 1971 年就提出过[一样的想法][bayer72]，他们将这个发明命名为 **B 树**。真是晴天霹雳，我花了一整本书来介绍一个东西，但是你却告诉我这玩意半个世纪之前就有了，简直悲剧。
 
 有趣的事实是：红黑树实际上是在 1978 年衍生出来的一种 B 树的特殊形式。这些数据结构都经历了岁月的洗礼。
 
 [bayer72]: https://dx.doi.org/10.1007%2Fbf00288683
 
 ## B 树的特性
 
 正如我们所见，**B 树**和红黑树一样，都是搜索树，但是它们的结构却有所不同。在 B 树中，节点可能会拥有成百甚至上千的子节点，而不仅仅是两个。不过子节点的个数也并非完全没有限制：节点数肯定会落在某个范围内。
 
 每个节点的最大子节点数在树创建的时候就已经决定了，这个值被叫做 B 树的“**阶**”。(阶的英文和顺序一样，都是 order，但是阶和元素的顺序无关。) 注意，节点中能存放的元素的最大数量要比它的阶的数字小一。这很可能会导致计算索引时发生差一错误，所以当我们在实现和使用 B 树的时候，一定要将此铭记于心。
 
 在上面，我们构建了一棵阶为 5 的 B 树。实际运用中，阶通常介于 100 到 2,000 之间，5 可以说是小的非同寻常。不过，有 1,000 个子节点的节点没法在页面上表示出来，使用一个能画出来的例子能让我们更容易地理解 B 树。
 
 为了能在树中定位元素，每个内部节点在它的两个子节点之间存储一个元素，这和红黑树中值存储在左右子树之间是类似的。也就是说，一个含有 1,000 个子节点的 B 树节点将存储 999 个按照升序排列好的值。
 
 为了保持查找操作的高效，B 树需要维护如下平衡：
 
 1. **最大尺寸：**每个节点最多存储 `order - 1` 个按照升序排列的元素。
 
 2. **最小尺寸：**非根节点中至少要填满一半元素，也就是说，除了根节点以外，其余每个节点中的元素个数至少为 `(order - 1) / 2`。
 
 3. **深度均匀：**所有叶子节点在树中所处的深度必须相同，也就是位于从顶端根节点向下计数的同一层上。
 
 要注意的是，后两个特性是我们的插入方式所诱发的自然结果；我们不需要做任何额外的工作，就可以保证节点不会变得太小，并且所有的叶子都在同一层上。(在其他 B 树操作中，想要维持这些特性会困难的多。比如，删除一个元素可能导致出现不满足要求的节点，此时需要对它进行修正。)
 
 根据这些规则，一个阶为 1,000 的 B 树的节点所能够持有的元素个数在 499 至 999 之间 (包括 999)。唯一的例外是根节点，它不受下限的限制：根节点中可以包含 0 到 999 个元素。(也正因如此，我们才能创建一棵元素个数少于 499 的 B 树。) 这样一来，单独一个 B 树的节点中能够持有的元素个数和一棵 **10 到 20 层**深的红黑树所能持有的元素个数相当！
 
 将如此之多的元素存放在单个节点中有两个主要好处：
 
 1. **降低内存开销。**红黑树中的每个值都存储在一个独立申请于堆上的节点中，该节点还包括了一个指向方法查找表的指针，自身引用计数，以及两个分别指向左右子节点的引用。而 B 树中的节点将批量存储元素，这可以明显地降低内存申请的开销。(具体节省了多少取决于元素个数以及树的阶。)
 
 2. **存取模式更适合内存缓存。** B 树将元素存储在小的连续缓冲区中。如果缓冲区的尺寸经过精心设计，能够全部载入 CPU 的 L1 缓存的话，对它们的操作将会明显快于等效代码对红黑树进行的操作，因为红黑树中的值是散落在堆上的。
 
 为 B 树添加额外的一层，可以使 B 树中所能存储的最大元素个数以阶的乘积的方式增加 (新的最大元素个数 = 原最大个数 × 树的阶)，B 树的稠密特性可见一斑。比如，对于一个阶为 1,000 的 B 树，其最小和最大元素个数随着树的层数的增长情况如下：
 
 ```
  Depth          Minimum size              Maximum size
 ────────────────────────────────────────────────────────
      1                     0                       999
      2                   999                   999 999
      3               499 999               999 999 999
      4           249 999 999           999 999 999 999
      5       124 999 999 999       999 999 999 999 999
      6    62 499 999 999 999   999 999 999 999 999 999
      ⋮                     ⋮                         ⋮ 
      n   2*⎣order/2⎦^(n-1)-1               order^n - 1
 ```
 
 很显然，我们几乎不太会有机会处理层级较多的 B 树。理论上，B 树的深度是 $O(\log n)$，这里 $n$ 是元素的个数。但是这个对数的底数实在太大，在真实世界的计算机中，由于可用内存数量的限制，实际上对于任意我们可预期的输入尺寸，可以说 B 树的深度都是 $O(1)$ 级别的。
 
 > 最后一句话看起来好像很有道理，而且都这么想的话，会让人觉得是不是只要把时间尺度放大到一个人的剩余生命的话，在实践中所有的算法就都是 $O(1)$ 复杂度的了。显然，我不会觉得一个跑到我死都没完成的算法是可以“实践”的。不过，你确实能将整个宇宙中可以观测到的粒子都放到一个阶为 1,000 的 B 树中，而这棵 B 树也不过就是 30 多层。所以千万不要去和对数较真，这没什么意义。
 
 在 B 树中，**绝大多数**元素都是存储在叶子节点中的，这是 B 树如此巨大的扇出 (fan-out) 所导致的另一个有趣的结果。在一个阶为 1,000 的 B 树中，至少 99.8% 的元素存在于叶子节点中。因此，在批量操作 B 树元素 (比如迭代) 时，我们大多数时候需要将注意力放在叶子节点上，对叶子节点进行优化，保持处理迅速：通常，在性能测试的结果中，花在中间节点的时间甚至都不做记录。
 
 奇怪的是，除此之外，B 树的节点数和它的元素数理论上还是成比例的。大多数的 B 树算法和对应的二叉树代码具有相同级别的时间复杂度。不过，在简化后的时间复杂度的背后，实践中复杂度的常数因子也很重要，B 树所做的正是在常数因子上进行优化。不要对此感到意外，因为如果我们完全不关心常数因子的话，这本书在讲完 `RedBlackTree` 之后就可以终结了！
 
 <!-- begin-exclude-from-preview -->
 
 ## 基本定义
 
 说得足够了，让我们开始动手吧！
 
 和 `RedblackTree2` 一样，我们通过为根节点引用定义一个公有的封装结构体开始，来实现 B 树：
*/
public struct BTree<Element: Comparable> {
    fileprivate var root: Node

    init(order: Int) {
        self.root = Node(order: order)
    }
}
/*:
 在 `RedblackTree2` 中，`root` 是一个可选引用，这样空树就不需要在内存中申请任何东西。不过将根节点定义为非可选值，将使我们的代码变得短一些。在这里，我推崇简洁至上。
 
 节点类需要持有两个缓冲区：一个用来存储元素，另一个用来存储子节点的引用。最简单的方法是使用数组，所以就让我们从数组开始。
 
 为了让我们的树更易于测试，树的阶将不是一个在编译时就决定的常数，我们会通过上面的初始化方法自定义树的阶。我们将阶数以只读属性的方式存储在每个节点中，这样我们就能轻易地获取它们了：
*/
extension BTree {
    final class Node {
        let order: Int
        var mutationCount: Int64 = 0
        var elements: [Element] = []
        var children: [Node] = []

        init(order: Int) {
            self.order = order
        }
    }
}
/*:
 和前一章一样，我们为节点添加了 `mutationCount` 属性。如前所述，现在在每个节点中存储变更计数值的浪费要少得多了，一个典型的节点将会存储数千字节的数据，所以再为它额外添加 8 个字节也无关紧要：
 
 下图
 显示了我们例子中的 B 树以 `BTree` 表示的方式。注意在 `elements` 和 `children` 数组中的索引的组织方式：对于 `0 ..< elements.count` 中的任意一个 `i`，`elements[i]` 的值要比 `children[i]` 中的任意值都要大，但是比 `children[i + 1]` 中的任意值都要小。
 
 ![图 6.1: 以 `BTree` 表示的示例 B 树。](Images/BTreeImplementation@3x.png)
 
 
 ## 默认初始化方法
 
 用户可以自定义树的阶，但是为了实现 `SortedSet`，我们还需要一个无参初始化方法；我们应该用什么值来做默认的阶呢？
 
 一种选择是直接在代码中设定一个具体的值：

```swift
extension BTree {
    public init() { self.init(order: 1024) }
}
```

 不过，我们还能做得更好。性能测试表明，当元素缓冲区的最大尺寸大约为 CPU L1 缓存尺寸的四分之一时，B 树拥有最快的速度。Darwin 系统 (Apple 操作系统底层的内核) 提供了 `sysctl` 指令用来查询缓存的大小，Linux 下也有对应的 `sysconf` 指令。在 Swift 中，我们可以这样来访问它们：
*/
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

let cacheSize: Int? = {
    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
        var result: Int = 0
        var size = MemoryLayout<Int>.size
        let status = sysctlbyname("hw.l1dcachesize", &result, &size, nil, 0)
        guard status != -1 else { return nil }
        return result
    #elseif os(Linux)
        let result = sysconf(Int32(_SC_LEVEL1_DCACHE_SIZE))
        guard result != -1 else { return nil }
        return result
    #else
        return nil // 未知平台
    #endif
}()
/*:
 > 在 Darwin 中，还有很多其他的 `sysctl` 名称；你可以通过在命令行窗口运行 `man 3 sysctl` 来获取最常用的名称列表。另外，`sysctl -a` 可以让你获取一份所有可用查询以及它们的当前值的列表，`confnames.h` 列出了所有你能用来作为 `sysconf` 参数的符号名称。
 
 当知道缓存尺寸后，配合上标准库中的 `MemoryLayout` 获取单个元素在连续内存缓冲区中占用的字节数，我们就可以定义无参的初始化方法了：
*/
extension BTree {
    public init() {
        let order = (cacheSize ?? 32768) / (4 * MemoryLayout<Element>.stride)
        self.init(order: Swift.max(16, order))
    }
}
/*:
 如果无法确定缓存尺寸，则使用一个看上去合理的默认数值。`max` 的调用确保了即使在元素尺寸巨大的时候，我们也还是能得到一棵足够茂密的树。
 
 ## 使用 `forEach` 迭代
 
 让我们来看看 B 树中的 `forEach` 方法吧。和之前一样，封装结构体的 `forEach` 方法只是简单地将调用传递给根节点：
*/
extension BTree {
    public func forEach(_ body: (Element) throws -> Void) rethrows {
        try root.forEach(body)
    }
}
/*:
 但我们要怎样才能访问到一个节点中的所有元素呢？如果该节点是一个叶子节点，那我们只需要在它的所有元素上调用 `body` 就行了。如果一个节点拥有子节点，那我们就需要在访问元素的时候，以递归调用的方式将对子节点的访问一个个插入其中：
*/
extension BTree.Node {
    func forEach(_ body: (Element) throws -> Void) rethrows {
        if children.isEmpty {
            try elements.forEach(body)
        }
        else {
            for i in 0 ..< elements.count {
                try children[i].forEach(body)
                try body(elements[i])
            }
            try children[elements.count].forEach(body)
        }
    }
}
/*:
 注意，第一个子节点的元素要比当前节点的第一个元素要小，所以我们需要以一个递归调用开头。同时，在最后一个元素之后，还存在一个子节点，其中的元素都比该末尾元素要大，我们还需要在最后对它加上一次额外的调用。
 
 ## 查找方法
 
 为了在 B 树中查找某个特定元素，我们首先要写一个用于在某个节点内部查找元素的工具方法。
 
 因为节点中的元素数组其实是已排序的，所以这项任务就简化为了实现一个与 `SortedArray` 相同的二分查找。不过为了让事情更简单一些，这次我们的函数还集成了对最终找到的元素进行成员测试的部分：
*/
extension BTree.Node {
    internal func slot(of element: Element) -> (match: Bool, index: Int) {
        var start = 0
        var end = elements.count
        while start < end {
            let mid = start + (end - start) / 2
            if elements[mid] < element {
                start = mid + 1
            }
            else {
                end = mid
            }
        }
        let match = start < elements.count && elements[start] == element
        return (match, start)
    }
}
/*:
 这里我们将一个节点中的索引称作**位置** (slots)，来和稍后定义的集合类型的索引进行区分。(在节点内部的数组中，包括 `elements` 和 `children`，我们都将用位置来代指其索引。)
 
 现在我们有了计算位置的方法，在实现 `contains` 的时候，我们会需要这个方法。同样，我们将封装结构体上的 `contains` 调用转发给根节点：
*/
extension BTree {
    public func contains(_ element: Element) -> Bool {
        return root.contains(element)
    }
}
/*:
 `Node.contains` 首先调用 `slot(of:)` 方法，如果它找到了一个匹配的位置，那么我们所寻找的元素肯定在树中，所以 `contains` 应该返回 `true`。否则，我们可以使用返回的 index 值来将搜索范围缩小到某一个子节点中：
*/
extension BTree.Node {
    func contains(_ element: Element) -> Bool {
        let slot = self.slot(of: element)
        if slot.match { return true }
        guard !children.isEmpty else { return false }
        return children[slot.index].contains(element)
    }
}
/*:
 没错，B 树将有序数组算法和搜索树算法结合起来，创造了全新且让人激动的东西。(如果考虑 B 树的年代的话，称之为**全新**似乎有些夸张，不过它们的确让人心潮澎湃，不是吗？)
 
 ## 实现写时复制
 
 实现写时复制的第一步，是使用我们到现在为止已经滚瓜烂熟的辅助方法来在必要的时候复制节点。对于根节点，没有什么特别可说的：
*/
extension BTree {
    fileprivate mutating func makeRootUnique() -> Node {
        if isKnownUniquelyReferenced(&root) { return root }
        root = root.clone()
        return root
    }
}
/*:
 打哈欠！
 
 `clone` 方法需要对节点的属性进行浅复制。注意 `elements` 和 `children` 是数组，所以它们有它们自己的写时复制的实现。在这种情况下，这里有些冗余，但是它确实让我们的代码更短：
*/
extension BTree.Node {
    func clone() -> BTree<Element>.Node {
        let clone = BTree<Element>.Node(order: order)
        clone.elements = self.elements
        clone.children = self.children
        return clone
    }
}
/*:
 我们不需要复制变更计数器中的值，因为我们绝对不会在不同节点间比较这个值：这个值只在我们区分某一个节点实例的不同版本时会被使用。
 
 子节点存在于一个数组中，而并不是独立的属性，所以它们的写时复制辅助方法稍有不同，我们需要添加一个参数来告诉函数我们之后想要改变的子节点到底是哪个：
*/
extension BTree.Node {
    func makeChildUnique(at slot: Int) -> BTree<Element>.Node {
        guard !isKnownUniquelyReferenced(&children[slot]) else {
            return children[slot]
        }
        let clone = children[slot].clone()
        children[slot] = clone
        return clone
    }
}
/*:
 幸运的是，Swift 的数组包含了一些非常秘密的实现方式，使得通过下标进行元素更改的操作是原地进行的。在这种实现方式下，我们可以对一个下标表达式进行 `isKnownUniquelyReferenced` 调用，而不会改变它的行为 (通常来说，我们只能对存储属性进行该调用。遗憾的是，在我们自己的集合类型中是无法实现这种**可变地址器** (mutating addressors) 的存取方式的；它背后的技术尚未成熟，而且只在标准库中可用。)
 
 ## 谓词工具 (Utility Predicates)
 
 在继续之前，让我们先来做一点有意义的事，为节点值定义两个谓词属性：
*/
extension BTree.Node {
    var isLeaf: Bool { return children.isEmpty }
    var isTooLarge: Bool { return elements.count >= order }
}
/*:
 之后，我们将会使用 `isLeaf` 属性来判断一个实例是不是叶子节点；用 `isTooLarge` 来判断节点是否需要分割，若返回 `true` 则意味着节点拥有太多元素，需要被分割。
 
 ## 插入
 
 是时候了，我们将按照引言中对本章的概述来实现插入操作，这里只需要将文字转换成实际的 Swift 代码即可。
 
 我们从定义一个由单个元素和节点所组成的结构体开始，我把这个结构体称为一个**碎片** (splinter)。
*/
extension BTree {
    struct Splinter {
        let separator: Element
        let node: Node
    }
}
/*:
 碎片中的 `separator` 值一定要比它的 `node` 中的所有值都要小。正如其名，碎片就像是一个节点的小切片，它由一个单独的元素和跟随它的子节点组成。
 
 接下来，定义一个方法来把某个节点分割为两部分，并将其中一部分提取为一个新的碎片：
*/
extension BTree.Node {
    func split() -> BTree<Element>.Splinter {
        let count = self.elements.count
        let middle = count / 2

        let separator = self.elements[middle]

        let node = BTree<Element>.Node(order: order)
        node.elements.append(contentsOf: self.elements[middle + 1 ..< count])
        self.elements.removeSubrange(middle ..< count)
        
        if !isLeaf {
            node.children.append(contentsOf: self.children[middle + 1 ..< count + 1])
            self.children.removeSubrange(middle + 1 ..< count + 1)
        }
        return .init(separator: separator, node: node)
    }
}
/*:
 这个函数中唯一值得注意的地方在于对索引的管理：稍不小心可能就会发生差一错误，从而破坏整棵树。
 
 ![图 6.2: 将一个值为 4–8 的过大节点进行分割的结果。`split()` 操作返回的碎片中的节点包含了元素 7 和 8，原节点中的元素为 4 和 5。](Images/BTreeSplit@3x.png)
 
 接下来我们可以用碎片和分割方法将一个新元素插入到某个节点中了：
*/
extension BTree.Node {
    func insert(_ element: Element) -> (old: Element?, splinter: BTree<Element>.Splinter?) {
/*:
 这个方法首先会寻找节点中新元素所对应的位置。如果这个元素已经存在了，那么直接返回这个值，而不进行任何修改：
*/
        let slot = self.slot(of: element)
        if slot.match {
            // 元素已经存在于树中。
            return (self.elements[slot.index], nil)
        }
/*:
 否则，就需要实际进行插入，首先肯定需要将变更计数加一：
*/
        mutationCount += 1
/*:
 将一个新元素插入到叶子节点是很简单的：我们只需要将它插入到 `elements` 数组的正确的位置中就可以了。不过，这个额外加入的元素可能会使节点过大。当这种情况发生时，我们需要使用 `split()` 将节点分割为两半，并且将结果的碎片返回：
*/
        if self.isLeaf {
            elements.insert(element, at: slot.index)
            return (nil, self.isTooLarge ? self.split() : nil)
        }
/*:
 如果节点拥有子节点，那么我们需要通过递归调用来将它插入到子节点中正确的位置。`insert` 是一个可变方法，所以我们在需要的时候，我们应该调用 `makeChildUnique(at:)` 来创建写时复制的副本。如果递归的 `insert` 返回一个碎片，则需要把它插入到 `self` 中我们已经计算出的位置：
*/
        let (old, splinter) = makeChildUnique(at: slot.index).insert(element)
        guard let s = splinter else { return (old, nil) }
        elements.insert(s.separator, at: slot.index)
        children.insert(s.node, at: slot.index + 1)
        return (nil, self.isTooLarge ? self.split() : nil)
    }
}
/*:
 这样一来，当我们将一个元素插入到 B 树中一条全满路径的末端时，`insert` 将触发一系列的分割，最终将其从插入点向上一直传递到树的根节点。
 
 如果路径上的所有节点都已经满了，那么最终根节点自身将被分割。这种时候，我们需要向树中添加新的层，具体的做法是：创建一个包含原根节点及得到的碎片的新根节点。实现这个处理的最佳位置是 `BTree` 结构体的公有 `insert` 方法之中，当然了，我们还必须牢记，对树进行任何变更之前务必先调用 `makeRootUnique` 方法：
*/
extension BTree {
    @discardableResult
    public mutating func insert(_ element: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        let root = makeRootUnique()
        let (old, splinter) = root.insert(element)
        if let splinter = splinter {
            let r = Node(order: root.order)
            r.elements = [splinter.separator]
            r.children = [root, splinter.node]
            self.root = r
        }
        return (old == nil, old ?? element)
    }
}
/*:
 这就是将元素插入到 B 树中所需要做的全部了。坦诚地讲，这些代码不如 `RedBlackTree` 中的优雅，但是对比我们在 `RedblackTree2` 所写的，已经好太多了。
 
 对插入进行性能测试，可以得到
 下图的结果。
 对于小集合，显然我们的性能和 `SortedArray` 在同等范围中：`BTree.insert` 仅仅只慢了 10-15%。好的地方在于，对于大的数据集，同样的代码对比 `RedblackTree2` 的插入速度快了有 3.5 倍！通过随机插入 400 万个元素的方式创建一棵 `BTree` 仅仅只需要三秒。
 
 ![图 6.3: 对比 `SortedSet.insert` 的五种不同实现的性能](Images/Insertion5.png)
 
 作为一棵平衡搜索树，`B-tree.insert` 和 `RedBlackTree` 以及 `RedblackTree2` 一样，拥有 $O(\log n)$ 的渐进复杂度，但是它借鉴并汲取了 `SortedArray` 的内存访问模式，这使得对于不论大小的任意输入尺寸，B 树的性能都能得到令人欣喜的提升。有时候组合两种数据结构会给我们带来 1 + 1 > 2 的效果。
 
 ## 实现集合类型
 
 实现 `Collection` 的时候，所面临的最大设计挑战不外乎于如何选定一个优秀的索引类型。我们将为 B 树选择一条和 `RedblackTree2` 相仿的路，让每个索引包含树中的一条完整路径。
 
 ### B 树路径
 
 B 树中的一条路径可以由从根节点开始的一系列位置构成。不过为了更高效一些，我们也会将路径上对相应节点的引用包含进来。
 
 索引不能包括对集合类型的强引用。在 `RedblackTree2` 中，我们一开始使用了弱引用来满足这个要求。这次，我们将利用上一章最后的结论，直接使用 unsafe unowned 引用。我们已经知道，这样的引用不会带来引用计数的额外开销，所以它们会稍微快一些。这种小改动在迭代测试中的累加效应相当明显，对于 `RedblackTree2` 来说，它为迭代带来了 200% 的加速。
 
 作为拥有卓越原生性能的交换，语言层面对于 `unowned(unsafe)` 的去引用操作完全没有提供安全性保障。它们的引用目标可能已不再存在，包含的数据也许并不在预期之内。从这个角度来说，这类引用的工作方式和 C 指针可以说是彼此彼此。
 
 对于有效的索引来说，这没有任何问题，因为它们所引用的树和它们被创建时的树的状态是一致的。但是对于无效的索引就必须特别小心了，因为它们的路径上的节点引用可能已经被破坏了。访问已经破坏的引用会造成不可预期的结果，app 可能会崩溃，或者默默给你返回不正确的数据。(这和简单的 `unowned` 引用稍有不同，`unowned` 还是做了一些引用计数的工作，来确保引用目标消失时你的程序会发生崩溃。)
 
 说了这么多，让我们开始写代码吧。我们将使用一个 `UnsafePathElement` 数组来表示一条 B 树路径。`UnsafePathElement` 结构体定义如下，它包含一个对节点的引用以及一个表示位置的整数：
*/
extension BTree {
    struct UnsafePathElement {
        unowned(unsafe) let node: Node
        var slot: Int

        init(_ node: Node, _ slot: Int) {
            self.node = node
            self.slot = slot
        }
    }
}
/*:
 上述定义中的存储属性 `node` 的声明看起来有点可怕。
 
 我们还会定义一系列计算属性，用来访问路径元素的一些基本特性，比如路径元素所引用的值，这个值之前的对应的子节点，元素上的节点是不是一个叶子节点，以及路径元素是否指向节点的末尾等：
*/
extension BTree.UnsafePathElement {
    var value: Element? {
        guard slot < node.elements.count else { return nil }
        return node.elements[slot]
    }
    var child: BTree<Element>.Node {
        return node.children[slot]
    }
    var isLeaf: Bool { return node.isLeaf }
    var isAtEnd: Bool { return slot == node.elements.count }
}
/*:
 注意，路径元素的位置有可能恰好在节点内最后一个元素之后，这种情况下这个路径元素将没有对应的 `value` 值。不过对于中间节点来说，其中的每个位置都会对应存在一个子节点。
 
 如果还能比较路径元素的相等性就再好不过了，所以让我们来实现 `Equatable`：
*/
extension BTree.UnsafePathElement: Equatable {
    static func ==(left: BTree<Element>.UnsafePathElement, right: BTree<Element>.UnsafePathElement) -> Bool {
        return left.node === right.node && left.slot == right.slot
    }
}
/*:
 ### B 树索引
 
 下面是 `BTreeIndex` 的定义。它看起来和 `RedblackTree2Index` 很相似，在索引中它将持有一个路径元素的序列，对根节点的弱引用，以及索引被创建时的变更次数。注意，对于根节点我们还是使用了弱引用，这是因为弱引用将允许我们在没有具体的树的值和索引中的值进行匹配的时候，可以使用索引自身来进行验证：
*/
extension BTree {
    public struct Index {
        fileprivate weak var root: Node?
        fileprivate let mutationCount: Int64

        fileprivate var path: [UnsafePathElement]
        fileprivate var current: UnsafePathElement
/*:
 大多数情况下，在 B 树中可以简单地通过增加最终路径元素的位置值，来进行索引步进。将这个“热点”元素从数组里拿出来，单独存储在一个 `current` 属性里，可以让这种通用处理稍微快一些。(`Array` 自身的索引验证，以及其固有的对数组底层存储缓冲区进行的非直接访问，将会带来些许的开销增加。) 这样的微小优化一般来说是不必要的 (或者甚至是有害的)。但是，我们已经决定了使用不安全的引用，相比起来，这就显得微不足道了，况且毫无疑问这几乎没什么危害。
 
 我们还需要两个内部初始化方法，来创建树的 `startIndex` 和 `endIndex`。前者将构造一条通向树中首个元素的路径，而后者只用将路径设在在根节点中最后一个元素之后即可：
*/
        init(startOf tree: BTree) {
            self.root = tree.root
            self.mutationCount = tree.root.mutationCount
            self.path = []
            self.current = UnsafePathElement(tree.root, 0)
            while !current.isLeaf { push(0) }
        }

        init(endOf tree: BTree) {
            self.root = tree.root
            self.mutationCount = tree.root.mutationCount
            self.path = []
            self.current = UnsafePathElement(tree.root, tree.root.elements.count)
        }
    }
}
/*:
 理论上说，`startIndex` 的复杂度是 $O(\log n)$。不过我们已经看到，实际上 B 树的深度更接近于 $O(1)$，所以在这种情况下，我们完全没有违背 `Colleciton` 中关于性能的要求。
 
 ### 索引验证
 
 因为空的 B 树也有一个根节点，所以在任意有效的 B 树索引中根节点的引用不能是 `nil`。除此以外，B 树的索引验证的方式基本上和 `RedblackTree2` 中的一样。
 
 当想要变更 `BTree` 的值时，需要先仔细考虑要么改变根节点引用，要么改变根节点变更计数。这样一来，当某个索引中根节点引用和变更计数两者都匹配时，我们就知道该索引依然有效，也就能安全地使用它的路径上的元素了：
*/
extension BTree.Index {
    fileprivate func validate(for root: BTree<Element>.Node) {
        precondition(self.root === root)
        precondition(self.mutationCount == root.mutationCount)
    }

    fileprivate static func validate(_ left: BTree<Element>.Index, _ right: BTree<Element>.Index) {
        precondition(left.root === right.root)
        precondition(left.mutationCount == right.mutationCount)
        precondition(left.root != nil)
        precondition(left.mutationCount == left.root!.mutationCount)
    }
}
/*:
 我们将会在 `Equatable` 和 `Comparable` 的实现中用上 static 版本的索引验证方法。由于这个方法的存在，我们不能将对根节点的弱引用转换为 `unowned(unsafe)`，因为我们需要在不从外部提供树的参照的情况下，也能完成索引的验证工作。
 
 ### 索引导航
 
 要在树中导航，我们需要定义两个辅助方法：`push` 和 `pop`。`push` 接受一个与当前路径相关的子节点中的位置值，并把它添加到路径的末端。`pop` 则负责将路径的最后一个元素移除：
*/
extension BTree.Index {
    fileprivate mutating func push(_ slot: Int) {
        path.append(current)
        let child = current.node.children[current.slot]
        current = BTree<Element>.UnsafePathElement(child, slot)
    }

    fileprivate mutating func pop() {
        current = self.path.removeLast()
    }
}
/*:
 有了这两个函数，我们就能定义在树中从一个索引步进到下一个元素的方法了。对于绝大多数情况来说，这个方法要做的仅仅是增加当前路径元素 (也就是最后一个元素，`current`) 的位置值。仅有的例外发生于 (1) 对应的叶子节点中没有更多的元素时，或者 (2) 当前节点不是一个叶子节点时。(两种情况相对来说都是很罕见的。)
*/
extension BTree.Index {
    fileprivate mutating func formSuccessor() {
        precondition(!current.isAtEnd, "Cannot advance beyond endIndex")
        current.slot += 1
        if current.isLeaf {
            // 这个循环很可能一次都不会执行。
            while current.isAtEnd, current.node !== root {
                // 上溯到最近的，拥有更多元素的祖先节点。
                pop()
            }
        }
        else {
            // 下行到当前节点最左侧叶子节点的开头。
            while !current.isLeaf {
                push(0)
            }
        }
    }
}
/*:
 寻找前置索引与此相似，我们需要稍微重新组织一下代码，因为我们想要找的是节点起始位置，而非结尾：
*/
extension BTree.Index {
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
                push(c.isLeaf ? c.elements.count - 1 : c.elements.count)
            }
        }
    }
}
/*:
 上面的函数都是私有的辅助方法，所以完全可以假设当它们被调用时，索引已经被它们的调用者验证过了。
 
 ### 比较索引
 
 索引需要满足 `Comparable`，所以我们还需要实现索引的判等和小于等于操作符。这些函数是公有入口，因此我们必须记住在访问它们路径上的任意元素之前，先对索引进行验证：
*/
extension BTree.Index: Comparable {
    public static func ==(left: BTree<Element>.Index, right: BTree<Element>.Index) -> Bool {
        BTree<Element>.Index.validate(left, right)
        return left.current == right.current
    }

    public static func <(left: BTree<Element>.Index, right: BTree<Element>.Index) -> Bool {
        BTree<Element>.Index.validate(left, right)
        switch (left.current.value, right.current.value) {
        case let (a?, b?): return a < b
        case (nil, _): return false
        default: return true
        }
    }
}
/*:
 ### 实现 `Collection`
 
 现在我们已经具备了让 `BTree` 满足 `BidirectionalCollection` 的所有条件了；在每个方法的实现中，我们只需要调用上述索引方法即可完成具体工作。此外，还需要确保在调用前已经对索引进行了验证，因为我们并没有在索引上实现验证其自身的功能：
*/
extension BTree: SortedSet {
    public var startIndex: Index { return Index(startOf: self) }
    public var endIndex: Index { return Index(endOf: self) }

    public subscript(index: Index) -> Element {
        index.validate(for: root)
        return index.current.value!
    }

    public func formIndex(after i: inout Index) {
        i.validate(for: root)
        i.formSuccessor()
    }

    public func formIndex(before i: inout Index) {
        i.validate(for: root)
        i.formPredecessor()
    }

    public func index(after i: Index) -> Index {
        i.validate(for: root)
        var i = i
        i.formSuccessor()
        return i
    }

    public func index(before i: Index) -> Index {
        i.validate(for: root)
        var i = i
        i.formPredecessor()
        return i
    }
}
/*:
 ### 获取元素个数
 
 使用索引进行迭代现在只消耗 $O(n)$ 的时间，但是所有那些索引验证的工作将让操作变慢很多。迫于此，我们可以考虑为像是 `count` 属性这样的基本的 `Collection` 成员，准备一些特殊的实现：
*/
extension BTree {
    public var count: Int {
        return root.count
    }
}

extension BTree.Node {
    var count: Int {
        return children.reduce(elements.count) { $0 + $1.count }
    }
}
/*:
 注意，`Node.count` 在 `reduce` 的闭包里使用了递归调用，这需要访问到 B 树中的每个节点，由于技术上来说我们会有 $O(n)$ 个节点，所以这个计数操作也将在 $O(n)$ 时间下完成。(虽然这已经比一个元素一个元素计数要快得多了。)
 
 > 由于 B 树的节点一般都很大，所以在每个节点中包含一个子树的元素个数值是一个不错的想法，这会使数据结构变为一棵**顺序统计树**。这么做可以将 `count` 变为一个 $O(1)$ 操作，并且让我们在 $O(\log n)$ 时间内就能查找到树中的第 *i* 个元素。我们这里就不给出实现了，你可以在我们官方的 [BTree][BTree-github] 项目里找到对于这个想法的完整实现。
 
 [BTree-github]: https://github.com/lorentey/BTree
 
 ### 自定义迭代器
 
 我们还需要自定义一个迭代器类型，这样我们才能将索引验证的开销从简单的 `for-in` 循环中移除。下面是一种直接的实现，我们在 `RedblackTree2` 中已经用过同样的方式了：
*/
extension BTree {
    public struct Iterator: IteratorProtocol {
        let tree: BTree
        var index: Index

        init(_ tree: BTree) {
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
 ### 迭代性能
 
 为了优化 B 树中的迭代性能，我们用上了十八般武艺：
 
 - **算法改进：**索引是由树中的完整路径来表示的，所以索引的步进平摊下来的时间复杂度是 $O(1)$。
 
 - **为一般情形进行优化：**B 树的绝大部分值都存储在叶子节点的 `elements` 数组中。通过将最后一个路径元素提出来放在自己的存储属性中，我们可以确保在这样的元素间步进时所需要的操作尽可能少。
 
 - **提升局部访问性**：通过将我们的值按照缓存的尺寸排列为合适大小的数组，我们可以构建出完美适合我们计算机多层内存架构的数据结构。
 
 - **使用捷径完成验证：**我们实现了自定义的迭代器，这样我们就可以在迭代的时候将重复的索引验证去除掉。
 
 - **谨慎使用不安全的操作：**在路径内部，我们使用了不安全的引用来指向树的节点，这样，创建或修改索引路径就不会再涉及引用计数操作了。索引验证为我们保驾护航，因此我们绝不会遇到被破坏的引用。
 
 那么，B 树中的迭代到底能有多快呢？快的离谱！
 下图是我们的测试结果。
 
 ![图 6.4: 对比五种 `SortedSet` 实现的迭代性能。](Images/Iteration5.png)
 
 我们已经很满意 `RedblackTree2` 最终的迭代性能了，不过它和 `BTree` 完全不在一个档次：`BTree` 要快上 40 倍！不过相比起来，`SortedArray` 还是比 `BTree` 快 8 倍，所以我们还有一些改进的空间。 
 
 ## 例子
*/
var set = BTree<Int>(order: 5)
for i in (1 ... 250).shuffled() {
    set.insert(i)
}
set
let evenMembers = set.reversed().lazy.filter { $0 % 2 == 0 }.map { "\($0)" }.joined(separator: ", ")
evenMembers
/*:
 ## 性能汇总
 
 下面的图表
 汇总了 `BTree` 在我们的四种标准微性能测试中的表现。值得指出的是，使用 `for-in` 的迭代现在要比用 `forEach` 的版本快得多，这和我们在红黑树中遇到的情况完全相反。
 
 ![图 6.5: `BTree` 操作的性能测试结果。](Images/BTree.png)
 
 我们使用 `Int` 作为元素，并在一台 64 位，拥有 32KB 的 L1 缓存的 MacBook 上进行性能测试，这样一来，`BTree<Int>` 的默认阶数为 1,024。所以，第一次节点分割将发生在我们插入第 1,024 个元素的时候，分割后树将从一个单一节点转换成排列为两层的三个节点。在图中元素数量达到 1,000 的地方，我们可以清晰地看到曲线突然发生了一个向上的跳跃。
 
 树扩展为三层时的尺寸是无法精确预言的，它将发生在五十万到一百万个元素之间。`insert` 和 `contains` 的曲线在这个区间内表现出更快速的增长，这和多加入一层的变化是一致的。
 
 为了让 B 树达到四层，我们需要插入大约十亿个整数。
 下图
 将 `BTree.insert` 的图表扩展到了这样一个怪兽级的大数据集。比较明显的是，插入曲线分为三个阶段，分别对应了 B 树中一层，两层和三层的情况。在图表最右侧，我们可以清晰地看到曲线的上翘，这表明了出现了第四层树。不过在此时，性能测试已经将 MacBook 的 16 GB 物理内存消耗殆尽，这使得 macOS 开始进行内存页面压缩，它甚至会将一些数据转存到 SSD 上。显然，最后的突然增长有一些 (或者说大部分？) 是由于页面操作，而非树的第四层带来的影响。对于测试用的这台机器来说，想将性能测试再往右延伸，会超出其本身的限制，是不可能的了。
 
 ![图 6.6: 通过随机插入创建 B 树。](Images/BTree-Insertion.png)
 
 <!-- end-exclude-from-preview -->

 [Next page](@next)
*/