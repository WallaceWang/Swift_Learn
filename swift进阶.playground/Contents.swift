import UIKit
import Foundation

var str = "Hello, playground"

// MARK: - 集合类型
/*
extension Array {
    
    /// Map函数实现原理
    func mapCustom<T>(_ transfrom: (Element) -> T) -> [T] {
        var resultArray: [T] = []
        resultArray.reserveCapacity(count) // 知道数组长度，提前分配以提高性能
        self.forEach { (element) in
            resultArray.append(transfrom(element))
        }
        return resultArray
    }
    
    /// 拼接
    /// - Parameter initalize: 初始值
    /// - Parameter nextPartialResult: 操作行为函数
    func accumulate<Result>(initalize: Result, nextPartialResult: (Result, Element) -> Result) -> [Result] {
        var resultArray: [Result] = []
        resultArray.reserveCapacity(count)
        var result = initalize
        var it = makeIterator()
        while let e = it.next() {
            result = nextPartialResult(result, e)
            resultArray.append(result)
        }
        return resultArray
    }
    
    /// 是否所有元素都满足标准
    /// - Parameter matching: 条件
    func all(matching: (Element) -> Bool ) -> Bool {
        var isMatching = true
        self.forEach { (element) in
            if !matching(element) {
                isMatching =  false
                return
            }
        }
        return isMatching
    }
    
    /// 是否所有元素都不满足
    /// - Parameter matching: 条件
    func none(matching: (Element) -> Bool) -> Bool {
        var noneMatching = true
        self.forEach { (element) in
            if matching(element) {
                noneMatching =  false
                return
            }
        }
        return noneMatching
    }
    
    
    func count(where condition: (Element) -> Bool) -> Int {
        var filterArray: [Element] = []
        self.forEach { (element) in
            if condition(element) {
                filterArray.append(element)
            }
        }
        return filterArray.count
    }
}


let mapCustomArray =  [1, 2, 3].mapCustom { $0 + 1 }
mapCustomArray

let accumulateArray = [1, 2, 3].accumulate(initalize: 2) { (result, new) in
    return result + new
}
accumulateArray

let strAccumulateArray = ["a", "b", "c"].accumulate(initalize: "") { (result, new) in
    return result + new
}
strAccumulateArray

let allIsMatching = [1, 2, 3].all { $0 > 0}
allIsMatching

let conditionCount = [1, 2, 3].count { $0 > 1 }
conditionCount


let nums = [1, 2, 3, 4]
let characters = ["a", "b", "c", "d"]

let combineArray =  nums.flatMap { num in
    characters.map { character in
        (num, character)
    }
}
combineArray
print(combineArray)

func addFive(num: Int) {
    num + 5
}
[1, 2, 3].forEach(addFive(num:))


["a", "b", "c"].indices.forEach { (index) in
    print("\(index)-")
}
*/
/*
["a": 1, "b": 2, "c": 3].indices.forEach { (index) in
    print("\(index)-")
}
*/



var fibs = [0, 1, 1, 2, 3, 5]
var dropFirstArray = fibs[1...]
dropFirstArray
type(of: dropFirstArray)

//dropFirstArray[0] = 10
//dropFirstArray
//fibs


var person1: [String: Any] = ["name": "xiaoming1", "age": 10]
let person2: [String: Any] = ["name": "xiaoming2", "id": 123456]

//person1.merge(person2) { $1 }
//person1.merge(person2) { (current, _) in
//    current
//}

person1.merge(person2) { (_, new) in
    new
}
person1

//person2.mapValues { (<#Any#>) -> T in
//    <#code#>
//}


// MARK: - Range
let singleDigitNumbers = 0..<10
Array(singleDigitNumbers)
let lowercaseLetters = Character("a")...Character("z")

let isContrans =  singleDigitNumbers.contains(9)
let isOverlaps = lowercaseLetters.overlaps("c"..<"f")

/*
Range ..<
ClosedRange ...
 
 如果元素类型仅仅只是满足 Comparable，它对应的是 “普通” 范围 (这是范围元素的最小要求)，那些元素满足 Strideable，并且使用整数作为步⻓的 范围则是可数范围。只有后一种范围是集合类型，它继承了我们在下一章中将要看到的一系列 强大的功能。
*/

// MARK: - sequence

do {
    /*
     struct PrefixSequence: Sequence {
         let string: String
         
         typealias Iterator = PrefixIterator
         __consuming func makeIterator() -> PrefixIterator {
             return PrefixIterator(string: string)
         }
     }

     struct PrefixIterator: IteratorProtocol {
         let string: String
         var offset: String.Index
         
         init(string: String) {
             self.string = string
             offset = string.startIndex
         }
         
         typealias Element = String
         mutating func next() -> String? {
             guard offset > string.endIndex else {
                 return nil
             }
             offset = string.index(after: offset)
             return string[..<offset]
         }
     }
     */
}

/*
do {
    let sequence = stride(from: 0, to: 10, by: 1)
    var i1 = sequence.makeIterator()
    i1.next()
    var i2 = AnyIterator(i1)
    i2.next()
}

do {
    func fibsIterator() ->AnyIterator<Int> {
        var state = (0, 1)
        return AnyIterator {
            let upNumber = state.0
            state = (state.1, state.0 + state.1)
            return upNumber
        }
    }
    let fibsSequence = AnySequence(fibsIterator)
    let array = Array(fibsSequence)
    array[..<10]
    print(array.prefix(10))
}
    
do {
    let fibSequence = sequence(state: (0, 1)) { (state: inout(Int, Int)) -> Int? in
        let upNum = state.0
        state = (state.1, state.0 + state.1)
        return upNum
    }
}
*/
do {
    var array = [1, 2, 3]
    for _ in array {
        array.removeLast()
    }
    array
}

// 错误写法，在迭代引用数组不能操作数组本身
//do {
//    let mutableArray: NSMutableArray = [1, 2, 3]
//    for _ in mutableArray {
//        mutableArray.removeAllObjects()
//    }
//    mutableArray
//}

/*
do {
    
    struct MyData {
        var _data: NSMutableData
        var _dataForWriting: NSMutableData {
            mutating get {
                print("_data1 - \(_data)")
                 _data = _data.mutableCopy() as! NSMutableData
                print("_data2 - \(_data)")
                
                return _data
            }
        }
        
        init() {
            _data = NSMutableData.init()
        }
        
        init(_ data: NSData) {
            _data = data.mutableCopy() as! NSMutableData
        }
        
        mutating func append(_ byte: UInt8) {
            var mutableByte = byte
            _dataForWriting.append(&mutableByte, length: 1)
        }
    }
    
    
    /// hhhhhh
    let theData = NSData(base64Encoded: "wAEP/w==")!
    var x = MyData(theData)
    var y = x
    x._data === y._data
    x.append(0x55)
    y
    x._data === y._data
    
    
}
*/

/*
protocol textProtocol {
    func textA()
    func textC()
}

extension textProtocol {
    func textA() {
        print("textA - extension textProtocol")
    }
    func textB() {
        print("textB - extension textProtocol")
    }
    func textC() {
        print("textC - extension textProtocol")
    }
    func textD() {
        print("textD - extension textProtocol")
    }
}

class Text: textProtocol {
    func textA() {
        print("textA - class text")
    }
    func textD() {
        print("textD - class text")
    }
}
*/

//extension Text: textProtocol {
//    func textB() {
//        print("textB - extension Text class")
//    }
//    func textC() {
//        print("textC - extension Text class")
//    }
//}

//let text: textProtocol = Text()
//text.textA()
//text.textB()
//text.textC()
//text.textD()



/*
do {
    var _handle: OpaquePointer? = nil
    var handle: OpaquePointer { return _handle! }
}



class Person {
    var name = "person"
    
}

class Wang: Person {
    override var name: String {
        get {
           return "wang"
        }
        set {
            super.name = newValue
        }
    }
}

class Li: Person {
    override var name: String {
        get {
           return "li"
        }
        set {
            super.name = newValue
        }
    }
}
*/

/*
func nextInt<I: IteratorProtocol>(iterator: inout I) -> Int? where I.Element == Int  {
    return 1
}


let subStr = "qwerty77".prefix(4)
let str123 = String.init(subStr)


/// 二进制 e2是 10的二次方，十六进制 p2 是2的二次方
let num1 = 1.25e2
let num2 = 0xFp2
let num3 = 1_000_000

// 断言和先决条件

// 多行字符串字面量
let moreStr = """
                hhhhh\
                kkkk
            """
let extensionStr = #"hhh\#nuuu"#
"hello".utf8.description
"hello".utf16.description
*/


/*
 // Sequence协议
struct ReverseIterator<T>: IteratorProtocol {
    typealias Element = T
    
    var array: [T]
    
    var currentIndex: Int
    
    init(_ array: [T]) {
        self.array = array
        self.currentIndex = array.count
    }
    
    mutating func next() -> T? {
        if currentIndex > 0 {
            currentIndex -= 1
            return array[currentIndex]
        }
        return nil
    }
}

struct ReverseArray<T>: Sequence {
    
    typealias Element = T
    
    typealias Iterator = ReverseIterator<T>
    
    var array: [T]
    
    init(_ array: [T]) {
        self.array = array
    }
    
    func makeIterator() -> ReverseIterator<T> {
        return ReverseIterator(self.array)
    }
}

for item in ReverseArray([1, 3, 4, 5, 8]) {
    debugPrint("item - \(item)")
}
*/

/*
// 用元组交换方法
func swap(a: inout Int, b: inout Int) {
    (a, b) = (b, a)
}

var a = 1
var b = 2

swap(a: &a, b: &b)

a
b
*/

/*
let rect = CGRect.init(x: 0, y: 0, width: 100, height: 100)
let (small, large) = rect.divided(atDistance: 20, from: .minXEdge)
*/


//T
//() -> T

/*
func oneAdd(value: Int) -> Int {
    return value + 1
}

// ?? 空合运算符原理
// @autoclosure 入参必须为空
func twoAdd(value: @autoclosure () -> Int) -> Int {
    return value() + 1
}

let result1 = oneAdd(value: 1)
let result2 = twoAdd(value: 1)

debugPrint("result1 - \(result1)")
debugPrint("result2 - \(result2)")
*/

/*

func doWork(block: () -> ()) {
    block()
}

func doWorkAsync(block: @escaping () -> ()) {
    DispatchQueue.main.async {
        block()
    }
}

class S {
    var foo = "foo"
    
    func method1() {
        doWork {
            print("foo - \(foo)")
        }
        foo = "bar"
    }
    
    func method2() {
        doWorkAsync {
            print("foo - \(self.foo)")
        }
        foo = "bar"
    }
    
    func method3() {
        doWorkAsync { [weak self] in
            guard let strongSelf = self else { return }
            print("foo - \(strongSelf.foo)")
        }
        foo = "bar"
    }
    deinit {
        print("deinit")
    }
}

S().method1()

S().method2()
//S().method3()
*/

// 闭包 逃逸 weak
// 1、只有堆上的对象相互持有才会循环引用，栈上的对象（属性、函数等）只是持有方式
// 2、@escaping 逃逸闭包只能用在函数参数上
// 3、闭包逃逸不逃逸与循环引用没有直接关系，只是闭包会捕获变量，逃逸闭包会强制要求写self，让你检查是否捕获，而非逃逸因为能确保在函数作用于执行完毕闭包也被执行完，所有不会存在循环引用的问题

/*

// 操作符
struct Vector2D {
    var x = 0.0
    var y = 0.0
}

func +(left: Vector2D, right: Vector2D) -> Vector2D {
    let x = left.x + right.x
    let y = left.y + right.y
    return Vector2D(x: x, y: y)
}

let v1 = Vector2D(x: 1, y: 2)
let v2 = Vector2D(x: 2, y: 3)
let v3 = v1 + v2
print("v3.x - \(v3.x), v3.y - \(v3.y)")



// 自定义操作符
precedencegroup DotProductPrecedence {
    associativity: none
    higherThan: MultiplicationPrecedence
}

infix operator +*: DotProductPrecedence

func +*(left: Vector2D, right: Vector2D) -> Double {
    return left.x * right.x + left.y * right.y
}

let result = v1 +* v2
*/

// 函数参数默认是不可变的
// inout 参数并不是修改指针的内容，而是因为是值类型，只是在函数内复制的值，返回的时候重新赋值了


let array = [1, 2, 3]
//array[3] // 崩溃

var array1: [Int] = []
//array1.removeLast() // 崩溃
array1.popLast() // 返回可选值


extension String: Error { }

func authenticateBiometrically(_ user: String) throws -> Bool {
    throw "Failed"
}

func authenticateByPassword(_ user: String) -> Bool {
    return true
}

//func authenticateUser(method: (String) throws -> Bool) throws {
//    try method("twostraws")
//    print("Success!")
//}

func authenticateUser(method: (String) throws -> Bool) rethrows {
//    try authenticateBiometrically("")
    print("Success!")
}


do {
    try authenticateUser(method: authenticateByPassword)
} catch {
    print("D'oh!")
}

//do {
//    try authenticateByPassword("")
//} catch let error  {
//    debugPrint(error)
//}


/*
/// - Complexity: O(*m* + *n*), where *n* is the length of this sequence
///   and *m* is the length of the result.
@inlinable public func compactMap<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult]
*/

/*
/// - Complexity: O(*m* + *n*), where *n* is the length of this sequence
///   and *m* is the length of the result.
@inlinable public func flatMap<SegmentOfResult>(_ transform: (Element) throws -> SegmentOfResult) rethrows -> [SegmentOfResult.Element] where SegmentOfResult : Sequence
*/

 /*
 public func flatMap<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult]
 */

var map: [String: Int] = [:]
map["a"] = 1
map["b"] = 2
map["a"] = 3
map

let sn = ["1", "2", "3", "foo"]
let y = sn.first
y
debugPrint(y)
let x = y.map { Int($0) }
debugPrint(x)
let z = y.flatMap { Int($0) }
debugPrint(z)


func transform(value: String?) {
    debugPrint("transform")
}

let s = "s"
transform(value: .some(s))
transform(value: s)

/*
func uniqueIntegerProvider() -> () -> Int {
    var i = 0
    return {
        i += 1
        return i
    }
}

let f = uniqueIntegerProvider()
let a = f()
let b = f()

let f1 = uniqueIntegerProvider()
let a1 = f1()
let b1 = f1()
*/


func uniqueIntegerProvider() -> AnyIterator<Int> {
    var i = 0
    return AnyIterator {
        i += 1
        return i }
}

let ai = uniqueIntegerProvider()
ai.next()
ai.next()



/*
struct City: Codable {
    var name = ""
    var park: Park?
}
*/

/*
let p = Park(name: "华新公园", address: "华新镇华富路555号")
let encoder = JSONEncoder()

let data = try? encoder.encode(p)

let de = JSONDecoder()
if let d = data {
    let p = try? de.decode(Park.self, from: d)
    
//    JSONSerialization.jsonObject(with: d)
}
*/



// 单层级正常解析
/*
let json = "{\"name\":\"中通快递\",\"address\":\"华新镇\"}"
do {
    let d = json.data(using: .utf8)
    let decoder = JSONDecoder()
    let p = try decoder.decode(Park.self, from: d!)
} catch  {
    debugPrint("解析错误")
}
*/


// 数组解析

/*
let json = "[{\"name\":\"中通快递\",\"address\":\"华新镇\"},{\"name\":\"申通快递\",\"address\":\"凤溪镇\"}]"
do {
    let d = json.data(using: .utf8)
    let decoder = JSONDecoder()
    let p = try decoder.decode([Park].self, from: d!)
    debugPrint("p: \(p)")
} catch  {
    debugPrint("解析错误")
}
*/

/*
struct Park: Codable {
    var name = ""
    var address = ""
}

struct City: Codable {
    var name = ""
    var park: Park?
}

// 嵌套解析
let json = "{\"name\":\"上海\",\"park\":{\"name\":\"申通快递\",\"address\":\"凤溪镇\"}}"
do {
    let d = json.data(using: .utf8)
    let decoder = JSONDecoder()
    let p = try decoder.decode(City.self, from: d!)
    debugPrint("p: \(p)")
} catch  {
    debugPrint("解析错误")
}
*/


// 重命名字段 和 部分解析
/*
struct Person: Codable {
    var name = ""
    var age: Int?
    
    enum CodingKeys: String, CodingKey {
        // 把json中的label字段解析成Person结构体中的name
        case name = "label"
        // 没有列举出来的字段不解析
//        case age
    }
}

let json = "{\"label\":\"小明\",\"age\":13}"
do {
    let d = json.data(using: .utf8)
    let decoder = JSONDecoder()
    let p = try decoder.decode(Person.self, from: d!)
    debugPrint("p: \(p)")
} catch  {
    debugPrint("解析错误")
}
*/



// 某个字段解析错误，如果不处理，整个解析都失败，可通过重写encode(to:) 和 init(from:) 方法实现
struct Person: Codable {
    var name = ""
    var age: Int?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        do{
//            self.coordinate = try container.decodeIfPresent(Coordinate.self, forKey: .coordinate)
            self.age = try container.decode(Int.self, forKey: .age)
        } catch {
            debugPrint("self.age decode")
            self.age = 0
        }
    }
}

let json = "{\"name\":\"小明\",\"age\":{}}"
do {
    let d = json.data(using: .utf8)
    let decoder = JSONDecoder()
    let p = try decoder.decode(Person.self, from: d!)
    debugPrint("p: \(p)")
} catch  {
    debugPrint("解析错误")
}

//let sortByYear: (Int) -> Bool = { num in return num / 2 == 0 }
let sortByYear: (Int) -> Bool = { $0 / 2 == 0}
let rs = sortByYear(4)

func increment(value: inout Int) {
    value += 1
}
var i = 0
increment(value: &i)
i


/*
struct P: TextP {
    typealias Element = Int
    
    func log() {
        debugPrint("log")
    }
}
// 含有 Self 或 关联类型 的协议不能作为独立类型
let p = P()

//func f(_: TextP) {
//
//}
*/


/*
class P<T: TextP> where T.Element == Int {
    func log() {
        debugPrint("log")
    }
}

class P1<T> where T: TextP, T.Element == Int {
    func log() {
        debugPrint("log")
    }
}
*/


//let p: P = P<<#T: TextP#>>()




/*
class IteratorStore<I: IteratorProtocol> where I.Element == Int {
    
    var iterator: I
    
    init(iterator: I){
        self.iterator = iterator
    }
}

class Iterator1: IteratorProtocol {
    func next() -> Int? {
        return 1
    }
}

class Iterator2: IteratorProtocol {
    func next() -> Int? {
        return 2
    }
}

let i1 = Iterator1()
let i2 = Iterator2()

let s1 = IteratorStore.init(iterator: i1)
let s2 = IteratorStore.init(iterator: i2)
*/

// 报错 IteratorProtocol 不能作为独立的类型
//let iArray: [IteratorProtocol] = [i1, i2]

//let sArray: [IteratorStore<Iterator1>] = [s1, s2]


public protocol TextP {
    associatedtype Element
    func log()
}

struct T1: TextP {
    typealias Element = Int
    
    func log() {
        debugPrint("T1 log")
    }
}

struct T2: TextP {
    typealias Element = Int
    
    func log() {
        debugPrint("T2 log")
    }
}
let t1 = T1()
let t2 = T2()

//let ts = [t1, T2]

/*
struct TextPBox: TextP{
    typealias Element = Int
    
    var tbLog: (() -> Void)?
    
    init<T: TextP>(item: T) {
        self.tbLog = {item.log()}
    }
    
    func log() {
        self.tbLog?()
    }
}


let tb1 = TextPBox.init(item: t1)
let tb2 = TextPBox.init(item: t2)
let tbs = [tb1, tb2]
tb1.tbLog?()
tb2.tbLog?()

tb1.log()
tb2.log()
*/


class TextPBox<Element>: TextP {
    func log() {
        fatalError("抽象类，需要子类来实现")
    }
}


class TextPBoxHelper<T: TextP>: TextPBox<Int> {
    var item: T
    init(item: T) {
        self.item = item
    }
    override func log() {
        item.log()
    }
}

let tbh1 = TextPBoxHelper.init(item: t1)
let tbh2 = TextPBoxHelper.init(item: t2)
tbh1.log()
tbh2.log()
let tbhs = [tbh1, tbh2]

while true {
    let runloop = RunLoop.current
    runloop.run(mode: .default, before: Date.distantFuture)
    debugPrint("haha")
}

