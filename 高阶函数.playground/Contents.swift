import UIKit
// MARK:- sort 和 sorted
/// 1.sort 对原集合进行排序，无返回值直接修改原集合, 只能排序 【Array】
/// 2.sorted 有返回值，能排序 【Array】【Dictionary】【Set】
/// .sort()无返回值 .sorted()有返回值   都是升序
do{
    let strs: Set = ["a","b","1","5","c","Peter", "Kweku"]
    var nums = [1,2,5,4,3,9]
    var students = ["Kofi", "Abena", "Peter", "Kweku", "Akosua"]
    
    var numDict = ["a": 2, "b": 1]
    
    /*
     nums.sort { (a, b) -> Bool in
         a > b
     }
     */
//    nums.sort(by: < )
    nums.sorted(by: {$0 > $1}) // 使用$0、$1 这样的格式必须在花括号内{}
    students.sorted(by: >)
    let num =  strs.sorted(by: >)
    nums.sort()
    let sortedNum = nums.sorted()
    let sortNumDict = numDict.sorted(by: > )
    
    print(nums)
    print(num)
}


/*
 enum HTTPResponse {
     case ok
     case error(Int)
 }
 var responses: [HTTPResponse] = [.error(500), .ok, .ok, .error(404), .error(403)]
 responses.sort {
     switch ($0, $1) {
     // Order errors by code
     case let (.error(aCode), .error(bCode)):
         return aCode < bCode

     // All successes are equivalent, so none is before any other
     case (.ok, .ok): return false

     // Order errors before successes
     case (.error, .ok): return true
     case (.ok, .error): return false
     }
 }
 print(responses)
 */


 // MARK:- map、flatMap、compactMap
/// 3.map 根据闭包的返回结果对集合的元素进行替代，映射函数,有返回值
/// 在闭包中，闭包的入参类型和返回类型可以不一样
do {
    let nums = [1,4,3,6,2]
    let mapNums =  nums.map { "No.\($0)" }
    print(mapNums)
    let sortMapNums = nums.sorted(by: > ).map({ "No.\($0)" })
    print(sortMapNums)
    
}

/// 4.flatMap a.降维【用于集合类型】  b.可选类型解包【用于可选类型】
do {
    let nums = [1,4,3,6,2]
    let flatMapNums = nums.flatMap { "No.\($0)" }
    print(flatMapNums)
    
    
    let nums2 = [2, 4, Optional(5), 6, nil]
    let flatNums2 = nums2.flatMap({$0})
    flatNums2
    
    let strs = [["aaa", "bbb"], ["ccc", "ddd"]]
    let flatMapStrs = strs.flatMap{ $0.map{ $0 + "0"} }
    print(flatMapStrs)
    
    let optLatticeNumbers = [[1, Optional(2), 3], [3, nil, 5], Optional(nil)]
    // 解析首层元素, 若有nil则过滤, 就不会降维
    let flatMapArr2 = optLatticeNumbers.flatMap { $0 }
    flatMapArr2
    
    let latticeNumbers = [[1, Optional(2), 3], [3, nil, 5]]
    // 解析首层元素, 若没有nil, 则会降维
    let flatMapArr = latticeNumbers.flatMap { $0 }
    flatMapArr
    
    
    
    
    
    
    let num1: Int? = 3
    let num2: Int? = nil
    
    let mapNum1 = num1.map { $0 + 2}
    mapNum1
    type(of: mapNum1)
    
    let mapNum2 = num2.map { $0 + 2}
    mapNum2
    type(of: mapNum2)
    
    func loadURL(url: URL) {
        print(url.absoluteString)
    }
    let urlStr: String? = "http://www.baidu.com"
    urlStr.flatMap(URL.init).map(loadURL)
    
    func add(a: Int) -> Int {
        return a + 4
    }
    
    let a: Int? = 3
    let flatA = a.map(add) // 函数只有一个参数的时候，可以省略，只写方法名
    flatA
    type(of: flatA)
    
}
/// 可选类型的解包：
/// 1.强制解包
/// 2.if判断
/// 3.可选绑定 if let guard let
/// 4.隐式解包
/// 5.map flatMap
/// 6.可选链（怎么实现的？）
///
/// 5.compactMap compactMap函数作为过滤nil的flatMap函数的替代函数。当集合中的元素为一个一维集合，他们之间的功能是没有差别的。
do {
    let optLatticeNumbers = [[1, Optional(2), 3], [3, nil, 5], Optional(nil)]
    // 解析首层元素, 若有nil则过滤, 不会降维
    let flatMapArr2 = optLatticeNumbers.compactMap({ $0 })
    flatMapArr2
    
    let latticeNumbers = [[1, Optional(2), 3], [3, nil, 5]]
    // 解析首层元素, 若没有nil, 不会降维
    let flatMapArr = latticeNumbers.compactMap { $0 }
    flatMapArr
}

 // MARK:- filter
/// 6.filter 按照条件对元素进行过滤
do {
    let nums = [5, 7, 1, 4, 3]
    let filterNums = nums.filter{
        return $0 > 3
    }
    filterNums
    
}

// MARK:- reduce
/// 7.reduce 以指定参数为基础，按照条件进行拼接
do {
    let nums = [1, 4, 2, 6, 3]
    /*
     let reduceNum = nums.reduce(100) { (result, num) -> Int in
         return result + num
     }
     */
    
    let reduceNum = nums.reduce(100) { result, num in
        return result + num
    }
    reduceNum
}

/// 8.prefix 正向取满足条件的元素进行新集合创建，一旦不满足，跳出循环，不再执行
// MARK:- prefix
do {
    let nums = [4, 5, 6, 2, 7, 10, 5, 4, 12, 4, 8]
    /// 正向取元素列表，直到不满足小于10，跳出循环，不再执行
    let prefixNums = nums.prefix { $0 < 10 }
    prefixNums
    
    /// 正向取元素列表，直到取够了8个，跳出循环，不再执行
    let prefixMaxLengthNums = nums.prefix(8)
    prefixMaxLengthNums
    
    /// 正向取元素列表，直到取到index为9，不包含index9，跳出循环，不再执行
    let prefixUptoNums = nums.prefix(upTo: 9)
    prefixUptoNums
    
    /// 正向取元素列表，直到取到index为9，包含index9，跳出循环，不再执行
    let prefixThroughNums = nums.prefix(through: 9)
    prefixThroughNums
}

// MARK:- drop
/// 9.drop 与prefix函数对应。正向跳过满足条件的元素，进行新集合创建。一旦出现不满足条件的元素，则跳出循环，不再执行
/// 【返回集合】
do {
    let nums = [3, 4, 7, 10, 12, 3, 6, 7, 11, 19, 4, 6, 10]
    
    /// 按条件跳过
    let dropNums = nums.drop { $0 < 10}
    dropNums
    
    /// 跳过第一个
    let dropFirst = nums.dropFirst()
    dropFirst
    
    /// 跳过前3个
    let dropFirst3 = nums.dropFirst(3)
    dropFirst3
    
    /// 跳过最后一个
    let dropLast = nums.dropLast()
    dropLast
    
    /// 跳过最后3个
    let dropLast4 = nums.dropLast(4)
    dropLast4
}

// MARK:- first
/// 10.first 正向找出第一个满足条件的元素 【返回一个元素】
do {
    let nums = [3, 4, 7, 10, 12, 3, 6, 7, 11, 19, 4, 6, 10]
    let first = nums.first { $0 > 10}
    first
}

// MARK:- last
/// 11.last 反向找出第一个满足条件的元素
do {
    let nums = [3, 4, 7, 10, 12, 3, 6, 7, 11, 19, 4, 6, 10]
    let last = nums.last { $0 > 10}
    last
}

// MARK:- firstIndex
/// 12.firstIndex 正向找出第一个满足条件的元素下标
do {
    let nums = [3, 4, 7, 10, 12, 3, 6, 7, 11, 19, 4, 6, 10]
    let firstIndex = nums.firstIndex { $0 > 10}
    firstIndex
    
    /// 返回第一个与之相等的元素下标
    let firstIndexOf = nums.firstIndex(of: 3)
    firstIndexOf
}

// MARK:- lastIndex
/// 13.lastIndex 反向找出第一个满足条件的元素下标
 do {
    let nums = [3, 4, 7, 10, 12, 3, 6, 7, 11, 19, 4, 6, 10]
    let lastIndex = nums.lastIndex { $0 > 10}
    lastIndex
    
    /// 返回最后一个与之相等的元素下标
    let lastIndexOf = nums.lastIndex(of: 3)
    lastIndexOf
}

// MARK:- partition
/// 14.partition【用于快排？】
/// 按照条件进行重新排序，不满足条件的元素在集合前半部分，满足条件的元素后半部分，但不是完整的升序或者降序排列。
/// 返回值为排序完成后集合中第一个满足条件的元素下标。
do {
    var partitionNumbers = [20, 50, 30, 10, 40, 20, 60]
    let pIndex = partitionNumbers.partition { $0 > 30 }
    partitionNumbers // partitionNumbers = [20, 20, 30, 10, 40, 50, 60]
    pIndex // pIndex = 4
}

// MARK:- min
/// 15.min 按条件排序后取最小元素
do {
    let nums = [3, 4, 7, 10, 12, 3, 6, 7, 11, 19, 4, 6, 10]
    let min = nums.min(by: < )
    min
    
    let min5 = nums.min { $0 % 5 < $1 % 5}
    min5
    
    let defaultMin = nums.min()
    defaultMin
}

// MARK:- max
/// 16.max 与min相反
/// 16.removeAll 移除原集合中所有满足条件的元素。无返回值，直接修改原集合，所以这个集合应该是可变类型的。
do {
    var nums = [3, 4, 7, 10, 12, 3, 6, 7, 11, 19, 4, 6, 10]
    nums.removeAll { $0 < 10 }
    nums
}

// MARK:- max
/// 17.集合遍历 （forEach、for-in enumerated() ）

// MARK:- shuffled
/// 18.shuffled 打乱集合中元素的的顺序
do {
    let ascendingNumbers = 0...9
    let shuffledArr = ascendingNumbers.shuffled()
    shuffledArr
}
// MARK:- contains
/// 19.contains 判断集合中是否包含某元素
///

// MARK:- split和joined
/// 20.split和joined函数
/// split:字符串的函数，按条件分割字符串，为子字符串创建集合。与Objective-C中的componentsSeparatedByString:方法类似。
/// joined:数组元素连接指定字符拼接成一个字符串。与Objective-C中的componentsJoinedByString:方法类似。
do {
    let line = "123Hi!123I'm123a123coder.123"
    let splitArr = line.split { $0.isNumber }
    splitArr // ["Hi!", "I'm", "a", "coder."]

    // 也可指定字符
    let splitArr2 = line.split(separator: "1")
    splitArr2 // ["23Hi!", "23I'm", "23a", "23coder.", "23"]
    
    let joined = splitArr.joined(separator: "_")
    joined // "Hi!_I'm_a_coder."

    // 也可以只传入字符
    let joined2 = splitArr2.joined(separator: "#")
    joined2 // "23Hi!#23I'm#23a#23coder.#23"

}

// MARK:- zip
/// 21.zip 将两个数组合并为一个元组组成的数组
do {
    let titles = ["aaa", "bbb", "ccc"]
    let numbers = [111, 222, 333]
    let zipA = zip(titles, numbers)
    for (title, num) in zipA {
        print("\(title)-\(num)")
    }
    zipA
}



