//: Functors, Applicative Functors, and Monads
//: ==========================================
//: 
//: In this chapter, we will explain some terminology and common patterns
//: used in functional programming, including functors, applicative
//: functors, and monads. Understanding these common patterns will help you
//: design your own data types and choose the correct functions to provide
//: in your APIs.
//: 
//: Functors
//: --------
//: 
//: Thus far, we have seen two different functions named `map` with the
//: following types:
//: 
//:
//:    func map<T, U>(xs: [T], transform: T -> U) -> [U]
//:    
//:    func map<T, U>(optional: T?, transform: T -> U) -> U?
//:
//: 
//: Why have two such different functions with the same name? To answer that
//: question, let's investigate how these functions are related. To begin
//: with, it helps to expand some of the shorthand notation that Swift uses.
//: Optional types, such as `Int?`, can also be written out explicitly as
//: `Optional<Int>`, in the same way that we can write `Array<T>` rather
//: than `[T]`. If we now state the types of the `map` function on arrays
//: and optionals, the similarity becomes more apparent:
//: 
//:
//:    func mapOptional<T, U>(maybeX: Optional<T>, 
//:                           transform: T -> U) -> Optional<U>
//:    
//:    func mapArray<T, U>(xs: Array<T>, transform: T -> U) -> Array<U>
//:
//: 
//: Both `Optional` and `Array` are *type constructors* that expect a
//: generic type argument. For instance, `Array<T>` and `Optional<Int>` are
//: valid types, but `Array` by itself is not. Both of these `map` functions
//: take two arguments: the structure being mapped, and a function
//: `transform` of type `T -> U`. The `map` functions use a function
//: argument to transform all the values of type `T` to values of type `U`
//: in the argument array or optional. Type constructors — such as optionals
//: or arrays — that support a `map` operation are sometimes referred to as
//: *functors*.
//: 
//: In fact, there are many other types that we have defined that are indeed
//: functors. For example, we can implement a `map` function on the `Box`
//: and `Result` types from Chapter 8:
//: 
//:
//:    func map<T, U>(box: Box<T>, transform: T -> U) -> Box<U> {
//:        return Box(transform(box.unbox))
//:    }
//:    
//:    func map<T, U> (result: Result<T>, transform: T -> U) -> Result<U> {
//:        switch result {
//:            case let Result.Success(box):
//:                return Result.Success(map(box, transform))
//:            case let Result.Failure(error):
//:                return Result.Failure(error)
//:        }
//:    }
//:
//: 
//: Similarly, the types we have seen for binary search trees, tries, and
//: parser combinators are all functors. Functors are sometimes described as
//: 'containers' storing values of some type. The `map` functions transform
//: the stored values stored in a container. This can be a useful intuition,
//: but it can be too restrictive. Remember the `Region` type that we saw in
//: Chapter 2?
//: 
//:
//:    typealias Region = Position -> Bool
//:


import Foundation
typealias Position = CGPoint

infix operator <*> { associativity left precedence 150 }

func curry<A, B, C>(f: (A, B) -> C) -> A -> B -> C {
    return { x in { y in f(x, y) } }
}

func flatten<T>(xss: [[T]]) -> [T] {
    return xss.reduce([]) { result, xs in result + xs }
}

//: 
//: Using this definition of regions, we can only generate black and white
//: bitmaps. We can generalize this to abstract over the kind of information
//: we associate with every position:
//: 

struct Region<T> {
    let value : Position -> T
}

//: 
//: Note that we need to introduce a struct here, as we cannot define
//: generic type aliases in Swift. Using this definition, we can associate
//: booleans, RGB values, or any other information with every position. We
//: can also define a `map` function on these generic regions. Essentially,
//: this definition boils down to function composition:
//: 

func map<T, U>(region: Region<T>, transform: T -> U) -> Region<U> {
    return Region { pos in transform(region.value(pos)) }
}

//: 
//: Such regions are a good example of a functor that does not fit well with
//: the intuition of functors being containers. Here, we have represented
//: regions as *functions*, which seem very different from containers.
//: 
//: Almost every generic enumeration that you can define in Swift will be a
//: functor. Providing a `map` function gives fellow developers a powerful,
//: yet familiar, function for working with such enumerations.
//: 
//: Applicative Functors
//: --------------------
//: 
//: Many functors also support other operations aside from `map`. For
//: example, the parsers from Chapter 12 were not
//: only functors, but also defined the following two operations:
//: 
//:
//:    func pure<Token, A>(value: A) -> Parser<Token, A>
//:    
//:    func <*><Token, A, B>(l: Parser<Token, A -> B>,
//:                          r: Parser<Token, A>) -> Parser<Token, B>
//:
//: 
//: The `pure` function explains how to turn any value into a (trivial)
//: parser that returns that value. Meanwhile, the `<*>` operator sequences
//: two parsers: the first parser returns a function, and the second parser
//: returns an argument for this function. The choice for these two
//: operations is no coincidence. Any type constructor for which we can
//: define appropriate `pure` and `<*>` operations is called an *applicative
//: functor*. To be more precise, a functor `F` is applicative when it
//: supports the following operations:
//: 
//:
//:    func pure<A>(value: A) -> F<A>
//:    
//:    func <*><A,B>(f: F<A -> B>, x: F<A>) -> F<B>
//:
//: 
//: Applicative functors have been lurking in the background throughout this
//: book. For example, the `Region` struct defined above is also an
//: applicative functor:
//: 

func pure<A>(value: A) -> Region<A> {
    return Region { pos in value }
}

func <*><A,B>(regionF: Region<A -> B>, 
              regionX: Region<A>) -> Region<B> {
              
    return Region { pos in regionF.value(pos)(regionX.value(pos)) }
}

//: 
//: Now the `pure` function always returns a constant value for every
//: region. The `<*>` operator distributes the position to both its region
//: arguments, which yields a function of type `A -> B`, and a value of type
//: `A`. It then combines these in the obvious manner, by applying the
//: resulting function to the argument.
//: 
//: Many of the functions defined on regions can be described succinctly
//: using these two basic building blocks. Here are a few example functions
//: — inspired by Chapter 2 — written in
//: applicative style:
//: 

func everywhere() -> Region<Bool> {
    return pure(true)
}

func invert(region: Region<Bool>) -> Region<Bool> {
    return pure(!) <*> region
}

func intersection(region1: Region<Bool>, 
                  region2: Region<Bool>) -> Region<Bool> {
                  
    return pure(curry{ x, y in x && y }) <*> region1 <*> region2
}

//: 
//: This shows how the applicative instance for the `Region` type can be
//: used to define pointwise operations on regions.
//: 
//: Applicative functors are not limited to regions and parsers. Swift's
//: built-in optional type is another example of an applicative functor. The
//: corresponding definitions are fairly straightforward:
//: 

func pure<A>(value: A) -> A? {
    return value
}

func <*><A, B>(optionalTransform: (A -> B)?, 
               optionalValue: A?) -> B? {
               
    if let transform = optionalTransform {
        if let value = optionalValue {
            return transform(value)
        }
    }
    return nil
}

//: 
//: The `pure` function wraps a value into an optional. This is usually
//: handled implicitly by the Swift compiler, so it's not very useful to
//: define ourselves. The `<*>` operator is more interesting: given a
//: (possibly `nil`) function and a (possibly `nil`) argument, it returns
//: the result of applying the function to the argument when both exist. If
//: either argument is `nil`, the whole function returns `nil`. We can give
//: similar definitions for `pure` and `<*>` for the `Result` type from
//: Chapter 8.
//: 
//: By themselves, these definitions may not be very interesting, so let's
//: revisit some of our previous examples. You may want to recall the
//: `addOptionals` function, which tried to add two possibly `nil` integers:
//: 
//:
//:    func addOptionals(maybeX: Int?, maybeY: Int?) -> Int? {
//:        if let x = maybeX, y = maybeY {
//:            return x + y
//:        }
//:        return nil
//:    }
//:
//: 
//: Using the definitions above, we can give a short alternative definition
//: of `addOptionals` using a single `return` statement:
//: 

func addOptionals(maybeX: Int?, maybeY: Int?) -> Int? {
    return pure(curry(+)) <*> maybeX <*> maybeY
}

//: 
//: Once you understand the control flow that operators like `<*>`
//: encapsulate, it becomes much easier to assemble complex computations in
//: this fashion.
//: 
//: There is one other example from the optionals chapter that we would like
//: to revisit:
//: 
//:
//:    func populationOfCapital(country: String) -> Int? {
//:        if let capital = capitals[country],
//:               population = cities[capital] {
//:            return population * 1000
//:        }
//:        return nil
//:    }
//:
//: 
//: Here we consulted one dictionary, `capitals`, to retrieve the capital
//: city of a given country. We then consulted another dictionary, `cities`,
//: to determine each city's population. Despite the obvious similarity to
//: the previous `addOptionals` example, this function *cannot* be written
//: in applicative style. Here is what happens when we try to do so:
//: 
//:
//:    func populationOfCapital(country: String) -> Int? {
//:        return { pop in pop * 1000 } <*> capitals[country] <*> cities[...]
//:    }
//:
//: 
//: The problem is that the *result* of the first lookup, which was bound to
//: the `capital` variable in the original version, is needed in the second
//: lookup. Using only the applicative operations, we quickly get stuck:
//: there is no way for the result of one applicative computation
//: (`capitals[country]`) to influence another (the lookup in the `cities`
//: dictionary). To deal with this, we need yet another interface.
//: 
//: The M-Word
//: ----------
//: 
//: In Chapter 5, we gave the following alternative definition
//: of `populationOfCapital`:
//: 
//:
//:    func populationOfCapital2 (country : String) -> Int? {
//:        return flatMap(capitals[country]) { capital in
//:            flatMap(cities[capital]) { population in
//:               population * 1000
//:           }
//:       }
//:    }
//:
//: 
//: Here we used the built-in `flatMap` function to combine optional
//: computations. How is this different from the applicative interface? The
//: types are subtly different. In the applicative `<*>` operation, *both*
//: arguments are optionals. In the `flatMap` function, on the other hand,
//: the second argument is a *function* that returns an optional value.
//: Consequently, we can pass the result of the first dictionary lookup on
//: to the second.
//: 
//: The `flatMap` function is impossible to define in terms of the
//: applicative functions. In fact, the `flatMap` function is one of the two
//: functions supported by *monads*. More generally, a type constructor `F`
//: is a monad if it defines the following two functions:
//: 
//:
//:    func pure<A>(value: A) -> F<A>
//:    
//:    func flatMap<A, B>(x: F<A>, f: A -> F<B>) -> F<B>
//:
//: 
//: The `flatMap` function is sometimes defined as an operator, `>>=`. This
//: operator is pronounced "bind," as it binds the result of the first
//: argument to the parameter of its second argument.
//: 
//: In addition to Swift's optional type, the `Result` enumeration defined
//: in Chapter 8 is also a monad. This insight makes it
//: possible to chain together computations that may return an `NSError`.
//: For example, we could define a function that copies the contents of one
//: file to another, as follows:
//: 
//:
//:    func copyFile(sourcePath: String, targetPath: String, 
//:                  encoding: Encoding) -> Result<()> {
//:                  
//:        return flatMap(readFile(sourcePath, encoding)) { contents in
//:            writeFile(contents, targetPath, encoding)
//:        }
//:    }
//:
//: 
//: If the call to either `readFile` or `writeFile` fails, the `NSError`
//: will be logged in the result. This may not be quite as nice as Swift's
//: optional binding mechanism, but it is still pretty close.
//: 
//: There are many other applications of monads aside from handling errors.
//: For example, arrays are also a monad. In the standard library, `flatMap`
//: is already defined, but you could implement it like this:
//: 

func pure<A>(value: A) -> [A] {
    return [value]
}

func flatMap<A, B>(xs: [A], f: A -> [B]) -> [B] {
    return flatten(xs.map(f))
}

//: 
//: The `flatten` function, defined in Chapter 4,
//: flattens an array of arrays into a single array. This is similar to the
//: `flatMap` function we previously defined on sequences.
//: 
//: What have we gained from these definitions? The monad structure of
//: arrays provides a convenient way to define various combinatorial
//: functions or solve search problems. For example, suppose we need to
//: compute the *cartesian product* of two arrays, `xs` and `ys`. The
//: cartesian product consists of a new array of tuples, where the first
//: component of the tuple is drawn from `xs`, and the second component is
//: drawn from `ys`. Using a for loop directly, we might write:
//: 

func cartesianProduct1<A, B>(xs: [A], ys: [B]) -> [(A, B)] {
    var result: [(A, B)] = []
    for x in xs {
        for y in ys {
            result += [(x, y)]
        }
    }
    return result
}

//: 
//: We can now rewrite `cartesianProduct` to use `flatMap` instead of for
//: loops:
//: 

func cartesianProduct2<A, B>(xs: [A], ys: [B]) -> [(A, B)] {
    return flatMap(xs) { x in flatMap(ys) { y in [(x, y)] } }
}

//: 
//: The `flatMap` function allows us to take an element `x` from the first
//: array, `xs`; next, we take an element `y` from `ys`. For each pair of
//: `x` and `y`, we return the array `[(x, y)]`. The `flatMap` function
//: handles combining all these arrays into one large result.
//: 
//: While this example may seem a bit contrived, the `flatMap` function on
//: arrays has many important applications. Languages like Haskell and
//: Python support special syntactic sugar for defining lists, called *list
//: comprehensions*. These list comprehensions allow you to draw elements
//: from existing lists and check that these elements satisfy certain
//: properties. They can all be desugared into a combination of maps,
//: filters, and `flatMap`. List comprehensions are very similar to optional
//: binding in Swift, except that they work on lists instead of optionals.
//: 
//: Discussion
//: ----------
//: 
//: Why care about these things? Does it really matter if you know that some
//: type is an applicative functor or a monad? We think it does.
//: 
//: Consider the parser combinators from Chapter 12.
//: Defining the correct way to sequence two parsers is not easy: it
//: requires a bit of insight into how parsers work. Yet it is an absolutely
//: essential piece of our library, without which we could not even write
//: the simplest parsers. If you have the insight that our parsers form an
//: applicative functor, you may realize that the existing `<*>` provides
//: you with exactly the right notion of sequencing two parsers, one after
//: the other. Knowing what abstract operations your types support can help
//: you find such complex definitions.
//: 
//: Abstract notions, like functors, provide important vocabulary. If you
//: ever encounter a function named `map`, you can probably make a pretty
//: good guess as to what it does. Without a precise terminology for common
//: structures like functors, you would have to rediscover each new `map`
//: function from scratch.
//: 
//: These structures give guidance when designing your own API. If you
//: define a generic enumeration or struct, chances are that it supports a
//: `map` operation. Is this something that you want to expose to your
//: users? Is your data structure also an applicative functor? Is it a
//: monad? What do the operations do? Once you familiarize yourself with
//: these abstract structures, you see them pop up again and again.
//: 
//: Although it is harder in Swift than in Haskell, you can define generic
//: functions that work on any applicative functor. Functions such as the
//: `</>` operator on parsers were defined exclusively in terms of the
//: applicative `pure` and `<*>` functions. As a result, we may want to
//: redefine them for *other* applicative functors aside from parsers. In
//: this way, we recognize common patterns in how we program using these
//: abstract structures; these patterns may themselves be useful in a wide
//: variety of settings.
//: 
//: The historical development of monads in the context of functional
//: programming is interesting. Initially, monads were developed in a branch
//: of Mathematics known as *category theory*. The discovery of their
//: relevance to Computer Science is generally attributed to @moggi and
//: later popularized by Wadler [-@wadler-monads-1; -@wadler-monads-2].
//: Since then, they have been used by functional languages such as Haskell
//: to contain side effects and I/O [@spj]. Applicative functors were first
//: described by McBride and Paterson [-@mcbride-paterson], although there
//: were many examples already known. A complete overview of the relation
//: between many of the abstract concepts described in this chapter can be
//: found in the Typeclassopedia [@yorgey-typeclassopedia].
//: 
