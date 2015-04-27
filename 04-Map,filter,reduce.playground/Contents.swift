//: Map, Filter, Reduce
//: ===================
//: 
//: Functions that take functions as arguments are sometimes called
//: *higher-order* functions. In this chapter, we will tour some of the
//: higher-order functions on arrays from the Swift standard library. By
//: doing so, we will introduce Swift's *generics* and show how to assemble
//: complex computations on arrays.
//: 
//: Introducing Generics
//: --------------------
//: 
//: Suppose we need to write a function that, given an array of integers,
//: computes a new array, where every integer in the original array has been
//: incremented by one. Such a function is easy to write using a single
//: `for` loop:
//: 
//:
//:    func incrementArray(xs: [Int]) -> [Int] {
//:        var result: [Int] = []
//:        for x in xs {
//:            result.append(x + 1)
//:        }
//:        return result
//:    }
//:
//: 
//: Now suppose we also need a function that computes a new array, where
//: every element in the argument array has been doubled. This is also easy
//: to do using a `for` loop:
//: 
//:
//:    func doubleArray1(xs: [Int]) -> [Int] {
//:        var result: [Int] = []
//:        for x in xs {
//:            result.append(x * 2)
//:        }
//:        return result
//:    }
//:
//: 
//: Both of these functions share a lot of code. Can we abstract over the
//: differences and write a single, more general function that captures this
//: pattern? Such a function would look something like this:
//: 
//:
//:    func computeIntArray(xs: [Int]) -> [Int] {
//:        var result: [Int] = []
//:        for x in xs {
//:            result.append(/* something using x */)
//:        }
//:        return result
//:    }
//:
//: 
//: To complete this definition, we need to add a new argument describing
//: how to compute a new integer from the individual elements of the array —
//: that is, we need to pass a function as an argument:
//: 

func computeIntArray(xs: [Int], f: Int -> Int) -> [Int] {
    var result: [Int] = []
    for x in xs {
        result.append(f(x))
    }
    return result
}

//: 
//: Now we can pass different arguments, depending on how we want to compute
//: a new array from the old array. The `doubleArray` and `incrementArray`
//: functions become one-liners that call `computeIntArray`:
//: 

func doubleArray2(xs: [Int]) -> [Int] {
    return computeIntArray(xs) { x in x * 2 }
}

//: 
//: Note that we are using Swift's syntax for [trailing
//: closures](http://objc.io/fpinswift/6) here — we provide the final
//: (closure) argument to `computeIntArray` after the parentheses containing
//: the other arguments.
//: 
//: This code is still not as flexible as it could be. Suppose we want to
//: compute a new array of booleans, describing whether the numbers in the
//: original array were even or not. We might try to write something like
//: this:
//: 
//:
//:    func isEvenArray(xs: [Int]) -> [Bool] {
//:        computeIntArray(xs) { x in x % 2 == 0 }
//:    }
//:
//: 
//: Unfortunately, this code gives a type error. The problem is that our
//: `computeIntArray` function takes an argument of type `Int -> Int`, that
//: is, a function that returns an integer. In the definition of
//: `isEvenArray`, we are passing an argument of type `Int -> Bool`, which
//: causes the type error.
//: 
//: How should we solve this? One thing we *could* do is define a new
//: version of `computeIntArray` that takes a function argument of type
//: `Int -> Bool`. That might look something like this:
//: 
//:
//:    func computeBoolArray(xs: [Int], f: Int -> Bool) -> [Bool] {
//:        let result: [Bool] = []
//:        for x in xs {
//:            result.append(f(x))
//:        }
//:        return result
//:    }
//:
//: 
//: This doesn't scale very well though. What if we need to compute a
//: `String` next? Do we need to define yet another higher-order function,
//: expecting an argument of type `Int -> String`?
//: 
//: Luckily, there is a solution to this problem: we can use
//: [generics](http://objc.io/fpinswift/7). The definitions of
//: `computeBoolArray` and `computeIntArray` are identical; the only
//: difference is in the *type signature*. If we were to define another
//: version, `computeStringArray`, the body of the function would be the
//: same again. In fact, the same code will work for *any* type. What we
//: really want to do is write a single generic function that will work for
//: every possible type:
//: 

func genericComputeArray<U>(xs: [Int], f: Int -> U) -> [U] {
    var result: [U] = []
    for x in xs {
        result.append(f(x))
    }
    return result
}

//: 
//: The most interesting thing about this piece of code is its type
//: signature. To understand this type signature, it may help you to think
//: of `genericComputeArray<U>` as a family of functions. Each choice of the
//: *type* variable `U` determines a new function. This function takes an
//: array of integers and a function of type `Int -> U` as arguments, and
//: returns an array of type `[U]`.
//: 
//: We can generalize this function even further. There is no reason for it
//: to operate exclusively on input arrays of type `[Int]`. Abstracting over
//: this yields the following type signature:
//: 

func map<T, U>(xs: [T], f: T -> U) -> [U] {
    var result: [U] = []
    for x in xs {
        result.append(f(x))
    }
    return result
}

//: 
//: Here we have written a function, `map`, that is generic in two
//: dimensions: for any array of `T`s and function `f: T -> U`, it will
//: produce a new array of `U`s. This `map` function is even more generic
//: than the `genericComputeArray` function we saw earlier. In fact, we can
//: define `genericComputeArray` in terms of `map`:
//: 

func computeIntArray<T>(xs: [Int], f: Int -> T) -> [T] {
    return map(xs, f)
}

//: 
//: Once again, the definition of the function is not that interesting:
//: given two arguments, `xs` and `f`, apply `map` to `(xs, f)`, and return
//: the result. The types are the most interesting thing about this
//: definition. The `computeIntArray` is an instance of the `map` function,
//: only it has a more specific type.
//: 
//: There is already a `map` method defined in the Swift standard library in
//: the array type. Instead of writing `map(xs, f)`, we can call `Array`'s
//: `map` function by writing `xs.map(f)`. Here is an example definition of
//: the `doubleArray` function, using Swift's built-in `map` function:
//: 

func doubleArray3(xs: [Int]) -> [Int] {
  return xs.map { x in 2 * x }
}

//: 
//: The point of this chapter is *not* to argue that you should define `map`
//: yourself; we want to argue that there is no magic involved in the
//: definition of `map` — you *could* have defined it yourself!
//: 
//: Filter
//: ------
//: 
//: The `map` function is not the only function in Swift's standard array
//: library that uses generics. In the upcoming sections, we will introduce
//: a few others.
//: 
//: Suppose we have an array containing strings, representing the contents
//: of a directory:
//: 

let exampleFiles = ["README.md", "HelloWorld.swift", 
                    "HelloSwift.swift", "FlappyBird.swift"]

//: 
//: Now suppose we want an array of all the `.swift` files. This is easy to
//: compute with a simple loop:
//: 

func getSwiftFiles(files: [String]) -> [String] {
    var result: [String] = []
    for file in files {
        if file.hasSuffix(".swift") {
            result.append(file)
        }
    }
    return result
}

//: 
//: We can now use this function to ask for the Swift files in our
//: `exampleFiles` array:
//: 
getSwiftFiles(exampleFiles)
//: 
//: Of course, we can generalize the `getSwiftFiles` function. For instance,
//: instead of hardcoding the `.swift` extension, we could pass an
//: additional `String` argument to check against. We could then use the
//: same function to check for `.swift` or `.md` files. But what if we want
//: to find all the files without a file extension, or the files starting
//: with the string `"Hello"`?
//: 
//: To perform such queries, we define a general purpose `filter` function.
//: Just as we saw previously with `map`, the `filter` function takes a
//: *function* as an argument. This function has type `T -> Bool` — for
//: every element of the array, this function will determine whether or not
//: it should be included in the result:
//: 

func filter<T>(xs: [T], check: T -> Bool) -> [T] {
    var result: [T] = []
    for x in xs {
        if check(x) {
            result.append(x)
        }
    }
    return result
}

//: 
//: It is easy to define `getSwiftFiles` in terms of `filter`:
//: 

func getSwiftFiles2(files: [String]) -> [String] {
    return filter(files) { file in file.hasSuffix(".swift") }
}

//: 
//: Just like `map`, the array type already has a `filter` function defined
//: in Swift's standard library. We can call Swift's built-in `filter`
//: function on our `exampleFiles` array, as follows:
//: 
exampleFiles.filter { file in file.hasSuffix(".swift") }
//: 
//: Now you might wonder: is there an even more general purpose function
//: that can be used to define *both* `map` and `filter`? In the last part
//: of this chapter, we will answer that question.
//: 
//: Reduce
//: ------
//: 
//: Once again, we will consider a few simple functions before defining a
//: generic function that captures a more general pattern.
//: 
//: It is straightforward to define a function that sums all the integers in
//: an array:
//: 

func sum(xs: [Int]) -> Int {
    var result: Int = 0
    for x in xs {
        result += x
    }
    return result
}

//: 
//: We can use this `sum` function to compute the sum of all the integers in
//: an array:
//: 
sum([1, 2, 3, 4])
//: 
//: A similar for loop computes the product of all the integers in an array:
//: 

func product(xs: [Int]) -> Int {
    var result: Int = 1
    for x in xs {
        result = x * result
    }
    return result
}

//: 
//: Similarly, we may want to concatenate all the strings in an array:
//: 

func concatenate(xs: [String]) -> String {
    var result: String = ""
    for x in xs {
        result += x
    }
    return result
}

//: 
//: Or, we can choose to concatenate all the strings in an array, inserting
//: a separate header line and newline characters after every element:
//: 

func prettyPrintArray(xs: [String]) -> String {
    var result: String = "Entries in the array xs:\n"
    for x in xs {
        result = "  " + result + x + "\n"
    }
    return result
}

//: 
//: What do all these functions have in common? They all initialize a
//: variable, `result`, with some value. They proceed by iterating over all
//: the elements of the input array, `xs`, updating the result somehow. To
//: define a generic function that can capture this pattern, there are two
//: pieces of information that we need to abstract over: the initial value
//: assigned to the `result` variable, and the *function* used to update the
//: `result` in every iteration.
//: 
//: With this in mind, we arrive at the following definition for the
//: `reduce` function that captures this pattern:
//: 

func reduce<A, R>(arr: [A], 
                  initialValue: R, 
                  combine: (R, A) -> R) -> R {
                 
    var result = initialValue
    for i in arr {
        result = combine(result, i)
    }
    return result
}

//: 
//: The type of reduce is a bit hard to read at first. It is generic in two
//: ways: for any *input array* of type `[A]`, it will compute a result of
//: type `R`. To do this, it needs an initial value of type `R` (to assign
//: to the `result` variable), and a function, `combine: (R, A) -> R`, which
//: is used to update the result variable in the body of the for loop. In
//: some functional languages, such as OCaml and Haskell, `reduce` functions
//: are called `fold` or `fold_right`.
//: 
//: We can define every function we have seen in this chapter thus far using
//: `reduce`. Here are a few examples:
//: 

func sumUsingReduce(xs: [Int]) -> Int {
    return reduce(xs, 0) { result, x in result + x }
}

//: 
//: Instead of writing a closure, we could have also written just the
//: operator as the last argument. This makes the code even shorter:
//: 

func productUsingReduce(xs: [Int]) -> Int {
    return reduce(xs, 1, *)
}

func concatUsingReduce(xs: [String]) -> String {
    return reduce(xs, "", +)
}

//: 
//: Once again, `reduce` is defined in Swift's standard library as an
//: extension to arrays. From now on, instead of writing `reduce(xs,`
//: `initialValue,` `combine)`, we will use `xs.reduce(initialValue,`
//: `combine)`.
//: 
//: We can use `reduce` to define new generic functions. For example,
//: suppose that we have an array of arrays that we want to flatten into a
//: single array. We could write a function that uses a for loop:
//: 

func flatten<T>(xss: [[T]]) -> [T] {
    var result : [T] = []
    for xs in xss {
        result += xs
    }
    return result
}

//: 
//: Using `reduce`, however, we can write this function as follows:
//: 

func flattenUsingReduce<T>(xss: [[T]]) -> [T] {
    return xss.reduce([]) { result, xs in result + xs }
}

//: 
//: In fact, we can even redefine `map` and `filter` using reduce:
//: 

func mapUsingReduce<T, U>(xs: [T], f: T -> U) -> [U] {
    return xs.reduce([]) { result, x in result + [f(x)] }
}

func filterUsingReduce<T>(xs: [T], check: T -> Bool) -> [T] {
    return xs.reduce([]) { result, x in
        return check(x) ? result + [x] : result 
    }
}

//: 
//: This shows how the `reduce` function captures a very common programming
//: pattern: iterating over an array to compute a result.
//: 
//: Putting It All Together
//: -----------------------
//: 
//: To conclude this section, we will give a small example of `map`,
//: `filter`, and `reduce` in action.
//: 
//: Suppose we have the following `struct` definition, consisting of a
//: city's name and population (measured in thousands of inhabitants):
//: 

struct City {
    let name: String
    let population: Int
}

//: 
//: We can define several example cities:
//: 

let paris = City(name: "Paris", population: 2243)
let madrid = City(name: "Madrid", population: 3216)
let amsterdam = City(name: "Amsterdam", population: 811)
let berlin = City(name: "Berlin", population: 3397)

let cities = [paris, madrid, amsterdam, berlin]

//: 
//: Now suppose we would like to print a list of cities with at least one
//: million inhabitants, together with their total populations. We can
//: define a helper function that scales up the inhabitants:
//: 

func scale(city: City) -> City {
    return City(name: city.name, population: city.population * 1000)
}

//: 
//: Now we can use all the ingredients we have seen in this chapter to write
//: the following statement:
//: 
cities.filter { city in city.population > 1000 }
      .map(scale)
      .reduce("City: Population") { result, c in 
          return result + "\n" + "\(c.name) : \(c.population)" 
      }
//: 
//: We start by filtering out those cities that have less than one million
//: inhabitants. We then map our `scale` function over the remaining cities.
//: Finally, we compute a `String` with a list of city names and
//: populations, using the `reduce` function. Here we use the `map`,
//: `filter`, and `reduce` definitions from the `Array` type in Swift's
//: standard library. As a result, we can chain together the results of our
//: maps and filters nicely. The `cities.filter(..)` expression computes an
//: array, on which we call `map`; we call `reduce` on the result of this
//: call to obtain our final result.
//: 
//: Generics vs. the `Any` Type
//: ---------------------------
//: 
//: Aside from generics, Swift also supports an `Any` type that can
//: represent [values of any type](http://objc.io/fpinswift/8). On the
//: surface, this may seem similar to generics. Both the `Any` type and
//: generics can be used to define functions accepting different types of
//: arguments. However, it is very important to understand the difference:
//: generics can be used to define flexible functions, the types of which
//: are still checked by the compiler; the `Any` type can be used to dodge
//: Swift's type system (and should be avoided whenever possible).
//: 
//: Let's consider the simplest possible example, which is a function that
//: does nothing but return its argument. Using generics, we might write the
//: following:
//: 

func noOp<T>(x: T) -> T {
    return x
}

//: 
//: Using the `Any` type, we might write the following:
//: 

func noOpAny(x: Any) -> Any {
    return x
}

//: 
//: Both `noOp` and `noOpAny` will accept any argument. The crucial
//: difference is what we know about the value being returned. In the
//: definition of `noOp`, we can clearly see that the return value is the
//: same as the input value. This is not the case for `noOpAny`, which may
//: return a value of any type — even a type different from the original
//: input. We might also give the following, erroneous definition of
//: `noOpAny`:
//: 

func noOpAnyWrong(x: Any) -> Any {
    return 0
}

//: 
//: Using the `Any` type evades Swift's type system. However, trying to
//: return `0` in the body of the `noOp` function defined using generics
//: will cause a type error. Furthermore, any function that calls `noOpAny`
//: does not know to which type the result must be cast. There are all kinds
//: of possible runtime exceptions that may be raised as a result.
//: 
//: Finally, the *type* of a generic function is extremely informative.
//: Consider the following generic version of the function composition
//: operator, `>>>`, that we defined in the chapter [Wrapping Core
//: Image](#wrapping-core-image):
//: 

infix operator >>> { associativity left }
func >>> <A, B, C>(f: A -> B, g: B -> C) -> A -> C {
    return { x in g(f(x)) }
}

//: 
//: The type of this function is so generic that it completely determines
//: how the *function itself* is defined. We'll try to give an informal
//: argument here. We need to produce a value of type `C`. As there is
//: nothing else we know about `C`, there is no value that we can return
//: immediately. If we knew that `C` was some concrete type, like `Int` or
//: `Bool`, we could potentially return a value of that type, such as `5` or
//: `True`, respectively. As our function must work *for any* type `C`, we
//: cannot do so. The only argument to the `>>>` operator that refers to `C`
//: is the function `g : B -> C`. Therefore, the only way to get our hands
//: on a value of type `C` is by applying the function `g` to a value of
//: type `B`.
//: 
//: Similarly, the only way to produce a `B` is by applying `f` to a value
//: of type `A`. The only value of type `A` that we have is the final
//: argument to our operator. Therefore, this definition of function
//: composition is the only possible function that has this generic type.
//: 
//: In the same way, we can define a generic function that curries any
//: function expecting a tuple of two arguments, thereby producing the
//: corresponding curried version:
//: 

func curry<A, B, C>(f: (A, B) -> C) -> A -> B -> C {
    return { x in { y in f(x, y) } }
}

//: 
//: We no longer need to define two different versions of the same function,
//: the curried and the uncurried, as we did in the last chapter. Instead,
//: generic functions such as `curry` can be used to transform *functions* —
//: computing the curried version from the uncurried. Once again, the type
//: of this function is so generic that it (almost) gives a complete
//: specification: there really is only one sensible implementation.
//: 
//: Using generics allows you to write flexible functions without
//: compromising type safety; if you use the `Any` type, you're pretty much
//: on your own.
//: 
//: Notes
//: -----
//: 
//: The history of generics traces back to @strachey, Girard's *System F*
//: [-@girard], and @reynolds:polymorphism. Note that these authors refer to
//: generics as (parametric) polymorphism, a term that is still used in many
//: other functional languages. Many object-oriented languages use the term
//: polymorphism to refer to implicit casts arising from subtyping, so the
//: term generics was introduced to disambiguate between the two concepts.
//: 
//: The process that we sketched informally above, motivating why there can
//: only be one possible function with the generic type
//: 
//:
//:    (f: A -> B, g: B -> C) -> A -> C
//:
//: 
//: can be made mathematically precise. This was first done by
//: @reynolds:parametricity; later @wadler referred to this as *Theorems for
//: free!* — emphasizing how you can compute a theorem about a generic
//: function from its type.
//: 
