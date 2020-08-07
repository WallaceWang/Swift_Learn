/*:
 [Previous page](@previous)

 # 写时复制 (Copy-On-Write) 优化
 
 
 在我们每次向 `RedBlackTree` 中添加新元素时，都会创建一棵全新的树。新的树会和原来的树共享一些节点，但是在从根节点到新加入的节点的路径上的节点都是新创建的。这种做法可以很“容易”地实现值语义，但是会造成一些浪费。
 
 如果树的某些节点没有被其他值引用的话，我们完全可以直接修改它们。这不会造成任何问题，因为根本没有其他人知道这个特定的树的实例。直接修改可以避免绝大部分的复制和内存申请操作，通常这会让性能得到大幅提升。
 
 Swift 通过提供 `isKnownUniquelyReferenced` 函数来为引用类型实现优化的写时复制值语义，我们已经介绍过相关内容了。但是在 Swift 3 中，语言本身并没有为我们提供为代数数据类型实现写时复制的工具。我们无法访问 Swift 用来包装节点的私有引用类型，因此也就无法获知某个特定节点是不是只有单一引用。(编译器自己还不够聪明，它也并不能帮我们做写时复制优化。) 同时，想要直接获取一个枚举成员里的值，我们也只能先提取一份它的单独的复制。(注意，与此不同，`Optional` 通过强制解包运算符 `!`，提供了直接访问存储的值的方式。然而，为我们自己的枚举类型提供类似的原地访问的工具只能被使用在标准库中，在标准库外它们是不可用的。)
 
 所以，为了实现写时复制，我们现在只能放弃我们钟爱的代数数据结构，将所有东西以一种更“世俗” (或者要我说的话，更**乏味**) 的命令式的形式进行重写，比如使用传统的结构体和类，以及少量的可选值。
 
 ## 基本定义
 
 首先，我们需要定义一个公有结构体，用来表示有序集合。下面的 `RedBlackTree2` 类型是对一个树节点的引用的简单封装，该节点将作为树的存储根节点。这与 `OrderedSet` 没有任何不同，所以我们现在对这个模式应该已经相当熟悉了：
*/
public struct RedBlackTree2<Element: Comparable>: SortedSet {
    fileprivate var root: Node? = nil
    
    public init() {}
}
/*:
 接下来，定义树的节点：
*/
extension RedBlackTree2 {
    class Node {
        var color: Color
        var value: Element
        var left: Node? = nil
        var right: Node? = nil
        var mutationCount: Int64 = 0

        init(_ color: Color, _ value: Element, _ left: Node?, _ right: Node?) {
            self.color = color
            self.value = value
            self.left = left
            self.right = right
        }
    }
}
/*:
 在原有的 `RedBlackTree.node` 枚举成员的基础上，这个类还包含了一个新的属性：`mutationCount`。它的值表示该节点从被创建以来一共被修改的次数。之后在实现我们的 `Collection` 时，这个值将被用来构建一种全新的索引方式。(我们这里明确将它定义为 64 位整数，这样就算在 32 位系统中，这个值也不会溢出了。在每个节点中都存储 8 个字节的计数器其实并不太必要，因为我们其实只会使用根节点的这个值。让我们先略过这个细节，这么做能让事情多多少少简单一些，在下一章里我们将会寻找减少浪费的方法。)
 
 不过现在还不是开始说下一章内容的时候！
 
 通过使用不同的类型来代表节点和树，意味着我们可以将节点类型的实现细节隐藏起来，而只将 `RedBlackTree2` 暴露为 public。对这个集合类型的外部使用者来说，他们将不会把两者混淆起来。在以前，任何人都可以看到 `RedBlackTree` 的内部实现，都能用 Swift 的枚举字面量语法来创建他们想要的树，这很容易破坏我们的红黑树的特性。
 
 `Node` 类现在是 `RedBlackTree2` 结构体的实现细节，将 `Node` 内嵌在 `RedBlackTree2` 中很完美地诠释了它们的关系。这也避免了 `Node` 与同一模块中可能存在的其他同名类型发生命名冲突的问题。同时，这么做还简化了语法：`Node` 现在将自动继承 `RedBlackTree2` 的 `Element` 这一类型参数，我们不再需要明确地进行指定。
 
 > 同样地，按照传统来说，我们只需要一个 bit 的 `color` 属性，并将它打包到 `Node` 的引用属性的二进制表示中某个没有在使用的位即可；但是在 Swift 中这么做既不安全，又很麻烦。我们最好还是简单地将 `color` 保持为一个独立的存储属性，并且让编译器来设置它的存储。
 
 注意，本质上我们将 `RedBlackTree` 枚举转换为了 `Node` 类型的可选值引用。`.empty` 成员现在以 `nil` 来表示，而非 `nil` 的值则表示一个 `.node`。`Node` 类型是一个在堆上申请内存的引用类型，所以我们将上一个方案中的隐式打包变成了显式的特性，这让我们可以直接访问堆上的引用，并且可以使用 `isKnownUniquelyReferenced`。
 
 <!-- begin-exclude-from-preview -->
 
 ## 重写简单的查找方法
 
 我们要将算法从代数数据结构重写为适合结构体和类的版本，`forEach` 就是一个很好的例子。我们通常需要创建两个方法 -- 一个用于封装结构体的公有方法，和一个用于节点类型的私有方法。
 
 在树为空的情况下，结构体的方法不需要做任何事。当树不为空时，它只需要将调用传递给树的根节点。我们可以通过可选值链来简洁地表达这个意图：
*/
extension RedBlackTree2 {
    public func forEach(_ body: (Element) throws -> Void) rethrows {
        try root?.forEach(body)
    }
}
/*:
 实际上进行中序遍历也只需借助节点的 `forEach` 方法就可以完成：
*/
extension RedBlackTree2.Node {
    func forEach(_ body: (Element) throws -> Void) rethrows {
        try left?.forEach(body)
        try body(value)
        try right?.forEach(body)
    }
}
/*:
 可选值链再一次给我们带来了优雅简洁的代码，太棒了！
 
 我们可以通过使用类似的递归的方式实现 `contains`，但是现在让我们用一种更“过程”式的方法来解决。我们将使用一个 `node` 变量来在树中导航，每次让当前节点与我们要查找的目标更加接近：
*/
extension RedBlackTree2 {
    public func contains(_ element: Element) -> Bool {
        var node = root
        while let n = node {
            if n.value < element {
                node = n.right
            }
            else if n.value > element {
                node = n.left
            }
            else {
                return true
            }
        }
        return false
    }
}
/*:
 这个函数非常类似于我们在第二章中提到的二分查找，不同之处只在于它作用于分支型的引用，而非平面缓冲区 (flat buffer) 的索引。对我们的平衡树来说，该算法同样是对数复杂度。
 
 ## 树形图
 
 显然，我们希望保持酷酷的树形图的特性，所以我们将会重写 `diagram` 方法。原来的方法作用于 `RedBlackTree`，而且其类型被转换为了 `Optional<Node>`。现在我们没法为一个包装了泛型的可选类型定义扩展方法，所以重写该方法最简单的方式是将它转换为一个自由函数：
*/
private func diagram<Element: Comparable>(for node: RedBlackTree2<Element>.Node?, _ top: String = "", _ root: String = "", _ bottom: String = "") -> String {
    guard let node = node else {
        return root + "•\n"
    }
    if node.left == nil && node.right == nil {
        return root + "\(node.color.symbol) \(node.value)\n"
    }
    return diagram(for: node.right, top + "    ", top + "┌───", top + "│   ")
        + root + "\(node.color.symbol) \(node.value)\n"
        + diagram(for: node.left, bottom + "│   ", bottom + "└───", bottom + "    ")
}

extension RedBlackTree2: CustomStringConvertible {
    public var description: String {
        return diagram(for: root)
    }
}
/*:
 ## 实现写时复制
 
 我们可以定义辅助方法，来确保在更改任何东西之前，涉及的引用是独立的，这是实现写时复制最简单的方式。对每个存储引用值的属性，我们都需要为其定义一个辅助方法。在我们的例子里有三个引用：`RedBlackTree2` 结构体中的 `root` 引用，以及 `Node` 中的两个子节点引用 (`left` 和 `right`)，所以一共需要定义三个方法。
 
 所有的三种情况里，辅助方法都需要检查对应的引用是否唯一，如果不唯一，它需要将其替换为一份复制。对一个节点进行复制，意味着以同样的属性创建一个新节点。下面这个简单的函数可以完成这件事：
*/
extension RedBlackTree2.Node {
    func clone() -> Self {
        return .init(color, value, left, right)
    }
}
/*:
 现在让我们来定义这些写时复制辅助方法，先从 `RedBlackTree2` 的根节点开始：
*/
extension RedBlackTree2 {
    fileprivate mutating func makeRootUnique() -> Node? {
        if root != nil, !isKnownUniquelyReferenced(&root) {
            root = root!.clone()
        }
        return root
    }
}
/*:
 还记得我们的 `NSOrderedSet` 封装吗？它有一个 `makeUnique` 方法，做的事情和这里差不多。不过这次我们的引用是可选值，这让事情稍微变复杂了一些。不过好在标准库里有一个接受可选值的 `isKnownUniquelyReferenced` 的重载方法，所以至少我们不需要为此操心。
 
 当我们在 Swift 中做一些像是实现写时复制或者构建非安全值这种低层级操作时，我们需要特别注意我们代码的语义精确度。拿写时复制为例，我们需要知道和掌握引用计数是在何时，以何种方式发生的改变，这样我们才能避免我们的唯一性检查被临时创建的引用破坏。
 
 举例来说，如果你是经验丰富的 Swift 开发者，可能会忍不住将看起来很笨拙的显式 `nil` 检查和随后的强制解包替换成漂亮的 `let` 条件绑定，就像下面这样：

```swift
if let root = self.root, !isKnownUniquelyReferenced(&root) { // BUG!
    self.root = root.clone()
}
```

 这个版本在语法上看起来好一些，**但是它所做的事情完全不同！** `let` 绑定将作为根节点的新的引用存在，因此 `isKnownUniquelyReferenced` 将永远返回 `false`。这会将写时复制优化破坏殆尽。
 
 我们在这里必须如履薄冰，如果有所差池，我们就只能从代码变慢这一点上获得线索，额外的复制并不会造成运行错误，因此很难纠错。
 
 另一方面，如果我们做的复制操作**少于**实际需要，我们的代码就有可能时不时地改变了一个共享的引用类型，从而破坏值语义。与性能上的问题相比较，这个错误要严重得多。如果我们足够幸运，这种对值语义的破坏将会造成运行时错误，比如索引无效等。但是通常结果会更糟：那些拥有引用却被我们忽略的代码有时会导致错误的结果，而我们对于哪里出了问题完全没有线索。这种时候，我只能说，祝你好运！
 
 所以，在实现写时复制的时候一定要**特别特别小心**。即使那些看上去无害的代码美化和改进，都有可能造成非常严重的后果。
 
 让我们回到实现，下面是一个节点中两个子节点的引用的辅助方法。它们都是基于 `makeRootUnique` 进行简单改编而成：
*/
extension RedBlackTree2.Node {
    func makeLeftUnique() -> RedBlackTree2<Element>.Node? {
        if left != nil, !isKnownUniquelyReferenced(&left) {
            left = left!.clone()
        }
        return left
    }

    func makeRightUnique() -> RedBlackTree2<Element>.Node? {
        if right != nil, !isKnownUniquelyReferenced(&right) {
            right = right!.clone()
        }
        return right
    }
}
/*:
 ## 插入
 
 现在我们已经准备好重写 `insert` 了。和之前一样，我们依然需要将它分解为两个部分：一个针对封装结构体的公有方法，以及一个针对节点类的私有方法。(`insert` 已经被拆分为若干更小的负责各自独立子任务的部分，所以这里主要涉及的是每个部分放到哪里的问题。)
 
 封装方法相对简单。它是一个可变方法，所以它必须调用 `makeRootUnique` 来确保变更根节点是可行的。如果树是空的，我们需要为被插入的元素创建一个新的根节点；如果树不为空，我们将调用传递给已经存在的根节点，这个时候我们已经可以确保根节点的引用已经是唯一的了：
*/
extension RedBlackTree2 {
    @discardableResult
    public mutating func insert(_ element: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        guard let root = makeRootUnique() else {
            self.root = Node(.black, element, nil, nil)
            return (true, element)
        }
        defer { root.color = .black }
        return root.insert(element)
    }
}
/*:
 我们使用 `defer` 来无条件地将根节点染黑，这样可以确保满足红黑树的第一个要求。
 
 节点的 `insert` 对应我们原来的 `RedBlackTree` 中的老朋友，`_inserting` 方法：
*/
extension RedBlackTree2.Node {
    func insert(_ element: Element)  -> (inserted: Bool, memberAfterInsert: Element) {
        mutationCount += 1
        if element < self.value {
            if let next = makeLeftUnique() {
                let result = next.insert(element)
                if result.inserted { self.balance() }
                return result
            }
            else {
                self.left = .init(.red, element, nil, nil)
                return (inserted: true, memberAfterInsert: element)
            }
        }
        if element > self.value {
            if let next = makeRightUnique() {
                let result = next.insert(element)
                if result.inserted { self.balance() }
                return result
            }
            else {
                self.right = .init(.red, element, nil, nil)
                return (inserted: true, memberAfterInsert: element)
            }
        }
        return (inserted: false, memberAfterInsert: self.value)
    }
}
/*:
 这里比较讨厌的是，我们只能把 `switch` 转换为一个级联的 `if` 操作，并且加入一堆用来更改值的语句。但是它还是和原来的代码具有相同的结构。事实上，我想要是 Swift 编译器能够自动帮我们进行这个重写就好了。(代数数据结构的写时复制自动优化对编译器来说将会是一个长足的进步，我们也许在**将来**，比如 Swift 10 的时候就能见到这个特性吧...)
 
 回到现实吧，我们现在来看看如何平衡这棵树。
 
 `RedBlackTree` 中我们用了一种基于模式匹配的方式，针对红黑树平衡给出了一种令人难忘的巧妙实现。在文明社会的现代编码中，模式匹配算得上一种优雅的武器。它是如此优美，如此绚烂！
 
 但是我们现在只能用一大坨充满恶臭的赋值语句来玷污这种优雅了：
*/
extension RedBlackTree2.Node {
    func balance() {
        if self.color == .red  { return }
        if left?.color == .red {
            if left?.left?.color == .red {
                let l = left!
                let ll = l.left!
                swap(&self.value, &l.value)
                (self.left, l.left, l.right, self.right) = (ll, l.right, self.right, l)
                self.color = .red
                l.color = .black
                ll.color = .black
                return
            }
            if left?.right?.color == .red {
                let l = left!
                let lr = l.right!
                swap(&self.value, &lr.value)
                (l.right, lr.left, lr.right, self.right) = (lr.left, lr.right, self.right, lr)
                self.color = .red
                l.color = .black
                lr.color = .black
                return
            }
        }
        if right?.color == .red {
            if right?.left?.color == .red {
                let r = right!
                let rl = r.left!
                swap(&self.value, &rl.value)
                (self.left, rl.left, rl.right, r.left) = (rl, self.left, rl.left, rl.right)
                self.color = .red
                r.color = .black
                rl.color = .black
                return
            }
            if right?.right?.color == .red {
                let r = right!
                let rr = r.right!
                swap(&self.value, &r.value)
                (self.left, r.left, r.right, self.right) = (r, self.left, r.left, rr)
                self.color = .red
                r.color = .black
                rr.color = .black
                return
            }
        }
    }
}
/*:
 没错，这就是我们原来的平衡函数直接用命令式的方式重写变形后的样子。这种代码真是闻者伤心，见者落泪。
 
 我们可以稍微重构一下这些代码，让它看起来更顺眼一些 (同时更快一些)。比如，我们可以将 `balance` 嵌入到 `insert` 函数里，这样我们可以根据插入新元素的左右方向，修剪掉一些不必要的分支。
 
 不过更简单的是，打开一本数据结构的教材，然后把里面关于红黑树的插入的算法直接照搬到 Swift 里。我们在这里不会去做这件事，因为这实在太无聊了，而且也不会让我们的代码变快很多。
 
 > 如果你依然对此感兴趣，可以看看我为 Swift 2 设计的[红黑树实现][rbt-insert]。我没有将它升级到 Swift 3，这是因为我们在接下来的章节要介绍的 B 树要比它好得多，所以我也就没有动力去升级了。
 
 [rbt-insert]: https://github.com/lorentey/RedBlackTree/blob/master/Sources/RedBlackTree.swift#L770-L819
  
 ## 实现 `Collection`
 
 我们来看看这次能不能给出一个更好的索引实现吧。
 
 在 `RedBlackTree` 里，我们使用了一个对元素值进行包装的 dummy 索引类型。为了实现 `index(after:)`，我们需要从头开始寻找元素在树中的位置，这个操作的时间复杂度是 $O(\log n)$。
 
 也就是说，当我们在整个 `RedBlackTree` 中用索引进行迭代的时候，我们要做的是一个 $O(n\log n)$ 的操作，这里 $n$ 是集合类型中元素的个数。这是很糟糕的结果，在一个集合类型中迭代所有元素应该只需要 $O(n)$ 的时间才对！(虽然这实际上不是 `Collection` 的要求，但是这绝对是一个合理的预期。)
 
 那么，我们怎么办呢？一种加速的办法是让索引包含从根到某个元素的整个路径。
 
 不过，这个想法有一个小问题，索引不应该持有集合类型中某些部分的强引用。所以，我们可以用一个弱引用的数组来表示路径。
 
 ### 索引定义
 
 Swift 3 里，我们不能直接定义一个弱引用数组，所以首先我们需要为弱引用定义一个简单的结构体封装：
*/
private struct Weak<Wrapped: AnyObject> {
    weak var value: Wrapped?

    init(_ value: Wrapped) {
        self.value = value
    }
}
/*:
 我们现在可以把路径声明为一个包含 `Weak` 值的数组了。在使用时，我们需要记住在 `Weak` 值后添加 `.value` 才能取出实际的引用 (比如 `path[0].value`)，不过这只是一个存在于表面的小问题。这个封装结构体不会在运行时造成任何性能问题。不过每次都这么做还是有一点麻烦，在语言层面添加 weak 或是 unowned 的数组支持也许是个不错的 Swift 特性提案。不过我们这里要做的是实现一个有序集合，而不是增强 Swift 本身，所以让我们先接受这一点语言上的小瑕疵并且继续前行吧。
 
 现在，我们可以定义实际的索引类型了。基本上来说，它是一个对路径的封装，里面保存了一个以弱引用方式持有节点的数组。为了能够简单地验证索引，我们还添加了一个直接指向根节点的弱引用，以及在索引被创建时根节点被更改次数的复制：
*/
extension RedBlackTree2 {
    public struct Index {
        fileprivate weak var root: Node?
        fileprivate let mutationCount: Int64?
    
        fileprivate var path: [Weak<Node>]
    
        fileprivate init(root: Node?, path: [Weak<Node>]) {
            self.root = root
            self.mutationCount = root?.mutationCount
            self.path = path
        }
    }
}
/*:
 下面的图表
 描述了一个索引的例子，它指向的是红黑树里的第一个值。注意，索引使用的都是弱引用，所以它不会保留任何一个树的节点。`isKnownUniquelyReferenced` 函数只计算强引用，这样一来，特定索引就不会影响到树的原地变更了。不过，这也意味着变更将会破坏之前创建的索引中的节点引用，所以我们需要对索引验证格外小心。
 
 ![图 5.1: 由 `RedBlackTree2.Index` 实现的一棵简单红黑树的起始索引。虚线表示弱引用。](Images/RedBlackTree-Index@3x.png)
 
 ### 起始索引和结束索引
 
 让我们开始写 `Collection` 的相关方法吧。
 
 首先，我们可以将 `endIndex` 定义为一个空路径，这很简单：
*/
extension RedBlackTree2 {
    public var endIndex: Index {
        return Index(root: root, path: [])
    }
/*:
 起始索引也不太困难，我们只需构建一条通往树里最左侧元素的路径：
*/
    // - 复杂度: O(log(n)); 这违背了 `Collection` 的要求。
    public var startIndex: Index {
        var path: [Weak<Node>] = []
        var node = root
        while let n = node {
            path.append(Weak(n))
            node = n.left
        }
        return Index(root: root, path: path)
    }
}
/*:
 该操作会消耗 $O(\log n)$ 的时间，这再一次打破了 `Collection` 的相应要求。当然，我们有办法可以修复它，但是相比在 `RedBlackTree` 里，这需要更多的技巧，况且我们也无法确认收益是否能值回这样的付出，所以我们暂时先搁置这个问题。如果在一个实际的软件包里，我们可能需要在文档中指出这一点，并给出警告，让我们的用户知道这件事情。(有些集合类型操作可能会因此变慢很多。)
 
 ### 索引验证
 
 接下来我们想讨论一下索引验证。对 `RedBlackTree2` 来说，我们需要在每次发生变更后让所有的索引失效，因为变更有可能修改或者替换了存储于索引路径上的某些节点。
 
 要做到这一点，我们需要验证树的根节点和索引中的根节点引用是否相同，然后再检查它们是否拥有相同的变更次数。对一个空树的有效索引来说，其根节点为 `nil`，这让事情稍微复杂了一些：
*/
extension RedBlackTree2.Index {
    fileprivate func isValid(for root: RedBlackTree2<Element>.Node?) -> Bool {
        return self.root === root 
            && self.mutationCount == root?.mutationCount
    }
}
/*:
 如果这个函数没有出错，我们就知道索引属于正确的树，并且树并没有在索引创建后被变更。也就是说，索引路径包含的是有效的引用。否则，就意味着路径上包含的弱引用或者节点里有变更后的值，因此我们也就不能再使用这个索引。
 
 要进行索引比较，我们需要检查两个索引是否属于同一棵树，以及它们对于这棵树来说是否都是有效的。这里有一个静态函数做这件事情：
*/
extension RedBlackTree2.Index {
    fileprivate static func validate(_ left: RedBlackTree2<Element>.Index, _ right: RedBlackTree2<Element>.Index) -> Bool {
        return left.root === right.root
            && left.mutationCount == right.mutationCount
            && left.mutationCount == left.root?.mutationCount
    }
}
/*:
 ### 下标
 
 通过索引来实现下标操作非常激动人心，因为它包含了不止一个，而是两个感叹号！！：
*/
extension RedBlackTree2 {
    public subscript(_ index: Index) -> Element {
        precondition(index.isValid(for: root))
        return index.path.last!.value!.value
    }
}
/*:
 这里对于强制解包的使用是没有问题的，通过 `endIndex`，或者是一个无效的索引来进行下标操作，确实应该造成崩溃。我们可以提供更好的错误信息，但是现在来说这样就足够了。
 
 ### 索引比较
 
 索引必须可以被比较，要实现这一点，我们采用和 `RedBlackTree` 里一样的做法，简单地将两个索引路径中的最后一个节点取出来，然后比较它们的值。现在让我们来看看可以如何取得一个索引的当前节点：
*/
extension RedBlackTree2.Index {
    /// 前置条件: `self` 是有效索引。
    fileprivate var current: RedBlackTree2<Element>.Node? {
        guard let ref = path.last else { return nil }
        return ref.value!
    }
}
/*:
 这个属性假设了索引是有效的，否则强制解包可能会失败，并让我们的程序崩溃。
 
 我们现在可以写比较的代码了，这和我们之前做的很相似：
*/
extension RedBlackTree2.Index: Comparable {
    public static func ==(left: RedBlackTree2<Element>.Index, right: RedBlackTree2<Element>.Index) -> Bool {
        precondition(RedBlackTree2<Element>.Index.validate(left, right))
        return left.current === right.current
    }

    public static func <(left: RedBlackTree2<Element>.Index, right: RedBlackTree2<Element>.Index) -> Bool {
        precondition(RedBlackTree2<Element>.Index.validate(left, right))
        switch (left.current, right.current) {
        case let (a?, b?):
            return a.value < b.value
        case (nil, _):
            return false
        default:
            return true
        }
    }
}
/*:
 ### 索引步进
 
 最后，我们要实现索引的步进操作。我们将把实际的工作转交给索引类型上的一个可变方法，我们之后马上会去实现这个方法：
*/
extension RedBlackTree2 {
    public func formIndex(after index: inout Index) {
        precondition(index.isValid(for: root))
        index.formSuccessor()
    }

    public func index(after index: Index) -> Index {
        var result = index
        self.formIndex(after: &result)
        return result
    }
}
/*:
 想要找到一个已存在索引的后续索引，我们需要寻找当前节点的右子树中的最左侧节点。如果当前节点没有右子树，那么我们就回到向上一级的节点，并判断当前节点是否存在于这个上级节点的**左**子树中。
 
 如果树里没有这样的上级节点，那就意味着我们到达了集合类型的尾部。这种情况下，返回一个和集合类型的 `endIndex` 一样的空路径索引正是我们所需要的：
*/
extension RedBlackTree2.Index {
    /// 前置条件: 除了 `endIndex` 以外，`self` 也是有效索引。
    mutating func formSuccessor() {
        guard let node = current else { preconditionFailure() }
        if var n = node.right {
            path.append(Weak(n))
            while let next = n.left {
                path.append(Weak(next))
                n = next
            }
        }
        else {
            path.removeLast()
            var n = node
            while let parent = self.current {
                if parent.left === n { return }
                n = parent
                path.removeLast()
            }
        }
    }
}
/*:
 为了满足 `BidirectionalCollection`，我们还需要实现从任意索引开始向前返回。实现的代码和 `index(before:)` 具有完全相同的结构，只是我们需要将左右互换，另外，我们还需要对 `endIndex` 做特殊处理：
*/
extension RedBlackTree2 {
    public func formIndex(before index: inout Index) {
        precondition(index.isValid(for: root))
        index.formPredecessor()
    }

    public func index(before index: Index) -> Index {
        var result = index
        self.formIndex(before: &result)
        return result
    }
}

extension RedBlackTree2.Index {
    /// 前置条件: 除了 `startIndex` 以外，`self` 也是有效索引。
    mutating func formPredecessor() {
        let current = self.current
        precondition(current != nil || root != nil)
        if var n = (current == nil ? root : current!.left) {
            path.append(Weak(n))
            while let next = n.right {
                path.append(Weak(next))
                n = next
            }
        }
        else {
            path.removeLast()
            var n = current
            while let parent = self.current {
                if parent.right === n { return }
                n = parent
                path.removeLast()
            }
        }
    }
}
/*:
 ## 例子
 
 呼，全部搞定了！让我们试试看这个新的类型吧：
*/
var set = RedBlackTree2<Int>()
for i in (1 ... 20).shuffled() {
    set.insert(i)
}
set

set.contains(13)

set.contains(42)

set.filter { $0 % 2 == 0 }
/*:
 ## 性能测试
 
 在 `RedBlackTree2` 上进行通常的性能测试，可以得到下面的结果。
 `insert`、`contains` 和 `forEach` 的曲线形状与我们在 `RedBlackTree` 中看到的结果大致一样。但是 `for-in` 的性能看起来却非常奇怪！
 
 ![图 5.2: `RedBlackTree2` 操作的性能测试，单次迭代的情况下，输入元素个数和平均执行时间的对数关系图。](Images/RedBlackTree2Benchmark.png)
 
 ### 优化迭代性能
 
 我们重新设计了索引类型，这样 `index(after:)` 在平摊后将以常数时间运行。看起来我们成功了：`for-in` 的曲线很平缓，它只在集合尺寸较大时有些许增加，但是它在整张图里实在是太高了！对于少于 100,000 个元素的小集合来说，显然插入一个元素比迭代还要快，这是不合常理的。
 
 下图
 将 `RedBlackTree` 和 `RedBlackTree2` 的 `for-in` 性能进行了对比。我们可以看到，`RedBlackTree2.index(after:)` 平摊下来确实是一个常数时间复杂度的操作，对于非常庞大的数据集，曲线也保持了平坦。而 `RedBlackTree` 的操作中索引步进是对数复杂度，它的渐进特性 (随着数据集扩大的耗时) 要差一些。不过因为这条曲线的起点要低得多，所以在元素数量达到大约一千六百万之前，都要比 `RedBlackTree2` 更快，这个值已经远远超过我们的性能测试图的显示范围了。这样的常数复杂度可以说不要也罢。
 
 ![图 5.3: 基于树结构的有序集合中 `for-in` 实现的性能对比。](Images/TreeIteration1.png)
 
 想要让 `RedBlackTree2` 和 `RedBlackTree` 里的原始的索引有相同竞争力的话，我们需要将它的索引操作提速四倍。虽然这应该是可能的，但是现在我们还不清楚要如何才能达到这个目标。不管那么多，我们可以先来尝试一下！
 
 移除索引验证是一个努力方向，因为它是迭代的主要开销来源之一。将索引验证完全移除显然不是什么好主意，但是在 `for-in` 循环的这个特例里，索引验证是完全没有必要的：集合在迭代过程中保持不变，所以验证永远不会失败。想要移除验证，我们可以放弃 `Collection` 默认的 `IndexingIterator`，取而代之，改用特殊的 `IteratorProtocol` 实现，它可以直接处理索引：
*/
extension RedBlackTree2 {
    public struct Iterator: IteratorProtocol {
        let tree: RedBlackTree2
        var index: RedBlackTree2.Index
        
        init(_ tree: RedBlackTree2) {
            self.tree = tree
            self.index = tree.startIndex
        }
    
        public mutating func next() -> Element? {
            if index.path.isEmpty { return nil }
            defer { index.formSuccessor() }
            return index.path.last!.value!.value
        }
    }
}

extension RedBlackTree2 {
    public func makeIterator() -> Iterator {
        return Iterator(self)
    }
}
/*:
 注意，很明显现在迭代器包含了一份对树的冗余复制。虽然我们在 `next` 中从未使用过这个存储属性，但是它扮演的角色却非常重要：它为我们保持着根节点，这保证了树在迭代器的生命周期内不会被释放。
 
 通过这个自定义的迭代器，我们的 `for-in` 得到了两倍的性能提升。
 (参见下图中的 `for-in2` 曲线。)
 这是一个不错的结果，但是我们想要 400% 的提速，所以我们来看看还有哪些方法能让迭代速度更快。
 
 ![图 5.4: 基于树结构的有序集合中 `for-in` 实现的性能对比。`RedBlackTree2.for-in2` 通过实现自定义迭代器移除了不必要的索引验证步骤，`for-in3` 将弱引用替换为不安全的 unowned 引用。](Images/TreeIteration2.png)
 
 一个值得注意的关键点是，我们对更改计数进行的检查，确保了一个有效索引的路径上永远不会有过期的弱引用，因为路径所关联的树还存在，所以那些节点和索引被创建时的节点完全是同样的东西。也就是说，我们可以安全地将路径上的弱引用替换为 `unowned(unsafe)`。这样一来，所有的引用计数的管理操作都被移除了，这带来了另一次两倍的性能提升。(参见上图中的 `for-in3` 曲线)。这让我们获得了可以接受的 `for-in` 性能，所以我们的优化可以在此告一段落了。
 
 在 `RedBlackTree2` 中，我们选择了渐进性能更好的索引算法，但是它并没有直接为我们带来更快的结果：算法的优势受累于实现的细节。然而，我们成功地进行了优化，使这个“更好”的算法的结果可以匹敌于“更差”的算法。在这个例子中，我们非常幸运，在两个相对简单的优化步骤之后就达到了满意的效果。一般来说，我们需要做的远不止如此！
 
 ### 插入性能
 
 `RedBlackTree2` 为我们带来了一个非常高效的基于树结构的 `SortedSet` 实现。如
 下图
 所示，通过原地变更，插入性能有了 300–500% 的提升。`RedBlackTree2.insert` 不再迟钝，现在它能在仅仅 12 秒内就完成四百万次插入操作。
 
 ![图 5.5: 对比四种 `insert` 实现的性能。](Images/Insertion4.png)
 
 但是在低于 8,000 个元素的时候，它还是比不上 `SortedArray`：后者要比红黑树快上四倍。嗯...虽然肯定有办法将红黑树的插入操作做进一步优化，但是看起来可能达不到 400% 的加速。那么，下面我们要做些什么呢？
 
 <!-- end-exclude-from-preview -->

 [Next page](@next)
*/