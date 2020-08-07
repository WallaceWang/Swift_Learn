/*:
 [Previous page](@previous)

 # 将 `NSOrderedSet` Swift 化
 
 
 Foundation 框架包含一个名为 `NSOrderedSet` 的类。它首次于 2012 年登场，与 iOS 5 和 OS X 10.7 Lion 一同诞生，是一个很年轻的类。`NSOrderedSet` 被添加到 Foundation 中的主要目的是支持 Core Data 中的有序关系。它就像 `NSArray` 和 `NSSet` 的合成体一样，同时实现了两个类的 API。正因如此，它提供了 `NSSet` 中复杂度仅为 $O(1)$ 的超快成员关系检查和 `NSArray` 的 $O(1)$ 复杂度的随机访问索引。作为折中，它继承了 `NSArray` 的 $O(n)$ 的插入。由于 `NSOrderedSet` (算) 是通过封装 `NSSet` 和 `NSArray` 实现的，所以相比两者中任意一个，它的内存消耗都要更高一些。
 
 `NSOrderedSet` 目前还尚未被桥接到 Swift，在这个前提下，尝试为 Objective-C 类定义简单的封装，使其更接近 Swift 的世界，看起来是一个不错的主题。
 
 尽管 `NSOrderedSet` 是一个很酷的名字，但这与我们的用例并不是十分匹配。`NSOrderedSet` 的元素的确是有顺序的，不过它并没有强制要求特定的有序关系，你可以以任何喜欢的顺序来进行元素插入，`NSOrderedSet` 会像一个数组一样为你记住这一切。"ordered" 和 "sorted" 之间的区别在于是否有一个预定义的顺序，这也是为什么 `NSOrderedSet` 并不能被称为 `NSSortedSet` 的原因。这么做最根本的目的是让查找操作的速度足够快，不过它使用的实现方法是哈希而非比较。(`Foundation` 中不存在与 `Comparable` 协议等效的东西；`NSObject` 只提供 `Equatable` (可判等) 和 `Hashable` (可哈希) 功能。)
 
 但是只要 `NSOrderedSet` 的元素实现了 `Comparable` 的话，我们就可以做到保持元素按大小排列，而不仅仅是按插入顺序排列。很明显，对 `NSOrderedSet` 而言这并不算是理想的使用方式，但是我们确实是可以做到这一点的。接下来就让我们引入 Foundation，开始着手于将 `NSOrderedSet` 锤炼为 `SortedSet`：
*/
import Foundation
/*:
 不过马上我们就遇到了几个大问题。
 
 第一，`NSOrderedSet` 是一个类，所以它的实例是引用类型。而我们想要让有序集合具有值语义。
 
 第二，`NSOrderedSet` 是一个混合类型序列，它接受 `Any` 类型作为成员。实现 `SortedSet` 时我们依然可以设置它的 `Element` 类型为 `Any`，而不是将其作为泛型参数，但是感觉这和我们想要的解决方案还有些差距。我们真正期待的是一个泛型的同质集合类型，它可以通过类型参数来指定其中的元素类型。
 
 基于上述原因，我们不能够只通过扩展 `NSOrderedSet` 来实现我们的协议。取而代之，我们将会定义一个泛型的封装结构体，它的内部使用 `NSOrderedSet` 的实例作为存储。这种方法类似于 Swift 标准库为了将 `NSArray`、`NSSet` 和 `NSDictionary` 实例桥接到 Swift 的 `Array`、 `Set` 和 `Dictionary` 值时所做的工作。这样看来，我们似乎步入了正轨。
 
 我们应该给结构体起个什么名字呢？`NSSortedSet` 这个想法浮现上来，而且在技术上这是可行的，同时 Swift 限定的构造 (现在和将来都) 并不依赖于使用前缀来解决命名冲突。但站在另一方面来看，对于开发者而言，`NS` 依然暗示着 **Apple 提供**，所以冒然使用显得很不礼貌，还极容易混淆。我们不妨换个思路，将我们的结构体命名为 `OrderedSet`。(虽然这个名字也不太正确，但至少像是一个基本数据结构的名字。)

```swift
public struct OrderedSet<Element: Comparable>: SortedSet {
    fileprivate var storage = NSMutableOrderedSet()
}
```

 我们希望能够修改存储，所以需要将它声明为一个 `NSMutableOrderedSet` 的实例，`NSMutableOrderedSet` 是 `NSOrderedSet` 的可变子类。
 
 ## 查找元素
 
 现在我们有一个数据结构的空壳。让我们用内容填满它，首先从 `forEach` 和 `contains` 这两个查找方法开始。
 
 `NSOrderedSet` 实现了 `Sequence`，所以它已经有了一个 `forEach` 方法。假如元素能够保持正确的顺序，我们可以简单地将 `forEach` 的调用传递给 `storage`。然而，我们需要先手动将 `NSOrderedSet` 提供的值向下转换 (downcast) 为正确类型：
  
*/
extension OrderedSet {
    public func forEach(_ body: (Element) -> Void) {
        storage.forEach { body($0 as! Element) }
    }
}
/*:
 `OrderedSet` 对自身存储具有完全控制权，因此它可以保证存储中永远不会包含除了 `Element` 以外的任何类型的东西。这确保了向下强制类型转换一定会成功。不过说实话这不太优雅！
 
 `NSOrderedSet` 恰好也为 `contains` 提供了实现，而且对于我们的用例来说似乎是完美的。因为不需要显式类型转换，它显得比 `forEach` 更易于使用：

```swift
extension OrderedSet {
    public func contains(_ element: Element) -> Bool { 
        return storage.contains(element)  // BUG!
    }
}
```

 编译上面的代码没有任何警告，当 `Element` 是 `Int` 或 `String` 的时候，它表现得一切正常。但是，正如我们已经提到过的，`NSOrderedSet` 使用了 `NSObject` 的哈希 API 来加速元素查找。而我们并未要求 `Element` 实现 `Hashable`！这凭什么可以正常工作呢？
 
 当我们像上面的 `storage.contains` 中做的那样，将一个 Swift 值类型提供给一个接受 Objective-C 对象的方法时，编译器会为此生成一个私有的 `NSObject` 子类，并将值装箱 (box) 到其中。一定要记住 `NSObject` 有内建的哈希 API；你不可能有一个不支持 `hash` 的 `NSObject` 实例。因此，这些自动生成的桥接类也必然有与 `isEqual(:)` 一致的 `hash` 实现。
 
 如果 `Element` 正好实现了 `Hashable`，那么 Swift 可以直接在桥接类中使用原类型自己的 `==` 和 `hashValue` 实现，这样一来，在 Objective-C 和 Swift 中取得 `Element` 的值的哈希值就是同样的方法了，而且两者都表现得很完美。
 
 然而，如果 `Element` 没有实现 `hashValue`，那么桥接类就只有唯一的选择，那就是使用 `NSObject` 默认实现的 `hash` 和 `isEqual(_:)`。由于没有其它可用信息，它们都将基于实例的标志符 (即物理地址)，而对于被装箱的值类型而言，这是完全随机的。所以两个不同的桥接实例即使持有两个完全相同的值，也不会被认为相等 (或是返回相同的 `hash`)。
 
 上面的这一切最终使 `contains` 可以通过编译，但是它却有一个致命的 bug：如果 `Element` 并未实现 `Hashable`，则查找总会返回 `false`。哎呀，糟糕了！
 
 亲爱的，这是一个教训：在 Swift 中使用 Objective-C 的 API 时一定要非常非常小心。将 Swift 值自动桥接到 `NSObject` 实例确实很便利，但是也存在不易察觉的陷阱。关于这个问题，代码中不会有任何明确的警告：没有感叹号，没有显示转换，什么都没有。
 
 现在我们知道了，在我们的例子中并不能够依赖 `NSOrderedSet` 的查找方法。所以我们不得不寻找其他 API 来查找元素。谢天谢地，`NSOrderedSet` 已经包含了另一个查找元素的方法，它依据比较函数的结果对一系列元素进行排序：

```swift
class NSOrderedSet: NSObject { // 在 Foundation 中
    ...
    func index(of object: Any, inSortedRange range: NSRange, options: NSBinarySearchingOptions = [], usingComparator: (Any, Any) -> ComparisonResult) -> Int
    ...
}
```

 我推测这是二分查找某种形式的实现，所以它应该足够快。我们的元素可以根据它们的 `Comparable` 特性进行排序，因此我们可以使用 Swift 的 `<` 和 `>` 操作符来定义一个适合的比较器函数：
*/
extension OrderedSet {
    fileprivate static func compare(_ a: Any, _ b: Any) -> ComparisonResult 
    {
        let a = a as! Element, b = b as! Element
        if a < b { return .orderedAscending }
        if a > b { return .orderedDescending }
        return .orderedSame
    }
}
/*:
 我们可以使用这个比较器来定义一个获取特定元素索引的方法。这正好是 `Collection` 的 `index(of:)` 方法应当做的，所以需要确保我们的定义让默认实现更加优雅：
*/
extension OrderedSet {
    public func index(of element: Element) -> Int? {
        let index = storage.index(
            of: element, 
            inSortedRange: NSRange(0 ..< storage.count),
            usingComparator: OrderedSet.compare)
        return index == NSNotFound ? nil : index
    }
}
/*:
 我们有这个函数以后，对 `contains` 的改造就可以降低到一个很小的范围内：
*/
extension OrderedSet {
    public func contains(_ element: Element) -> Bool {
        return index(of: element) != nil
    }
}
/*:
 不知道你感觉如何，我发现事情比我预想的要更复杂一些。在如何将值桥接到 Objective-C 的问题上，细节**有时**会带来深远的影响，这可能会以难以察觉却致命的方法破坏我们的代码。如果我们不知道这些玄机的话，很难不经历意料之外的痛苦。
 
 `NSOrderedSet` 的 `contains` 实现特别快，这是它的一个旗舰特性，所以不能够使用 `contains` 这件事就显得更加悲伤了。但是天无绝人之路！考虑到某些类型下 `NSOrderedSet.contains` 可能错误地返回 `false`，但如果值不是确实存在于集合里，它也绝不会返回 `true`。所以，我们可以写一个新版本的 `OrderedSet.contains`，依然在其中调用原版本方法，但省去了一部分场景下的二分查找需求：
*/
extension OrderedSet {
    public func contains2(_ element: Element) -> Bool {
        return storage.contains(element) || index(of: element) != nil
    }
}
/*:
 对于实现了 `Hashable` 的元素而言，这个版本返回 `true` 的速度比 `index(of:)` 更快。不过，遇到值并非集合的成员，或者类型不是可哈希的这两种情况时，处理速度会略微慢一点点。
 
 ## 实现 `Collection`
 
 `NSOrderedSet` 只遵循 `Sequence`，而不遵循 `Collection`。(这不是什么独特的巧合；它有名的小伙伴 `NSArray` 和 `NSSet` 也一样。) 不过，`NSOrderedSet` 提供了一些基于整数的索引方法，我们可以使用它们在 `OrderedSet` 中实现 `RandomAccessCollection`。
*/
extension OrderedSet: RandomAccessCollection {
    public typealias Index = Int
    public typealias Indices = CountableRange<Int>

    public var startIndex: Int { return 0 }
    public var endIndex: Int { return storage.count }
    public subscript(i: Int) -> Element { return storage[i] as! Element }
}
/*:
 事实证明，这出乎意料的简单。
 
 <!-- begin-exclude-from-preview -->
 
 ## 保证值语义
 
 `SortedSet` 要求值语义，这意味着每个包含有序集合的变量都需要表现地像是持有自身的值的单独复制，完全与所有其它变量独立。
 
 这次我们不会再“免费”得到值语义了！我们的 `OrderedSet` 结构体包含一个指向类实例的引用，所以拷贝一个 `OrderedSet` 的值到另一个变量只会增加存储对象的引用计数。
 
 这意味着两个 `OrderedSet` 的变量可能很容易共享相同的存储：

```swift
var a = OrderedSet()
var b = a
```

 这是上述代码的执行结果，注意两个变量是如何具有相同存储引用的。
 
 ![两个 `OrderedSet` 的值共享指向同一个存储对象的引用。](Images/NonUniqueStorage@3x.png)
 
 
 虽然存储可能被共享，但像 `insert` 这类可变方法一定只能修改调用它的变量所持有的集合实例。实现方法之一是：在我们修改它之前，总是复制一个全新的 `storage`。不过，这样做也太浪费了，很多时候我们的 `OrderedSet` 的值持有对其存储的唯一引用，在这种情况下，即使不做复制而是直接进行修改也是安全的。
 
 Swift 标准库提供了一个名为 `isKnownUniquelyReferenced` 的函数，可以调用它来判断一个指向对象的特定引用是否唯一。如果返回 `true`，那我们就知道没有其它值持有该对象的引用，所以直接修改它是安全的。
 
 (务必注意，这个函数只关注强引用；并不计算弱引用和无主 (unowned) 引用。因此我们不可能**真正地**明察每一种引用持有的情况。还好，在我们的例子中这不是问题，由于 `storage` 是一个私有属性，只有 `OrderedSet` 内部的代码才可以访问它，我们也绝不会创建“隐式”引用。不计算弱引用和无主引用是故意而为，并非偶然的疏忽；这样一来，更复杂的集合类型的索引就可以在某些情况下 (比如将一个元素从特定索引移除时)，不进行强制写时复制，也能包含对存储的引用。我们将会在本书后面的章节中见到像这样的索引定义的例子。)
 
 然而，还有一个很重要的问题：`isKnownUniquelyReferenced` 从来不会为 `NSObject` 的子类返回 `true`，因为子类有它们自己的引用计数实现，所以无法保证总是能返回一个正确的结果。毫无疑问，`NSOrderedSet` 也是 `NSObject` 的一个子类，这么看来我们完蛋了，这简直让人绝望！
 
 噢，等等！如果我们将 `OrderedSet` 扩展，使其包含一个对 Swift 类的替代引用，那么也可以使用替代引用来确定存储引用的唯一性。复制一个 `OrderedSet` 的值将会为它的这两个成员添加新的引用，所以对象的引用计数会保持同步。现在，让我们着手修改 `OrderedSet` 的定义，为其添加一个额外的成员：
*/
private class Canary {}

public struct OrderedSet<Element: Comparable>: SortedSet {
    fileprivate var storage = NSMutableOrderedSet()
    fileprivate var canary = Canary()
    public init() {}
}
/*:
 `canary` 存在的唯一目的是表示变更 `storage` 是否安全。(另外一种方法是将 `NSMutableOrderedSet` 的引用放到新的 Swift 类**内部**。这也可以顺利达到目的。)
 
 现在我们可以定义一个为安全修改存储保驾护航的方法：
*/
extension OrderedSet {
    fileprivate mutating func makeUnique() {
        if !isKnownUniquelyReferenced(&canary) {
            storage = storage.mutableCopy() as! NSMutableOrderedSet
            canary = Canary()
        }
    }
}
/*:
 有一个需要注意的点是，一旦我们发现旧的 canary 过期了，需要立即创建一个新的。假如我们忘了，这个函数会在每次被调用时都复制存储。
 
 至此，实现值语义已经变得手到擒来，只要记住在变更发生之前调用 `makeUnique` 即可。
 
 ## 插入
 
 最后，让我们来实现 `insert`。`NSMutableOrderedSet` 中的 `insert` 方法很像 `NSMutableArray` 的，它接受一个整数索引作为参数：

```swift
class NSOrderedSet: NSObject { // 在 Foundation 中
    ...
    func insert(_ object: Any, at idx: Int)
    ...
}
```

 所幸，我们在上面用过的 `index(of:inSortedRange:options:usingComparator:)` 方法也可以准确地找到我们的新元素应该插入到的索引，以保证不会破坏排序顺序；我们需要做的，就只是将它的 `options` 参数设置为 `.insertionIndex`。这样一来，即使元素不在集合中，它也会返回一个有效索引：
*/
extension OrderedSet {
    fileprivate func index(for value: Element) -> Int {
        return storage.index(
            of: value, 
            inSortedRange: NSRange(0 ..< storage.count),
            options: .insertionIndex,
            usingComparator: OrderedSet.compare)
    }
}
/*:
 准备就绪，我们要开始实现实际的插入了。这并不复杂，只需要将新元素作为参数调用 `index(for:)`，并检查该元素是否已经存在：
*/
extension OrderedSet {
    @discardableResult
    public mutating func insert(_ newElement: Element) -> (inserted: Bool, memberAfterInsert: Element) 
    {
        let index = self.index(for: newElement)
        if index < storage.count, storage[index] as! Element == newElement {
            return (false, storage[index] as! Element)
        }
        makeUnique()
        storage.insert(newElement, at: index)
        return (true, newElement)
    }
}
/*:
 我们付出了相当大的努力来实现 `makeUnique`；如果我们在上面忘记调用它，估计就只能用追悔莫及来形容复杂的心情了。但事实上这个错误很容易发生，然后我们就会疑惑：为什么向一个集合插入值时，偶尔会把其它集合也一同修改了。
 
 结束了！我们现在有了第二个可以愉快玩耍的 `SortedSet` 实现。
 
 ## 测试
 
 以下是以随机顺序将 1 到 20 之间的数字插入有序集合的代码：
*/
var set = OrderedSet<Int>()
for i in (1 ... 20).shuffled() {
    set.insert(i)
}
/*:
 这个集合中的数据应该是有序的；让我们来看看结果是否正确：
*/
set
/*:
 太棒了！那 `contains` 怎么样呢？它能正确地进行查找吗？
*/
set.contains(7)
set.contains(42)
/*:
 我们也可以使用 `Collection` 的方法来操作集合。作为测试，让我们来试一试计算所有元素的总和：
*/
set.reduce(0, +)
/*:
 没问题，那我们能得到正确的值语义吗？
*/
let copy = set
set.insert(42)
copy
set
/*:
 看起来也没有问题。会不会感觉很了不起呢？
 
 我们还做了一些额外的工作，来确保我们的 `OrderedSet` 支持没有实现 `Hashable` 的 `Element`，所以现在最好来检查一下是否能正常运作。下面是一个包含单一整型属性的简单可比较结构体：
*/
import Foundation
struct Value: Comparable {
    let value: Int
    init(_ value: Int) { self.value = value }
    
    static func ==(left: Value, right: Value) -> Bool {
        return left.value == right.value
    }
    
    static func <(left: Value, right: Value) -> Bool {
        return left.value < right.value
    }
}
/*:
 当我们将 `Value` 转换为 `AnyObject` 时，它们会得到一个没有使用 `==` 的 `isEqual` 实现，而 `hash` 属性会返回一些看起来很随机的值，如下所示：
*/
let value = Value(42)
let a = value as AnyObject
let b = value as AnyObject
a.isEqual(b)
a.hash
b.hash
/*:
 我们可以将这个类型放到前面的例子中试一试，以验证 `OrderedSet` 并不依赖于哈希：
*/
var values = OrderedSet<Value>()
(1 ... 20).shuffled().map(Value.init).forEach { values.insert($0) }
values.contains(Value(7))
values.contains(Value(42))
/*:
 很棒，看起来没有问题。
 
 我认为在本书的 playground 版本中进行测试是个好主意。还可以顺便试着切换到有 bug 的 `contains` 版本来看一看它会对结果造成怎样的影响。
 
 ## 性能
 
 下图绘制了 `OrderedSet` 操作的性能。
 这个图中最显眼的一个地方是 `contains` 和 `contains2` 之间的巨大差距。看来说 Foundation 的  `NSOrderedSet.contains` 很快并不是在开玩笑：比起二分查找快了大约 15–25 倍。比较悲剧的是，这只针对可哈希的元素...
 
 ![图 3.2: `OrderedSet` 操作的性能测试结果。该图基于双对数坐标系反映了单次迭代中输入值的元素个数和总体执行时间的关系。](Images/OrderedSet.png)
 
 实在有趣，当元素数量超过 16,000 之后，`contains2`、`forEach` 和 `for-in` 似乎全都慢了下来。`contains2` 在一个哈希表中查找随机值，所以我们好像可以把它的下降原因归结为缓存或页表缓存的颠簸，这和 `SortedArray.contains` 的情况差不多。但是这个解释在 `forEach` 和 `for-in` 上说不过去：它们只是按照元素在集合中出现的顺序进行迭代，按理说曲线应该是完全水平的。如果不对 `NSOrderedSet` 进行逆向工程，恐怕很难说发生了什么；这简直是一个谜！
 
 `OrderedSet.insert` 的曲线以二次函数收尾，就像 `SortedArray.insert` 一样。
 下图
 的两个插入算法的实现相互竞争。很显然，元素数量较少时，`NSOrderedSet` 的消耗比 `Array` 大很多，后者较之前者大概快了 64 倍。(部分原因是 `NSOrderedSet` 需要将元素装箱到一个 `NSObject` 衍生类型中；将元素类型转换从 `Int` 转换为一个对整数类型进行简单封装的类，这个类可以将两个算法之间的差距缩小到只有 800%。) 但是在大约 300,000 个元素之后，`NSOrderedSet` 克服了自身不足，最终反而比 Swift 数组快了 2 倍！
 
 ![图 3.3: 比较两种 `insert` 实现的性能。](Images/Insertion2.png)
 
 发生了什么？标准库中的 `Array` 定义有着丰富的语义注释 (semantic annotations)，这有助于编译器以一些几乎想不到的方法来优化代码；编译器还可以内联 `Array` 的方法，从而消除哪怕仅仅是一个函数调用的微小成本，并探寻进一步优化的可能性。那么，这些弱小且无法优化的 Objective-C 类是怎么做到在插入时反而比 `Array` 更快的呢？
 
 秘密在于，`NSMutableOrderedSet` 可能是构建在 `NSMutableArray` 之上的。`NSMutableArray` 根本就不是一个数组，它是一个双端队列 (double-ended queue)，简称 *deque*。从前面向 `NSMutableArray` 插入一个新元素与从后面追加一个元素花费的是相同的常量时间。这与 `Array.insert` 形成了鲜明的对比，其中在位置 0 插入一个元素是 $O(n)$ 操作，因为该操作需要通过将每个元素向右移动一个位置来为新元素腾出空间。
 
 将元素向前或向后移动的过程中，`NSMutableArray.insert` 需要移动的元素一定少于一半；当我们有足够多的元素时，大部分的插入时间会被移动元素所占据，所以平均看来，尽管 Swift 编译器的优化足够聪明，`NSMutableArray.insert` 还是会比 `Array.insert` 快两倍。这太酷了！
 
 总体来说，200% 的提速无法完全弥补 `NSOrderedSet` 在元素数量较少时缓慢的缺陷。此外，也许并不太引人注目，但插入操作仍然维持着 $O(n^2)$ 的增长率：创建一个包含四百万元素的 `OrderedSet` 需要花费超过 26 分钟。这可能比 `SortedArray` 要好 (`SortedArray` 处理同样的任务大约需要 50 分钟)，但它依旧慢得可怕。
 
 我们已经在 `NSOrderedSet` 上付出了大量精力，但是得到的回报却不成正比。我们的代码复杂，脆弱，缓慢。不过，这章绝对不能说是**彻头彻尾**的失败，我们又创建了一个正确的 `SortedSet` 实现，而且，我们学到了一个很好的解决方案，来使用 Swift 封装传统的 Objective-C 接口，这会成为一个长期实用的技能。
 
 有没有办法实现真正意义上比 `SortedArray` 更快的 `SortedSet` 呢？答案是肯定的！在此之前，我们需要先学习搜索树。
 
 <!-- end-exclude-from-preview -->

 [Next page](@next)
*/