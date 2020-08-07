/*:
 [Previous page](@previous)

 # 引言
 
 集合类型是 Swift 语言的核心抽象概念之一。标准库中的主要集合类型包括：数组 (array)、集合 (set) 和字典 (dictionary)，从小脚本到大应用，它们被用在几乎所有的 Swift 程序中。Swift 程序员都熟悉它们的具体运作方式，而且它们的存在赋予了这门语言独特的个性。
 
 当我们需要设计一个新的通用集合类型时，效仿标准库已经建立的先例不失为一个好办法。但是单纯遵循 `Collection` 协议的要求并不够，我们还需要再多做一些额外的工作来让它的行为与标准集合类型相匹配。本质上来说，就是要符合一些**Swift 风格**的难以捉摸的性质，很难解释如何正确地做到这一切，但它们的缺席会让人痛不欲生。
 
 ## 写时复制 (copy-on-write) 值语义
 
 不知道是否与你的想法不谋而合，我认为 Swift 集合类型中最重要的特性非**写时复制值语义**莫属。
 
 从本质上来说，**值语义**在上下文中意味着每个变量都持有一个值，而且表现得**像是**拥有独立的复制，所以改变一个变量持有的值并不会修改其它变量的值：
*/
var a = [2, 3, 4]
var b = a
a.insert(1, at: 0)
a
b
/*:
 为了实现值语义，上述代码需要在某些时候复制数组的底层存储，以允许两个数组实例拥有不同的元素。对于简单值类型 (像是 `Int` 或 `CGPoint`) 来说，整个值直接存储在一个变量中，当初始化一个新变量，或是将新值赋给已经存在的变量时，复制都会自动发生。
 
 然而，将一个数组赋给新变量并**不会**发生底层存储的复制，这只会创建一个新的引用，它指向同一块在堆上分配的缓冲区，所以该操作将在常数时间内完成。直到指向共享存储的变量中有一个值被更改了 (例如：进行 `insert` 操作)，这时才会发生真正的复制。不过要注意的是，只有在改变时底层存储是共享的情况下，才会发生复制存储的操作。如果数组对它自身存储所持有的引用是唯一的，那么直接修改存储缓冲区也是安全的。
 
 当我们说 `Array` 实现了**写时复制**优化时，我们本质上是在对其操作性能进行一系列相关的保证，从而使它们表现得就像上面描述的一样。
 
 (要注意的是，完整的值语义通常被认为是由一些名字很可怕的抽象概念组成，就像是**引用透明** (referential transparency)、**外延性** (extensionality) 和**确定性** (definiteness)。在某种程度上，Swift 的标准集合违反了每一条。比如说，就算两个集合包含完全相同的元素，一个集合的索引在另一个集合中也并不一定有效。因此，Swift 的集合并不是**完全**引用透明的。)
 
 ## `SortedSet` 协议
 
 
 在开始之前，我们首先需要确定一个想要解决的课题。目前标准库中缺少一个非常常用的数据结构：有序集合 (sorted set) 类型，这是一个类似 `Set` 的集合类型，但是要求元素是 `Comparable` (可比较的)，而非 `Hashable` (可哈希的)，此外，它的元素保持升序排列。接下来，让我们卯足火力来实现一个这样的集合类型吧！
 
 这本书将始终围绕有序集合问题进行，对于用多种方法构建数据结构来说，无疑这会是一个很好的示范。之后我们将会创造一些独立的解决方案，并 (举例) 说明一些有趣的 Swift 编码技术。
 
 现在，我们来起草一份想要实现的 API 协议作为开始。理想情况下，我们希望创建遵循下述协议的具体类型：

```swift
public protocol SortedSet: BidirectionalCollection, SetAlgebra {
    associatedtype Element: Comparable
}
```

 有序集合的核心是将多个元素按一定顺序放置，所以实现 `BidirectionalCollection` 是一个合情合理的需求，这允许从前至后遍历，也允许自后往前遍历。
 
 `SetAlgebra` 包含所有的常规集合操作，像是 `union(_:)`、`isSuperset(of:)`、`insert(_:)` 和 `remove(_:)`，以及创建空集合或者包含特定内容的集合的初始化方法。如果我们志在实现产品级的有序集合，那么毫无疑问，没有理由不完整实现该协议。然而，为了让这本书在可控范围内，我们将只实现 `SetAlgebra` 协议中很小的一部分，包括 `contains` 和 `insert` 两个方法，再加上用于创建空集合的无参初始化方法：
*/
public protocol SortedSet: BidirectionalCollection, CustomStringConvertible, CustomPlaygroundQuickLookable {
    associatedtype Element: Comparable

    init()
    func contains(_ element: Element) -> Bool
    mutating func insert(_ newElement: Element) -> (inserted: Bool, memberAfterInsert: Element)
}
/*:
 作为放弃完整实现 `SetAlgebra` 的交换，我们添加了 `CustomStringConvertible` 和 `CustomPlaygroundQuickLookable`；这样一来，当我们想要在示例代码和 playground 中显示有序集合的内容时，能够稍微得心应手一些。
 
 我们需要知道的是，`BidirectionalCollection` 有大约 30 项要求 (像是 `startIndex`、`index(after:)`、`map` 和 `lazy`)，它们中的大多数有默认实现。在这本书中，我们将聚焦于要求的绝对最小集，包括 `startIndex`、`endIndex`、`subscript`、`index(after:)`、`index(before:)`、`formIndex(after:)`、`formIndex(before:)` 和 `count`。大多数情况下，我们只实现这些方法，尽管通常来讲，进行专门的处理能获得更好的性能，但我们还是选择将其它方法保持默认实现的状态。不过有一个例外，因为 `forEach` 是 `contains` 的好搭档，所以我们也会专门实现它。
 
 ## 语义要求
 
 通常，实现一个 Swift 协议意味着不仅要遵循它的明确要求，大多数协议还具有一系列在类型系统中无法表达的附加语义要求。这些要求需要被单独写成文档。`SortedSet` 协议也不例外，我们期望所有实现都能满足下述的六个性质：
 
 <!--
 TODO [Ole]: Note for the future: In Swift 4 `Sequence` will most likely get an associated type `Element` that is constrained to `Iterator.Element`, see https://github.com/apple/swift/pull/8939.
 -->
    
 1. **相容元素类型：**`Iterator.Element` 和 `Element` 必须保持类型一致。如果插入某种类型的元素，集合类型的方法却返回了其他类型的元素，这样的处理并没有任何意义。(截至 Swift 3，我们仍然无法规定这两种类型必须一致。我们本可以简单地使用 `Iterator.Element` 来替代 `Element`；不过我选择引入一个新的关联类型，这仅仅是为了让上述函数签名简短一点。)
 
 2. **有序：**集合类型中的元素需要时刻保持已排序状态。具体一点说就是：如果在实现了 `SortedSet` 的 `set` 中，`i` 和 `j` 都是有效的下标索引，那么 `i < j` 必须与 `set[i] < set[j]` 等效。(这个例子也暗示了我们，集合没有重复元素。)
 
 3. **值语义：**通过一个变量更改 `SortedSet` 类型的实例时，必须不能影响同类型的任意其他变量。这也就是说，我们需要遵循：类型必须表现得**像是**每个变量都拥有自己的独一无二的值，完全独立于其它所有变量。
 
 4. **写时复制：**复制一个 `SortedSet` 值到新变量的复杂度应该是 $O(1)$。存储可能在不同的 `SortedSet` 值之间部分或完全共享。当需要满足值语义时，所有更改都必须先检查共享存储，并在合适的时机创建新的复制。因此，当存储被共享的时候，一旦发生改变可能需要较长的时间才能完成整个处理。
 
 5. **特定索引：**索引和特定的 `SortedSet` 实例相关联，它们只保证对于这个特定的实例和它的不可变直接复制是有效的。即使 `a` 和 `b` 是包含完全相同元素的同一类型的 `SortedSet` 实例，`a` 的索引在 `b` 中也未必有效。(通常在技术上，这种对真的值语义的放宽是一种无奈之举，似乎很难避免。)
 
 6. **索引失效：**任何 `SortedSet` 的改变都**可能**导致所有已经存在的索引失效，包括 `startIndex` 和 `endIndex`。对于具体实现来说，让所有的索引失效并不总是**必要的**，但是想这么做也没问题。(这一点并不能算是要求，因为这从根本上来说不可能被违背。这只是一个提醒，让我们铭记在心，集合类型的索引很脆弱，需要谨慎地处理。)
 
 注意，如果你忘记实现任意一个要求，编译器并不会提醒你。但是实现它们是至关重要的，只有这样，使用有序集合的一般代码才能有稳定的行为。
 
 假如我们正在实现一个现实可用，满足生产要求的有序集合，我们完全没有必要实现 `SortedSet` 协议，而只需简单地定义一个直接实现了所有要求的单一类型即可。然而，我们将编写不止一个有序集合，因此有一个规定了所有要求的协议再好不过了，而且我们可以基于它定义通用扩展。
 
 虽然我们还没有具体实现 `SortedSet`，但是果断先来定义一个通用扩展又何尝不是一个激动人心的选择呢！
 
 ## 打印有序集合
 
 提供一个 `description` 的默认实现能够让我们免去今后设置输出格式的麻烦。由于所有的有序集都是集合类型，我们完全可以使用标准集合类型的方法来打印它们，就像标准库的数组和集合一样，将元素用逗号分隔，并用括号括起来：
*/
extension SortedSet {
    public var description: String {
        let contents = self.lazy.map { "\($0)" }.joined(separator: ", ")
        return "[\(contents)]"
    }
}
/*:
 此外，为 `customPlaygroundQuickLook` 创建一个默认实现也很有价值，这样我们的集合类型在 playground 中的输出也能稍微优美一些。一眼看上去，默认的 Quick Look 视图很难理解，所以我使用属性字符串 (attributed string)，将 `description` 的字体设置为等宽字体，并以此来代替原来的视图。
*/
#if os(iOS)
import UIKit

extension PlaygroundQuickLook {
    public static func monospacedText(_ string: String) -> PlaygroundQuickLook {
        let text = NSMutableAttributedString(string: string)
        let range = NSRange(location: 0, length: text.length)
        let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        style.lineSpacing = 0
        style.alignment = .left
        style.maximumLineHeight = 17
        text.addAttribute(NSFontAttributeName, value: UIFont(name: "Menlo", size: 13)!, range: range)
        text.addAttribute(NSParagraphStyleAttributeName, value: style, range: range)
        return PlaygroundQuickLook.attributedString(text)
    }
}
#endif

extension SortedSet {
    public var customPlaygroundQuickLook: PlaygroundQuickLook {
        #if os(iOS)
            return .monospacedText(String(describing: self))
        #else
            return .text(String(describing: self))
        #endif
    }
}
/*:
 [Next page](@next)
*/