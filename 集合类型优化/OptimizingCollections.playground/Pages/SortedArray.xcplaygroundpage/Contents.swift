/*:
 [Previous page](@previous)

 # 有序数组 (Sorted Arrays)
 
 
 想要实现 `SortedSet`，也许最简单的方法是将集合的元素存储在一个数组中。这引出了一个像下面这样的简单结构的定义：
*/
public struct SortedArray<Element: Comparable>: SortedSet {
    fileprivate var storage: [Element] = []
    
    public init() {}
}
/*:
 为了满足协议的要求，我们会时刻保持 `storage` 数组处于已排序的状态，故此，命其名曰 `SortedArray`。
 
 ## 二分查找
 
 为了实现 `insert` 和 `contains`，我们需要一个方法，给定一个元素，该方法返回该元素在数组中应当放置的位置。
 
 如何快速实现这样一个方法呢？首先我们需要实现**二分查找算法**。这个算法的工作原理是，将数组一分为二，舍弃不包含我们正在查找的元素的那一半，将这个过程循环往复，直到减少到只有一个元素为止。下面是 Swift 中实现该算法的方法之一：
*/
extension SortedArray {
    func index(for element: Element) -> Int {
        var start = 0
        var end = storage.count
        while start < end {
            let middle = start + (end - start) / 2
            if element > storage[middle] {
                start = middle + 1
            }
            else {
                end = middle
            }
        }
        return start
    }
}
/*:
 值得注意的是，即使我们将集合的元素数量加倍，上述循环也仅仅只需要多进行一次迭代。这可以说是代价相当低了！人们常常说二分查找具有**对数复杂度** (logarithmic complexity)，具体来说就是：它的运行时间与数据规模大小大致呈对数比。(用大 O 符号来描述则是：$O(\log n)$。)
 
 二分查找是一个巧妙的算法，看似简单，实则暗藏玄机，正确地实现它并不是一件容易的事情。二分查找包含许多索引计算，以至于发生错误的几率并不低，像是差一错误 (off-by-one errors)、溢出问题等等。举个例子：我们运用了表达式 `start + (end - start) / 2` 来计算中间索引，这看起来似乎有些歪门邪道；通常会更直观地写为 `(start + end) / 2`。然而，这两个表达式并不总是能够获得相同结果，因为第二个版本的表达式包含的加法运算可能会在集合类型元素数量过多时发生溢出，从而导致运行时错误。
 
 我希望有朝一日二分查找能被纳入 Swift 标准库。在此之前，如果什么时候你需要实现二分查找，务必找一本好的算法书籍作为参考。(尽管我认为这本书也会有一些帮助。) 还有，不要忘记测试你的代码，有时候即使是书中的代码也有 bug！我发现覆盖率 100% 的单元测试能帮助我捕获大多数错误。
 
 我们的 `index(for:)` 函数所做的事情与 `Collection` 的标准 `index(of:)` 方法很相似，不同的是，即使要查找的元素并不存在于当前集合，我们的版本也还是能返回一个有效索引。这个细微但是十分重要的不同点能够让 `index(for:)` 在插入操作中也相当好用。
 
 ## 查找方法
 
 提到 `index(of:)`，我认为借助 `index(for:)` 来定义它也不失为一个好主意，这样一来它也可以用到更好的算法：
*/
extension SortedArray {
    public func index(of element: Element) -> Int? {
        let index = self.index(for: element)
        guard index < count, storage[index] == element else { return nil }
        return index
    }
}
/*:
 `Collection` 的默认查找算法的原理是：执行一个线性查找来遍历所有元素，直到找到目标或是到达末尾为止。经过我们专门优化后的版本要快得**多的多**。
 
 检验元素与集合类型的所属关系所需要的代码会稍微少一点，因为我们只需要知道元素是否存在：
*/
extension SortedArray {
    public func contains(_ element: Element) -> Bool {
        let index = self.index(for: element)
        return index < count && storage[index] == element
    }
}
/*:
 实现 `forEach` 更加容易，因为我们可以直接将这个调用传递给我们的存储数组。数组已经排序，因此这个方法将会以正确的顺序访问元素：
*/
extension SortedArray {
    public func forEach(_ body: (Element) throws -> Void) rethrows {
        try storage.forEach(body)
    }
}
/*:
 到现在我们已经实现了几个方法，不妨回过头看一看其他 `Sequence` 和 `Collection` 的成员，值得开心的是，它们也受益于专门的实现。比如说，由 `Comparable` 元素组成的序列有一个 `sorted()` 方法，返回一个包含该序列所有元素的有序数组。对于 `SortedArray`，简单地返回 `storage` 就可以实现：
*/
extension SortedArray {
    public func sorted() -> [Element] {
        return storage
    }
}
/*:
 ## 插入
 
 向有序集合中插入一个新元素的流程是：首先用 `index(for:)` 找到它相应的索引，然后检查这个元素是否已经存在。为了维护 `SortedSet` 不能包含重复元素特性，我们只向 `storage` 插入目前不存在的元素：
*/
extension SortedArray {
    @discardableResult
    public mutating func insert(_ newElement: Element) -> (inserted: Bool, memberAfterInsert: Element) 
    {
        let index = self.index(for: newElement)
        if index < count && storage[index] == newElement {
            return (false, storage[index])
        }
        storage.insert(newElement, at: index)
        return (true, newElement)
    }
}
/*:
 ## 实现集合类型
 
 下一步，让我们来实现 `BidirectionalCollection`。因为我们将所有东西都存储到了一个单一数组中，所以最简单的实现方法是在 `SortedArray` 和它的 `storage` 之间共享索引。这样一来，我们可以将大多数集合类型的方法直接传递给 `storage` 数组，从而大幅度简化我们的实现。
 
 `Array` 实现的不止是 `BidirectionalCollection`，实际是有着相同 API 接口但语义要求更严格的 `RandomAccessCollection`。`RandomAccessCollection` 要求高效的索引计算，因为我们必须任何时候都能够将索引进行任意数量的偏移，以及测算任意两个索引之间的距离。
 
 一个事实是，我们无论如何都会向 `storage` 传递各种调用，所以在 `SortedArray` 上实现相同的协议是一件有意义的事情：
*/
extension SortedArray: RandomAccessCollection {
    public typealias Indices = CountableRange<Int>

    public var startIndex: Int { return storage.startIndex }
    public var endIndex: Int { return storage.endIndex }

    public subscript(index: Int) -> Element { return storage[index] }
}
/*:
 这样我们就完成了 `SortedSet` 协议的实现。太棒了！
 
 ## 例子
 
 
 让我们来检验一下是否一切正常：
*/
var set = SortedArray<Int>()
for i in (0 ..< 22).shuffled() {
    set.insert(2 * i)
}
set

set.contains(42)

set.contains(13)

let copy = set
set.insert(13)

set.contains(13)

copy.contains(13)
/*:
 看起来答案是肯定的！我们并没有做任何工作来实现值语义；凭借 `SortedArray` 是一个由单一数组构成的结构体这个仅有的事实，我们得到了前面结果。值语义是一个组合性质，若结构体中的存储属性全都具有值语义，它的行为也会自动表现得一致。
 
 ## 性能
 
 
 当我们谈论一个算法的性能时，我们常用所谓的**大 O 符号**来描述执行时间受输入元素个数的影响所发生的改变，记为：$O(1)$、$O(n)$、$O(n^2)$、$O(\log n)$、$O(n\log n)$ 等。这个符号在数学上有明确的定义，不过你不需要太关注，理解我们在为算法**增长率** (growth rate) 分类时使用这个符号作为简写就足够了。当输入元素个数倍增时，一个 $O(n)$ 的算法会花费不超过两倍的时间，但是一个 $O(n^2)$ 的算法可能比从前慢四倍，同时一个 $O(1)$ 的算法的执行时间并不大会受输入影响。
 
 我们可以基于数学来分析我们的算法，合理地推导出渐进复杂度估计值。分析能为我们提供关于性能的有用指标，但它不是绝对的；就其本质而言，由于依赖简化的模型，与真实世界中的实际硬件的行为既有可能相匹配，也有可能存在差池。
 
 为了了解我们的 `SortedSet` 的真实性能，运行一些性能测试是个好办法。例如，下述代码可以对四个 `SortedArray` 上的基础操作进行微型性能测试，它们分别是：`insert`、`contains`、`forEach` 和用 `for` 语句实现的迭代：

```swift
func benchmark(count: Int, measure: (String, () -> Void) -> Void) {
    var set = SortedArray<Int>()
    let input = (0 ..< count).shuffled()
    measure("SortedArray.insert") {
        for value in input {
            set.insert(value)
        }
    }

    let lookups = (0 ..< count).shuffled()
    measure("SortedArray.contains") {
        for element in lookups {
            guard set.contains(element) else { fatalError() }
        }
    }
    
    measure("SortedArray.forEach") {
        var i = 0
        set.forEach { element in
            guard element == i else { fatalError() }
            i += 1
        }
        guard i == input.count else { fatalError() }
    }
    
    measure("SortedArray.for-in") {
        var i = 0
        for element in set {
            guard element == i else { fatalError() }
            i += 1
        }
        guard i == input.count else { fatalError() }
    }
}
```

 `measure` 参数是测量其闭包执行时间的函数，第一个参数表示它的名字。驱动 `benchmark` 函数的一个简单方法是在不同元素个数的循环中调用它，并打印测量结果：

```swift
for size in (0 ..< 20).map({ 1 << $0 }) {
    benchmark(size: size) { name, body in 
        let start = Date()
        body()
        let end = Date()
        print("\(name), \(size), \(end.timeIntervalSince(start))")
    }
}
```

 这是我实际用来画出下面图表时所使用的 [Attabench] 性能测试框架的简化版。真实的代码中含有更多的测试模板之类的东西，不过实际的测量方式 (`measure` 闭包中的代码) 并无二致。
 
 [Attabench]: https://github.com/lorentey/Attabench
 
 绘制我们的性能测试结果，得到下述图表。
 注意，在这个图表中，我们对两个坐标轴都使用了对数标度 (logarithmic scales)，这意味着：向右移动一个刻度，输入值的数量翻一倍；向上移动一条水平线，执行时间增长为十倍。
 
 ![`SortedArray` 操作的性能测试结果，在双对数坐标系上描画输入值的元素个数和总体执行时间。](Images/SortedArray-raw.png)
 
 双对数坐标系非常适合用来表示性能测试结果。不仅可以无压力地在单一图表上表示跨度巨大的数据，而且有效避免了小值被埋没在大值的世界里。在这个例子中，我们可以很容易地比较元素数量从一增加到四百万的执行时间，尽管它们之间的差异达到了惊人的 22 个二的幂次数量级！
 
 此外，双对数坐标系让我们能够简单地估计一个算法展现的实际复杂度。如果性能测试中某部分是一条直线，那么输入元素个数和执行时间之间的关系近似于一个简单多项式的倍数，如 $n$、$n^2$ 甚至是 $\sqrt n$。指数与直线的斜率相关联，$n^2$ 的斜率是 $n$ 的两倍。在有了一些亲身实践之后，你会对发生频率最高的关系一目了然，完全没有必要进行复杂的分析。
 
 在我们的例子中，单纯地迭代数组中的所有元素应该会花费 $O(n)$ 的时间，这在我们的图中也得到了证实。`Array.forEach` 和 `for-in` 循环的时间成本几乎相同，而且在初始热身周期之后，它们都变成了直线。横坐标向右移动三个单位多一点，纵坐标就向上移动一个单位，相当于 $2^{3.3} \approx 10$，这证明了一个简单的线性关系。
 
 再来看一看 `SortedArray.insert` 的图，我们会发现元素数量约为 4,000 时它逐渐变化成为一条直线，斜率大致为 `SortedArray.forEach` 斜率的两倍，由此可以推断插入的执行时间是输入元素数量的二次函数。我们从理论上进行的推测是：每次向已排序数组插入一个随机元素的时候，需要将 (平均) 一半的既有元素向右移动一位来给插入元素腾出位置。因此插入是一个线性操作，$n$ 个插入操作需要花费 $O(n^2)$。很幸运，图表走势与我们的预期相吻合。
 
 `SortedArray.contains` 进行 $n$ 次二分查找, 每次花费 $O(\log n)$ 的时间，因此它应该是一个 $O(n\log n)$ 的函数。这很难从
 上面的图表中看出来,
 但是如果你离近了仔细看，便可以验证我们的推测：`contains` 的曲线几乎平行于 `forEach` 的曲线，只是稍微向上偏离，但它不是一条完美的直线。你可以将一张纸的边缘放到 `contains` 图的旁边来进行验证，它弯弯曲曲远离了纸的直边，反映了一种超线性 (superlinear) 关系。
 
 为了突出 $O(n)$ 和 $O(n\log n)$ 之间的差异，一个不错的方案是：用输入元素个数除以执行时间，并将结果反映在图表中来展示花费在一个元素上的平均执行时间。(我喜欢把这种类型的图称为**平摊图** (amortized chart)。我不确定在上下文中使用**平摊**合不合适，但是这个词语很容易给人留下深刻的印象！) 这个除法运算排除了斜率始终不变的 $O(n)$，使得我们可以简单地区分线性因子和对数因子。
 这里展示的是 `SortedArray` 的平摊图。
 你会发现，现在 `contains` 有一个明显 (但是细微) 的向上趋势，而 `forEach` 的尾部趋于完全水平。
 
 ![`SortedArray` 操作的性能测试结果，在双对数坐标系上描画输入值的元素个数和单次操作的平均执行时间。](Images/SortedArray.png)
 
 `contains` 的曲线带来了两个意料之外的事实。其一是：在元素个数为 2 的幂次方时，会出现一个明显的尖峰。这是因为在二分查找和运行性能测试的 MacBook 的二级 (L2) 缓存架构之间存在一个有意思的相互作用。缓存被分为一些 64 字节的**行** (line)，其中每一部分都可能持有来自一系列特定物理地址的内存中的内容。由于一个不幸的巧合，如果存储大小接近于 2 的幂次方时，二分查找算法的连续查找操作可能会落入相同的 L2 缓存行，从而迅速耗尽它的容量，其它行却处于未使用状态。这个现象被称为**缓存行别名** (cache line aliasing)，它会导致一个极具戏剧性的性能衰退：`contains` 峰值耗费的执行时间约为相邻元素个数耗时的两倍。
 
 <!-- citation: https://www.pvk.ca/Blog/2012/07/30/binary-search-is-a-pathological-case-for-caches/ -->
 
 消除这些尖峰的一种方法是改用**三分查找** (ternary search)，每次迭代时将缓存等分为**三个**部分。还有一种更简单的解决方案，选择一个略微偏离中心的位置作为中心索引来扰乱二分查找。如果选择这个方案，我们只需要在 `index(for:)` 的实现中修改一行即可，在中心索引上添加一个额外的小偏移量：
*/
extension SortedArray {
    func index2(for element: Element) -> Int {
        var start = 0
        var end = storage.count
        while start < end {
            let middle = start + (end - start) / 2 + (end - start) >> 6
            if element > storage[middle] {
                start = middle + 1
            }
            else {
                end = middle
            }
        }
        return start
    }

    public func contains2(_ element: Element) -> Bool {
        let index = self.index2(for: element)
        return index < count && storage[index] == element
    }
    
    func index3(for element: Element) -> Int {
        var start = 0
        var end = storage.count
        while start < end {
            let diff = end - start
            if diff < 1024 {
                let middle = start + diff >> 1
                if element > storage[middle] {
                    start = middle + 1
                }
                else {
                    end = middle
                }
            }
            else {
                let third = diff / 3
                let m1 = start + third
                let m2 = end - third
                let v1 = storage[m1]
                let v2 = storage[m2]
                if element < v1 {
                    end = m1
                }
                else if element > v2 {
                    start = m2 + 1
                }
                else {
                    start = m1
                    end = m2 + 1
                }
            }
        }
        return start
    }
    
    public func contains3(_ element: Element) -> Bool {
        let index = self.index3(for: element)
        return index < count && storage[index] == element
    }
}
/*:
```swift
let middle = start + (end - start) / 2 + (end - start) >> 6
```

 这样的话，中间索引将落在两个端点的 $33/64$ 处，足以避免缓存行别名现象。不幸的是，代码变得稍微复杂了一点，相较于二分查找，这些偏离正中的中心索引通常会导致存储查找次数小幅增加。这样看来，消除 2 的幂次方的尖峰所需付出的代价是总体上的衰退，在图表中也得到了证明，如
 下图所示。
 
 ![比较二分查找 (`contains`) 和使用中心索引偏移来避免缓存行别名的版本 (`contains2`) 的性能。](Images/SortedArray-contains.png)
 
 还记得上文说的 `contains` 曲线带来了两个意料之外的事实吗？其二是：在 64,000 个元素及之后，曲线出现轻微上升 (斜率变大)。(如果你仔细观察，你可能会察觉到从大概一百万个元素开始，`insert` 发生了一个虽然不太明显，但是很类似的衰退。)对于这种规模的元素个数，我的 MacBook 的虚拟内存子系统无法保持 CPU 的地址缓存 (也叫做页表缓存 (Translation Lookaside Buffer)，简称 TLB) 中 `storage` 数组的所有分页的物理地址。再加上 `contains` 的性能测试进行的是随机查找，它毫无规律的访问模式导致了 TLB 频繁发生缓存未命中，很大程度上增加了内存访问的成本。另外，随着存储数组的元素个数越来越多，它的绝对大小超过 L1 和 L2 缓存，那些缓存未命中造成了大量附加延迟。
 
 所以在最后，看起来在一个足够大的连续缓冲区进行随机内存访问要花费 $O(\log n)$ 的时间，而远非 $O(1)$，所以我们的二分查找的渐进执行时间实际更像是 $O(\log n\log n)$，而非我们通常认为的 $O(\log n)$。这结果是不是很有趣？(如果我们从性能测试的代码中将在 `lookups` 数组上调用的用来随机打乱数组的 `shuffled` 方法移除，衰退便会烟消云散。试试看！)
 
 另一方面，对于元素个数少的情况，`contains` 的曲线与 `insert` 其实非常接近。一部分原因可以归结为对数刻度的副作用，在它们接近的位置，`contains` 仍然比 `insert` 快了近 80%。但是 `insert` 曲线在大约 1,000 个元素时平坦得令人吃惊，似乎当有序数组足够小的时候，插入一个新元素所耗费的时间与数组大小无关。(我认为这是因为在元素个数处于这些区间的时候，整个数组可以完全放入 CPU 的 L1 缓存。)
 
 数组元素足够少的时候，`SortedArray.insert` 似乎快的难以置信。目前我们可以把这件事视作无关紧要的有趣的假说。但是务必把它牢记在心，因为我们会在本书后面的部分对这个事实进行严肃的讨论。

 [Next page](@next)
*/
