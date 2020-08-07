/*:
 [Previous page](@previous)

 # 红黑树
 
 
 **自平衡二叉搜索树**可以为有序集合类型的实现提供高效的算法。特别是，用这些数据结构来实现的有序集合，其中元素的插入只需消耗对数时间。这实在是一个相当有吸引力的特性，还记得吗，我们实现的 `SortedArray` 的插入是线性时间复杂度的操作。
 
 “自平衡二叉搜索树”这样的描述看起来多少有些专业，每个词组都有一个具体的含义，之后我会快速地解释一下它们。
 
 **树**是一种将数据存储在**节点**内部，按分支排布为树状结构的数据结构。每棵树有一个位于顶部的单独节点，被称作**根节点**。(树的根被置于顶部，追溯历史，计算机科学家们已经将树颠倒着画了几十年了。这并不是因为他们不知道一棵真实的树长什么样，只不过这样更容易画树形图而已。反正，至少我希望是这样的。) 如果一个节点没有子节点，那就将它称为**叶子节点**；否则就是一个**内部节点**。一棵树通常有大量叶子节点。
 
 通常，内部节点可能拥有任意个子节点，但是对于**二叉树**来说，节点只可以拥有**左**和**右**两个子节点。一些节点有两个子节点，当然，只有左子节点或右子节点甚至是根本没有子节点的情况也是时常存在的。
 
 ![图 4.1: 一棵二分搜索树。节点 6 是根节点；节点 6、3 和 8 是内部节点，而节点 2、4 和 9 是叶子。](Images/SearchTree@3x.png)
 
 在**搜索树**中，节点内部的值在某种程度上是可比较的，而且树中的节点都是按照一定次序排列的，所有左子树中的值都比节点自身的小，右子树则相反，比节点自身的值更大。这使得查找任意指定元素变得很容易。
 
 通过**自平衡** (意味着这个数据结构有排序机制)，无论一棵树包含什么值，以及这些值以什么顺序被插入，这棵树的高度都可以确保尽可能低，且在此范围内保持完整而茂密。如果允许树肆意地生长，那么很简单的操作都可能变得效率奇低。(举一个极端的例子来说，如果一棵树所有的节点最多都只有一个子节点，如同链表一般，那可以说是根本没有效率。)
 
 创建自平衡二叉树的方法有很多；在这个部分中，我们将会实现一个名叫**红黑树**的版本。由于红黑树自身独有的特征，为了实现自平衡的部分，每个字节都需要额外多存储一位来保存相关信息。这额外的一位是节点的颜色，可以是红色或黑色。
 
 ![图 4.2: 一棵示例红黑树。](Images/RedBlackTree@3x.png)
 
 红黑树总是保持它的节点的按照一定顺序排布，并以恰当的颜色着色，从而始终满足下述几条性质：
    
 1. 根节点是黑色的。
 2. 红色节点只拥有黑色的子节点。(只要有，就一定是。)
 3. 从根节点到一个空位，树中存在的每一条路径都包含相同数量的黑色节点。
 
 空位指的是在树中所有可以插入新节点的空间，即，一个左右子节点都没有的节点。要让增长一个节点，我们只需要用一个新节点替换它的一个空位即可。
 
 第一个性质使得算法略微简单了一点；而且完全不会影响树的形态。后两个性质保证了树的密度始终良好，树中的空位与根节点的距离，不会超过其它任意节点与根节点距离的两倍。
 
 为了完全理解这些平衡性质，稍微做几个小实验，探索一下它们的极端情况，可能会很有帮助。例如，可以构建一棵只包含黑色节点的红黑树；
 下面的树就是一个例子。
 
 ![图 4.3: 每个节点都是黑色的示例红黑树。](Images/RedBlackTree-Black@3x.png)
 
 如果我们尝试构建更多的例子，很快就会意识到红黑树的第三条性质其实将这种树限定为了一种特定的形态：所有内部节点都有两个子节点，而且所有叶子节点都在同一层上。形态如此的树被称为**完美树**，因为它们完全平衡，完全对称。我们期望所有平衡树都这样生长成这样的理想形态，因为它的每个节点都已尽可能靠近根节点。
 
 不过，要求平衡算法来维护完美树是不可能的：实际上，只有特定的节点数才能构建完美搜索树。比方说，没有哪棵完美树拥有四个节点。
 
 为了使红黑树更实用，第三条性质使用了一个平衡的弱定义，那就是红色节点并不会被计算。不过，为了不让事情变的**难以控制**，第二条性质将红色节点的数量限制在了合理范围内：这确保了在树中的任何指定路径上，红色节点的数量都不会超过黑色节点。
 
 <!-- begin-exclude-from-preview -->
 
 ## 代数数据类型
 
 现在关于红黑树应该是什么，我们有了一个粗略的想法，让我们从一个节点的颜色开始，马上进入实现环节吧。传统上通常会使用低层次 hack 的方式将颜色信息放到节点的二进制表示的一个未使用的位中，这样的话可以不占用额外的空间。但是我们喜欢干净且安全的代码，所以使用枚举来表示颜色才是我们的心之所向：
*/
public enum Color {
    case black
    case red
}
/*:
  
 > 事实上，并不需要我们做任何事，Swift 编译器有时自己就能够将颜色的值放到这样一个未使用的位。相较于 C/C++/Objective-C，Swift 类型的二进制布局非常灵活，而且编译器拥有很大程度的自由来决定如何进行打包。对于具有关联值的枚举来说尤其如此，编译器经常能够找到未使用的位模式来表示枚举成员，而无需分配额外的空间来区分它们。例如，`Optional` 会将一个引用类型封装到其自身的空间中。`Optional.none` 成员则由一个从来没有被任何有效引用使用过的 (全零) 位模式来表示。(顺便一提，相同的全零位模式也用来表示 C 的空指针和 Objective-C 的 `nil` 值，这在某种程度上提供了二进制兼容性。)
 
 一棵树本身要么是空的，要么含有一个根节点，这个根节点具有颜色，且包含一个值和左右两个子节点。Swift 允许枚举的成员包含字段值，这能够将该描述转换为第二个枚举类型：
*/
public enum RedBlackTree<Element: Comparable> {
    case empty
    indirect case node(Color, Element, RedBlackTree, RedBlackTree)
}
/*:
 在实际的代码中，我们常常会给一个节点的字段加上标签，这样它们所扮演的角色就很清晰了。这里我们没有给它们命名，单纯只是为了避免下面的示例代码在不合适的地方被换行。对此我深感抱歉。
 
 我们之所以需要使用 `indirect case` 语法，是因为节点的子节点是树本身。`indirect` 关键字强调了在我们的代码中递归的存在，而且也允许编译器将节点的值装箱到隐藏的在堆上申请内存的引用类型中。(这么做是必须的，它可以防止不必要的麻烦，比如编译器无法将特定的存储大小分配给枚举值。递归这种数据结构有时候很是棘手。)
 
 拥有像这样的字段的枚举体现了 Swift 定义**[代数数据结构][adt]**的方式，(马上就会看到) 这为我们提供了一种强大而优雅的构建数据结构的方式。
 
 [adt]: https://en.wikipedia.org/wiki/Algebraic_data_type
 
 至此新红黑树类型的骨架搭建已经完成，我们准备进一步在树上实现 `SortedSet` 的方法。
 
 ## 模式匹配和递归
 
 当使用代数数据类型的时候，我们一般使用模式匹配来将我们想要的解决的问题拆分为许多不同的情况，然后一一解决各种不同的情况。对于某一种特定情况来说，通常我们会依赖递归的方式来解决这种情况中稍小的版本。
 
 ### `contains`
 
 举个例子，让我们来看一看 `contains` 的实现。我们的搜索树按照特定的顺序存储值，据此我们可以将查找一个元素这个问题分割为四种小情况：
 
 1. 如果树为空，则它不包含任何元素，`contains` 一定返回 `false`。
 2. 或者，树的顶端肯定有一个根节点。如果存储的元素恰好等于我们正在查找的元素，那么我们就知道了这棵树包含元素；这种情况下 `contains` 应该返回 `true`。
 3. 或者，如果根值大于我们正在查找的元素，那么该元素一定不存在于右子树中。当且仅当元素存在于左子树，树才包含该元素。
 4. 或者，根值比元素小，那么在右子树中进行查找即可。
 
 我们可以使用 `switch` 语句将上面的文字描述直接转换为 Swift 表达式：
*/
public extension RedBlackTree {
    func contains(_ element: Element) -> Bool {
        switch self {
        case .empty:
            return false
        case .node(_, element, _, _):
            return true
        case let .node(_, value, left, _) where value > element:
            return left.contains(element)
        case let .node(_, _, _, right):
            return right.contains(element)
        }
    }
}
/*:
 用 Swift 的模式匹配语法表达这类结构条件非常自然。我们将在 `RedBlackTree` 上定义的大多数方法都会遵循这种结构，当然了，细节上各有不同。
 
 ### `forEach`
 
 在 `forEach` 中，我们想按照升序在树中对所有元素调用一个闭包。如果树为空，没有任何难度就可以做到：因为根本就什么都不用做。除此之外，我们需要先访问所有左子树中的元素，然后是存储在根节点中的元素，最后访问右子树中的元素。
 
 这样的场景很适合使用 `switch` 语句的另一种递归方法：
*/
public extension RedBlackTree {
    func forEach(_ body: (Element) throws -> Void) rethrows {
        switch self {
        case .empty:
            break
        case let .node(_, value, left, right):
            try left.forEach(body)
            try body(value)
            try right.forEach(body)
        }
    }
}
/*:
 这个例子甚至比 `contains` 还要简短，但是你会发现它们有着相同的构造，类似的风格：在 `switch` 语句中有几个模式匹配的分支，以及在分支内部偶尔使用递归。
 
 这个算法对树进行了**中序遍历** (inorder walk)。记住这个词会很有用；如果你打算去参加面试，而考官出题很可能就涉及到这样的名词，要是你不知所云的话，那可就完蛋了。当我们在一棵搜索树中进行中序遍历时，我们将会从最小值到最大值“按照顺序”访问元素。
 
 ## 树形图
 
 接下来，我们将会稍微绕一点儿路，用一个很有意思的自定义方法来实现 `CustomStringConvertible`。(我希望你还记得，我们曾经在引言中写过一个泛型的版本。)
 
 开发一个新的数据结构时，投资一些额外的时间来保证我们可以用一个简单易懂的格式来输出值的确切结构是非常有价值的。这份投资通常会让调试变得容易很多，可以让你事半功倍。至于红黑树，我们会**尽可能**努力，使用 Unicode 图形来构建精细的小规模树形图。
 
 下面的属性返回代表 `Color` 的符号，我们以此作为开始。目前黑白小方块表现尚可：
*/
extension Color {
    public var symbol: String {
        switch self {
        case .black: return "■"
        case .red:   return "□"
        }
    }
}
/*:
 (另一个选择是使用黑色和红色的 emoji 圆形，即 ⚫️ 和 🔴。我认为它们稍微有点喧宾夺主，但是如果你喜欢它们，也请放心使用。不管黑猫白猫，能抓住耗子就是好猫！)
 
 我们将会巧妙地修改 `forEach` 函数来让它自己生成图。为了让本书不那么无聊，我决定把读懂这段代码的机会留给你，也许这能让你更容易弄清楚到底发生了什么。我保证，它绝不像看起来那样难以下手！(提示：可以尝试改变一些字符串文字，看看下面的输出结果会有什么变化。)
*/
extension RedBlackTree: CustomStringConvertible {
    func diagram(_ top: String, _ root: String, _ bottom: String) -> String {
        switch self {
        case .empty:
            return root + "•\n"
        case let .node(color, value, .empty, .empty):
            return root + "\(color.symbol) \(value)\n"
        case let .node(color, value, left, right):
            return right.diagram(top + "    ", top + "┌───", top + "│   ")
                + root + "\(color.symbol) \(value)\n"
                + left.diagram(bottom + "│   ", bottom + "└───", bottom + "    ")
        }
    }

    public var description: String {
        return self.diagram("", "", "")
    }
}
/*:
 让我们来看看对于一些简单的树，`diagram` 做了什么。`RedBlackTree` 只是一个枚举，所以我们可以通过手动嵌套枚举来构建各种各样的树。
     
 1. 一棵空树被打印为一个小黑点。它是由上述 `diagram` 方法的第一个 `case` 模式实现的：
*/
    let emptyTree: RedBlackTree<Int> = .empty
emptyTree
/*:
     
 2. 只有一个节点的树会匹配第二个 `case` 模式，所以它被打印为一条由节点颜色和值组成的线上：
*/
    let tinyTree: RedBlackTree<Int> = .node(.black, 42, .empty, .empty)
tinyTree
/*:
     
 3. 最后，一棵拥有根节点且包含非空子节点的树与第三个 `case` 相匹配。它的描述看起来和前一个 `case` 很相似，不过根节点已经生长出表示其子节点的左右枝：
*/
    let smallTree: RedBlackTree<Int> = 
        .node(.black, 2, 
            .node(.red, 1, .empty, .empty), 
            .node(.red, 3, .empty, .empty))
smallTree
/*:
 即使表示更复杂的树，也一样没问题，图形也确实像一棵树：
*/
let bigTree: RedBlackTree<Int> =
    .node(.black, 9,
        .node(.red, 5,
            .node(.black, 1, .empty, .node(.red, 4, .empty, .empty)),
            .node(.black, 8, .empty, .empty)),
        .node(.red, 12,
            .node(.black, 11, .empty, .empty),
            .node(.black, 16,
                .node(.red, 14, .empty, .empty),
                .node(.red, 17, .empty, .empty))))
bigTree
/*:
 是不是还挺齐整的？有时使用代数数据结构就是这么神奇，本该很复杂的事情，在你不经意之间就完成了。
 
 现在我们要回到编码中去了，让我们继续来构建一个有序集合的实现。
 
 ## 插入
 
 在 `SortedSet` 中，我们将插入定义为了一个可变函数。不过，对于红黑树的例子来说，我们将会定义一个更简单的函数式版本，该版本不会对已经存在的树进行修改，它将返回一棵全新的树。下面是为它量身打造的函数签名：

```swift
func inserting(_ element: Element) -> (tree: RedBlackTree, existingMember: Element?) 
```

 拥有这样的一个函数，我们就可以通过将该函数返回的树赋值给 `self` 自身来实现可变插入了：
*/
extension RedBlackTree {
    @discardableResult
    public mutating func insert(_ element: Element) -> (inserted: Bool, memberAfterInsert: Element) 
    {
        let (tree, old) = inserting(element)
        self = tree
        return (old == nil, old ?? element)
    }
}
/*:
 对于 `inserting`，我们将参照由 [Chris Okasaki 在 1999 年][okasaki99-doi] 首次发表的一个非常出色的模式匹配算法来进行实现。
 
 [okasaki99-doi]: https://dx.doi.org/10.1017%2FS0956796899003494
 
 务必牢记在心，红黑树需要满足下述三个要求：
    
 1. 根节点是黑色的。
 2. 红色节点只拥有黑色的子节点。(只要有，就一定是。)
 3. 从根节点到任意一个空位，树中存在的每一条路径都包含相同数量的黑色节点。
 
 保证满足第一个要求的方法是，当作要求并不存在，直接插入元素。如果得到的树的根节点恰好是红色，则将它染黑即可，这么做并不会影响其它要求。(第二个要求只关心红色节点，所以我们可以将每一个节点都绘制为黑色，这样并不会破坏这条要求。对于第三个要求：根节点存在于树中的每一条路径上，所以将它染黑能够统一增加所有路径上包含的黑色节点数量。因此，如果树在为根节点染色之前本来就已经满足第三个要求的话，那么重新将树进行染色也并不会违反这个条件。)
 
 所有的这些考虑指引着我们将 `inserting` 定义为一个致力于保证第一个要求的短小的封装函数。它将实际的插入操作委托给一些我们尚未定义的内部辅助函数：
*/
extension RedBlackTree {
    public func inserting(_ element: Element) -> (tree: RedBlackTree, existingMember: Element?) {
        let (tree, old) = _inserting(element)
        switch tree {
        case let .node(.red, value, left, right):
            return (.node(.black, value, left, right), old)
        default:
            return (tree, old)
        }
    }
}
/*:
 接下来让我们处理一下 `_insertion` 方法。它的基本工作是查找指定元素可以作为叶子节点被插入到树中的位置。这个任务和 `contains` 很像，这是由于我们需要沿着与查找已存在的元素时相同的路径一路向下。所以发现 `_insertion` 和 `contains` 有着完全相同的结构也并不是什么震惊的事情；它们只需要在各个 `case` 语句返回**略微**不同的东西就行了。
 
 让我们依次来看一看四个例子，与此同时，我们将对代码进行解释：
*/
extension RedBlackTree {
    func _inserting(_ element: Element) -> (tree: RedBlackTree, old: Element?) 
    {
        switch self {
/*:
 首先，向一棵空树插入一个新的元素，我们只需简单地创建一个包含指定值的根节点：
*/
        case .empty:
            return (.node(.red, element, .empty, .empty), nil)
/*:
 显而易见，上述代码违反了第一个要求，因为我们从一个红色节点开始创建树。但是这算不上问题，当我们返回之后 `inserting` 将会对其进行修正。另外，代码满足其它两个要求。
 
 让我们继续看第二个例子。如果我们试图插入的值与根节点所持有的相同，则说明树已经包含该值，于是我们可以安全地返回 `self` 和现有成员的复制：
*/
        case let .node(_, value, _, _) where value == element:
            return (self, value)
/*:
 由于 `self` 理应满足所有条件，不修改直接返回并不会破坏任何条件。
 
 除此之外，取决于与根节点值比较的结果，值最终应该被插入左子树或右子树，所以我们需要做一个递归调用。如果返回值表明值尚未存在于树中，那么我们需要返回一个根节点的复制，相同子树的前一个版本会被这个新的替代。(否则，我们只需再次返回 `self`。)
*/
        case let .node(color, value, left, right) where value > element:
            let (l, old) = left._inserting(element)
            if let old = old { return (self, old) }
            return (balanced(color, value, l, right), nil)

        case let .node(color, value, left, right):
            let (r, old) = right._inserting(element)
            if let old = old { return (self, old) }
            return (balanced(color, value, left, r), nil)
        }
    }
}
/*:
 你也许已经注意到了，上面的两个例子都在返回新树之前调用了一个神秘的 `balanced` 函数。这个函数暗藏着红黑树的魔法。(这里的 `_inserting` 函数与我们可能会为普通二叉搜索树定义的插入操作几乎一模一样；事实上，在这里红黑树特定的东西并不多。)
 
 ## 平衡
 
 `balanced` 方法的工作是检测现有的树是否违反了平衡的要求，如果是，则巧妙地重排节点，随即返回符合标准的树来进行修复。
 
 上面的 `_inserting` 代码创建了一个新的节点作为红色叶子节点；在大多数例子中，这个处理会在一个递归调用中完成，然后将结果作为一个已经存在的节点的子节点插入。这样做哪些红黑树的要求可能会被违反呢?
 
 第一个要求很安全，因为它只和根节点相关，不会影响子节点 (另外，我们在 `inserting` 中特别关照了根节点，不管怎么说这里我们都可以放心地忽略它)。由于第三个性质并不关心红色节点，插入一个新的红色叶子节点也不会破坏它。然而，代码中并没有任何举措能防止我们在一个红色亲节点下插入同为红色的子节点，所以最终第二个性质可能会被违反。
 
 
 所以 `balanced` 只需要检查第二项要求，并且在不破坏第三项的同时设法修复它。在一棵合法的红黑树中，一个红色节点总会拥有一个黑色的亲节点；如果插入操作违反了第二个要求，那么其结果一定会匹配下图中的某一个例子。
 
 ![插入一个元素之后，一个红色节点拥有红色子节点的四种可能的情况。*x*、 *y* 和 *z* 代表值，而 *a*、*b*、*c* 和 *d* 是 (可能为空的) 子树。如果树与 1-4 的模式相匹配，则它的节点需要按照模式 R 重组。](Images/BalancePatterns@3x.png)
 
 
 完成插入之后，我们可以通过检查树是否匹配这些模式，来实现重新平衡的处理，如果匹配，重新组织树，使其匹配模式 R。由此产生的模式在巧妙修复了第二个要求的同时，又不会破坏第三个要求。
 
 你能猜到我们将会使用什么工具来进行实现吗？
 
 由于某种惊人的巧合, 这个特殊的问题可以称得上是极好地展示了在代数数据类型上模式匹配的威力。
 作为开始，让我们将上图中的五个图转换为 Swift 表达式。
 当我们创建华丽的 Unicode 树时，我们看到了如何精心使用 Swift 表达式来构建小规模的树；现在我们只需要将这些知识运用到下面的图中即可：
 
 ```
   1: .node(.black, z, .node(.red, y, .node(.red, x, a, b), c), d)
   2: .node(.black, z, .node(.red, x, a, .node(.red, y, b, c)), d)
   3: .node(.black, x, a, .node(.red, z, .node(.red, y, b, c), d))
   4: .node(.black, x, a, .node(.red, y, b, .node(.red, z, c, d)))
   R: .node(.red, y, .node(.black, x, a, b), .node(.black, z, c, d))
 ```
 
 此刻，我们基本完成了！只需要将这些表达式添加到一个 `switch` 语句中，我们就能得到一个正确的 `balanced` 函数实现：

```swift
extension RedBlackTree {
    func balanced(_ color: Color, _ value: Element, _ left: RedBlackTree, _ right: RedBlackTree) -> RedBlackTree {
        switch (color, value, left, right) {
        case let (.black, z, .node(.red, y, .node(.red, x, a, b), c), d),
            let (.black, z, .node(.red, x, a, .node(.red, y, b, c)), d),
            let (.black, x, a, .node(.red, z, .node(.red, y, b, c), d)),
            let (.black, x, a, .node(.red, y, b, .node(.red, z, c, d))):
            return .node(.red, y, .node(.black, x, a, b), .node(.black, z, c, d))
        default:
            return .node(color, value, left,  right)
        }
    }
}
```

 这是一种十分出色的编程方法。
 本质上, 我们用这样一种方法将上面的图直接翻译为了 Swift，
 这样一来，我们用来解释任务的五个图在代码里仍然能被识别出来！
 
 有一个小问题。虽然上述 Swift 代码完全有效，但很遗憾，[它在 Swift 3.1 的编译器中会发生崩溃][sr2924]。为了解决这个错误，我们需要将所有情况分开处理，只能重复写四个几乎一样的 case 语句：
 
 [sr2924]: https://bugs.swift.org/browse/SR-2924
*/
extension RedBlackTree {
    func balanced(_ color: Color, _ value: Element, _ left: RedBlackTree, _ right: RedBlackTree) -> RedBlackTree {
        switch (color, value, left, right) {
        case let (.black, z, .node(.red, y, .node(.red, x, a, b), c), d):
            return .node(.red, y, .node(.black, x, a, b), .node(.black, z, c, d))
        case let (.black, z, .node(.red, x, a, .node(.red, y, b, c)), d):
            return .node(.red, y, .node(.black, x, a, b), .node(.black, z, c, d))
        case let (.black, x, a, .node(.red, z, .node(.red, y, b, c), d)):
            return .node(.red, y, .node(.black, x, a, b), .node(.black, z, c, d))
        case let (.black, x, a, .node(.red, y, b, .node(.red, z, c, d))):
            return .node(.red, y, .node(.black, x, a, b), .node(.black, z, c, d))
        default:
            return .node(color, value, left, right)
        }
    }
}
/*:
 这个变通的方法淡化了一丝原来的震惊，幸亏魔法依然闪耀。(衷心希望这个 bug 在未来的编译器中得以被修复。)
 
 来看一看插入操作是否真的有效，创建一棵包含数字 1 到 20 的红黑树：
*/
var set = RedBlackTree<Int>.empty
for i in (1 ... 20).shuffled() {
    set.insert(i)
}
set
/*:
 看起来一切正常！欢呼起来！可以看到我们的树满足所有三个红黑树应有的性质。
 
 在插入数字之前，我们先调用了 `shuffled` 函数，所以每次执行这段代码都能够得到全新的树。借助本书的 playground 版本来进行测试会是一个绝佳的选择。
 
 ## 集合类型
 
 
 实现像 `Collection` 一样的协议恐怕是代数数据类型开始显得不那么方便的地方。我们需要定义一个合适的索引类型，而最简单的方法就是直接使用一个元素本身作为索引，就像这样：
*/
extension RedBlackTree {
    public struct Index {
        fileprivate var value: Element?
    }
}
/*:
 value 是一个可选值，因为我们将会使用 `nil` 值来表示结束索引。
 
 集合类型的索引必须是可以比较的。幸运的是，我们的元素正好是可比较的，这样比较索引就相当容易了。唯一棘手的事情是，我们必须确保结束索引比其它任何索引都**更大**：
*/
extension RedBlackTree.Index: Comparable {
    public static func ==(left: RedBlackTree<Element>.Index, right: RedBlackTree<Element>.Index) -> Bool {
        return left.value == right.value
    }

    public static func <(left: RedBlackTree<Element>.Index, right: RedBlackTree<Element>.Index) -> Bool {
        if let lv = left.value, let rv = right.value { 
            return lv < rv 
        }
        return left.value != nil
    }
}
/*:
 接下来，我们要具体实现 `Sequence` 扩展方法中的 `min()` 和 `max()`，以取得树的最小元素和最大元素。它们是在下面即将实现的索引步进的必要组成部件。
 
 最小的元素是存储在最左边的节点中的值；这里我们使用模式匹配和递归来查找它：
*/
extension RedBlackTree {
    func min() -> Element? {
        switch self {
        case .empty: 
            return nil 
        case let .node(_, value, left, _): 
            return left.min() ?? value
        }
    }
}
/*:
 查找最大元素可以用相似的方法。不过为了让事情更有趣一些，这里的 `max()` 版本会把递归展开成为一个循环：
*/
extension RedBlackTree {
    func max() -> Element? {
        var node = self
        var maximum: Element? = nil
        while case let .node(_, value, _, right) = node {
            maximum = value
            node = right
        }
        return maximum
    }
}
/*:
 注意，理解这段代码比 `min()` 更难。这个版本并没有使用一个简单的表达式来定义结果，而是使用了一个 `while` 循环，其中一些内部状态一直在改变。为了理解它是如何工作的，你需要在大脑中运行代码，来弄清楚 `node` 和 `maximum` 是如何随着循环的进程而改变的。但是从根本上说，这不过是相同算法的两种不同表达方式罢了，两者都有存在的意义。迭代版本有时稍微要快一点，所以可以通过使用它，用一点可读性交换一点额外的性能。不过递归的解决方案往往会更容易上手。如果性能测试告诉我们降低可读性是值得的，我们随时可以重写代码。
 
 现在我们拥有了 `min()` 和 `max()` 方法，可以开始实现 `Collection` 了！
 
 首先从最基础的开始：`startIndex`、 `endIndex` 和 `subscript`：
*/
extension RedBlackTree: Collection {
    public var startIndex: Index { return Index(value: self.min()) }
    public var endIndex: Index { return Index(value: nil) }

    public subscript(i: Index) -> Element {
        return i.value!
    }
}
/*:
 `Collection` 的实现应该明确定义关于索引失效的规则。在我们的例子中，我们可以对索引的有效性进行定义：对于一个原本是在树 `t` 中所创建的索引 `i`，如果有另一棵树 `u`，那么当且仅当 `i` 是结束索引，或者 `t[i]` 的值存在于 `u` 中时，`i` 是 `u` 中的**有效索引**。这个定义允许人们在树发生某些改变之后重用一部分索引，这是很有用的特性。(该规则与 `Array` 索引的工作方式不同，因为在我们的例子中，索引基于值，而非位置。这种定义索引无效的方式有点不同于寻常，但是并不违反 `Collection` 的语义要求。)
 
 我们的下标实现特别简短，因为只是解包索引中的值而已。然而，这么做不太好，它并没有验证存储在索引中的值是否确确实实存在于树中。我们可以用任意索引对任意的树进行下标操作，然后得到一个可能有用也可能并不存在的结果。虽然在实现 `Collection` 的时候我们可以自己定义索引无效的相关规则，但是在运行的时候应该尽可能验证遵循这些规则是否被真正遵守。使用一个无效索引来对集合类型做下标操作是个严重的编码错误，最好通过异常机制来进行处理，而不要默默地返回一些诡异的值。现在就需要这么做。我保证从这里开始我们会做得更好。
 
 不太妙的是，`startIndex` 调用了 `min()`，这是一个对数操作。但是 `Collection` 要求 `startIndex` 和 `endIndex` 的实现应该在常数时间内完成，对数操作自然就成为了一个问题。一个相对简单的解决方案是，通过引入一个简单的结构体对树进行封装，来缓存树的节点内部或附近的最小值。(亲爱的读者们，我决定把这个实现留给你们作为一个练习。当然我们也可以假装这一段所说的事情从未发生，继续前进！)
 
 不管怎么说，我们现在需要实现 `index(after:)` 和 `formIndex(after:)`，也就是说，我们要查找树中存在的比指定值大的最小的元素。为此我打算写一个工具函数来达成目的。为了保证我们关于索引验证的承诺，这个函数还会返回一个布尔值，表明存储在索引中的元素是否也存在于树中，这样我们就可以为它设置一个 precondition 来抛出异常：
*/
extension RedBlackTree: BidirectionalCollection {
    public func formIndex(after i: inout Index) {
        let v = self.value(following: i.value!)
        precondition(v.found)
        i.value = v.next
    }

    public func index(after i: Index) -> Index {
        let v = self.value(following: i.value!)
        precondition(v.found)
        return Index(value: v.next)
    }
}
/*:
 `value(following:)` 函数是一个 `contains` 的巧妙变体。虽然它的逻辑非常复杂，但是绝对值得你再看一次：
*/
extension RedBlackTree {
    func value(following element: Element) -> (found: Bool, next: Element?) {
        switch self {
            case .empty:
                return (false, nil)
            case .node(_, element, _, let right):
                return (true, right.min())
            case let .node(_, value, left, _) where value > element:
                let v = left.value(following: element)
                return (v.found, v.next ?? value)
            case let .node(_, _, _, right):
                return right.value(following: element)
        }
    }
}
/*:
 最复杂的部分应该是，第三个分支中，当元素存在于左子树时，会发生什么。通常跟随 (following) 该元素的元素也在同一棵子树中，所以一个递归调用会返回正确的结果。但是若 `element` 是 `left` 中的最大值，这次调用会返回 `(true, nil)`。在这个例子中，我们需要返回跟随 `left` 子树的值，也就是存储在亲节点中的它自身的值。
 
 除此以外，我们也需要能够用其它方法查找上述的值。同样地，为了让事情有趣，我们将会再次尝试用迭代而非递归来实现一个新版本的方法：
*/
extension RedBlackTree {
    func value(preceding element: Element) -> (found: Bool, next: Element?) {
        var node = self
        var previous: Element? = nil
        while case let .node(_, value, left, right) = node {
            if value > element {
                node = left
            }
            else if value < element {
                previous = value
                node = right
            }
            else {
                return (true, left.max())
            }
        }
        return (false, previous)
    }
}
/*:
 注意这里的 `previous` 变量的目的是什么，事实上它等效于上面那个复杂例子中的 nil 聚合 (nil-coalescing) 运算符 `??`。(我们无法将这种递归结果进行后置处理的代码直接转换为迭代代码，但是可以通过添加新的变量来消除后置处理，这样一来，就可以在从递归调用返回之前进行处理。上面迭代代码中的 `previous` 就是一个这样的变量。)
 
 距离完成 `BidirectionalCollection` 的实现，就只差添加调用 `value(preceding:)` 方法来查找索引的前序了：
*/
extension RedBlackTree {
    public func formIndex(before i: inout Index) {
        let v = self.value(preceding: i.value!)
        precondition(v.found)
        i.value = v.next
    }

    public func index(before i: Index) -> Index {
        let v = self.value(preceding: i.value!)
        precondition(v.found)
        return Index(value: v.next)
    }
}
/*:
 像这样定义 `index(after:)` 和 `index(before:)` 比起我们前面所做的明显更加复杂。最终的运行时结果可能也会相当慢 -- 毕竟所有递归查找导致算法开销达到了 $O(\log n)$，而非一贯的 $O(1)$。这没有违反任何 `Collection` 的规则；只不过使用索引进行迭代操作会比一般的集合更慢。
 
 最后，让我们来看看 `count` 的实现；这是目前为止又一个极好的实践模式匹配和递归的机会：
*/
extension RedBlackTree {
    public var count: Int {
        switch self {
        case .empty:
            return 0
        case let .node(_, _, left, right):
            return left.count + 1 + right.count
        }
    }
}
/*:
 如果我们忘记专门实现 `count`，它的默认实现将会计算 `startIndex` 和 `endIndex` 之间的步数，这样 $O(n\log n)$ 比起我们的 $O(n)$ 会慢得多。但是我们的实现也并没有什么值得宣扬的：它仍然需要访问树中每一个节点。
  
 > 我们可以让所有节点记住在它们下面的元素数量，这将使我们的树变成一棵所谓的**顺序统计树** (order statistic tree)，速度也会随之得到提升。(我们将会需要更新插入和任何其它可变方法，并谨慎地维护这个额外的信息。使用这类扩展叫做**树的扩充**。添加元素数量只是众多扩充树的方法中的一种。) 除了提升 `count` 的速度以外，顺序统计树还带来了许多有趣的附加收益；例如，在这样一棵树中，只需 $O(\log n)$ 个步骤即可查找第 $i$ 小或第 $i$ 大的值。不过，这可不是免费得来的：内存消耗的增加和代码更加复杂便是代价。
 
 大功告成了，在我们最熟知和喜爱的标准库中的扩展实现的帮助下，`RedBlackTree` 现在已经是一个 `BidirectionalCollection` 了：
*/
let evenMembers = set.lazy.filter { $0 % 2 == 0 }.map { "\($0)" }.joined(separator: ", ")
evenMembers
/*:
 为了做到有始有终，我们将会实现 `SortedSet`。幸运的是，除了空树的初始化方法外，我们已经满足了所有的要求 -- 不过添加这个方法也并不是什么大工程：
*/
extension RedBlackTree: SortedSet {
    public init() {
        self = .empty
    }
}
/*:
 全部完成！为了完善这一章，你可以进行一个挑战：尝试实现 `SetAlgebra` 的 `remove(_:)` 操作。专业建议：在第一个版本中姑且先忽略红黑树的要求。在代码能够工作之后，再开始思考如何在删除操作后重新平衡树。(你可以在网上或是喜爱的算法书籍中阅读相关内容，即便是这样这个游戏也不失公平；就算是参考资料，实现这些东西也足够具有挑战性。)
 
 ## 性能
 
 我们预计 `RedBlackTree` 上的大多数操作都会消耗 $O(\log n)$ 的时间, 除了
 `forEach`, 它应该是 $O(n)$ -- 因为它对树中的每个节点 (和空位) 都会执行一次递归调用。
 运行我们的常规性能测试证明了推测大抵是正确的；下图绘制了在我的 Mac 上产生的结果。
 
 ![`RedBlackTree` 操作的性能测试结果。图表在双对数坐标系上展示了输入值的元素个数和单次迭代的平均执行时间。](Images/RedBlackTreeBenchmark.png)
 
 曲线的噪声很严重。这是因为红黑树允许树的形态发生巨大改变。树的深度不仅取决于元素的个数，我们插入元素的 (随机) 顺序 (在很小的程度上) 也会产生影响。大多数操作的性能与树的深度成正比，所以我们的曲线发生了抖动。不过小规模的噪声并不影响总体形状。
 
 使用 `forEach` 进行迭代是一个复杂度为 $O(n)$ 的操作，所以所以它的平摊图应该是一条水平线。它的中间部分的确看起来是平坦的，但是大约从 20,000 个元素开始，它渐渐地减速，并开始以对数速率增长。这是因为即使 `forEach` 以升序访问元素，它的在内存中的位置从本质上来说仍然是随机的：因为在插入初期元素被分配时这一切就已经被决定的。红黑树在保持相邻元素靠近彼此这件事情上，可以说是表现十分糟糕，受困于此，使得它们相当不适合今天的计算机内存架构。
 
 但是不管怎么说，`forEach` 仍然比 `for-in` 略快一点；增加索引是一个相对复杂的 $O(\log n)$ 操作，尽管中序遍历总是清楚地知道在哪里找到下一个值，但基本上这个操作都需要从头开始查找一个元素。
 
 `contains` 与 `for-in` 之间越来越大的差距是缓存效果的另一个表现。在 `for-in` 中我们连续调用 `index(after:)` 来访问随机内存中的新元素，但是大部分路径保持不变，所以 `for-in` 仍然相对是缓存友好的。`contains` 就不是这样了，它每次都会迭代访问树中全新的随机路径，内存访问几乎没有重复，从而导致缓存无效。
 
 为了看一看 `RedBlackTree` 中基于索引的迭代到底多慢，将它与以前的实现进行比较不失为一个好主意。 结果如
 下图，
 一个对 `RedBlackTree` 所有元素进行 `for-in` 循环的操作比对 `SortedArray` 的相应操作慢了大约 200–1,000 倍，而且曲线慢慢分离，证明了我们预计的 $O(\log n)$ 和 $O(1)$ 的时间复杂度。
 
 ![比较三个 `index(after:)` 实现的性能。](Images/Iteration3.png)
 
 我们会在未来的章节中修复缓慢的问题，但是至少有一部分 (看起来) 应该是由于查找和可变性之间无法避免的权衡所导致的：当元素在巨大的连续缓冲区按顺序排列时，迭代的速度是最快的，但是恰恰这种缓冲区在做快速插入时是最不便利的数据结构。任何对插入性能进行的优化可能都涉及将存储分解成更小的块，而副作用正是迭代速度下降。
 
 在红黑树中，元素被单独封装在树的节点中，这些节点在堆上申请的内存是分离的，如果你想快速地迭代所有元素，这大概是最糟糕的元素存储方式了。这种特殊的设计中，我们使用 $O(\log n)$ 的算法来查找下一个索引，但是也许会让你惊讶，这个算法并不是 `for` 循环中花费大多数时间的地方：即使用 `forEach` 来替代 `for-in`，性能测试中 `RedBlackTree` 仍然比 `SortedArray` 慢 90–200 倍。
 
 唉，真令人失望。但是插入变快了，对吧？让我们来看一看！
 下图将 `RedBlackTree.insert` 的性能与之前的实现进行了比较。
 
 ![比较三个 `insert` 实现的性能。](Images/Insertion3.png)
 
 我们可以看到，当元素个数变得庞大时，红黑树算法的优势明显得到了回报。向一棵红黑树插入四百万个元素大约比有序数组要快 50–100 倍。(它仅仅花费了 33 **秒**，比 `OrderedSet` 的 26 **分钟**好太多了。) 如果添加更多元素，两者之间的差距会越来越大。
 
 然而，当我们的元素数量低于 50,000 个时，`SortedArray` 显然击败了 `RedBlackTree`。相较于红黑树，有序数组有着更好的位置性：即使我们需要进行更多次的内存访问来将新元素插入到有序数组中，但是这些访问彼此也非常靠近。只要我们使用各种各样的缓存 (比如 L1，L2，TLB，只要你拥有就行)，这些访问具有的规律性就能弥补大数据量所带来的消耗。
 
 `RedBlackTree.insert` 的增长率曲线是我们所能够做到的最好的 -- 目前没有任何数据结构能解决常规的 `SortedSet` 的渐进性能问题。但是并不是说没有任何提升空间！
 
 为了让插入更快，我们需要着手于优化我们的实现，通过一些常数因子来加速它。这么做不会改变性能测试曲线的形态，但是能够让曲线在双对数坐标系所处的位置向下平移。
 
 于我们而言，理想的状态是能将 `insert` 向下平移足够多的距离，让它在全规模的数据上都达到甚至超越 `SortedArray` 的性能，同时保持对数增长率。
 
 <!-- end-exclude-from-preview -->

 [Next page](@next)
*/