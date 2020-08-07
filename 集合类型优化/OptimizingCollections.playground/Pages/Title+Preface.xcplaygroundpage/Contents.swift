/*:
 [Previous page](@previous)

 # Swift 集合类型优化
 ## by Károly Lőrentey，王 巍，陈 聿菡
 
 Copyright © 2017 Károly Lőrentey
 
 英文版本 1.0 (2017 年 6 月)，中文版本 1.0 (2017 年 8 月)
 
 
 # 前言 
 
 
 从表面上来说，这本书围绕如何实现高性能集合类型进行展开。针对同一个简单的问题，我们将提供多种不同的解决方案，并依次对它们进行详细地说明。同时为了不断地挑战性能巅峰，我们会一直走在找寻新方法的探索征途中。
 
 Swift 提供了很多工具来帮助我们表达自己的想法，说句心里话，这本书仅仅只是针对这些工具进行了一个愉快的探索。本书不会告诉你如何创造一个卓越的 iPhone 应用；但是它会教给你一些工具和技术，以帮助你更好地借助 Swift 代码的形式来表达想法。
 
 这本书源于我曾为 [dotSwift 2017 大会][talk] 准备的大量笔记和代码。由于准备的材料过于详实有趣，我无法做到将全部东西融入到一次演讲中，也正因如此，我写了这本书。（你完全不需要为了理解这本书而特意去看我的演讲，不过视频仅有 20 分钟左右，而且 dotSwift 的剪辑工作非常棒，使我几乎摇身一变成了一位像样的讲者。不过我确信，你会爱上我迷人的匈牙利口音！）
 
 [talk]: http://www.thedotpost.com/2017/01/karoly-lorentey-optimizing-swift-collections
 
 ## 本书面向的读者 
 
 从表面看，这本书的受众是那些想要自己实现集合类型的人，但切不可以知表不知里，Swift 中存在一些能使它更加独特的语言天赋，事实上本书的内容对于任何一个想要学习这些独特天赋的人来说都是十分有用的。无论是学会使用代数数据类型 (algebraic data type)，亦或是了解如何通过写时复制 (copy-on-write) 的引用计数存储来创建 *swifty* 的数据类型，都将有助于你在日常开发中成为更好的程序员。
 
 本书假设你已经是有一定经验的 Swift 程序员。不过你完全不需要是 Swift 专家：如果你熟悉基本语法，而且已经写了数千行 Swift 代码，那么你一定能够顺利地理解本书。如果你需要快速上手 Swift，我会强烈推荐另一本 objc.io 的书给你，由 Chris Eidhof、Begemann 和 Airspeed Velocity 所著的 **[Swift 进阶][AdvancedSwift]**。这本书可是说是 Apple 的 *[The Swift
 Programming Language][SwiftBook]* 的接续，它对 Swift 的特性进行了更深入的挖掘，很好地解释了如何以一种符合语言特性 (或者说：*swifty*)的方式来使用它们。
 
 > 译者注：您也可以在 ObjC 中国的网站找到 [Swift 进阶][AdvancedSwiftCN]一书的中译版本。
 
 [SwiftBook]: https://developer.apple.com/swift/resources/
 [AdvancedSwift]: https://www.objc.io/books/advanced-swift/
 [AdvancedSwiftCN]: https://objccn.io/products/advanced-swift/
 
 本书中几乎所有代码都可以运行在支持 Swift 代码的任意平台上。除了在几个特例中，目前标准库和跨平台基础框架都不支持所需要使用的特性，所以我引入了平台特定的代码用以分别支持 Apple 和 GNU/Linux 平台。另外，本书的代码均在 Xcode 8.3.2 自带的 Swift 3.1 编译器中进行了测试。
 
 ## 书籍更新 
 
 随着时间的推进，我随时有可能发布新版本，或是为修复 bug，或是为补充资料，或是跟随 Swift 语言的进化而迭代。届时你将可以从你原来购买本书的页面下载更新。此外，你还可以在那里获取到不同格式的书籍：当前版本支持 EPUB、PDF 和 Xcode playground 三种格式。(只要登录购买该书所使用的账号，你将可以无限期免费下载。)
 
 ## 相关工作 
 
 我创建了一个 [GitHub 仓库][github]，你可以在那里找到书中提到的所有算法的完整源码。不过我只是将代码单纯地从书中提取出来，未做任何修饰，所以并不包含额外的信息。为了避免你想要尝试修改源码来进行测试却无法即兴而为之，我认为提供一个独立的源码包会是一个不错的选择。
 
 [github]: https://github.com/objcio/OptimizingCollections
 
 你可以在自己的应用中随意使用任意来自上述仓库的代码，虽然诚实地说，很多时候这并不见得是一个好主意：为了配合本书，我将部分代码进行了一定程度的简化，因此并不一定满足生产代码所要求的质量。不过，我建议你看一看 **B 树** ([BTree])，这是我精心为 Swift 量身打造的有序集合类型。我私以为这是本书中最先进的数据结构，而且代码实现完全满足生产代码的质量要求，在那里，你可以看到基于树实现的类似于标准库中 `Array`、`Set` 和 `Dictionary` 一样的集合类型，以及一个灵活的 `BTree` 数据类型，它可以用来对底层结构进行低层级访问。
 
 [BTree]: https://github.com/lorentey/BTree
 
 *[Attabench]* 是我开发的 macOS 版的性能测试应用，用于为小段代码生成微型的性能测试图表。本书中实际使用的性能测试默认就包含在该应用中。我强烈建议你在自己的电脑中下载这个应用来实际试一试我所做过的测试。在这之后你也可以将自己的算法用性能测试图反映出来并进行种种探索。
 
 [Attabench]: https://github.com/lorentey/Attabench
 
 ## 联系作者 
 
 如果你发现任何错误，请[在本书的 Github 仓库中提交一个 issue][bugreport] 来帮助我解决它。有其它任何类型的反馈，也随时欢迎在 Twitter 上联络我，账号是 [*@lorentey*][twitter]。如果你钟爱写邮件，发邮件到 [*collections@objc.io*](mailto:collections@objc.io) 也完全没问题。
 
 [bookrepo]: https://github.com/objcio/OptimizingCollections
 [bugreport]: https://github.com/objcio/OptimizingCollections/issues/new
 [twitter]: https://twitter.com/lorentey
 
 ## 如何阅读本书 
 
 我没有打破常规，所以本书的阅读顺序更倾向于从前至后。假设读者按照正序阅读，会发现书中有不少内容需要与前面的章节参照阅读。话虽然这么说，但按照自己的喜好的顺序来阅读也是可以的。不过答应我，这样做的时候就算感觉并不那么顺畅，也不要惆怅，好吗？
 
 这本书包含大量源码。在 playground 版本的书籍中，几乎所有代码都可以编辑，而且你所做的修改会即时反映出来。你可以通过改动代码来亲身体会所讲述的内容 -- 有时候最佳的理解方式正是看一看当你改变它时会发生什么。
 
 比如说，`Sequence` 上有一个很有用的扩展方法，用于将所有元素乱序重排。那部分代码中有几个 FIXME 注释描述了代码实现存在的问题。不妨尝试修改代码来修复它们！
*/
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin // 为了支持 arc4random_uniform()
#elseif os(Linux)
import Glibc // 为了支持 random()
#endif

extension Sequence {
    func shuffled() -> [Iterator.Element] {
        var contents = Array(self)
        for i in 0 ..< contents.count {
            #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
                // FIXME: 数组元素数量超过 2^32 时会挂
                let j = Int(arc4random_uniform(UInt32(contents.count)))
            #elseif os(Linux)
                // FIXME: 这里存在模偏差（modulo bias）的问题。 
                // 另外，应该通过调用 `srandom` 来为 `random` 配置随机种子。
                let j = random() % contents.count
            #endif
            if i != j {
                swap(&contents[i], &contents[j])
            }
        }
        return contents
    }
}
/*:
 为了说明一段代码被执行之后发生了什么，有时我会展示执行结果。作为例子，让我们来试着运行 `shuffled`，以证明每次运行都返回了新的随机顺序：
*/
(0 ..< 20).shuffled()
(0 ..< 20).shuffled()
(0 ..< 20).shuffled()
/*:
 在 playground 版本的书籍中，所有输出结果都会被即时生成，因此你会在每次打开这一页时得到一组不同的乱序数字集。
 
 ## 致谢 
 
 如果没有读者们针对早期草稿给出的精彩绝伦的反馈，一定没有这本书的今天。除了我的读者们，我尤其还想要感谢 *Chris Eidhof*，他花了相当多的时间来审查早期的书稿，提出了很多详尽的反馈意见，使本书最终版得到了质的飞跃。
 
 *Ole Begemann* 作为本书的技术审查者；没有问题能逃过他滴水不漏地审查。他绝妙的建议使得代码更加简明漂亮，而且他发现了很多就连我自己也从未意识到的令人惊叹的细节。
 
 还因为有了 *Natalye Childress* 顶级的审校，我那笨拙且凌乱的句子们才得以转化成为一本真正用妥帖的英语写成的书。我绝对不是在夸大她的贡献；她几乎对每一个段落都做出了不少适当的调整。
 
 当然了，书中也许尚存问题，但我绝不允许这一群很棒的人因此而被指责。如有不善，还请唯我是问。
 
 最后我想感谢的是 *Floppy*，我七岁的比格犬：她总是耐心地听我描述纷繁复杂的技术问题，让我能够提供更好的问题解决方案。谢谢你，我的好孩子！

 [Next page](@next)
*/