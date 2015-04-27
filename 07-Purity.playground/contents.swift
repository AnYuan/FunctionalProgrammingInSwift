//: The Value of Immutability
//: =========================
//: 
//: Swift has several mechanisms for controlling how values may change. In
//: this chapter, we will explain how these different mechanisms work,
//: distinguish between value types and reference types, and argue why it is
//: a good idea to limit the usage of mutable state.
//: 
//: Variables and References
//: ------------------------
//: 
//: In Swift, there are two ways to initialize a variable, using either
//: `var` or `let`:
//: 

var x: Int = 1
let y: Int = 2

//: 
//: The crucial difference is that we can assign new values to variables
//: declared using `var`, whereas variables created using `let` *cannot*
//: change:
//: 
//:
//:    x = 3 // This is fine
//:    y = 4 // This is rejected by the compiler
//:
//: 
//: We will refer to variables declared using a `let` as *immutable*
//: variables; variables declared using a `var`, on the other hand, are said
//: to be *mutable*.
//: 
//: Why — you might wonder — would you ever declare an immutable variable?
//: Doing so limits the variable's capabilities. A mutable variable is
//: strictly more versatile. There is a clear case for preferring `var` over
//: `let`. Yet in this section, we want to try and argue that the opposite
//: is true.
//: 
//: Imagine having to read through a Swift class that someone else has
//: written. There are a few methods that all refer to an instance variable
//: with some meaningless name, say `x`. Given the choice, would you prefer
//: `x` to be declared with a `var` or a `let`? Clearly declaring `x` to be
//: immutable is preferable: you can read through the code without having to
//: worry about what the *current* value of `x` is, you're free to
//: substitute `x` for its definition, and you cannot invalidate `x` by
//: assigning it some value that might break invariants on which the rest of
//: the class relies.
//: 
//: Immutable variables may not be assigned a new value. As a result, it is
//: *easier* to reason about immutable variables. In his famous paper, "Go
//: To Statement Considered Harmful," Edsger Dijkstra writes:
//: 
//: > My... remark is that our intellectual powers are rather geared to
//: > master static relations and that our powers to visualize processes
//: > evolving in time are relatively poorly developed.
//: 
//: Dijkstra goes on to argue that the mental model a programmer needs to
//: develop when reading through structured code (using conditionals, loops,
//: and function calls, but not goto statements) is simpler than spaghetti
//: code full of gotos. We can take this discipline even further and eschew
//: the use of mutable variables: `var` considered harmful.
//: 
//: Value Types vs. Reference Types
//: -------------------------------
//: 
//: The careful treatment of mutability is not present only in variable
//: declarations. Swift distinguishes between *value* types and *reference*
//: types. The canonical examples of value and reference types are structs
//: and classes, respectively. To illustrate the difference between value
//: types and reference types, we will define the following struct:
//: 

struct PointStruct {
    var x: Int
    var y: Int
}

//: 
//: Now consider the following code fragment:
//: 

var structPoint = PointStruct(x: 1, y: 2)
var sameStructPoint = structPoint
sameStructPoint.x = 3

//: 
//: After executing this code, `sameStructPoint` is clearly equal to
//: `(x: 3,` `y: 2)`. However, `structPoint` still has its original value.
//: This is the crucial distinction between value types and reference types:
//: when assigned to a new variable or passed as an argument to a function,
//: value types are copied. The assignment to `sameStructPoint.x` does *not*
//: update the original `structPoint`, because the prior assignment,
//: `sameStructPoint` `=` `structPoint`, has *copied* the value.
//: 
//: To further illustrate the difference, we could declare a class for
//: points:
//: 

class PointClass {
    var x: Int
    var y: Int

    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

//: 
//: Then we can adapt our code fragment from above to use this class
//: instead:
//: 

var classPoint = PointClass(x: 1, y: 2)
var sameClassPoint = classPoint
sameClassPoint.x = 3

//: 
//: Now the assignment, `sameClassPoint.x`, modifies both `classPoint` and
//: `sameClassPoint`, because classes are *reference* types. The distinction
//: between value types and reference types is extremely important — you
//: need to understand this distinction to predict how assignments modify
//: data and which code may be affected by such changes.
//: 
//: The difference between value types and reference types is also apparent
//: when calling functions. Consider the following (somewhat contrived)
//: function that always returns the origin:
//: 

func setStructToOrigin(var point: PointStruct) -> PointStruct {
    point.x = 0
    point.y = 0
    return point
}

//: 
//: We use this function to compute a point:
//: 

var structOrigin: PointStruct = setStructToOrigin(structPoint)

//: 
//: All value types, such as structs, are copied when passed as function
//: arguments. Therefore, in this example, the original `structPoint` is
//: unmodified after the call to `setStructToOrigin`.
//: 
//: Now suppose we had written the following function, operating on classes
//: rather than structs:
//: 

func setClassToOrigin(point: PointClass) -> PointClass {
    point.x = 0
    point.y = 0
    return point
}

//: 
//: Now the following function call *would* modify the `classPoint`:
//: 

var classOrigin = setClassToOrigin(classPoint)

//: 
//: When assigned to a new variable or passed to a function, value types are
//: *always* copied, whereas reference types are *not*. Instead, a reference
//: to the existing object or instance is used. Any changes to this
//: reference will also mutate the original object or instance.
//: 
//: Andy Matuschak provides some very useful intuition for the difference
//: between value types and reference types in [his article for
//: objc.io](http://objc.io/fpinswift/14).
//: 
//: Structs are not the only value type in Swift. In fact, almost all the
//: types in Swift are value types, including arrays, dictionaries, numbers,
//: booleans, tuples, and enums (the latter will be covered in the coming
//: chapter). Classes are the exception, rather than the rule. This is one
//: example of how Swift is moving away from object-oriented programming in
//: favor of other programming paradigms.
//: 
//: We will discuss the relative merits of classes and structs later on in
//: this section; before we do so, we want to briefly discuss the
//: interaction between the different forms of mutability that we have seen
//: thus far.
//: 
//: ### Structs and Classes: Mutable or Not?
//: 
//: In the examples above, we have declared all our points and their fields
//: to be mutable, using `var` rather than `let`. The interaction between
//: compound types, such as structs and classes, and the `var` and `let`
//: declarations, requires some explanation.
//: 
//: Suppose we create the following immutable `PointStruct`:
//: 

let immutablePoint = PointStruct(x: 0, y: 0)

//: 
//: Of course, assigning a new value to this `immutablePoint` is not
//: accepted:
//: 
//:
//:    immutablePoint = PointStruct(x: 1, y: 1) // Rejected
//:
//: 
//: Similarly, trying to assign a new value to one of the point's properties
//: is also rejected, although the properties in `PointStruct` have been
//: defined as `var`, since `immutablePoint` is defined using `let`:
//: 
//:
//:    immutablePoint.x = 3 // Rejected
//:
//: 
//: However, if we would have declared the point variable as mutable, we
//: could change its components after initialization:
//: 

var mutablePoint = PointStruct(x: 1, y: 1)
mutablePoint.x = 3;

//: 
//: If we declare the `x` and `y` properties within the struct using the
//: `let` keyword, then we can't ever change them after initialization, no
//: matter whether the variable holding the point instance is mutable or
//: immutable:
//: 

struct ImmutablePointStruct {
    let x: Int
    let y: Int
}

var immutablePoint2 = ImmutablePointStruct(x: 1, y: 1)


//:
//:    immutablePoint2.x = 3 // Rejected!
//:
//: 
//: Of course, we can still assign a new value to `immutablePoint2`:
//: 

immutablePoint2 = ImmutablePointStruct(x: 2, y: 2)

//: 
//: ### Objective-C
//: 
//: The concept of mutability and immutability should already be familiar to
//: many Objective-C programmers. Many of the data structures provided by
//: Apple's Core Foundation and Foundation frameworks exist in immutable and
//: mutable variants, such as `NSArray` and `NSMutableArray`, `NSString` and
//: `NSMutableString`, and others. Using the immutable types is the default
//: choice in most cases, just as Swift favors value types over reference
//: types.
//: 
//: In contrast to Swift, however, there is no foolproof way to enforce
//: immutability in Objective-C. We could declare the object's properties as
//: read-only (or only expose an interface that avoids mutation), but this
//: will not stop us from (unintentionally) mutating values internally after
//: they have been initialized. When working with legacy code, for instance,
//: it is all too easy to break assumptions about mutability that cannot be
//: enforced by the compiler. Without checks by the compiler, it is very
//: hard to enforce any kind of discipline in the use of mutable variables.
//: 
//: Discussion
//: ----------
//: 
//: In this chapter, we have seen how Swift distinguishes between mutable
//: and immutable values, and between value types and reference types. In
//: this final section, we want to explain *why* these are important
//: distinctions.
//: 
//: When studying a piece of software, *coupling* measures the degree to
//: which individual units of code depend on one another. Coupling is one of
//: the single most important factors that determines how well software is
//: structured. In the worst case, all classes and methods refer to one
//: another, sharing numerous mutable variables, or even relying on exact
//: implementation details. Such code can be very hard to maintain or
//: update: instead of understanding or modifying a small code fragment in
//: isolation, you constantly need to consider the system in its totality.
//: 
//: In Objective-C and many other object-oriented languages, it is common
//: for class methods to be coupled through shared instance variables. As a
//: result, however, mutating the variable may change the behavior of the
//: class's methods. Typically, this is a good thing — once you change the
//: data stored in an object, all its methods may refer to its new value. At
//: the same time, however, such shared instance variables introduce
//: coupling between all the class's methods. If any of these methods or
//: some external function invalidate the shared state, all the class's
//: methods may exhibit buggy behavior. It is much harder to test any of
//: these methods in isolation, as they are now coupled to one another.
//: 
//: Now compare this to the functions that we tested in the
//: QuickCheck chapter. Each of these functions computed an
//: output value that *only* depended on the input values. Such functions
//: that compute the same output for equal inputs are sometimes called
//: *referentially transparent*. By definition, referentially transparent
//: methods are loosely coupled from their environments: there are no
//: implicit dependencies on any state or variables, aside from the
//: function's arguments. Consequently, referentially transparent functions
//: are easier to test and understand in isolation. Furthermore, we can
//: compose, call, and assemble functions that are referentially transparent
//: without losing this property. Referential transparency is a guarantee of
//: modularity and reusability.
//: 
//: Referential transparency increases modularity on all levels. Imagine
//: reading through an API, trying to figure out how it works. The
//: documentation may be sparse or out of date. But if you know the API is
//: free of mutable state — all variables are declared using `let` rather
//: than `var` — this is incredibly valuable information. You never need to
//: worry about initializing objects or processing commands in exactly the
//: right order. Instead, you can just look at types of the functions and
//: constants that the API defines, and how these can be assembled to
//: produce the desired value.
//: 
//: Swift's distinction between `var` and `let` enables programmers not only
//: to distinguish between mutable and immutable data, but also to have the
//: compiler enforce this distinction. Favoring `let` over `var` reduces the
//: complexity of the program — you no longer have to worry about what the
//: current value of mutable variables is, but can simply refer to their
//: immutable definitions. Favoring immutability makes it easier to write
//: referentially transparent functions, and ultimately, reduces coupling.
//: 
//: Similarly, Swift's distinction between value types and reference types
//: encourages you to distinguish between mutable objects that may change
//: and immutable data that your program manipulates. Functions are free to
//: copy, change, or share values — any modifications will only ever affect
//: their local copies. Once again, this helps write code that is more
//: loosely coupled, as any dependencies resulting from shared state or
//: objects can be eliminated.
//: 
//: Can we do without mutable variables entirely? Pure programming
//: languages, such as Haskell, encourage programmers to avoid using mutable
//: state altogether. There are certainly large Haskell programs that do not
//: use any mutable state. In Swift, however, dogmatically avoiding `var` at
//: all costs will not necessarily make your code better. There are plenty
//: of situations where a function uses some mutable state internally.
//: Consider the following example function that sums the elements of an
//: array:
//: 

func sum(xs: [Int]) -> Int {
    var result = 0
    for x in xs {
        result += x
    }
    return result
}

//: 
//: The `sum` function uses a mutable variable, `result`, that is repeatedly
//: updated. Yet the *interface* exposed to the user hides this fact. The
//: `sum` function is still referentially transparent, and arguably easier
//: to understand than a convoluted definition avoiding mutable variables at
//: all costs. This example illustrates a *benign* usage of mutable state.
//: 
//: Such benign mutable variables have many applications. Consider the
//: `qsort` method defined in the QuickCheck chapter:
//: 

func qsort(var array: [Int]) -> [Int] {
    if array.isEmpty { return [] }
    let pivot = array.removeAtIndex(0)
    let lesser = array.filter { $0 < pivot }
    let greater = array.filter { $0 >= pivot }
    return qsort(lesser) + [pivot] + qsort(greater)
}

//: 
//: Although this method mostly avoids using mutable references, it does not
//: run in constant memory. It allocates new arrays, `lesser` and `greater`,
//: which are combined to produce the final result. Of course, by using a
//: mutable array, we can define a version of Quicksort that runs in
//: constant memory and is still referentially transparent. Clever usage of
//: mutable variables can sometimes improve performance or memory usage.
//: 
//: In summary, Swift offers several language features specifically designed
//: to control the usage of mutable state in your program. It is almost
//: impossible to avoid mutable state altogether, but mutation is used
//: excessively and unnecessarily in many programs. Learning to avoid
//: mutable state and objects whenever possible can help reduce coupling,
//: thereby improving the structure of your code.
//: 
