//: Optionals
//: =========
//: 
//: Swift's *optional types* can be used to represent values that may be
//: missing or computations that may fail. This chapter describes Swift's
//: optional types, how to work with them effectively, and how they fit well
//: within the functional programming paradigm.
//: 
//: Case Study: Dictionaries
//: ------------------------
//: 
//: In addition to arrays, Swift has special support for working with
//: *dictionaries*. A dictionary is a collection of key-value pairs, and it
//: provides an efficient way to find the value associated with a certain
//: key. The syntax for creating dictionaries is similar to arrays:
//: 

let cities = ["Paris": 2243, "Madrid": 3216, 
              "Amsterdam": 881, "Berlin": 3397]

//: 
//: This dictionary stores the population of several European cities. In
//: this example, the key `"Paris"` is associated with the value `2243`;
//: that is, Paris has about 2,243,000 inhabitants.
//: 
//: As with arrays, the `Dictionary` type is generic. The type of
//: dictionaries takes two type parameters, corresponding to the types of
//: the stored keys and stored values, respectively. In our example, the
//: city dictionary has type `Dictionary<String, Int>`. There is also a
//: shorthand notation, `[String: Int]`.
//: 
//: We can look up the value associated with a key using the same notation
//: as array indexing:
//: 
//:
//:    let madridPopulation: Int = cities["Madrid"]
//:
//: 
//: This example, however, does not type check. The problem is that the key
//: `"Madrid"` may not be in the `cities` dictionary — and what value should
//: be returned if it is not? We cannot guarantee that the dictionary lookup
//: operation *always* returns an `Int` for every key. Swift's *optional*
//: types track the possibility of failure. The correct way to write the
//: example above would be:
//: 

let madridPopulation: Int? = cities["Madrid"]

//: 
//: Instead of having type `Int`, the `madridPopulation` example has the
//: optional type `Int?`. A value of type `Int?` is either an `Int` or a
//: special 'missing' value, `nil`.
//: 
//: We can check whether or not the lookup was successful:
//: 

if madridPopulation != nil {
    println("The population of Madrid is " +
            "\(madridPopulation! * 1000)")
} else {
    println("Unknown city: Madrid")
}

//: 
//: If `madridPopulation` is not `nil`, then the branch is executed. To
//: refer to the underlying `Int`, we write `madridPopulation!`. The
//: post-fix `!` operator forces an optional to a non-optional type. To
//: compute the total population of Madrid, we force the optional
//: `madridPopulation` to an `Int`, and multiply it by `1000`.
//: 
//: Swift has a special *optional binding* mechanism that lets you avoid
//: writing the `!` suffix. We can combine the definition of
//: `madridPopulation` and the check above into a single statement:
//: 

if let madridPopulation = cities["Madrid"] {
    println("The population of Madrid is " +
            "\(madridPopulation * 1000)")
} else {
    println("Unknown city: Madrid")
}

//: 
//: If the lookup, `cities["Madrid"]`, is successful, we can use the
//: variable `madridPopulation: Int` in the then-branch. Note that we no
//: longer need to explicitly use the forced unwrapping operator.
//: 
//: Given the choice, we'd recommend using optional binding over forced
//: unwrapping. Forced unwrapping may crash if you have a `nil` value;
//: optional binding encourages you to handle exceptional cases explicitly,
//: thereby avoiding runtime errors. Unchecked usage of the forced
//: unwrapping of optional types or Swift's [implicitly unwrapped
//: optionals](http://objc.io/fpinswift/9) can be a bad code smell,
//: indicating the possibility of runtime errors.
//: 
//: Swift also provides a safer alternative to the `!` operator, which
//: requires an additional default value to return when applied to `nil`.
//: Roughly speaking, it can be defined as follows:
//: 
//:
//:    infix operator ?? 
//:    
//:    func ??<T>(optional: T?, defaultValue: T) -> T {
//:        if let x = optional {
//:            return x
//:        } else {
//:            return defaultValue
//:        }
//:    }
//:
//: 
//: The `??` operator checks whether or not its optional argument is `nil`.
//: If it is, it returns its `defaultValue` argument; otherwise, it returns
//: the optional's underlying value.
//: 
//: There is one problem with this definition: the `defaultValue` will be
//: evaluated, regardless of whether or not the optional is `nil`. This is
//: usually undesirable behavior: an if-then-else statement should only
//: execute *one* of its branches, depending on whether or not the
//: associated condition is true. Similarly, the `??` operator should only
//: evaluate the `defaultValue` argument when the optional argument is
//: `nil`. As an illustration, suppose we were to call `??`, as follows:
//: 
//:
//:    optional ?? defaultValue
//:
//: 
//: In this example, we really do not want to evaluate `defaultValue` if the
//: `optional` variable is non-nil — it could be a very expensive
//: computation that we only want to run if it is absolutely necessary. We
//: can resolve this issue as follows:
//: 
//:
//:    func ??<T>(optional: T?, defaultValue: () -> T) -> T {
//:        if let x = optional {
//:            return x
//:        } else {
//:            return defaultValue()
//:        }
//:    }
//:
//: 
//: Instead of providing a default value of type `T`, we now provide one of
//: type `() -> T`. The code in the `defaultValue` closure is now only
//: executed when we pass it its (void) argument. In this definition, this
//: code is only executed in the else branch, as we intended. The only
//: drawback is that when calling the `??` operator, we need to create an
//: explicit closure for the default value. For example, we would need to
//: write:
//: 
//:
//:    myOptional ?? { myDefaultValue }
//:
//: 
//: The definition in the Swift standard library avoids the need for
//: creating explicit closures by using Swift's [`autoclosure` type
//: attribute](http://objc.io/fpinswift/10). This implicitly wraps any
//: arguments to the `??` operator in the required closure. As a result, we
//: can provide the same interface that we initially had, but without
//: requiring the user to create an explicit closure wrapping the
//: `defaultValue` argument. The actual definition used in Swift's standard
//: library is as follows:
//: 
//:
//:    infix operator ?? { associativity right precedence 110 }
//:    
//:    func ??<T>(optional: T?, 
//:               @autoclosure defaultValue: () -> T) -> T {
//:               
//:        if let x = optional {
//:            return x
//:        } else {
//:            return defaultValue()
//:        }
//:    }
//:
//: 
//: The `??` provides a safer alternative to the forced optional unwrapping,
//: without being as verbose as the optional binding.
//: 
//: Combining Optional Values
//: -------------------------
//: 
//: Swift's optional values make the possibility of failure explicit. This
//: can be cumbersome, especially when combining multiple optional results.
//: There are several techniques to facilitate the use of optionals.
//: 
//: ### Optional Chaining
//: 
//: First of all, Swift has a special mechanism, *optional chaining*, for
//: selecting methods or attributes in nested classes or structs. Consider
//: the following (fragment of a) model for processing customer orders:
//: 

struct Order {
    let orderNumber: Int
    let person: Person?
    // ...
}

struct Person {
    let name: String
    let address: Address?
    // ...
}

struct Address {
    let streetName: String
    let city: String
    let state: String?
    // ...
}

//: 
//: Given an `Order`, how can we find the state of the customer? We could
//: use the explicit unwrapping operator:
//: 
//:
//:    order.person!.address!.state!
//:
//: 
//: Doing so, however, may cause runtime exceptions if any of the
//: intermediate data is missing. It would be much safer to use optional
//: binding:
//: 
//:
//:    if let myPerson = order.person {
//:        if let myAddress = myPerson.address {
//:            if let myState = myAddress.state {
//:                // ...
//:
//: 
//: But this is rather verbose. Using optional chaining, this example would
//: become:
//: 
//:
//:    if let myState = order.person?.address?.state {
//:        print("This order will be shipped to \(myState)")
//:    } else {
//:        print("Unknown person, address, or state.")
//:    }
//:
//: 
//: Instead of forcing the unwrapping of intermediate types, we use the
//: question mark operator to try and unwrap the optional types. When any of
//: the component selections fails, the whole chain of selection statements
//: returns `nil`.
//: 
//: ### Maps and More
//: 
//: The `?` operator lets us select methods or fields of optional values.
//: There are plenty of other examples, however, where you may want to
//: manipulate an optional value, if it exists, and return `nil` otherwise.
//: Consider the following example:
//: 

func incrementOptional(optional: Int?) -> Int? {
    if let x = optional {
        return x + 1
    } else {
        return nil
    }
}

//: 
//: The `incrementOptional` example behaves similarly to the `?` operator:
//: if the optional value is `nil`, the result is `nil`; otherwise, some
//: computation is performed.
//: 
//: We can generalize both `incrementOptional` and the `?` operator and
//: define a `map` function. Rather than only increment a value of type
//: `Int?`, as we did in `incrementOptional`, we pass the operation we wish
//: to perform as an argument to the `map` function:
//: 

func map<T, U>(optional: T?, f: T -> U) -> U? {
    if let x = optional {
        return f(x)
    } else {
        return nil
    }
}

//: 
//: This `map` function takes two arguments: an optional value of type `T?`,
//: and a function `f` of type `T -> U`. If the optional value is not `nil`,
//: it applies `f` to it and returns the result; otherwise, the `map`
//: function returns `nil`. This `map` function is part of the Swift
//: standard library.
//: 
//: Using `map`, we write the `incrementOptional` function as:
//: 

func incrementOptional2(optional: Int?) -> Int? {
    return optional.map { x in x + 1 }
}

//: 
//: Of course, we can also use `map` to project fields or methods from
//: optional structs and classes, similar to the `?` operator.
//: 
//: Why is this function called `map`? What does it have to do with array
//: computations? There is a good reason for calling both of these functions
//: `map`, but we will defer this discussion for the moment. In [Chapter
//: 14](#functors-applicative-functors-and-monads), we will explain the
//: relation in greater detail.
//: 
//: ### Optional Binding Revisited
//: 
//: The `map` function shows one way to manipulate optional values, but many
//: others exist. Consider the following example:
//: 
//:
//:    let x: Int? = 3
//:    let y: Int? = nil
//:    let z: Int? = x + y
//:
//: 
//: This program is not accepted by the Swift compiler. Can you spot the
//: error?
//: 
//: The problem is that addition only works on `Int` values, rather than the
//: optional `Int?` values we have here. To resolve this, we could introduce
//: nested `if` statements, as follows:
//: 
//:
//:    func addOptionals(optionalX: Int?, optionalY: Int?) -> Int? {
//:        if let x = optionalX {
//:            if let y = optionalY {
//:                return x + y
//:            }
//:        }
//:        return nil
//:    }
//:
//: 
//: However, instead of the deep nesting, we can also bind multiple
//: optionals at the same time:
//: 

func addOptionals(optionalX: Int?, optionalY: Int?) -> Int? {
    if let x = optionalX, y = optionalY {
        return x + y
    }
    return nil
}

//: 
//: This may seem like a contrived example, but manipulating optional values
//: can happen all the time. Suppose we have the following dictionary,
//: associating countries with their capital cities:
//: 

let capitals = ["France": "Paris", "Spain": "Madrid", 
                "The Netherlands": "Amsterdam", 
                "Belgium": "Brussels"]

//: 
//: In order to write a function that returns the number of inhabitants for
//: the capital of a given country, we use the `capitals` dictionary in
//: conjunction with the `cities` dictionary defined previously. For each
//: dictionary lookup, we have to make sure that it actually returned a
//: result:
//: 

func populationOfCapital(country: String) -> Int? {
    if let capital = capitals[country],
           population = cities[capital] {
        return population * 1000
    }
    return nil
}

//: 
//: Both optional chaining and `if let` are special constructs in the
//: language to make working with optionals easier. However, Swift offers
//: yet another way to solve the problem above: the function `flatMap` in
//: the standard library. The `flatMap` function is defined for multiple
//: types, and in the case of optionals, it looks like this:
//: 
//:
//:    func flatMap<A, B>(x: A?, f: A -> B?) -> B? {
//:        if let x = optional {
//:            return f(x)
//:        } else {
//:            return nil
//:        }
//:    }
//:
//: 
//: The `flatMap` function checks whether an optional value is non-`nil`. If
//: it is, we pass it on to the argument function `f`; if the optional
//: argument is `nil`, the result is also `nil`.
//: 
//: Using this function, we can now write our examples as follows:
//: 

func addOptionals2(optionalX: Int?, optionalY: Int?) -> Int? {
    return flatMap(optionalX) { x in
        flatMap(optionalY) { y in
            x + y
        }
    }
}

func populationOfCapital2(country: String) -> Int? {
    return flatMap(capitals[country]) { capital in
        flatMap(cities[capital]) { population in
            population * 1000
        }
    }
}

//: 
//: We do not want to advocate that `flatMap` is the 'right' way to combine
//: optional values. Instead, we hope to show that optional binding is not
//: magically built-in to the Swift compiler, but rather a control structure
//: you can implement yourself using a higher-order function.
//: 
//: Why Optionals?
//: --------------
//: 
//: What's the point of introducing an explicit optional type? For
//: programmers used to Objective-C, working with optional types may seem
//: strange at first. The Swift type system is rather rigid: whenever we
//: have an optional type, we have to deal with the possibility of it being
//: `nil`. We have had to write new functions like `map` to manipulate
//: optional values. In Objective-C, you have more flexibility. For
//: instance, when translating the example above to Objective-C, there is no
//: compiler error:
//: 
//:
//:    - (int)populationOfCapital:(NSString *)country 
//:    {
//:        return [self.cities[self.capitals[country]] intValue] * 1000;
//:    }
//:
//: 
//: We can pass in `nil` for the name of a country, and we get back a result
//: of `0.0`. Everything is fine. In many languages without optionals, null
//: pointers are a source of danger. Much less so in Objective-C. In
//: Objective-C, you can safely send messages to `nil`, and depending on the
//: return type, you either get `nil`, 0, or similar “zero-like” values. Why
//: change this behavior in Swift?
//: 
//: The choice for an explicit optional type fits with the increased static
//: safety of Swift. A strong type system catches errors before code is
//: executed, and an explicit optional type helps protect you from
//: unexpected crashes arising from missing values.
//: 
//: The default zero-like behavior employed by Objective-C has its
//: drawbacks. You may want to distinguish between failure (a key is not in
//: the dictionary) and success-returning `nil` (a key is in the dictionary,
//: but associated with `nil`). To do that in Objective-C, you have to use
//: `NSNull`.
//: 
//: While it is safe in Objective-C to send messages to `nil`, it is often
//: not safe to use them. Let's say we want to create an attributed string.
//: If we pass in `nil` as the argument for `country`, the `capital` will
//: also be `nil`, but `NSAttributedString` will crash when trying to
//: initialize it with a `nil` value:
//: 
//:
//:    - (NSAttributedString *)attributedCapital:(NSString *)country 
//:    {
//:        NSString *capital = self.capitals[country];
//:        NSDictionary *attributes = @{ /* ... */ };
//:        return [[NSAttributedString alloc] initWithString:capital 
//:                                               attributes:attributes];
//:    }
//:
//: 
//: While crashes like that don't happen too often, almost every developer
//: has had code like this crash. Most of the time, these crashes are
//: detected during debugging, but it is very possible to ship code without
//: noticing that, in some cases, a variable might unexpectedly be `nil`.
//: Therefore, many programmers use asserts to verify this behavior. For
//: example, we can add an `NSParameterAssert` to make sure we crash quickly
//: when the `country` is `nil`:
//: 
//:
//:    - (NSAttributedString *)attributedCapital:(NSString *)country 
//:    {
//:        NSParameterAssert(country);
//:        NSString *capital = self.capitals[country];
//:        NSDictionary *attributes = @{ /* ... */ };
//:        return [[NSAttributedString alloc] initWithString:capital 
//:                                               attributes:attributes];
//:    }
//:
//: 
//: Now, when we pass in a country value that is `nil`, the assert fails
//: immediately, and we are almost certain to hit this during debugging. But
//: what if we pass in a `country` value that doesn't have a matching key in
//: `self.capitals`? This is much more likely, especially when `country`
//: comes from user input. In that case, `capital` will be `nil` and our
//: code will still crash. Of course, this can be fixed easily enough. The
//: point is, however, that it is easier to write *robust* code using `nil`
//: in Swift than in Objective-C.
//: 
//: Finally, using these assertions is inherently non-modular. Suppose we
//: implement a `checkCountry` method that checks that a non-empty
//: `NSString*` is supported. We can incorporate this check easily enough:
//: 
//:
//:    - (NSAttributedString *)attributedCapital:(NSString*)country 
//:    {
//:        NSParameterAssert(country);
//:        if (checkCountry(country)) {
//:            // ...
//:        }
//:    }
//:
//: 
//: Now the question arises: should the `checkCountry` function also assert
//: that its argument is non-`nil`? On one hand, it should not — we have
//: just performed the check in the `attributedCapital` method. On the other
//: hand, if the `checkCountry` function only works on non-`nil` values, we
//: should duplicate the assertion. We are forced to choose between exposing
//: an unsafe interface or duplicating assertions. It is also possible to
//: add a `nonnull` attribute to the signature, which will emit a warning
//: when the method is called with a value that could be `nil`, but this is
//: not common practice in most Objective-C codebases.
//: 
//: In Swift, things are a bit better. Function signatures using optionals
//: explicitly state which values may be `nil`. This is invaluable
//: information when working with other peoples' code. A signature like the
//: following provides a lot of information:
//: 
//:
//:    func attributedCapital(country: String) -> NSAttributedString?
//:
//: 
//: Not only are we warned about the possibility of failure, but we know
//: that we must pass a `String` as argument — and not a `nil` value. A
//: crash like the one we described above will not happen. Furthermore, this
//: is information *checked* by the compiler. Documentation goes out of date
//: easily; you can always trust function signatures.
//: 
//: When dealing with scalar values, optionality is even more tricky in
//: Objective-C. Consider the following sample, which tries to find mentions
//: of a specific keyword in a string. It looks innocent enough: if
//: `rangeOfString:` does not find the string, then the location will be set
//: to `NSNotFound`. `NSNotFound` is defined as `NSIntegerMax`. This code is
//: almost correct, and the problem is hard to see at first sight: when
//: `someString` is `nil`, then `rangeOfString:` will return a structure
//: filled with zeroes, and the `location` will return 0. The check will
//: then succeed, and the code inside the if-statement will be executed:
//: 
//:
//:    NSString *someString = ...; 
//:    if ([someString rangeOfString:@"swift"].location != NSNotFound]) {
//:        NSLog(@"Someone mentioned swift!");
//:    }
//:
//: 
//: With optionals, this can not happen. If we wanted to port this code to
//: Swift, we would need to make some structural changes. The above code
//: would be rejected by the compiler, and the type system would not allow
//: you to run `rangeOfString:` on a `nil` value. Instead, you first need to
//: unwrap it:
//: 
//:
//:    if let someString = ... {
//:        if someString.rangeOfString("swift").location != NSNotFound {
//:            println("Found")
//:        }
//:    }
//:
//: 
//: The type system will help in catching subtle errors for you. Some of
//: these errors would have been easily detected during development, but
//: others might accidentally end up in production code. By using optionals,
//: this class of errors can be eliminated automatically.
//: 
