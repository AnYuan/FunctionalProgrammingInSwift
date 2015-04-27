

import Foundation

func one<X>(x: X?) -> GeneratorOf<X> {
    return GeneratorOf(GeneratorOfOne(x))
}

func map<A, B>(var g: GeneratorOf<A>, f: A -> B) -> GeneratorOf<B> {
    return GeneratorOf {
        g.next().map(f)
    }
}

protocol Smaller {
    func smaller() -> GeneratorOf<Self>
}

extension Array {
    var decompose : (head: T, tail: [T])? {
      return (count > 0) ? (self[0], Array(self[1..<count])) : nil
    }
}

class Box<T> {
    let unbox: T
    init(_ value: T) { self.unbox = value }
}



func map<A, B>(s: SequenceOf<A>, f: A -> B) -> SequenceOf<B> {
    return SequenceOf { map(s.generate(), f) }
}

extension Int: Smaller {
    func smaller() -> GeneratorOf<Int> {
        let result: Int? = self < 0 ? nil : self.predecessor()
        return one(result)
    }
}

//: 
//: Generators and Sequences
//: ========================
//: 
//: In this chapter, we'll look at generators and sequences. These form the
//: machinery underlying Swift's for loops, and will be the basis of the
//: parsing library that we will present in the following chapters.
//: 
//: Generators
//: ----------
//: 
//: In Objective-C and Swift, we almost always use the `Array` datatype to
//: represent a list of items. It is both simple and fast. There are
//: situations, however, where arrays are not suitable. For example, you
//: might not want to calculate all the elements of an array, because there
//: is an infinite amount, or you don’t expect to use them all. In such
//: situations, you may want to use a *generator* instead.
//: 
//: We will try to provide some motivation for generators, using familiar
//: examples from array computations. Swift's for loops can be used to
//: iterate over array elements:
//: 
//:
//:    for x in xs {
//:        // do something with x
//:    }
//:
//: 
//: In such a for loop, the array is traversed from beginning to end. There
//: may be examples, however, where you want to traverse arrays in a
//: different order. This is where generators may be useful.
//: 
//: Conceptually, a generator is a 'process' that generates new array
//: elements on request. A generator is any type that adheres to the
//: following protocol:
//: 
//:
//:    protocol GeneratorType {
//:        typealias Element
//:        func next() -> Element?
//:    }
//:
//: 
//: This protocol requires an *associated type*, `Element`, defined by the
//: `GeneratorType`. There is a single method, `next`, that produces the
//: next element if it exists, and `nil` otherwise.
//: 
//: For example, the following generator produces array indices, starting
//: from the end of an array until it reaches 0:
//: 

class CountdownGenerator: GeneratorType {
    typealias Element = Int
    
    var element: Element
    
    init<T>(array: [T]) {
        self.element = array.count - 1
    }

    func next() -> Element? {
        return self.element < 0 ? nil : element--
    }
}

//: 
//: We define an initializer that is passed an array and initializes the
//: `element` to the array's last valid index.
//: 
//: We can use this `CountdownGenerator` to traverse an array backward:
//: 

let xs = ["A", "B", "C"]


let generator = CountdownGenerator(array: xs)
while let i = generator.next() {
    println("Element \(i) of the array is \(xs[i])")
}
//: 
//: Although it may seem like overkill on such simple examples, the
//: generator encapsulates the computation of array indices. If we want to
//: compute the indices in a different order, we only need to update the
//: generator, and never the code that uses it.
//: 
//: Generators need not produce a `nil` value at some point. For example, we
//: can define a generator that produces an 'infinite' series of powers of
//: two (until `NSDecimalNumber` overflows, which is only with extremely
//: large values):
//: 

class PowerGenerator: GeneratorType {
    typealias Element = NSDecimalNumber
    
    var power: NSDecimalNumber = NSDecimalNumber(int: 1)
    let two = NSDecimalNumber(int: 2)
    
    func next() -> Element? {
        power = power.decimalNumberByMultiplyingBy(two)
        return power
    }
}

//: 
//: We can use the `PowerGenerator` to inspect increasingly large array
//: indices, for example, when implementing an exponential search algorithm
//: that doubles the array index in every iteration.
//: 
//: We may also want to use the `PowerGenerator` for something entirely
//: different. Suppose we want to search through the powers of two, looking
//: for some interesting value. The `findPower` function takes a `predicate`
//: of type `NSDecimalNumber -> Bool` as argument, and returns the smallest
//: power of two that satisfies this predicate:
//: 

func findPower(predicate: NSDecimalNumber -> Bool) 
              -> NSDecimalNumber {
    let g = PowerGenerator()
    while let x = g.next() {
        if predicate(x) {
            return x
        }
    }
    return 0;
}

//: 
//: We can use the `findPower` function to compute the smallest power of two
//: larger than 1,000:
//: 
findPower { $0.integerValue > 1000 }
//: 
//: The generators we have seen so far all produce numerical elements, but
//: this need not be the case. We can just as well write generators that
//: produce some other value. For example, the following generator produces
//: a list of strings, corresponding to the lines of a file:
//: 

class FileLinesGenerator: GeneratorType {
    typealias Element = String
    
    var lines: [String]
    
    init(filename: String) {
        if let contents = String(contentsOfFile: filename,
                                 encoding: NSUTF8StringEncoding,
                                 error: nil) {
            let newLine = NSCharacterSet.newlineCharacterSet()
            lines = contents
                    .componentsSeparatedByCharactersInSet(newLine)
        } else {
            lines = []
        }
    }
    
    func next() -> Element? {
        if let nextLine = lines.first {
            lines.removeAtIndex(0)
            return nextLine
        } else {
            return nil
        }
    }
    
}

//: 
//: By defining generators in this fashion, we separate the *generation* of
//: data from its *usage*. The generation may involve opening a file or URL
//: and handling the errors that arise. Hiding this behind a simple
//: generator protocol helps keep the code that manipulates the generated
//: data oblivious to these issues.
//: 
//: By defining a protocol for generators, we can also write generic
//: functions that work for every generator. For instance, our previous
//: `findPower` function can be generalized as follows:
//: 

func find <G: GeneratorType>(var generator: G, 
                             predicate: G.Element -> Bool) 
                             -> G.Element? {
                               
    while let x = generator.next() {
        if predicate(x) {
            return x
        }
    }
    return nil
}

//: 
//: The `find` function is generic over any possible generator. The most
//: interesting thing about it is its type signature. The `find` function
//: takes two arguments: a generator and a predicate. The generator may be
//: modified by the find function, resulting from the calls to `next`, hence
//: we need to add the `var` attribute in the type declaration. The
//: predicate should be a function mapping generated elements to `Bool`. We
//: can refer to the generator's associated type as `G.Element`, in the type
//: signature of `find`. Finally, note that we may not succeed in finding a
//: value that satisfies the predicate. For that reason, `find` returns an
//: optional value, returning `nil` when the generator is exhausted.
//: 
//: It is also possible to combine generators on top of one another. For
//: example, you may want to limit the number of items generated, buffer the
//: generated values, or encrypt the data generated. Here is one simple
//: example of a generator transformer that produces the first `limit`
//: values from its argument generator:
//: 

class LimitGenerator<G: GeneratorType>: GeneratorType {
    typealias Element = G.Element
    var limit = 0
    var generator: G

    init(limit: Int, generator: G) {
        self.limit = limit
        self.generator = generator
    }
    
    func next() -> Element? {
        if limit >= 0 {
            limit--
            return generator.next()
        }
        else {
            return nil
        }
    }
}

//: 
//: Such a generator may be useful when populating an array of a fixed size,
//: or somehow buffering the elements generated.
//: 
//: When writing generators, it can sometimes be cumbersome to introduce new
//: classes for every generator. Swift provides a simple struct,
//: `GeneratorOf<T>`, that is generic in the element type. It can be
//: initialized with a `next` function:
//: 
//:
//:    struct GeneratorOf<T>: GeneratorType, SequenceType {
//:        init(next: () -> T?)
//:        ...
//:
//: 
//: We will provide the complete definition of `GeneratorOf` shortly. For
//: now, we'd like to point out that the `GeneratorOf` struct not only
//: implements the `GeneratorType` protocol, but it also implements the
//: `SequenceType` protocol that we will cover in the next section.
//: 
//: Using `GeneratorOf` allows for much shorter definitions of generators.
//: For example, we can rewrite our `CountdownGenerator` as follows:
//: 

func countDown(start: Int) -> GeneratorOf<Int> {
    var i = start
    return GeneratorOf {return i < 0 ? nil : i--}
}

//: 
//: We can even define functions to manipulate and combine generators in
//: terms of `GeneratorOf`. For example, we can append two generators with
//: the same underlying element type, as follows:
//: 

func +<A>(var first: GeneratorOf<A>, 
          var second: GeneratorOf<A>) -> GeneratorOf<A> {
    return GeneratorOf {
        first.next() ?? second.next()
    }
}

//: 
//: The resulting generator simply reads off new elements from its `first`
//: argument generator; once this is exhausted, it produces elements from
//: its `second` generator. Once both generators have returned `nil`, the
//: composite generator also returns `nil`.
//: 
//: Sequences
//: ---------
//: 
//: Generators form the basis of another Swift protocol, *sequences*.
//: Generators provide a 'one-shot' mechanism for repeatedly computing a
//: next element. There is no way to rewind or replay the elements
//: generated. The only thing we can do is create a fresh generator and use
//: that instead. The `SequenceType` protocol provides just the right
//: interface for doing that:
//: 
//:
//:    protocol SequenceType {
//:        typealias Generator: GeneratorType
//:        func generate() -> Generator
//:    }
//:
//: 
//: Every sequence has an associated generator type and a method to create a
//: new generator. We can then use this generator to traverse the sequence.
//: For example, we can use our `CountdownGenerator` to define a sequence
//: that generates a series of array indexes in back-to-front order:
//: 

struct ReverseSequence<T>: SequenceType {
    var array: [T]
    
    init(array: [T]) {
        self.array = array
    }
    
    typealias Generator = CountdownGenerator
    func generate() -> Generator {
        return CountdownGenerator(array: array)
    }
}

//: 
//: Every time we want to traverse the array stored in the `ReverseSequence`
//: struct, we can call the `generate` method to produce the desired
//: generator. The following example shows how to fit these pieces together:
//: 

let reverseSequence = ReverseSequence(array: xs)
let reverseGenerator = reverseSequence.generate()


while let i = reverseGenerator.next() {
    println("Index \(i) is \(xs[i])")
}
//: 
//: In contrast to the previous example that just used the generator, the
//: *same* sequence can be traversed a second time — we would simply call
//: `generate` to produce a new generator. By encapsulating the creation of
//: generators in the `SequenceType` definition, programmers using sequences
//: do not have to be concerned with the creation of the underlying
//: generators. This is in line with the object-oriented philosophy of
//: separating use and creation, which tends to result in more cohesive
//: code.
//: 
//: Swift has special syntax for working with sequences. Instead of creating
//: the generator associated with a sequence yourself, you can write a
//: for-in loop. For example, we can also write the previous code snippet
//: as:
//: 
for i in ReverseSequence(array: xs) {
    println("Index \(i) is \(xs[i])")
}
//: 
//: Under the hood, Swift then uses the `generate` method to produce a
//: generator and repeatedly call its `next` function until it produces
//: `nil`.
//: 
//: The obvious drawback of our `CountdownGenerator` is that it produces
//: numbers, while we may be interested in the *elements* associated with an
//: array. Fortunately, there are standard `map` and `filter` functions that
//: manipulate sequences rather than arrays:
//: 
//:
//:    func filter<S: SequenceType>(source: S, 
//:                        includeElement: S.Generator.Element -> Bool) 
//:                        -> [S.Generator.Element]
//:    
//:    func map<S: SequenceType, T>(source: S, 
//:                                 transform: S.Generator.Element -> T) 
//:                                 -> [T]
//:
//: 
//: To produce the *elements* of an array in reverse order, we can `map`
//: over our `ReverseSequence`:
//: 
let reverseElements = map(ReverseSequence(array: xs)) { i in xs[i] }
for x in reverseElements {
    println("Element is \(x)")
}
//: 
//: Similarly, we may of course want to filter out certain elements from a
//: sequence.
//: 
//: It is worth pointing out that these `map` and `filter` functions do
//: *not* return new sequences, but instead traverse the sequence to produce
//: an array. Mathematicians may therefore object to calling such operations
//: `map`s, as they fail to leave the underlying structure (a sequence)
//: intact. There are separate versions of `map` and `filter` that do
//: produce sequences. These are defined as extensions of the `LazySequence`
//: class. A `LazySequence` is a simple wrapper around regular sequences:
//: 
//:
//:    func lazy<S: SequenceType>(s: S) -> LazySequence<S>
//:
//: 
//: If you need to map or filter sequences that may produce either infinite
//: results, or many results that you may not be interested in, be sure to
//: use a `LazySequence` rather than a `Sequence`. Failing to do so could
//: cause your program to diverge or take much longer than you might expect.
//: 
//: Case Study: Traversing a Binary Tree
//: ------------------------------------
//: 
//: To illustrate sequences and generators, we will consider defining a
//: traversal on a binary tree. Recall our definition of binary trees from
//: Chapter 8:
//: 

enum Tree<T> {
    case Leaf
    case Node(Box<Tree<T>>, T, Box<Tree<T>>)
}

//: 
//: Before we define a generator that produces the elements of this tree, we
//: need to define an auxiliary function. In the Swift standard library,
//: there is a `GeneratorOfOne` struct that can be useful for wrapping an
//: optional value as a generator:
//: 
//:
//:    struct GeneratorOfOne<T>: GeneratorType, SequenceType {
//:        init(_ element: T?)
//:        // ...
//:    }
//:
//: 
//: Given an optional element, it generates the sequence with just that
//: element (provided it is non-nil):
//: 

let three: [Int] = Array(GeneratorOfOne(3))
let empty: [Int] = Array(GeneratorOfOne(nil))

//: 
//: For the sake of convenience, we will define our own little wrapper
//: function around `GeneratorOfOne`:
//: 
//:
//:    func one<X>(x: X?) -> GeneratorOf<X> {
//:        return GeneratorOf(GeneratorOfOne(x))
//:    }
//:
//: 
//: We can use this `one` function, together with the append operator on
//: generators, `+`, to produce sequences of elements of a binary tree. For
//: example, the `inOrder` traversal visits the left subtree, the root, and
//: the right subtree, in that order:
//: 

func inOrder<T>(tree: Tree<T>) -> GeneratorOf<T> {
    switch tree {
        case Tree.Leaf:
            return GeneratorOf { return nil }
        case let Tree.Node(left, x, right):
            return inOrder(left.unbox) + one(x) + inOrder(right.unbox)
    }
}

//: 
//: If the tree has no elements, we return an empty generator. If the tree
//: has a node, we combine the results of the two recursive calls, together
//: with the single value stored at the root, using the append operator on
//: generators.
//: 
//: Case Study: Better Shrinking in QuickCheck
//: ------------------------------------------
//: 
//: In this section, we will provide a somewhat larger case study of
//: defining sequences, by improving the `Smaller` protocol we implemented
//: in the QuickCheck chapter. Originally, the protocol was
//: defined as follows:
//: 
//:
//:    protocol Smaller {
//:        func smaller() -> Self?
//:    }
//:
//: 
//: We used the `Smaller` protocol to try and shrink counterexamples that
//: our testing uncovered. The `smaller` function is repeatedly called to
//: generate a smaller value; if this value still fails the test, it is
//: considered a 'better' counterexample than the original one. The
//: `Smaller` instance we defined for arrays simply tried to repeatedly
//: strip off the first element:
//: 
//:
//:    extension Array: Smaller {
//:        func smaller() -> [T]? {
//:            if (!self.isEmpty) {
//:                return Array(dropFirst(self))
//:            }
//:            return nil
//:        }
//:    }
//:
//: 
//: While this will certainly help shrink counterexamples in *some* cases,
//: there are many different ways to shrink an array. Computing all possible
//: subarrays is an expensive operation. For an array of length `n`, there
//: are `2^n` possible subarrays that may or may not be interesting
//: counterexamples — generating and testing them is not a good idea.
//: 
//: Instead, we will show how to use a generator to produce a series of
//: smaller values. We can then adapt our QuickCheck library to use the
//: following protocol:
//: 
//:
//:    protocol Smaller {
//:        func smaller() -> GeneratorOf<Self>
//:    }
//:
//: 
//: When QuickCheck finds a counterexample, we can then rerun our tests on
//: the series of smaller values until we have found a suitably small
//: counterexample. The only thing we still have to do is write a `smaller`
//: function for arrays (and any other type that we might want to shrink).
//: 
//: As a first step, instead of removing just the first element of the
//: array, we will compute a series of arrays, where each new array has one
//: element removed. This will not produce all possible sublists, but only a
//: sequence of arrays in which each array is one element shorter than the
//: original array. Using `GeneratorOf`, we can define such a function as
//: follows:
//: 

func removeElement<T>(var array: [T]) -> GeneratorOf<[T]> {
    var i = 0
    return GeneratorOf {
        if i < array.count {
            var result = array
            result.removeAtIndex(i)
            i++
            return result
        }
        return nil
    }
}

//: 
//: The `removeElement` function keeps track of a variable `i`. When asked
//: for the next element, it checks whether or not `i` is less than the
//: length of the array. If so, it computes a new array, `result`, and
//: increments `i`. If we have reached the end of our original array, we
//: return `nil`.
//: 
//: We can now see that this returns all possible arrays that are one
//: element smaller:
//: 
//:
//:    removeElement([1, 2, 3])
//:
//: 
//: Unfortunately, this call does not produce the desired result — it
//: defines a `GeneratorOf<[Int]>`, whereas we would like to see an array of
//: arrays. Fortunately, there is an `Array` initializer that takes a
//: `Sequence` as argument. Using that initializer, we can test our
//: generator as follows:
//: 
Array(removeElement([1, 2, 3]))
//: 
//: Using the `decompose` function, we can redefine the `smaller` function
//: on arrays. If we try to formulate a recursive pseudocode definition of
//: what our original `removeElement` function computed, we might arrive at
//: something along the following lines:
//: 
//: -   If the array is empty, return nil
//: -   If the array can be split into a head and tail, we can recursively
//:     compute the remaining subarrays as follows:
//:     -   tail of the array is a subarray
//:     -   if we prepend `head` to all the subarrays of the tail, we can
//:         compute the subarrays of the original array
//: 
//: We can translate this algorithm directly into Swift with the functions
//: we have defined:
//: 

func smaller1<T>(array: [T]) -> GeneratorOf<[T]> {
    if let (head, tail) = array.decompose {
        let gen1: GeneratorOf<[T]> = one(tail)
        let gen2: GeneratorOf<[T]> = map(smaller1(tail)) { 
            smallerTail in 
            [head] + smallerTail 
        }
        return gen1 + gen2
    } else {
        return one(nil)
    }
}

//: 
//: We're now ready to test our functional variant, and we can verify that
//: it's the same result as `removeElement`:
//: 
Array(smaller1([1, 2, 3]))
//: 
//: Here, there is one thing we should point out. In this definition of
//: `smaller`, we are using our own version of `map`:
//: 
//:
//:    func map<A, B>(var g: GeneratorOf<A>, f: A -> B) -> GeneratorOf<B> {
//:        return GeneratorOf {
//:            g.next().map(f)
//:        }
//:    }
//:
//: 
//: You may recall that the `map` and `filter` methods from the standard
//: library return a `LazySequence`. To avoid the overhead of wrapping and
//: unwrapping these lazy sequences, we have chosen to manipulate the
//: `GeneratorOf` directly.
//: 
//: There is one last improvement worth making: there is one more way to try
//: and reduce the counterexamples that QuickCheck finds. Instead of just
//: removing elements, we may also want to try and shrink the elements
//: themselves. To do that, we need to add a condition that `T` conforms to
//: the smaller protocol:
//: 

func smaller<T: Smaller>(ls: [T]) -> GeneratorOf<[T]> {
    if let (head, tail) = ls.decompose {
        let gen1: GeneratorOf<[T]> = one(tail)
        let gen2: GeneratorOf<[T]> = map(smaller(tail), { xs in 
            [head] + xs
        })
        let gen3: GeneratorOf<[T]> = map(head.smaller(), { x in 
            [x] + tail
        })
        return gen1 + gen2 + gen3
    } else {
        return one(nil)
    }
}

//: 
//: We can check the results of our new `smaller` function:
//: 
Array(smaller([1, 2, 3]))
//: 
//: In addition to generating sublists, this new version of the `smaller`
//: function also produces arrays, where the values of the elements are
//: smaller.
//: 
//: Beyond Map and Filter
//: ---------------------
//: 
//: In the coming chapter, we will need a few more operations on sequences
//: and generators. To define those operations, we need the `SequenceOf`
//: struct, defined analogously to the `GeneratorOf` we saw previously.
//: Essentially, it wraps any function that returns a generator in a
//: sequence. It is (more or less) defined as follows:
//: 
//:
//:    struct SequenceOf<T> : SequenceType {
//:        init<G : GeneratorType>(_ makeUnderlyingGenerator: () -> G)
//:    
//:        func generate() -> GeneratorOf<T>
//:    }
//:
//: 
//: We have already defined concatenation, using the `+` operator, on
//: generators. A first attempt at defining concatenation for sequences
//: might result in the following definition:
//: 
//:
//:    func +<A>(l: SequenceOf<A>, r: SequenceOf<A>) -> SequenceOf<A> {
//:      return SequenceOf(l.generate() + r.generate())
//:    }
//:
//: 
//: This definition calls the generate method of the two argument sequences,
//: concatenates these, and assigns the resulting generator to the sequence.
//: Unfortunately, it does not quite work as expected. Consider the
//: following example:
//: 
//:
//:    let s = SequenceOf([1, 2, 3]) + SequenceOf([4, 5, 6])
//:    print("First pass: ")
//:    for x in s {
//:        print(x)
//:    }
//:    println("\nSecond pass:")
//:    for x in s {
//:        print(x)
//:    }
//:
//: 
//: We construct a sequence containing the elements `[1, 2, 3, 4, 5, 6]` and
//: traverse it twice, printing the elements we encounter. Somewhat
//: surprisingly perhaps, this code produces the following output:
//: 
//:     First pass: 123456
//:     Second pass:
//: 
//: The second for loop is not producing any output — what went wrong? The
//: problem is in the definition of concatenation on sequences. We assemble
//: the desired generator, `l.generate() + r.generate()`. This generator
//: produces all the desired elements in the first loop in the example
//: above. Once it has been exhausted, however, traversing the compound
//: sequence a second time will not produce a fresh generator, but instead
//: use the generator that has already been exhausted.
//: 
//: Fortunately, this problem is easy to fix. We need to ensure that the
//: result of our concatenation operation can produce new generators. To do
//: so, we pass a *function* that produces generators, rather than passing a
//: fixed generator to the `SequenceOf` initializer:
//: 

func +<A>(l: SequenceOf<A>, r: SequenceOf<A>) -> SequenceOf<A> {
  return SequenceOf { l.generate() + r.generate() }
}

//: 
//: Now, we can iterate over the same sequence multiple times. When writing
//: your own methods that combine sequences, it is important to ensure that
//: every call to `generate()` produces a fresh generator that is oblivious
//: to any previous traversals.
//: 
//: Thus far, we can concatenate two sequences. What about flattening a
//: sequence of sequences? Before we deal with sequences, let's try writing
//: a `join` operation that, given a `GeneratorOf<GeneratorOf<A>>`, produces
//: a `GeneratorOf<A>`:
//: 

struct JoinedGenerator<A>: GeneratorType {
    typealias Element = A 
    
    var generator: GeneratorOf<GeneratorOf<A>>
    var current: GeneratorOf<A>?
    
    init(_ g: GeneratorOf<GeneratorOf<A>>) {
        generator = g
        current = generator.next()
    }
    
    mutating func next() -> A? {
        if var c = current {
            if let x = c.next() {
                return x
            } else {
                current = generator.next()
                return next()
            }
        }
        return nil
    }
}

//: 
//: This `JoinedGenerator` maintains two pieces of mutable state: an
//: optional `current` generator, and the remaining `generators`. When asked
//: to produce the next element, it calls the `next` function on the current
//: generator, if it exists. When this fails, it updates the `current`
//: generator and *recursively* calls `next` again. Only when all the
//: generators have been exhausted does the `next` function return `nil`.
//: 
//: Next, we use this `JoinedGenerator` to join a sequence of sequences:
//: 

func join<A>(s: SequenceOf<SequenceOf<A>>) -> SequenceOf<A> {
    return SequenceOf { 
        JoinedGenerator(map(s.generate()) { g in 
            g.generate()
        }) 
    }
}

//: 
//: The argument of `JoinedGenerator` may look complicated, but it does very
//: little. When struggling to understand an expression like this, following
//: the types is usually a good way to learn what it does. We need to
//: provide an argument closure producing a value of type
//: `GeneratorOf<GeneratorOf<A>>`; calling `s.generate()` gets us part of
//: the way there, producing a value of type `GeneratorOf<SequenceOf<A>>`.
//: The only thing we need to do is call `generate` on all the sequences
//: inside the resulting generators, which is precisely what the call to
//: `map` accomplishes.
//: 
//: Finally, we can also combine `join` and `map` to write the following
//: `flatMap` function:
//: 

func flatMap<A, B>(xs: SequenceOf<A>, 
                   f: A -> SequenceOf<B>) -> SequenceOf<B> {
                   
    return join(map(xs, f))
}

//: 
//: Given a sequence of `A` elements, and a function `f` that, given a
//: single value of type `A`, produces a new sequence of `B` elements, we
//: can build a single sequence of `B` elements. To do so, we simply map `f`
//: over the argument sequence, constructing a `SequenceOf<SequenceOf<B>>`,
//: which we `join` to obtain the desired `SequenceOf<B>`.
//: 
//: Now that we've got a good grip on sequences and the operations they
//: support, we can start to write our parser combinator library.
//: 
