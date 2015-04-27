

import Cocoa

class Box<T> {
    let unbox: T
    init(_ value: T) { self.unbox = value }
}

extension NSGraphicsContext {
    var cgContext : CGContextRef {
        let opaqueContext = COpaquePointer(self.graphicsPort)
        return Unmanaged<CGContextRef>.fromOpaque(opaqueContext)
               .takeUnretainedValue()
    }
}

func *(l: CGPoint, r: CGRect) -> CGPoint {
    return CGPointMake(r.origin.x + l.x*r.size.width, 
                       r.origin.y + l.y*r.size.height)
}

func *(l: CGFloat, r: CGPoint) -> CGPoint { 
    return CGPointMake(l*r.x, l*r.y) 
}
func *(l: CGFloat, r: CGSize) -> CGSize { 
    return CGSizeMake(l*r.width, l*r.height) 
}

func pointWise(f: (CGFloat, CGFloat) -> CGFloat, 
               l: CGSize, r: CGSize) -> CGSize {
               
    return CGSizeMake(f(l.width, r.width), f(l.height, r.height))
}

func pointWise(f: (CGFloat, CGFloat) -> CGFloat, 
               l: CGPoint, r:CGPoint) -> CGPoint {
               
    return CGPointMake(f(l.x, r.x), f(l.y, r.y))
}

func /(l: CGSize, r: CGSize) -> CGSize { 
    return pointWise(/, l, r) 
}
func *(l: CGSize, r: CGSize) -> CGSize { 
    return pointWise(*, l, r) 
}
func +(l: CGSize, r: CGSize) -> CGSize { 
    return pointWise(+, l, r) 
}
func -(l: CGSize, r: CGSize) -> CGSize { 
    return pointWise(-, l, r) 
}

func -(l: CGPoint, r: CGPoint) -> CGPoint { 
    return pointWise(-, l, r) 
}
func +(l: CGPoint, r: CGPoint) -> CGPoint { 
    return pointWise(+, l, r) 
}
func *(l: CGPoint, r: CGPoint) -> CGPoint { 
    return pointWise(*, l, r) 
}


extension CGSize {
    var point : CGPoint {
        return CGPointMake(self.width, self.height)
    }
}

func isHorizontalEdge(edge: CGRectEdge) -> Bool {
    switch edge {
        case .MaxXEdge, .MinXEdge:
            return true
        default:
            return false
    }
}

func splitRect(rect: CGRect, sizeRatio: CGSize, 
               edge: CGRectEdge) -> (CGRect, CGRect) {
               
    let ratio = isHorizontalEdge(edge) ? sizeRatio.width 
                                       : sizeRatio.height
    let multiplier = isHorizontalEdge(edge) ? rect.width 
                                            : rect.height
    let distance : CGFloat = multiplier * ratio
    var mySlice : CGRect = CGRectZero
    var myRemainder : CGRect = CGRectZero
    CGRectDivide(rect, &mySlice, &myRemainder, distance, edge)
    return (mySlice, myRemainder)
}

func splitHorizontal(rect: CGRect, 
                     ratio: CGSize) -> (CGRect, CGRect) {
                     
    return splitRect(rect, ratio, CGRectEdge.MinXEdge)
}

func splitVertical(rect: CGRect, 
                   ratio: CGSize) -> (CGRect, CGRect) {
                   
    return splitRect(rect, ratio, CGRectEdge.MinYEdge)
}

extension CGRect {
    init(center: CGPoint, size: CGSize) {
        let origin = CGPointMake(center.x - size.width/2, 
                                 center.y - size.height/2)
        self.init(origin: origin, size: size)
    }
}

// A 2-D Vector
struct Vector2D {
    let x: CGFloat
    let y: CGFloat
    
    var point : CGPoint { return CGPointMake(x, y) }
    
    var size : CGSize { return CGSizeMake(x, y) }
}

func *(m: CGFloat, v: Vector2D) -> Vector2D {
    return Vector2D(x: m * v.x, y: m * v.y)
}

extension Dictionary {
    var keysAndValues: [(Key, Value)] {
        var result: [(Key, Value)] = []
        for item in self {
            result.append(item)
        }
        return result
    }
}

func normalize(input: [CGFloat]) -> [CGFloat] {
    let maxVal = input.reduce(0) { max($0, $1) }
    return input.map { $0 / maxVal }
}

//: 
//: Diagrams
//: ========
//: 
//: In this chapter, we'll look at a functional way to describe diagrams,
//: and discuss how to draw them with Core Graphics. By wrapping Core
//: Graphics with a functional layer, we get an API that's simpler and more
//: composable.
//: 
//: Drawing Squares and Circles
//: ---------------------------
//: 
//: Imagine drawing the diagram in Figure \ref{fig:diagram1}. In Core
//: Graphics, we could achieve this drawing with the following command:
//: 
//: *Playgrounds don't contain images, please see the book*
//: 
//:
//:    NSColor.blueColor().setFill()
//:    CGContextFillRect(context, CGRectMake(0.0, 37.5, 75.0, 75.0))
//:    NSColor.redColor().setFill()
//:    CGContextFillRect(context, CGRectMake(75.0, 0.0, 150.0, 150.0))
//:    NSColor.greenColor().setFill()
//:    CGContextFillEllipseInRect(context, 
//:                               CGRectMake(225.0, 37.5, 75.0, 75.0))
//:
//: 
//: This is nice and short, but it is a bit difficult to maintain. For
//: example, what if we wanted to add an extra circle like in Figure
//: \ref{fig:diagram2}?
//: 
//: *Playgrounds don't contain images, please see the book*
//: 
//: We would need to add the code for drawing a rectangle, but also update
//: the drawing code to move some of the other objects to the right. In Core
//: Graphics, we always describe *how* to draw things. In this chapter,
//: we'll build a library for diagrams that allows us to express *what* we
//: want to draw. For example, the first diagram can be expressed like this:
//: 
//:
//:    let blueSquare = square(side: 1).fill(NSColor.blueColor())
//:    let redSquare = square(side: 2).fill(NSColor.redColor())
//:    let greenCircle = circle(diameter: 1).fill(NSColor.greenColor())
//:    let example1 = blueSquare ||| redSquare ||| greenCircle
//:
//: 
//: Adding the second circle is as simple as changing the last line of code:
//: 
//:
//:    let cyanCircle = circle(diameter: 1).fill(NSColor.cyanColor())
//:    let example2 = blueSquare ||| cyanCircle ||| 
//:                   redSquare ||| greenCircle
//:
//: 
//: The code above first describes a blue square with a relative size of
//: `1`. The red square is twice as big (it has a relative size of `2`). We
//: compose the diagram by putting the squares and the circle next to each
//: other with the `|||` operator. Changing this diagram is very simple, and
//: there's no need to worry about calculating frames or moving things
//: around. The examples describe *what* should be drawn, not *how* it
//: should be drawn.
//: 
//: One of the techniques we'll use in this chapter is building up an
//: intermediate structure of the diagram. Instead of executing the drawing
//: commands immediately, we build up a data structure that describes the
//: diagram. This is a very powerful technique, as it allows us to inspect
//: the data structure, modify it, and convert it into different formats.
//: 
//: As a more complex example of a diagram generated by the same library,
//: Figure \ref{fig:diagram3} shows a bar graph.
//: 
//: *Playgrounds don't contain images, please see the book*
//: 
//: We can write a `barGraph` function that takes a list of names (the keys)
//: and values (the relative heights of the bars). For each value in the
//: dictionary, we draw a suitably sized rectangle. We then horizontally
//: concatenate these rectangles with the `hcat` function. Finally, we put
//: the bars and the text below each other using the `---` operator:
//: 
//:
//:    func barGraph(input: [(String, Double)]) -> Diagram {
//:        let values: [CGFloat] = input.map { CGFloat($0.1) }
//:        let nValues = normalize(values)
//:        let bars = hcat(nValues.map { (x: CGFloat) -> Diagram in
//:            return rect(width: 1, height: 3 * x)
//:                   .fill(NSColor.blackColor()).alignBottom()
//:        })
//:        let labels = hcat(input.map { x in
//:            return text(width: 1, height: 0.3, text: x.0).alignTop()
//:        })
//:        return bars --- labels
//:    }
//:    let cities = ["Shanghai": 14.01, "Istanbul": 13.3, 
//:                  "Moscow": 10.56, "New York": 8.33, "Berlin": 3.43]
//:    let example3 = barGraph(cities.keysAndValues)
//:
//: 
//: The Core Data Structures
//: ------------------------
//: 
//: In our library, we'll draw three kinds of things: ellipses, rectangles,
//: and text. Using enums, we can define a data type for these three
//: possibilities:
//: 

enum Primitive {
    case Ellipse
    case Rectangle
    case Text(String)
}

//: 
//: Diagrams are defined using an enum as well. First, a diagram could be a
//: primitive, which has a size and is either an ellipse, a rectangle, or
//: text. Note that we call it `Prim` because, at the time of writing, the
//: compiler gets confused by a case that has the same name as another enum:
//: 
//:
//:    case Prim(CGSize, Primitive)
//:
//: 
//: Then, we have cases for diagrams that are beside each other
//: (horizontally) or below each other (vertically). Note how a `Beside`
//: diagram is defined recursively — it consists of two diagrams next to
//: each other:
//: 
//:
//:    case Beside(Diagram, Diagram)
//:    case Below(Diagram, Diagram)
//:
//: 
//: To style diagrams, we'll add a case for attributed diagrams. This allows
//: us to set the fill color (for example, for ellipses and rectangles).
//: We'll define the `Attribute` type later:
//: 
//:
//:    case Attributed(Attribute, Diagram)
//:
//: 
//: The last case is for alignment. Suppose we have a small and a large
//: rectangle that are next to each other. By default, the small rectangle
//: gets centered vertically, as seen in Figure \ref{fig:diagram4}.
//: 
//: *Playgrounds don't contain images, please see the book*
//: 
//: But by adding a case for alignment, we can control the alignment of
//: smaller parts of the diagram:
//: 
//:
//:    case Align(Vector2D, Diagram)
//:
//: 
//: For example, Figure \ref{fig:diagram5} shows a diagram that's top
//: aligned. It is drawn using the following code:
//: 
//: *Playgrounds don't contain images, please see the book*
//: 
//:
//:    Diagram.Align(Vector2D(x: 0.5, y: 1), Box(blueSquare)) ||| redSquare
//:
//: 
//: Unfortunately, in the current version of Swift, recursive data types are
//: not allowed. So instead of having a `Diagram` case that contains other
//: `Diagram`s, we have to wrap each recursive `Diagram` with `Box` (defined
//: in Chapter 8
//: 

enum Diagram {
    case Prim(CGSize, Primitive)
    case Beside(Box<Diagram>, Box<Diagram>)
    case Below(Box<Diagram>, Box<Diagram>)
    case Attributed(Attribute, Box<Diagram>)
    case Align(Vector2D, Box<Diagram>)
}

//: 
//: The `Attribute` enum is a data type for describing different attributes
//: of diagrams. Currently, it only supports `FillColor`, but it could
//: easily be extended to support attributes for stroking, gradients, text
//: attributes, etc.:
//: 

enum Attribute {
    case FillColor(NSColor)
}

//: 
//: Calculating and Drawing
//: -----------------------
//: 
//: Calculating the size for the `Diagram` data type is easy. The only cases
//: that aren't straightforward are for `Beside` and `Below`. In case of
//: `Beside`, the width is equal to the sum of the widths, and the height is
//: equal to the maximum height of the left and right diagram. For `Below`,
//: it's a similar pattern. For all the other cases, we just call size
//: recursively:
//: 

extension Diagram {
    var size: CGSize {
        switch self {
        case .Prim(let size, _):
            return size
        case .Attributed(_, let x):
            return x.unbox.size
        case .Beside(let l, let r):
            let sizeL = l.unbox.size
            let sizeR = r.unbox.size
            return CGSizeMake(sizeL.width + sizeR.width,
                max(sizeL.height, sizeR.height))
        case .Below(let l, let r):
            let sizeL = l.unbox.size
            let sizeR = r.unbox.size
            return CGSizeMake(max(sizeL.width, sizeR.width),
                sizeL.height+sizeR.height)
        case .Align(_, let r):
            return r.unbox.size
        }
    }
}

//: 
//: Before we start drawing, we will first define one more function. The
//: `fit` function takes an alignment vector (which we used in the `Align`
//: case of a diagram), an input size (i.e. the size of a diagram), and a
//: rectangle that we want to fit the input size into. The input size is
//: defined relatively to the other elements in our diagram. We scale it up
//: and maintain its aspect ratio:
//: 

func fit(alignment: Vector2D, 
         inputSize: CGSize, rect: CGRect) -> CGRect {
         
    let scaleSize = rect.size / inputSize
    let scale = min(scaleSize.width, scaleSize.height)
    let size = scale * inputSize
    let space = alignment.size * (size - rect.size)
    return CGRect(origin: rect.origin - space.point, size: size)
}

//: 
//: For example, if we fit and center a square of 1x1 into a rectangle of
//: 200x100, we get the following result:
//: 
fit(Vector2D(x: 0.5, y: 0.5), CGSizeMake(1, 1), 
    CGRectMake(0, 0, 200, 100))
//: 
//: To align the rectangle to the left, we would do the following:
//: 
fit(Vector2D(x: 0, y: 0.5), CGSizeMake(1, 1), 
    CGRectMake(0, 0, 200, 100))
//: 
//: Now that we can represent diagrams and calculate their sizes, we're
//: ready to draw them. We use pattern matching to make it easy to know what
//: to draw. The `draw` method takes a few parameters: the context to draw
//: in, the bounds to draw in, and the actual diagram. Given the bounds, the
//: diagram will try to fit itself into the bounds using the `fit` function
//: defined before. For example, when we draw an ellipse, we center it and
//: make it fill the available bounds:
//: 

func draw(context: CGContextRef, bounds: CGRect, diagram: Diagram) {
    switch diagram {
        case .Prim(let size, .Ellipse):
            let frame = fit(Vector2D(x: 0.5, y: 0.5), size, bounds)
            CGContextFillEllipseInRect(context, frame)

//: 
//: For rectangles, this is almost the same, except that we call a different
//: Core Graphics function. You might note that the `frame` calculation is
//: the same as for ellipses. It would be possible to pull this out and have
//: a nested switch statement, but we think this is more readable when
//: presenting in book form:
//: 

        case .Prim(let size, .Rectangle):
            let frame = fit(Vector2D(x: 0.5, y: 0.5), size, bounds)
            CGContextFillRect(context, frame)

//: 
//: In the current version of our library, all text is set in the system
//: font with a fixed size. It's very possible to make this an attribute, or
//: change the `Text` primitive to make this configurable. In its current
//: form though, drawing text works like this:
//: 

        case .Prim(let size, .Text(let text)):
            let frame = fit(Vector2D(x: 0.5, y: 0.5), size, bounds)
            let font = NSFont.systemFontOfSize(12)
            let attributes = [NSFontAttributeName: font]
            let attributedText = NSAttributedString(
                    string: text, attributes: attributes)
            attributedText.drawInRect(frame)

//: 
//: The only attribute we support is fill color. It's very easy to add
//: support for extra attributes, but we left that out for brevity. To draw
//: a diagram with a `FillColor` attribute, we save the current graphics
//: state, set the fill color, draw the diagram, and finally, restore the
//: graphics state:
//: 

        case .Attributed(.FillColor(let color), let d):
            CGContextSaveGState(context)
            color.set()
            draw(context, bounds, d.unbox)
            CGContextRestoreGState(context)

//: 
//: To draw two diagrams next to each other, we first need to find their
//: respective frames. We create a function, `splitHorizontal`, that splits
//: a `CGRect` according to a ratio (in this case, the relative size of the
//: left diagram). Then we draw both diagrams with their frames:
//: 

        case .Beside(let left, let right):
            let l = left.unbox
            let r = right.unbox
            let (lFrame, rFrame) = splitHorizontal(
                    bounds, l.size/diagram.size)
            draw(context, lFrame, l)
            draw(context, rFrame, r)

//: 
//: The case for `Below` is exactly the same, except that we split the
//: `CGRect` vertically instead of horizontally. This code was written to
//: run on the Mac, and therefore the order is `bottom` and `top` (unlike
//: UIKit, the Cocoa coordinate system has the origin at the bottom left):
//: 

        case .Below(let top, let bottom):
            let t = top.unbox
            let b = bottom.unbox
            let (lFrame, rFrame) = splitVertical(
                    bounds, b.size/diagram.size)
            draw(context, lFrame, b)
            draw(context, rFrame, t)

//: 
//: Our last case is aligning diagrams. Here, we can reuse the fit function
//: that we defined earlier to calculate new bounds that fit the diagram
//: exactly:
//: 

        case .Align(let vec, let d):
            let diagram = d.unbox
            let frame = fit(vec, diagram.size, bounds)
            draw(context, frame, diagram)
    }
}

//: 
//: We've now defined the core of our library. All the other things can be
//: built on top of these primitives.
//: 
//: Creating Views and PDFs
//: -----------------------
//: 
//: We can create a subclass of `NSView` that performs the drawing, which is
//: very useful when working with playgrounds, or when you want to draw
//: these diagrams in Mac applications:
//: 

class Draw: NSView {
    let diagram: Diagram

    init(frame frameRect: NSRect, diagram: Diagram) {
        self.diagram = diagram
        super.init(frame:frameRect)
    }

    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    override func drawRect(dirtyRect: NSRect) {
        if let context = NSGraphicsContext.currentContext() {
            draw(context.cgContext, self.bounds, diagram)
        }
    }
}

//: 
//: Now that we have an `NSView`, it's also very simple to make a PDF out of
//: our diagrams. We calculate the size and just use `NSView`'s method,
//: `dataWithPDFInsideRect`, to get the PDF data. This is a nice example of
//: taking existing object-oriented code and wrapping it in a functional
//: layer:
//: 

func pdf(diagram: Diagram, width: CGFloat) -> NSData {
    let unitSize = diagram.size
    let height = width * (unitSize.height/unitSize.width)
    let v: Draw = Draw(frame: NSMakeRect(0, 0, width, height), 
                       diagram: diagram)
    return v.dataWithPDFInsideRect(v.bounds)
}

//: 
//: Extra Combinators
//: -----------------
//: 
//: To make the construction of diagrams easier, it's nice to add some extra
//: functions (also called combinators). This is a common pattern in
//: functional libraries: have a small set of core data types and functions,
//: and then build convenience functions on top of them. For example, for
//: rectangles, circles, text, and squares, we can define convenience
//: functions:
//: 

func rect(#width: CGFloat, #height: CGFloat) -> Diagram {
    return Diagram.Prim(CGSizeMake(width, height), .Rectangle)
}

func circle(#diameter: CGFloat) -> Diagram {
    return Diagram.Prim(CGSizeMake(diameter, diameter), .Ellipse)
}

func text(#width: CGFloat, 
          #height: CGFloat, text theText: String) -> Diagram {
          
    return Diagram.Prim(CGSizeMake(width, height), .Text(theText))
}

func square(#side: CGFloat) -> Diagram { 
    return rect(width: side, height: side) 
}

//: 
//: Also, it turns out that it's very convenient to have operators for
//: combining diagrams horizontally and vertically, making the code more
//: readable. They are just wrappers around `Beside` and `Below`:
//: 

infix operator ||| { associativity left }
func ||| (l: Diagram, r: Diagram) -> Diagram {
    return Diagram.Beside(Box(l), Box(r))
}

infix operator --- { associativity left }
func --- (l: Diagram, r: Diagram) -> Diagram {
    return Diagram.Below(Box(l), Box(r))
}

//: 
//: We can also extend the `Diagram` type and add methods for filling and
//: alignment. We also might have defined these methods as top-level
//: functions instead. This is a matter of style; one is not more powerful
//: than the other:
//: 

extension Diagram {
    func fill(color: NSColor) -> Diagram {
        return Diagram.Attributed(Attribute.FillColor(color), 
                                  Box(self))
    }
    
    func alignTop() -> Diagram {
        return Diagram.Align(Vector2D(x: 0.5, y: 1), Box(self))
    }
    
    func alignBottom() -> Diagram {
        return Diagram.Align(Vector2D(x:0.5, y: 0), Box(self))
    }
}

//: 
//: Finally, we can define an empty diagram and a way to horizontally
//: concatenate a list of diagrams. We can just use the array's `reduce`
//: function to do this:
//: 

let empty: Diagram = rect(width: 0, height: 0)

func hcat(diagrams: [Diagram]) -> Diagram {
    return diagrams.reduce(empty, combine: |||)
}

//: 
//: By adding these small helper functions, we have a powerful library for
//: drawing diagrams.
//: 
//: Discussion
//: ----------
//: 
//: The code in this chapter is inspired by the Diagrams library for Haskell
//: [@yorgey]. Although we can draw simple diagrams, there are many possible
//: improvements and extensions to the library we have presented here. Some
//: things are still missing but can be added easily. For example, it's
//: straightforward to add more attributes and styling options. A bit more
//: complicated would be adding transformations (such as rotation), but this
//: is certainly still possible.
//: 
//: When we compare the library that we've built in this chapter to the
//: library in Chapter 2, we can see many
//: similarities. Both take a problem domain (regions and diagrams) and
//: create a small library of functions to describe this domain. Both
//: libraries provide an interface through functions that are highly
//: composable. Both of these little libraries define a *domain-specific
//: language* (or DSL) embedded in Swift. A DSL is a small programming
//: language, tailored to solve a particular problem. You are probably
//: already familiar with lots of DSLs, such as regular expressions, SQL, or
//: HTML — each of these languages is not a general-purpose programming
//: language in which to write *any* application, but instead is more
//: restricted to solve a particular kind of problem. Regular expressions
//: are used for describing patterns or lexers, SQL is used for querying a
//: database, and HTML is used for describing the content of a webpage.
//: 
//: However, there is an important difference between the two DSLs: in the
//: Thinking Functionally chapter, we created
//: functions that return a bool for each position. To draw the diagrams, we
//: built up an intermediate structure, the `Diagram` enum. A *shallow
//: embedding* of a DSL in a general-purpose programming language like Swift
//: does not create any intermediate data structures. A *deep embedding*, on
//: the other hand, explicitly creates an intermediate data structure, like
//: the `Diagram` enumeration described in this chapter. The term
//: 'embedding' refers to how the DSL for regions or diagrams are 'embedded'
//: into Swift. Both have their advantages. A shallow embedding can be
//: easier to write, there is less overhead during execution, and it can be
//: easier to extend with new functions. However, when using a deep
//: embedding, we have the advantage that we can analyze an entire
//: structure, transform it, or assign different meanings to the
//: intermediate data structure.
//: 
//: If we would rewrite the DSL from Chapter 2 to use deep embedding
//: instead, we would need to define an enumeration representing the
//: different functions from the library. There would be members for our
//: primitive regions, like circles or squares, and members for composite
//: regions, such as those formed by intersection or union. We could then
//: analyze and compute with these regions in different ways: generating
//: images, checking whether a region is primitive or not, determining
//: whether or not a given point is in the region, or performing an
//: arbitrary computation over this intermediate data structure. Rewriting
//: the diagrams library to a shallow embedding would be complicated. The
//: intermediate data structure can be inspected, modified, and transformed.
//: To define a shallow embedding, we would need to call Core Graphics
//: directly for every operation that we wish to support in our DSL. It is
//: much more difficult to compose drawing calls than it is to first create
//: an intermediate structure and only render it once the diagram has been
//: completely assembled.
//: 


// *********************************************
// This code generates example PDFs for the book
// *********************************************

let blueSquare = square(side: 1).fill(NSColor.blueColor())
let redSquare = square(side: 2).fill(NSColor.redColor())
let greenCircle = circle(diameter: 1).fill(NSColor.greenColor())
let example1 = blueSquare ||| redSquare ||| greenCircle
let cyanCircle = circle(diameter: 1).fill(NSColor.cyanColor())
let example2 = blueSquare ||| cyanCircle ||| 
               redSquare ||| greenCircle

func writepdf(name: String, diagram: Diagram) {
    let filename = Process.arguments[1].stringByAppendingPathComponent("artwork/generated").stringByAppendingPathComponent(name + ".pdf")
    let data = pdf(diagram, 300)
    data.writeToFile(filename, atomically: false)
}

writepdf("example1", example1)
writepdf("example2", example2)

func barGraph(input: [(String, Double)]) -> Diagram {
    let values: [CGFloat] = input.map { CGFloat($0.1) }
    let nValues = normalize(values)
    let bars = hcat(nValues.map { (x: CGFloat) -> Diagram in
        return rect(width: 1, height: 3 * x)
               .fill(NSColor.blackColor()).alignBottom()
    })
    let labels = hcat(input.map { x in
        return text(width: 1, height: 0.3, text: x.0).alignTop()
    })
    return bars --- labels
}
let cities = ["Shanghai": 14.01, "Istanbul": 13.3, 
              "Moscow": 10.56, "New York": 8.33, "Berlin": 3.43]
let example3 = barGraph(cities.keysAndValues)

writepdf("example3", example3)

writepdf("example4", blueSquare ||| redSquare)
writepdf("example5", Diagram.Align(Vector2D(x: 0.5, y: 1), Box(blueSquare)) ||| redSquare)


//:
//:    
//:    extension NSGraphicsContext {
//:        var cgContext : CGContextRef {
//:            let opaqueContext = COpaquePointer(self.graphicsPort)
//:            return Unmanaged<CGContextRef>.fromOpaque(opaqueContext)
//:                   .takeUnretainedValue()
//:        }
//:    }
//:    
//:    func *(l: CGPoint, r: CGRect) -> CGPoint {
//:        return CGPointMake(r.origin.x + l.x*r.size.width, 
//:                           r.origin.y + l.y*r.size.height)
//:    }
//:    
//:    func *(l: CGFloat, r: CGPoint) -> CGPoint { 
//:        return CGPointMake(l*r.x, l*r.y) 
//:    }
//:    func *(l: CGFloat, r: CGSize) -> CGSize { 
//:        return CGSizeMake(l*r.width, l*r.height) 
//:    }
//:    
//:    func pointWise(f: (CGFloat, CGFloat) -> CGFloat, 
//:                   l: CGSize, r: CGSize) -> CGSize {
//:                   
//:        return CGSizeMake(f(l.width, r.width), f(l.height, r.height))
//:    }
//:    
//:    func pointWise(f: (CGFloat, CGFloat) -> CGFloat, 
//:                   l: CGPoint, r:CGPoint) -> CGPoint {
//:                   
//:        return CGPointMake(f(l.x, r.x), f(l.y, r.y))
//:    }
//:    
//:    func /(l: CGSize, r: CGSize) -> CGSize { 
//:        return pointWise(/, l, r) 
//:    }
//:    func *(l: CGSize, r: CGSize) -> CGSize { 
//:        return pointWise(*, l, r) 
//:    }
//:    func +(l: CGSize, r: CGSize) -> CGSize { 
//:        return pointWise(+, l, r) 
//:    }
//:    func -(l: CGSize, r: CGSize) -> CGSize { 
//:        return pointWise(-, l, r) 
//:    }
//:    
//:    func -(l: CGPoint, r: CGPoint) -> CGPoint { 
//:        return pointWise(-, l, r) 
//:    }
//:    func +(l: CGPoint, r: CGPoint) -> CGPoint { 
//:        return pointWise(+, l, r) 
//:    }
//:    func *(l: CGPoint, r: CGPoint) -> CGPoint { 
//:        return pointWise(*, l, r) 
//:    }
//:    
//:    
//:    extension CGSize {
//:        var point : CGPoint {
//:            return CGPointMake(self.width, self.height)
//:        }
//:    }
//:    
//:    func isHorizontalEdge(edge: CGRectEdge) -> Bool {
//:        switch edge {
//:            case .MaxXEdge, .MinXEdge:
//:                return true
//:            default:
//:                return false
//:        }
//:    }
//:    
//:    func splitRect(rect: CGRect, sizeRatio: CGSize, 
//:                   edge: CGRectEdge) -> (CGRect, CGRect) {
//:                   
//:        let ratio = isHorizontalEdge(edge) ? sizeRatio.width 
//:                                           : sizeRatio.height
//:        let multiplier = isHorizontalEdge(edge) ? rect.width 
//:                                                : rect.height
//:        let distance : CGFloat = multiplier * ratio
//:        var mySlice : CGRect = CGRectZero
//:        var myRemainder : CGRect = CGRectZero
//:        CGRectDivide(rect, &mySlice, &myRemainder, distance, edge)
//:        return (mySlice, myRemainder)
//:    }
//:    
//:    func splitHorizontal(rect: CGRect, 
//:                         ratio: CGSize) -> (CGRect, CGRect) {
//:                         
//:        return splitRect(rect, ratio, CGRectEdge.MinXEdge)
//:    }
//:    
//:    func splitVertical(rect: CGRect, 
//:                       ratio: CGSize) -> (CGRect, CGRect) {
//:                       
//:        return splitRect(rect, ratio, CGRectEdge.MinYEdge)
//:    }
//:    
//:    extension CGRect {
//:        init(center: CGPoint, size: CGSize) {
//:            let origin = CGPointMake(center.x - size.width/2, 
//:                                     center.y - size.height/2)
//:            self.init(origin: origin, size: size)
//:        }
//:    }
//:    
//:    // A 2-D Vector
//:    struct Vector2D {
//:        let x: CGFloat
//:        let y: CGFloat
//:        
//:        var point : CGPoint { return CGPointMake(x, y) }
//:        
//:        var size : CGSize { return CGSizeMake(x, y) }
//:    }
//:    
//:    func *(m: CGFloat, v: Vector2D) -> Vector2D {
//:        return Vector2D(x: m * v.x, y: m * v.y)
//:    }
//:    
//:    extension Dictionary {
//:        var keysAndValues: [(Key, Value)] {
//:            var result: [(Key, Value)] = []
//:            for item in self {
//:                result.append(item)
//:            }
//:            return result
//:        }
//:    }
//:    
//:    func normalize(input: [CGFloat]) -> [CGFloat] {
//:        let maxVal = input.reduce(0) { max($0, $1) }
//:        return input.map { $0 / maxVal }
//:    }
//:

