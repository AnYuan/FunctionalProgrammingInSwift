//: Enumerations
//: ============
//: 

import Foundation

//: 
//: Throughout this book, we want to emphasize the important role *types*
//: play in the design and implementation of Swift applications. In this
//: chapter, we will describe Swift's *enumerations*, which enable you to
//: craft precise types representing the data your application uses.
//: 
//: Introducing Enumerations
//: ------------------------
//: 
//: When creating a string, it is important to know its character encoding.
//: In Objective-C, an `NSString` object can have several possible
//: encodings:
//: 
//:
//:    enum NSStringEncoding {
//:        NSASCIIStringEncoding = 1,
//:        NSNEXTSTEPStringEncoding = 2,
//:        NSJapaneseEUCStringEncoding = 3,
//:        NSUTF8StringEncoding = 4,
//:        // ...
//:    }
//:
//: 
//: Each of these encodings is represented by a number; the `enum` allows
//: programmers to assign meaningful names to the integer constants
//: associated with particular character encoding.
//: 
//: There are some drawbacks to the enumeration declarations in Objective-C
//: and other C dialects. Most notably, the type *NSStringEncoding* is not
//: precise enough — there are integer values, such as 16, that do not
//: correspond to a valid encoding. Furthermore, because all enumerated
//: types are represented by integers, we can compute with them *as if they
//: are numbers*, which is also a disadvantage:
//: 
//:     NSAssert(NSASCIIStringEncoding + NSNEXTSTEPStringEncoding
//:              == NSJapaneseEUCStringEncoding, @"Adds up...");
//: 
//: Who would have thought that
//: 
//:     NSASCIIStringEncoding + NSNEXTSTEPStringEncoding
//: 
//: is equal to `NSJapaneseEUCStringEncoding`? Such expressions are clearly
//: nonsense, yet they are happily accepted by the Objective-C compiler.
//: 
//: Throughout the examples we have seen so far, we have used Swift's *type
//: system* to catch such errors. Simply identifying enumerated types with
//: integers is at odds with the one of core tenets of functional
//: programming in Swift: using types effectively to rule out invalid
//: programs.
//: 
//: Swift also has an `enum` construct, but it behaves very differently from
//: the one you may be familiar with from Objective-C. We can declare our
//: own enumerated type for string encodings as follows:
//: 

enum Encoding {
    case ASCII
    case NEXTSTEP
    case JapaneseEUC
    case UTF8
}

//: 
//: We have chosen to restrict ourselves to the first four possibilities
//: defined in the `NSStringEncoding` enumeration listed above — there are
//: many common encodings that we have not incorporated in this definition.
//: This Swift enumeration declaration is for the purpose of illustration
//: only. The `Encoding` type is inhabited by four possible values: `ASCII`,
//: `NEXTSTEP`, `JapaneseEUC`, and `UTF8`. We will refer to the possible
//: values of an enumeration as *member values*, or *members* for short. In
//: a great deal of literature, such enumerations are sometimes called *sum
//: types*. Throughout this book, however, we will use Apple's terminology.
//: 
//: In contrast to Objective-C, the following code is *not* accepted by the
//: compiler:
//: 
//:
//:    let myEncoding = Encoding.ASCII + Encoding.UTF8
//:
//: 
//: Unlike Objective-C, enumerations in Swift create new types, distinct
//: from integers or other existing types.
//: 
//: We can define functions that calculate with encodings using `switch`
//: statements. For example, we may want to compute the `NSStringEncoding`
//: corresponding to our encoding enumeration:
//: 

func toNSStringEncoding(encoding: Encoding) -> NSStringEncoding {
    switch encoding {
        case Encoding.ASCII:
            return NSASCIIStringEncoding
        case Encoding.NEXTSTEP:
            return NSNEXTSTEPStringEncoding
        case Encoding.JapaneseEUC:
            return NSJapaneseEUCStringEncoding
        case Encoding.UTF8:
            return NSUTF8StringEncoding
    }
}

//: 
//: This definition defines which value to return for each of our `Encoding`
//: types. Note that we have one branch for each of our four different
//: encoding schemes. If we leave any of these branches out, the Swift
//: compiler warns us that the `toNSStringEncoding` function's switch
//: statement is not complete.
//: 
//: Of course, we can also define a function that works in the opposite
//: direction, creating an `Encoding` from an `NSStringEncoding`:
//: 

func createEncoding(enc: NSStringEncoding) -> Encoding? {
    switch enc {
        case NSASCIIStringEncoding:
            return Encoding.ASCII
        case NSNEXTSTEPStringEncoding:
            return Encoding.NEXTSTEP
        case NSJapaneseEUCStringEncoding:
            return Encoding.JapaneseEUC
        case NSUTF8StringEncoding:
            return Encoding.UTF8
        default:
            return nil
    }
}

//: 
//: As we have not modeled all possible `NSStringEncoding` values in our
//: little `Encoding` enumeration, the `createEncoding` function returns an
//: optional `Encoding` value. If none of the first four cases succeed, the
//: `default` branch is selected, which returns `nil`.
//: 
//: Of course, we do not need to use switch statements to work with our
//: `Encoding` enumeration. For example, if we want the localized name of an
//: encoding, we can compute it as follows:
//: 

func localizedEncodingName(encoding: Encoding) -> String {
    return String.localizedNameOfStringEncoding(
            toNSStringEncoding(encoding))
}

//: 
//: Associated Values
//: -----------------
//: 
//: So far, we have seen how Swift's enumerations can be used to describe a
//: choice between several different alternatives. The `Encoding`
//: enumeration provided a safe, typed representation of different string
//: encoding schemes. There are, however, many more applications of
//: enumerations.
//: 
//: Suppose that we want to write Swift wrappers around the existing
//: Objective-C methods to read and write files. Functions that might return
//: an error, such as the `NSString`'s initializer below, can be a bit
//: clunky. In addition to the file path and string encoding, it requires a
//: third argument: a pointer to memory for potential error messages. In
//: Swift, we can use an optional type to provide a slightly simpler
//: interface:
//: 

func readFile1(path: String, encoding: Encoding) -> String? {
    var maybeError: NSError? = nil
    let maybeString = NSString(contentsOfFile: path,
                      encoding: toNSStringEncoding(encoding), 
                      error: &maybeError)
    return maybeString as? String
}

//: 
//: The `readFile1` function returns an optional string. It simply calls the
//: initializer, passing the address for an `NSError` object. If the call to
//: the initializer succeeds, the resulting string is returned; upon
//: failure, the whole function returns `nil`.
//: 
//: This interface is a bit more precise than Objective-C's
//: `stringWithContentsOfFile` — from the type alone, it is clear that this
//: function may fail. There is no temptation for developers to pass null
//: pointers for the `error` argument, ignoring the possibility of failure.
//: 
//: There is one drawback to using Swift's optional type: we no longer
//: return the error message when the file cannot be read. This is rather
//: unfortunate — if a call to `readFile1` fails, there is no way to
//: diagnose what went wrong. Does the file not exist? Is it corrupt? Or do
//: you not have the right permissions?
//: 
//: Ideally, we would like our `readFile` function to return *either* a
//: `String` *or* an `NSError`. Using Swift's enumerations, we can do just
//: that. Instead of returning a `String?`, we will redefine our `readFile`
//: function to return a member of the `ReadFileResult` enumeration. We can
//: define this enumeration as follows:
//: 

enum ReadFileResult {
    case Success(String)
    case Failure(NSError)
}

//: 
//: In contrast to the `Encoding` enumeration, the members of the
//: `ReadFileResult` have [*associated
//: values*](http://objc.io/fpinswift/15). The `ReadFileResult` has only two
//: possible member values: `Success` and `Failure`. In contrast to the
//: `Encoding` enumeration, both of these member values carry additional
//: information: the `Success` member has a string associated with it,
//: corresponding to the contents of the file; the `Failure` member has an
//: associated `NSError`. To illustrate this, we can declare an example
//: `Success` member as follows:
//: 

let exampleSuccess: ReadFileResult = ReadFileResult.Success(
        "File contents goes here")

//: 
//: Similarly, to create a `ReadFile` result using the `Failure` member, we
//: would need to provide an associated `NSError` value.
//: 
//: Now we can rewrite our `readFile` function to return a `ReadFileResult`:
//: 

func readFile(path: String, encoding: Encoding) -> ReadFileResult {
    var maybeError: NSError?
    let maybeString: NSString? = NSString(contentsOfFile: path,
          encoding: toNSStringEncoding(encoding), error: &maybeError)
    if let string = maybeString as? String {
        return .Success(string)
    } else if let error = maybeError {
        return .Failure(error)
    } else {
        fatalError("The impossible occurred")
    }
}

//: 
//: Instead of returning an optional `String`, we now return either the file
//: contents or an `NSError`. We first check if the string is non-`nil` and
//: return the value. If the string is `nil`, we check if there was an error
//: opening the file and, if so, return a `Failure`. Finally, if both
//: `maybeError` and `maybeString` are `nil` after the call to the
//: initializer, something is very wrong indeed, so we halt execution
//: immediately.
//: 
//: Upon calling `readFile`, you can use a switch statement to determine
//: whether or not the function succeeded:
//: 

switch readFile("/Users/wouter/fpinswift/README.md", Encoding.ASCII) {
    case let ReadFileResult.Success(contents):
        println("File successfully opened..")
    case let ReadFileResult.Failure(error):
        println("Failed to open file. Error code: \(error.code)")
}

//: 
//: In contrast to the type interface defined by the Objective-C version of
//: `stringWithContentsOfFile`, it is clear from the types alone what to
//: expect when calling `readFile`. There are corner cases in Objective-C
//: that are not clearly defined: What to do if, after calling
//: `stringWithContentsOfFile`, the error message is non-null, but you also
//: have a valid `String`? Or what happens if the string is `nil`, and there
//: is no error message? The `ReadFileResult` type makes it crystal clear
//: what you can expect: a `String` or an `NSError`. You don't have to read
//: any supporting documentation to understand how to treat the result.
//: 
//: Adding Generics
//: ---------------
//: 
//: Now that we have a Swift function for reading files, the obvious next
//: challenge is to define a function for writing files. As a first
//: approximation, we might write the following:
//: 

func writeFile(contents: String, 
               path: String, encoding: Encoding) -> Bool {
               
    return contents.writeToFile(path, atomically: false, 
            encoding: toNSStringEncoding(encoding), error: nil)
}

//: 
//: The `writeFile` function now returns a boolean, indicating whether or
//: not the operation succeeded. Unfortunately, this definition suffers from
//: the same limitations as our earlier version of `readFile`: when
//: `writeFile` fails, we are not returning the `NSError`.
//: 
//: But we now know how to solve this! Our first approach might be to reuse
//: the `ReadFileResult` enumeration to return the error. When `writeFile`
//: succeeds, however, we do not have a string to associate with the
//: `Success` member value. While we could pass some dummy string, doing so
//: usually indicates bad design: our types should be precise enough to
//: prevent us from having to work with such dummy values.
//: 
//: Alternatively, we can define a new enumeration, `WriteFileResult`,
//: corresponding to the two possible cases:
//: 

enum WriteFileResult {
    case Success
    case Failure(NSError)
}

//: 
//: We can certainly write a new version of the `writeFile` function using
//: this enumeration — but introducing a new enumeration for each possible
//: function seems like overkill. Besides, the `WriteFileResult` and
//: `ReadFileResult` have an awful lot in common. The only difference
//: between the two enumerations is the value associated with `Success`. We
//: would like to define a new enumeration that is *generic* in the result
//: associated with `Success`:
//: 
//:
//:    enum Result<T> {
//:        case Success(T)
//:        case Failure(NSError)
//:    }
//:
//: 
//: Unfortunately, generic associated values are not supported by the
//: current Swift compiler. But there is a workaround — defining a dummy
//: wrapper `Box<T>`:
//: 

class Box<T> {
    let unbox: T
    init(_ value: T) { self.unbox = value }
}



enum Result<T> {
    case Success(Box<T>)
    case Failure(NSError)
}

//: 
//: The `Box` class does not serve any particular purpose, except to hide
//: the associated generic value `T` in the `Success` member.
//: 
//: Now we can use the same result type for both `readFile` and `writeFile`.
//: Their new type signatures would become:
//: 
//:
//:    func readFile(path: String, encoding: Encoding) -> Result<String>
//:    func writeFile(contents: String, 
//:                   path: String, encoding: Encoding) -> Result<()>
//:
//: 
//: The `readFile` function returns either a `String` or an `NSError`; the
//: `writeFile` function returns nothing, represented by the void type `()`
//: or an `NSError`.
//: 
//: Optionals Revisited
//: -------------------
//: 
//: Under the hood, Swift's built-in optional type is very similar to the
//: `Result` type that we've defined here. The following snippet is taken
//: almost directly from the Swift standard library:
//: 
//:
//:    enum Optional<T> {
//:        case None
//:        case Some(T)
//:        // ...
//:    }
//:
//: 
//: The optional type just provides some syntactic sugar, such as the
//: postfix `?` notation and optional unwrapping mechanism, to make it
//: easier to use. There is, however, no reason that you couldn't define it
//: yourself.
//: 
//: In fact, we can even define some of the library functions for
//: manipulating optionals on our own `Result` type. For example, our
//: `Result` type also supports a `map` operation:
//: 

func map<T, U>(f: T -> U, result: Result<T>) -> Result<U> {
    switch result {
        case let Result.Success(box):
            return Result.Success(Box(f(box.unbox)))
        case let Result.Failure(error):
            return Result.Failure(error)
    }
}

//: 
//: Similarly, we can redefine the `??` operator to work on our `Result`
//: type. Note that, instead of taking an `autoclosure` argument, we expect
//: a function that handles the `NSError` to produce the desired value of
//: type `T`:
//: 

func ??<T>(result: Result<T>, handleError: NSError -> T) -> T {
    switch result {
        case let Result.Success(box):
            return box.unbox
        case let Result.Failure(error):
            return handleError(error)
    }
}

//: 
//: The Algebra of Data Types
//: -------------------------
//: 
//: As we mentioned previously, enumerations are often referred to as sum
//: types. This may be a confusing name, as enumerations seem to have no
//: relation to numbers. Yet if you dig a little deeper, you may find that
//: enumerations and tuples have mathematical structure, very similar to
//: arithmetic.
//: 
//: Before we explore this structure, we need to consider the question of
//: when two types are the same. This may seem like a very strange question
//: to ask — isn't it obvious that `String` and `String` are equal, but
//: `String` and `Int` are not? However, as soon as you add generics,
//: enumerations, structs, and functions to the mix, the answer is not so
//: obvious. Such a simple question is still the subject of active research
//: exploring the [very foundations of
//: mathematics](http://objc.io/fpinswift/16). For the purpose of this
//: subsection, we will study when two types are *isomorphic*.
//: 
//: Intuitively, the two types `A` and `B` are isomorphic if we can convert
//: between them without losing any information. We need to have two
//: functions, `f: A -> B` and `g: B -> A`, which are the inverse of one
//: another. More specifically, for `x: A`, the result of calling `g(f(x))`
//: must be equal to `x`; similarly, for all `y : B`, the result of
//: `f(g(y))` must be equal to `y`. This definition crystallizes the
//: intuition we stated above: we can convert freely between the types `A`
//: and `B` using `f` and `g`, without ever losing information (as we can
//: always undo `f` using `g`, and vice versa). This definition is not
//: precise enough for most programming purposes — 64 bits can be used to
//: represent integers or memory addresses, even if these are two very
//: different concepts. They will be useful, however, as we study the
//: algebraic structure of types.
//: 
//: To begin with, consider the following enumeration:
//: 

enum Add<T, U> {
    case InLeft(Box<T>)
    case InRight(Box<U>)
}

//: 
//: Given two types, `T` and `U`, the enumeration `Add<T, U>` consists of
//: either a (boxed) value of type `T`, or a (boxed) value of type `U`. As
//: its name suggests, the `Add` enumeration adds together the members from
//: the types `T` and `U`: if `T` has three members and `U` has seven,
//: `Add<T, U>` will have ten possible members. This observation provides
//: some further insight into why enumerations are called sum types.
//: 
//: In arithmetic, zero is the unit of addition, i.e., `x + 0` is the same
//: as using just `x` for any number `x`. Can we find an enumeration that
//: behaves like zero? Interestingly, Swift allows us to define the
//: following enumeration:
//: 

enum Zero { }

//: 
//: This enumeration is empty — it doesn't have any members. As we hoped,
//: this enumeration behaves exactly like the zero of arithmetic: for any
//: type `T`, the types `Add<T, Zero>` and `T` are isomorphic. It is fairly
//: easy to prove this. We can use `InLeft` to define a function converting
//: `T` to `Add<T,Zero>`, and the conversion in the other direction can be
//: done by pattern matching.
//: 
//: So much for addition — let us now consider multiplication. If we have an
//: enumeration, `T`, with three members, and another enumeration, `U`, with
//: two members, how can we define a compound type, `Times<T, U>`, with six
//: members? To do this, the `Times<T, U>` type should allow you to choose
//: *both* a member of `T` and a member of `U`. In other words, it should
//: correspond to a pair of two values of type `T` and `U` respectively:
//: 
//:
//:    struct Times<T, U> {
//:        let fst: T
//:        let snd: U
//:    }
//:
//: 
//: Just as `Zero` was the unit of addition, the void type, `()`, is the
//: unit of `Times`:
//: 
//:     typealias One = ()
//: 
//: It is easy to check that many familiar laws from arithmetic are still
//: valid when read as isomorphisms between types:
//: 
//: -   `Times<One, T>` is isomorphic to `T`
//: -   `Times<Zero, T>`is isomorphic to `Zero`
//: -   `Times<T, U>` is isomorphic to `Times<U, T>`
//: 
//: Types defined using enumerations and tuples are sometimes referred to as
//: *algebraic data types*, because they have this algebraic structure,
//: similar to natural numbers.
//: 
//: This correspondence between numbers and types runs much deeper than we
//: have sketched here. Functions can be shown to correspond to
//: exponentiation. There is even [a notion of
//: differentiation](http://objc.io/fpinswift/17) that can be defined on
//: types!
//: 
//: This observation may not be of much practical value. Rather it shows how
//: enumerations, like many of Swift's features, are not new, but instead
//: draw on years of research in mathematics and program language design.
//: 
//: Why Use Enumerations?
//: ---------------------
//: 
//: Working with optionals may still be preferable over the `Result` type
//: that we have defined here, for a variety of reasons: the built-in
//: syntactic sugar can be convenient; the interface you define will be more
//: familiar to Swift developers, as you only rely on existing types instead
//: of defining your own enumeration; and sometimes the `NSError` is not
//: worth the additional hassle of defining an enumeration.
//: 
//: The point we want to make, however, is not that the `Result` type is the
//: best way to handle all errors in Swift. Instead, we hope to illustrate
//: how you can use enumerations to define your own types, tailored to your
//: specific needs. By making these types precise, you can use Swift's type
//: checking to your advantage and prevent many bugs, before your program
//: has been tested or run.
//: 
