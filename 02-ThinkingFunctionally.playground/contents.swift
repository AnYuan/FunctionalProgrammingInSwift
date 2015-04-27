//: Thinking Functionally
//: =====================
//: 
//: Functions in Swift are *first-class values*, i.e. functions may be
//: passed as arguments to other functions, and functions may return new
//: functions. This idea may seem strange if you're used to working with
//: simple types, such as integers, booleans, or structs. In this chapter,
//: we will try to explain why first-class functions are useful and provide
//: our first example of functional programming in action.
//: 
//: Example: Battleship
//: -------------------
//: 
//: We'll introduce first-class functions using a small example: a
//: non-trivial function that you might need to implement if you were
//: writing a Battleship-like game. The problem we'll look at boils down to
//: determining whether or not a given point is in range, without being too
//: close to friendly ships or to us.
//: 
//: As a first approximation, you might write a very simple function that
//: checks whether or not a point is in range. For the sake of simplicity,
//: we will assume that our ship is located at the origin. We can visualize
//: the region we want to describe in Figure \ref{fig:battleship1}.
//: 
//: *Playgrounds don't contain images, please see the book*
//: 
//: The first function we write, `inRange1`, checks that a point is in the
//: grey area in Figure \ref{fig:battleship1}. Using some basic geometry, we
//: can write this function as follows:
//: 

import Foundation



typealias Position = CGPoint
typealias Distance = CGFloat

func inRange1(target: Position, range: Distance) -> Bool {
   return sqrt(target.x * target.x + target.y * target.y) <= range
}

//: 
//: Note that we are using Swift's [typealias](http://objc.io/fpinswift/2)
//: construct, which allows us to introduce a new name for an existing type.
//: From now on, whenever we write `Position`, feel free to read `CGPoint`,
//: a pairing of an `x` and `y` coordinate.
//: 
//: Now this works fine, if you assume that we are always located at the
//: origin. But suppose the ship may be at a location, `ownposition`, other
//: than the origin. We can update our visualization in Figure
//: \ref{fig:battleship2}.
//: 
//: *Playgrounds don't contain images, please see the book*
//: 
//: We now add an argument representing the location of the ship to our
//: `inRange` function:
//: 

func inRange2(target: Position, ownPosition: Position, 
              range: Distance) -> Bool {
              
    let dx = ownPosition.x - target.x
    let dy = ownPosition.y - target.y
    let targetDistance = sqrt(dx * dx + dy * dy) 
    return targetDistance <= range
}

//: 
//: But now you realize that you also want to avoid targeting ships if they
//: are too close to you. We can update our visualization to illustrate the
//: new situation in Figure \ref{fig:battleship-3}, where we want to target
//: only those enemies that are at least `minimumDistance` away from our
//: current position.
//: 
//: *Playgrounds don't contain images, please see the book*
//: 
//: As a result, we need to modify our code again:
//: 

let minimumDistance: Distance = 2.0

func inRange3(target: Position, ownPosition: Position, 
              range: Distance) -> Bool {
              
    let dx = ownPosition.x - target.x
    let dy = ownPosition.y - target.y
    let targetDistance = sqrt(dx * dx + dy * dy) 
    return targetDistance <= range
           && targetDistance > minimumDistance
}

//: 
//: Finally, you also need to avoid targeting ships that are too close to
//: one of your other ships. Once again, we can visualize this in Figure
//: \ref{fig:battleship-4}.
//: 
//: *Playgrounds don't contain images, please see the book*
//: 
//: Correspondingly, we can add a further argument that represents the
//: location of a friendly ship to our `inRange` function:
//: 

func inRange4(target: Position, ownPosition: Position, 
              friendly: Position, range: Distance) -> Bool {
              
    let dx = ownPosition.x - target.x
    let dy = ownPosition.y - target.y
    let targetDistance = sqrt(dx * dx + dy * dy) 
    let friendlyDx = friendly.x - target.x
    let friendlyDy = friendly.y - target.y
    let friendlyDistance = sqrt(friendlyDx * friendlyDx +
                                friendlyDy * friendlyDy)
    return targetDistance <= range
           && targetDistance > minimumDistance
           && (friendlyDistance > minimumDistance)
}

//: 
//: As this code evolves, it becomes harder and harder to maintain. This
//: method expresses a complicated calculation in one big lump of code.
//: Let's try to refactor this into smaller, compositional pieces.
//: 
//: First-Class Functions
//: ---------------------
//: 
//: There are different approaches to refactoring this code. One obvious
//: pattern would be to introduce a function that computes the distance
//: between two points, or functions that check when two points are 'close'
//: or 'far away' (or some definition of close and far away). In this
//: chapter, however, we'll take a slightly different approach.
//: 
//: The original problem boiled down to defining a function that determined
//: when a point was in range or not. The type of such a function would be
//: something like:
//: 
//:     func pointInRange(point: Position) -> Bool {
//:         // Implement method here
//:     }
//: 
//: The type of this function is going to be so important that we're going
//: to give it a separate name:
//: 

typealias Region = Position -> Bool

//: 
//: From now on, the `Region` type will refer to functions transforming a
//: `Position` to a `Bool`. This isn't strictly necessary, but it can make
//: some of the type signatures that we'll see below a bit easier to digest.
//: 
//: Instead of defining an object or struct to represent regions, we
//: represent a region by a *function* that determines if a given point is
//: in the region or not. If you're not used to functional programming, this
//: may seem strange, but remember: functions in Swift are first-class
//: values! We consciously chose the name `Region` for this type, rather
//: than something like `CheckInRegion` or `RegionBlock`. These names
//: suggest that they denote a function type, yet the key philosophy
//: underlying *functional programming* is that functions are values, no
//: different from structs, integers, or booleans — using a separate naming
//: convention for functions would violate this philosophy.
//: 
//: We will now write several functions that create, manipulate, and combine
//: regions. The first region we define is a `circle`, centered around the
//: origin:
//: 

func circle(radius: Distance) -> Region {
    return { point in 
        sqrt(point.x * point.x + point.y * point.y) <= radius 
   }
}

//: 
//: Note that, given a radius `r`, the call `circle(r)` *returns a
//: function*. Here we use Swift's [notation for
//: closures](http://objc.io/fpinswift/3) to construct the function that we
//: wish to return. Given an argument position, `point`, we check that the
//: `point` is in the region delimited by a circle of the given radius
//: centered around the origin.
//: 
//: Of course, not all circles are centered around the origin. We could add
//: more arguments to the `circle` function to account for this. To compute
//: a circle that's centered around a certain position, we just add another
//: argument representing the circle's center, and make sure to use the new
//: argument to compute the new region:
//: 

func circle2(radius: Distance, center: Position) -> Region {
    return { point in
        let shiftedPoint = Position(x: point.x - center.x,
                                    y: point.y - center.y)
        return sqrt(shiftedPoint.x * shiftedPoint.x +
                    shiftedPoint.y * shiftedPoint.y) <= radius
   }
}

//: 
//: However, if we we want to make the same change to more primitives (for
//: example, imagine we not only had circles, but also rectangles or other
//: shapes), we might need to duplicate this code. A more functional
//: approach is to write a *region transformer* instead. This function
//: shifts a region by a certain position:
//: 

func shift(offset: Position, region: Region) -> Region {
    return { point in
        let shiftedPoint = Position(x: point.x - offset.x, 
                                    y: point.y - offset.y)
        return region(shiftedPoint)
    }
}

//: 
//: The call `shift(offset, region)` moves the region to the right and up by
//: `offset.x` and `offset.y`, respectively. We need to return a `Region`,
//: which is a function from a point to a boolean value. To do this, we
//: start writing another closure, introducing the point we need to check.
//: From this point, we compute a new point with the coordinates
//: `point.x - offset.x` and `point.y - offset.y`. Finally, we check that
//: this new point is in the *original* region by passing it as an argument
//: to the `region` function.
//: 
//: This is one of the core concepts of functional programming: rather than
//: creating increasingly complicated functions such as `circle2`, we have
//: written a function, `shift`, that modifies another function. For
//: example, a circle that's centered at `(5, 5)` and has a radius of `10`
//: can now be expressed like this:
//: 
shift(Position(x: 5, y: 5), circle(10))
//: 
//: There are lots of other ways to transform existing regions. For
//: instance, we may want to define a new region by inverting a region. The
//: resulting region consists of all the points outside the original region:
//: 

func invert(region: Region) -> Region {
    return { point in !region(point) }
}

//: 
//: We can also write functions that combine existing regions into larger,
//: complex regions. For instance, these two functions take the points that
//: are in *both* argument regions or *either* argument region,
//: respectively:
//: 

func intersection(region1: Region, region2: Region) -> Region {
    return { point in region1(point) && region2(point) }
}

func union(region1: Region, region2: Region) -> Region {
    return { point in region1(point) || region2(point) }
}

//: 
//: Of course, we can use these functions to define even richer regions. The
//: `difference` function takes two regions as argument, `region` and
//: `minusRegion`, and constructs a region with all points that are in the
//: first, but not in the second, region:
//: 

func difference(region: Region, minusRegion: Region) -> Region {
    return intersection(region, invert(minusRegion))
}

//: 
//: This example shows how Swift lets you compute and pass around functions
//: no differently than you would integers or booleans. This enables us to
//: write small primitives (such as `circle`) and to build a series of
//: functions on top of these primitives. Each of these functions modifies
//: or combines regions into new regions. Instead of writing complex
//: functions to solve a very specific problem, we can now use many small
//: functions that can be assembled to solve a wide variety of problems.
//: 
//: Now let's turn our attention back to our original example. With this
//: small library in place, we can now refactor the complicated `inRange`
//: function as follows:
//: 

func inRange(ownPosition: Position, target: Position, 
             friendly: Position, range: Distance) -> Bool {
             
    let rangeRegion = difference(circle(range), 
                                 circle(minimumDistance))
    let targetRegion = shift(ownPosition, rangeRegion)
    let friendlyRegion = shift(friendly, circle(minimumDistance))
    let resultRegion = difference(targetRegion, friendlyRegion)
    return resultRegion(target)
}

//: 
//: This code defines two regions: `targetRegion` and `friendlyRegion`. The
//: region that we're interested in is computed by taking the difference
//: between these regions. By applying this region to the `target` argument,
//: we can compute the desired boolean.
//: 
//: Compared to the original `inRange4` function, the `inRange` function
//: provides a more *declarative* solution to the same problem. We would
//: argue that the `inRange` function is easier to understand because the
//: solution is *compositional*. To understand the `inRange` function, you
//: can study each of its constituent regions, such as `targetRegion` and
//: `friendlyRegion`, and see how these are assembled to solve the original
//: problem. The `inRange4` function, on the other hand, mixes the
//: description of the constituent regions and the calculations needed to
//: describe them. Separating these concerns by defining the helper
//: functions we have presented previously increases the compositionality
//: and legibility of complex regions.
//: 
//: Having first-class functions is essential for this to work. Objective-C
//: also supports first-class functions, or *blocks*. It can, unfortunately,
//: be quite cumbersome to work with blocks. Part of this is a syntax issue:
//: both the declaration of a block and the type of a block are not as
//: straightforward as their Swift counterparts. In later chapters, we will
//: also see how generics make first-class functions
//: even more powerful, going beyond what is easy to achieve with blocks in
//: Objective-C.
//: 
//: The way we've defined the `Region` type does have its disadvantages. In
//: particular, we cannot inspect *how* a region was constructed: Is it
//: composed of smaller regions? Or is it simply a circle around the origin?
//: The only thing we can do is to check whether a given point is within a
//: region or not. If we would want to visualize a region, we would have to
//: sample enough points to generate a (black and white) bitmap.
//: 
//: In later chapters, we will sketch an alternative design
//: that will allow you to answer these questions.
//: 
//: Type-Driven Development
//: -----------------------
//: 
//: In the introduction, we mentioned how functional programs take the
//: application of functions to arguments as the canonical way to assemble
//: bigger programs. In this chapter, we have seen a concrete example of
//: this functional design methodology. We have defined a series of
//: functions for describing regions. Each of these functions is not very
//: powerful by itself. Yet together, they can describe complex regions that
//: you wouldn't want to write from scratch.
//: 
//: The solution is simple and elegant. It is quite different from what you
//: might write if had you naively refactored the ´inRange4´ function into
//: separate methods. The crucial design decision we made was *how* to
//: define regions. Once we chose the `Region` type, all the other
//: definitions followed naturally. The moral of the example is **choose
//: your types carefully**. More than anything else, types guide the
//: development process.
//: 
//: Notes
//: -----
//: 
//: The code presented here is inspired by the Haskell solution to a problem
//: posed by the United States Advanced Research Projects Agency (ARPA) by
//: @hudak-jones.
//: 
//: Objective-C added support for first-class functions when they introduced
//: blocks: you can use functions and closures as parameters, and easily
//: define them inline. However, working with them is not nearly as
//: convenient in Objective-C as it is in Swift, even though they're
//: semantically equivalent.
//: 
//: Historically, the idea of first-class functions can be traced as far
//: back as Church's lambda calculus [@church; @barendregt]. Since then, the
//: concept has made its way into numerous (functional) programming
//: languages, including Haskell, OCaml, Standard ML, Scala, and F\#.
//: 
