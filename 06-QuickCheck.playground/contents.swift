

// You might want to turn this down to a really low number when running this in a playground.
let numberOfIterations = 10

import Foundation

func iterateWhile<A>(condition: A -> Bool, 
                     initialValue: A, 
                     next: A -> A?) -> A {
                     
    if let x = next(initialValue) where condition(x) {
        return iterateWhile(condition, x, next)
    }
    return initialValue
}

protocol Smaller {
    func smaller() -> Self?
}

protocol Arbitrary: Smaller {
    static func arbitrary() -> Self
}

struct ArbitraryI<T> {
    let arbitrary: () -> T
    let smaller: T -> T?
}

func checkHelper<A>(arbitraryInstance: ArbitraryI<A>, 
                    prop: A -> Bool, message: String) -> () {
                    
    for _ in 0..<numberOfIterations {
        let value = arbitraryInstance.arbitrary()
        if !prop(value) {
            let smallerValue = iterateWhile({ !prop($0) }, 
                    value, arbitraryInstance.smaller)
            println("\"\(message)\" doesn't hold: \(smallerValue)")
            return
        }
    }
    println("\"\(message)\" passed \(numberOfIterations) tests.")
}

func check<X: Arbitrary>(message: String, prop: X -> Bool) -> () {
    let instance = ArbitraryI(arbitrary: { X.arbitrary() }, smaller: { $0.smaller() })
    checkHelper(instance, prop, message)
}

func check<X: Arbitrary, Y: Arbitrary>(message: String, prop: (X, Y) -> Bool) -> () {
    let arbitraryTuple = { (X.arbitrary(), Y.arbitrary()) }
    let smaller: (X, Y) -> (X, Y)? = { (x, y) in
        if let newX = x.smaller() {
            if let newY = y.smaller() {
                return (newX, newY)
            }
        }
        return nil
    }
    
    let instance = ArbitraryI(arbitrary: arbitraryTuple, smaller: smaller)
    checkHelper(instance, prop, message)
}

extension Int: Smaller {
    func smaller() -> Int? {
        return self == 0 ? nil : self / 2
    }
}
extension Int: Arbitrary {
    static func arbitrary() -> Int {
        return Int(arc4random())
    }
} 
extension String: Smaller {
    func smaller() -> String? {
        return isEmpty ? nil : dropFirst(self)
    }
}



extension CGSize: Arbitrary {
    func smaller() -> CGSize? {
        return nil
    }
    
    static func arbitrary() -> CGSize {
        return CGSizeMake(CGFloat.arbitrary(), CGFloat.arbitrary())
    }
}

extension CGFloat: Arbitrary {
    func smaller() -> CGFloat? {
        return nil
    }
    
    static func arbitrary() -> CGFloat {
        let random: CGFloat = CGFloat(arc4random())
        let maxUint = CGFloat(UInt32.max)
        return 10000 * ((random - maxUint/2) / maxUint)
    }
}

//: 
//: QuickCheck
//: ==========
//: 
//: In recent years, testing has become much more prevalent in Objective-C.
//: Many popular libraries are now tested automatically with continuous
//: integration tools. The standard framework for writing unit tests is
//: [XCTest](http://objc.io/fpinswift/11). Additionally, a lot of
//: third-party frameworks (such as Specta, Kiwi, and FBSnapshotTestCase)
//: are already available, and a number of new frameworks are currently
//: being developed in Swift.
//: 
//: All of these frameworks follow a similar pattern: Tests typically
//: consist of some fragment of code, together with an expected result. The
//: code is then executed, and its result is compared to the expected result
//: mentioned in the test. Different libraries test at different levels —
//: some test individual methods, some test classes, and some perform
//: integration testing (running the entire app). In this chapter, we will
//: build a small library for property-based testing of Swift functions. We
//: will build this library in an iterative fashion, improving it step by
//: step.
//: 
//: When writing unit tests, the input data is static and defined by the
//: programmer. For example, when unit testing an addition method, we might
//: write a test that verifies that `1 + 1` is equal to `2`. If the
//: implementation of addition changes in such a way that this property is
//: broken, the test will fail. More generally, however, we could choose to
//: test that the addition is commutative — in other words, that `a + b` is
//: equal to `b + a`. To test this, we could write a test case that verifies
//: that `42 + 7` is equal to `7 + 42`.
//: 
//: QuickCheck [@claessen:quickcheck] is a Haskell library for random
//: testing. Instead of writing individual unit tests, each of which tests
//: that a function is correct for some particular input, QuickCheck allows
//: you to describe abstract *properties* of your functions and *generate*
//: tests to verify these properties. When a property passes, it doesn't
//: necessarily prove that the property is correct. Rather, QuickCheck aims
//: to find boundary conditions that invalidate the property. In this
//: chapter, we'll build a (partial) Swift port of QuickCheck.
//: 
//: This is best illustrated with an example. Suppose we want to verify that
//: addition is a commutative operation. To do so, we start by writing a
//: function that checks whether `x + y` is equal to `y + x` for the two
//: integers `x` and `y`:
//: 

func plusIsCommutative(x: Int, y: Int) -> Bool {
    return x + y == y + x
}

//: 
//: Checking this statement with QuickCheck is as simple as calling the
//: `check` function:
//: 
check("Plus should be commutative", plusIsCommutative)
//: 
//: The `check` function works by calling the `plusIsCommutative` function
//: with two random integers, over and over again. If the statement isn't
//: true, it will print out the input that caused the test to fail. The key
//: insight here is that we can describe abstract *properties* of our code
//: (like commutativity) using *functions* that return a `Bool` (like
//: `plusIsCommutative`). The `check` function now uses this property to
//: *generate* unit tests, giving much better code coverage than you could
//: achieve using handwritten unit tests.
//: 
//: Of course, not all tests pass. For example, we can define a statement
//: that describes that subtraction is commutative:
//: 

func minusIsCommutative(x: Int, y: Int) -> Bool {
    return x - y == y - x
}

//: 
//: Now, if we run QuickCheck on this function, we will get a failing test
//: case:
//: 
check("Minus should be commutative", minusIsCommutative)
//: 
//: Using Swift's syntax for [trailing
//: closures](http://objc.io/fpinswift/12), we can also write tests
//: directly, without defining the property (such as `plusIsCommutative` or
//: `minusIsCommutative`) separately:
//: 
check("Additive identity") { (x: Int) in x + 0 == x }
//: 
//: Of course, there are many other similar properties of standard
//: arithmetic that we can test. We will cover more interesting tests and
//: properties shortly. Before we do so, however, we will give some more
//: details about how QuickCheck is implemented.
//: 
//: Building QuickCheck
//: -------------------
//: 
//: In order to build our Swift implementation of QuickCheck, we will need
//: to do a couple of things.
//: 
//: -   First, we need a way to generate random values for different types.
//: -   Using these random value generators, we need to implement the
//:     `check` function, which passes random values to its argument
//:     property.
//: -   If a test fails, we would like to make the test input as small as
//:     possible. For example, if our test fails on an array with 100
//:     elements, we'll try to make it smaller and see if the test still
//:     fails.
//: -   Finally, we'll need to do some extra work to make sure our check
//:     function works on types that have generics.
//: 
//: ### Generating Random Values
//: 
//: First, let's define a [protocol](http://objc.io/fpinswift/13) that knows
//: how to generate arbitrary values. This protocol contains only one
//: function, `arbitrary`, which returns a value of type `Self`, i.e. an
//: instance of the class or struct that implements the `Arbitrary`
//: protocol:
//: 
//:
//:    protocol Arbitrary {
//:        static func arbitrary() -> Self
//:    }
//:
//: 
//: So let's write an instance for `Int`. We use the `arc4random` function
//: from the standard library and convert it into an `Int`. Note that this
//: only generates positive integers. A real implementation of the library
//: would generate negative integers as well, but we'll try to keep things
//: simple in this chapter:
//: 
//:
//:    extension Int: Arbitrary {
//:        static func arbitrary() -> Int {
//:            return Int(arc4random())
//:        }
//:    } 
//:
//: 
//: Now we can generate random integers, like this:
//: 
Int.arbitrary()
//: 
//: To generate random strings, we need to do a little bit more work. We
//: start off by generating random characters:
//: 

extension Character: Arbitrary {
    static func arbitrary() -> Character {
        return Character(UnicodeScalar(random(from: 65, to: 90)))
    }

    func smaller() -> Character? { return nil }
}

//: 
//: Then, we generate a random length between 0 and 40 — `x` — using the
//: `random` function defined below. Then, we generate `x` random
//: characters, and reduce them into a string. Note that we currently only
//: generate capital letters as random characters. In a production library,
//: we should generate longer strings that contain arbitrary characters:
//: 

func tabulate<A>(times: Int, f: Int -> A) -> [A] {
    return Array(0..<times).map(f)
}

func random(#from: Int, #to: Int) -> Int {
    return from + (Int(arc4random()) % (to-from))
}

extension String: Arbitrary {
    static func arbitrary() -> String {
        let randomLength = random(from: 0, to: 40)
        let randomCharacters = tabulate(randomLength) { _ in 
            Character.arbitrary() 
        }
        return reduce(randomCharacters, "") { $0 + String($1) }
    }
}

//: 
//: We use the `tabulate` function to fill an array with the numbers from
//: `0` to `times-1`. By using the `map` function, we then generate an array
//: with the values `f(0)`, `f(1)`, ..., `f(times-1)`. The `arbitrary`
//: extension to `String` uses the `tabulate` function to populate an array
//: of random characters.
//: 
//: We can call it in the same way as we generate random `Int`s, except that
//: we call it on the `String` class:
//: 
String.arbitrary()
//: 
//: ### Implementing the `check` Function
//: 
//: Now we are ready to implement a first version of our check function. The
//: `check1` function consists of a simple loop that generates random input
//: for the argument property in every iteration. If a counterexample is
//: found, it is printed, and the function returns; if no counterexample is
//: found, the `check1` function reports the number of successful tests that
//: have passed. (Note that we called the function `check1`, because we'll
//: write the final version a bit later.)
//: 

func check1<A: Arbitrary>(message: String, prop: A -> Bool) -> () {
    for _ in 0..<numberOfIterations {
        let value = A.arbitrary()
        if !prop(value) {
            println("\"\(message)\" doesn't hold: \(value)")
            return
        }
    }
    println("\"\(message)\" passed \(numberOfIterations) tests.")
}

//: 
//: We could have chosen to use a more functional style by writing this
//: function using `reduce` or `map`, rather than a `for` loop. In this
//: example, however, `for` loops make perfect sense: we want to iterate an
//: operation a fixed number of times, stopping execution once a
//: counterexample has been found — and `for` loops are perfect for that.
//: 
//: Here's how we can use this function to test properties:
//: 

func area(size: CGSize) -> CGFloat {
    return size.width * size.height
}


check1("Area should be at least 0") { size in area(size) >= 0 }
//: 
//: Here we can see a good example of when QuickCheck can be very useful: it
//: finds an edge case for us. If a size has exactly one negative component,
//: our `area` function will return a negative number. When used as part of
//: a `CGRect`, a `CGSize` can have negative values. When writing ordinary
//: unit tests, it is easy to oversee this case, because sizes usually only
//: have positive components. (The `CGSize` instances are omitted in this
//: chapter, but can be found in the appendix
//: 
//: Making Values Smaller
//: ---------------------
//: 
//: If we run our `check1` function on strings, we might receive a rather
//: long failure message:
//: 
check1("Every string starts with Hello") { (s: String) in 
    s.hasPrefix("Hello")
}
//: 
//: Ideally, we'd like our failing input to be a short as possible. In
//: general, the smaller the counterexample, the easier it is to spot which
//: piece of code is causing the failure. In this example, the
//: counterexample is still pretty easy to understand — but this may not
//: always be the case. Imagine a complicated condition on arrays or
//: dictionaries that fails for some unclear reason — diagnosing why a test
//: is failing is much easier with a minimal counterexample. In principle,
//: the user could try to trim the input that triggered the failure and
//: attempt rerunning the test — rather than place the burden on the user —
//: however, we will automate this process.
//: 
//: To do so, we will make an extra protocol called `Smaller`, which does
//: only one thing — it tries to shrink the counterexample:
//: 
//:
//:    protocol Smaller {
//:        func smaller() -> Self?
//:    }
//:
//: 
//: Note that the return type of the `smaller` function is marked as
//: optional. There are cases when it is not clear how to shrink test data
//: any further. For example, there is no obvious way to shrink an empty
//: array. We will return `nil` in that case.
//: 
//: In our instance, for integers, we just try to divide the integer by two
//: until we reach zero:
//: 
//:
//:    extension Int: Smaller {
//:        func smaller() -> Int? {
//:            return self == 0 ? nil : self / 2
//:        }
//:    }
//:
//: 
//: We can now test our instance:
//: 
100.smaller()
//: 
//: For strings, we just drop the first character (unless the string is
//: empty):
//: 
//:
//:    extension String: Smaller {
//:        func smaller() -> String? {
//:            return isEmpty ? nil : dropFirst(self)
//:        }
//:    }
//:
//: 
//: To use the `Smaller` protocol in the `check` function, we will need the
//: ability to shrink any test data generated by our `check` function. To do
//: so, we will redefine our `Arbitrary` protocol to extend the `Smaller`
//: protocol:
//: 
//:
//:    protocol Arbitrary: Smaller {
//:        static func arbitrary() -> Self
//:    }
//:
//: 
//: ### Repeatedly Shrinking
//: 
//: We can now redefine our `check` function to shrink any test data that
//: triggers a failure. To do this, we use the `iterateWhile` function,
//: which takes a condition and an initial value, and repeatedly applies a
//: function as long as the condition holds:
//: 
//:
//:    func iterateWhile<A>(condition: A -> Bool, 
//:                         initialValue: A, 
//:                         next: A -> A?) -> A {
//:                         
//:        if let x = next(initialValue) where condition(x) {
//:            return iterateWhile(condition, x, next)
//:        }
//:        return initialValue
//:    }
//:
//: 
//: Using `iterateWhile`, we can now repeatedly shrink counterexamples that
//: we uncover during testing:
//: 

func check2<A: Arbitrary>(message: String, prop: A -> Bool) -> () {
    for _ in 0..<numberOfIterations {
        let value = A.arbitrary()
        if !prop(value) {
            let smallerValue = iterateWhile({ !prop($0) }, value) { 
                $0.smaller() 
            }
            println("\"\(message)\" doesn't hold: \(smallerValue)")
            return
        }
    }
    println("\"\(message)\" passed \(numberOfIterations) tests.")
}

//: 
//: This function is doing quite a bit: generating random input values,
//: checking whether they satisfy the `property` argument, and repeatedly
//: shrinking a counterexample, once one is found. One advantage of defining
//: the repeated shrinking using `iterateWhile`, rather than a separate
//: while loop, is that the control flow of this piece of code stays
//: reasonably simple.
//: 
//: Arbitrary Arrays
//: ----------------
//: 
//: Currently, our `check2` function only supports `Int` and `String`
//: values. While we are free to define new extensions for other types, such
//: as `Bool`, things get more complicated when we want to generate
//: arbitrary arrays. As a motivating example, let's write a functional
//: version of QuickSort:
//: 

func qsort(var array: [Int]) -> [Int] {
    if array.isEmpty { return [] }
    let pivot = array.removeAtIndex(0)
    let lesser = array.filter { $0 < pivot }
    let greater = array.filter { $0 >= pivot }
    return qsort(lesser) + [pivot] + qsort(greater)
}

//: 
//: We can also try to write a property to check our version of QuickSort
//: against the built-in `sort` function:
//: 
//:
//:    check2("qsort should behave like sort") { (x: [Int]) in 
//:        return qsort(x) == x.sorted(<) 
//:    }
//:
//: 
//: However, the compiler warns us that `[Int]` doesn't conform to the
//: `Arbitrary` protocol. Before we can implement `Arbitrary`, we first have
//: to implement `Smaller`. As a first step, we provide a simple definition
//: that drops the first element in the array:
//: 

extension Array: Smaller {
    func smaller() -> [T]? {
        if !isEmpty {
            return Array(dropFirst(self))
        }
        return nil
    }
}

//: 
//: We can also write a function that generates an array of arbitrary length
//: for any type that conforms to the `Arbitrary` protocol:
//: 

func arbitraryArray<X: Arbitrary>() -> [X] {
    let randomLength = Int(arc4random() % 50)
    return tabulate(randomLength) { _ in return X.arbitrary() }
}

//: 
//: Now what we'd like to do is define an extension that uses the
//: `arbitraryArray` function to give the desired `Arbitrary` instance for
//: arrays. However, to define an instance for `Array`, we also need to make
//: sure that the element type of the array is also an instance of
//: `Arbitrary`. For example, in order to generate an array of random
//: numbers, we first need to make sure that we can generate random numbers.
//: Ideally, we would write something like this, saying that the elements of
//: an array should also conform to the arbitrary protocol:
//: 
//:
//:    extension Array<T: Arbitrary>: Arbitrary {
//:        static func arbitrary() -> [T] {
//:            ...
//:        }
//:    }
//:
//: 
//: Unfortunately, it is currently not possible to express this restriction
//: as a type constraint, making it impossible to write an extension that
//: makes `Array` conform to the `Arbitrary` protocol. Instead, we will
//: modify the `check2` function.
//: 
//: The problem with the `check2<A>` function was that it required the type
//: `A` to be `Arbitrary`. We will drop this requirement, and instead
//: require the necessary functions, `smaller` and `arbitrary`, to be passed
//: as arguments.
//: 
//: We start by defining an auxiliary struct that contains the two functions
//: we need:
//: 
//:
//:    struct ArbitraryI<T> {
//:        let arbitrary: () -> T
//:        let smaller: T -> T?
//:    }
//:
//: 
//: We can now write a helper function that takes an `ArbitraryI` struct as
//: an argument. The definition of `checkHelper` closely follows the
//: `check2` function we saw previously. The only difference between the two
//: is where the `arbitrary` and `smaller` functions are defined. In
//: `check2`, these were constraints on the generic type, `<A: Arbitrary>`;
//: in `checkHelper`, they are passed explicitly in the `ArbitraryI` struct:
//: 
//:
//:    func checkHelper<A>(arbitraryInstance: ArbitraryI<A>, 
//:                        prop: A -> Bool, message: String) -> () {
//:                        
//:        for _ in 0..<numberOfIterations {
//:            let value = arbitraryInstance.arbitrary()
//:            if !prop(value) {
//:                let smallerValue = iterateWhile({ !prop($0) }, 
//:                        value, arbitraryInstance.smaller)
//:                println("\"\(message)\" doesn't hold: \(smallerValue)")
//:                return
//:            }
//:        }
//:        println("\"\(message)\" passed \(numberOfIterations) tests.")
//:    }
//:
//: 
//: This is a standard technique: instead of working with functions defined
//: in a protocol, we explicitly pass the required information as an
//: argument. By doing so, we have a bit more flexibility. We no longer rely
//: on Swift to *infer* the required information, but instead have complete
//: control over this ourselves.
//: 
//: We can redefine our `check2` function to use the `checkHelper` function.
//: If we know that we have the desired `Arbitrary` definitions, we can wrap
//: them in the `ArbitraryI` struct and call `checkHelper`:
//: 
//:
//:    func check<X: Arbitrary>(message: String, 
//:                             prop: X -> Bool) -> () {
//:                             
//:        let instance = ArbitraryI(arbitrary: { X.arbitrary() }, 
//:                                  smaller: { $0.smaller() })
//:        checkHelper(instance, prop, message)
//:    }
//:
//: 
//: If we have a type for which we cannot define the desired `Arbitrary`
//: instance, as is the case with arrays, we can overload the `check`
//: function and construct the desired `ArbitraryI` struct ourselves:
//: 

func check<X: Arbitrary>(message: String, 
                         prop: [X] -> Bool) -> () {
                         
    let instance = ArbitraryI(arbitrary: arbitraryArray, 
                              smaller: { (x: [X]) in x.smaller() })
    checkHelper(instance, prop, message)
}

//: 
//: Now, we can finally run `check` to verify our QuickSort implementation.
//: Lots of random arrays will be generated and passed to our test:
//: 
check("qsort should behave like sort") { (x: [Int]) in 
    return qsort(x) == x.sorted(<) 
}
//: 
//: Using QuickCheck
//: ----------------
//: 
//: Somewhat counterintuitively, there is strong evidence to suggest that
//: testing technology influences the design of your code. People who rely
//: on *test-driven design* use tests not only to verify that their code is
//: correct. Instead, they also report that by writing your code in a
//: test-driven fashion, the design of the code gets simpler. This makes
//: sense — if it is easy to write a test for a class without having a
//: complicated setup procedure, it means that the class is nicely
//: decoupled.
//: 
//: For QuickCheck, the same rules apply. It will often not be easy to take
//: existing code and add QuickCheck tests as an afterthought, particularly
//: when you have an existing object-oriented architecture that relies
//: heavily on other classes or makes use of mutable state. However, if you
//: start by doing test-driven development using QuickCheck, you will see
//: that it strongly influences the design of your code. QuickCheck forces
//: you to think of the abstract properties that your functions must satisfy
//: and allows you to give a high-level specification. A unit test can
//: assert that `3 + 0` is equal to `0 + 3`; a QuickCheck property states
//: more generally that addition is a commutative operation. By thinking
//: about a high-level QuickCheck specification first, your code is more
//: likely to be biased toward modularity and *referential transparency*
//: (which we will cover in the next chapter.
//: QuickCheck does not work as well on stateful functions or APIs. As a
//: result, writing your tests up front with QuickCheck will help keep your
//: code clean.
//: 
//: Next Steps
//: ----------
//: 
//: This library is far from complete, but already quite useful. That said,
//: there are a couple of obvious things that could be improved upon:
//: 
//: -   The shrinking is naive. For example, in the case of arrays, we
//:     currently remove the first element of the array. However, we might
//:     also choose to remove a different element, or make the elements of
//:     the array smaller (or do all of that). The current implementation
//:     returns an optional shrunken value, whereas we might want to
//:     generate a list of values. In a [later
//:     chapter](#generators-and-sequences), we will see how to generate a
//:     lazy list of results, and we could use that same technique here.
//: -   The `Arbitrary` instances are quite simple. For different data
//:     types, we might want to have more complicated arbitrary instances.
//:     For example, when generating arbitrary enum values, we could
//:     generate certain cases with different frequencies. We could also
//:     generate constrained values, such as sorted or non-empty arrays.
//:     When writing multiple `Arbitrary` instances, it's possible to define
//:     some helper functions that aid us in writing these instances.
//: -   Classify the generated test data: if we generate a lot of arrays of
//:     length one, we could classify this as a 'trivial' test case. The
//:     Haskell library has support for classification, so these ideas could
//:     be ported directly.
//: -   We might want better control of the size of the random input that is
//:     generated. In the Haskell version of QuickCheck, the `Arbitrary`
//:     protocol takes an additional size argument, limiting the size of the
//:     random input generated; the `check` function than starts testing
//:     'small' values, which correspond to small and fast tests. As more
//:     and more tests pass, the `check` function increases the size to try
//:     and find larger, more complicated counterexamples.
//: -   We might also want to initialize the random generator with an
//:     explicit seed, and make it possible to replay the generation of test
//:     cases. This will make it easier to reproduce failing tests.
//: 
//: Obviously, that's not everything; there are many other small and large
//: things that could be improved upon to make this into a full library.
//: 
