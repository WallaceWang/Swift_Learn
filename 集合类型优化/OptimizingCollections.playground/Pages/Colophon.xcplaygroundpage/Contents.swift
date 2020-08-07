/*:
 [Previous page](@previous)

 # 这本书是如何创建的 
 
 
 本书是由 *bookie* 生成的，这是一个我用来创建关于 Swift 书籍的工具。(显然 *Bookie* 是出书人 (bookmaker) 的非正式名字，所以名字上来说我觉得简直是完美契合。)
 
 Bookie 是用 Swift 编写的一个命令行工具，它接受 Markdown 文本文件作为输入，然后生成组织良好的 Xcode Playground、GitHub 样式的 Markdown、EPUB、HTML、LaTeX 以及 PDF 文件，同时它还包括一份含有全部源代码的 Swift 包。Bookie 可以直接生成 playground，Markdown 和源代码，对于其他格式，它将在把文本转换为 Pandoc 自己的 Markdown 方言后再使用 [Pandoc][pandoc] 进行生成。
 
 [pandoc]: https://pandoc.org
 
 为了验证示例代码，bookie 将会把所有 Swift 代码例子提取到一个特殊的 Swift 包中 (以 `#sourceLocation` 进行细心标注)，并使用 Swift Package Manager 进行构建。之后得到的命令行 app 将会被运行，所有被用来求值的代码将依次运行，并打印返回值。输出将会被分割，每个独立的结果都将被插回打印版书籍中相应的代码行之后：
*/
func factorial(_ n: Int) -> Int {
    return (1 ... max(1, n)).reduce(1, *)
}
factorial(4)
factorial(10)
/*:
 (在 playground 中，这些输出是动态生成的；但在其他格式里，输出结果将被包括进来。)
 
 和 Xcode 中一样，语法颜色是通过 [SourceKit] 完成的。SourceKit 使用的是官方的 Swift 语法，所以上下文关键字总是能够被正确高亮：
*/
var set = Set<Int>() // "set" 也是定义属性 setter 的关键字
set.insert(42)
set.contains(42)
/*:
 [SourceKit]: https://github.com/apple/swift/tree/master/tools/SourceKit
 
 本书电子版使用的字体是 [Adobe 的思源黑体][adobe]。示例代码使用的是 [Laurenz Brunner 的 *Akkurat*][akkurat]。
 
 [adobe]: https://github.com/adobe-fonts/source-han-sans
 [akkurat]: https://lineto.com/The+Fonts/All+Fonts/Akkurat/
 
 Bookie (暂时还？) 不是一个免费/开源软件，如果你有兴趣在自己的项目中使用它，请直接联系我。

 [Next page](@next)
*/