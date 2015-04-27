

class Box<T> {
    let unbox: T
    init(_ value: T) { self.unbox = value }
}
func all<T> (xs : [T], predicate : T -> Bool) -> Bool {
    for x in xs {
        if !predicate(x) {
            return false
        }
    }
    return true
}

//: 
//: Purely Functional Data Structures
//: =================================
//: 
//: In the previous chapter, we saw how to use enumerations to define
//: specific types tailored to the application you are developing. In this
//: chapter, we will define *recursive* enumerations and show how these can
//: be used to define data structures that are both efficient and
//: persistent.
//: 
//: Binary Search Trees
//: -------------------
//: 
//: When Swift was released, it did not have a library for manipulating
//: sets, like Objective-C's `NSSet` library. While we could have written a
//: Swift wrapper around `NSSet` — like we did for Core Image and the
//: `String` initializer — we will instead explore a slightly different
//: approach. Our aim is, once again, not to define a complete library for
//: manipulating sets in Swift, but rather to demonstrate how recursive
//: enumerations can be used to define efficient data structures.
//: 
//: In our little library, we will implement the following four operations:
//: 
//: -   `emptySet` — returns an empty set
//: -   `isEmptySet` — checks whether or not a set is empty
//: -   `setContains` — checks whether or not an element is in a set
//: -   `setInsert` — adds an element to an existing set
//: 
//: As a first attempt, we may use arrays to represent sets. These four
//: operations are almost trivial to implement:
//: 

func emptySet<T>() -> Array<T> {
    return []
}

func isEmptySet<T>(set: [T]) -> Bool {
    return set.isEmpty
}

func setContains<T: Equatable>(x: T, set: [T]) -> Bool {
    return contains(set, x)
}

func setInsert<T: Equatable>(x: T, set:[T]) -> [T] {
     return setContains(x, set) ? set : [x] + set
}

//: 
//: While simple, the drawback of this implementation is that many of the
//: operations perform linearly in the size of the set. For large sets, this
//: may cause performance problems.
//: 
//: There are several possible ways to improve performance. For example, we
//: could ensure the array is sorted and use binary search to locate
//: specific elements. Instead, we will define a *binary search tree* to
//: represent our sets. We can build a tree structure in the traditional C
//: style, maintaining pointers to subtrees at every node. However, we can
//: also define such trees directly as an enumeration in Swift, using the
//: same `Box` trick as in the last chapter:
//: 

enum Tree<T> {
    case Leaf
    case Node(Box<Tree<T>>, Box<T>, Box<Tree<T>>)
}

//: 
//: This definition states that every tree is either:
//: 
//: -   a `Leaf` without associated values, or
//: -   a `Node` with three associated values, which are the left subtree, a
//:     value stored at the node, and the right subtree. Unfortunately,
//:     limitations in the Swift compiler prevent us from storing a
//:     recursive subtree or a generic value of type `T` in the `Node`
//:     directly. One workaround is, once again, to wrap these in a `Box`
//:     explicitly, which is accepted by the compiler.
//: 
//: Before defining functions on trees, we can write a few example trees by
//: hand:
//: 

let leaf: Tree<Int> = Tree.Leaf

let five: Tree<Int> = Tree.Node(Box(leaf), Box(5), Box(leaf))

//: 
//: The `leaf` tree is empty; the `five` tree stores the value `5` at a
//: node, but both subtrees are empty. We can generalize this construction
//: and write a function that builds a tree with a single value:
//: 

func single<T>(x: T) -> Tree<T> {
    return Tree.Node(Box(Tree.Leaf), Box(x), Box(Tree.Leaf))
}

//: 
//: Just as we saw in the previous chapter, we can write functions that
//: manipulate trees using switch statements. As the `Tree` enumeration
//: itself is recursive, it should come as no surprise that many functions
//: that we write over trees will also be recursive. For example, the
//: following function counts the number of elements stored in a tree:
//: 

func count<T>(tree: Tree<T>) -> Int {
    switch tree {
        case let Tree.Leaf:
            return 0
        case let Tree.Node(left, x, right):
            return 1 + count(left.unbox) + 
                   count(right.unbox)
    }
}

//: 
//: In the base case for leaves, we can return `0` immediately. The case for
//: nodes is more interesting: we compute the number of elements stored in
//: both subtrees *recursively* (after unboxing the subtrees). We then
//: return their sum, and add `1` to account for the value `x` stored at
//: this node.
//: 
//: Similarly, we can write an `elements` function that calculates the array
//: of elements stored in a tree:
//: 

func elements<T>(tree: Tree<T>) -> [T] {
    switch tree {
        case let Tree.Leaf:
            return []
        case let Tree.Node(left, x, right):
            return elements(left.unbox) + [x.unbox] + 
                   elements(right.unbox)
    }
}

//: 
//: Note that we need also need to unbox the elements stored in the tree
//: explicitly, writing `x.unbox` to access the underlying value of type
//: `T`.
//: 
//: Now let's return to our original goal, which is writing an efficient set
//: library using trees. We have obvious choices for the `isEmptySet` and
//: `emptySet` functions:
//: 

func emptySet<T>() -> Tree<T> {
    return Tree.Leaf
}

func isEmptySet<T>(tree: Tree<T>) -> Bool {
    switch tree {
        case let Tree.Leaf:
            return true
        case let Tree.Node(_, _, _):
            return false
    }
}

//: 
//: Note that in the `Node` case for the `isEmptySet` function, we do not
//: need to refer to the subtrees or the value stored at the node, but can
//: immediately return `false`. Correspondingly, we can put wildcard
//: patterns for the three values associated with a `Node`, indicating they
//: are not used in this case branch.
//: 
//: If we try to write naive versions of `setInsert` and `setContains`,
//: however, it seems that we have not gained much. If we restrict ourselves
//: to *binary search trees*, however, we can perform much better. A
//: (non-empty) tree is said to be a binary search tree if all of the
//: following conditions are met:
//: 
//: -   all the values stored in the left subtree are *less* than the value
//:     stored at the root
//: -   all the values stored in the right subtree are *greater* than the
//:     value stored at the root
//: -   both the left and right subtrees are binary search trees
//: 
//: We can write an (inefficient) check to ascertain if a `Tree` is a binary
//: search tree or not:
//: 

func isBST<T: Comparable>(tree: Tree<T>) -> Bool {
    switch tree {
        case Tree.Leaf:
            return true
        case let Tree.Node(left, x, right):
            let leftElements = elements(left.unbox)
            let rightElements = elements(right.unbox)
            return all(leftElements) { y in y < x.unbox }
                   && all(rightElements) { y in y > x.unbox }
                   && isBST(left.unbox)
                   && isBST(right.unbox)
    }
}

//: 
//: The `all` function checks if a property holds for all elements in an
//: array. It is defined in the appendix of this book.
//: 
//: The crucial property of binary search trees is that they admit an
//: efficient lookup operation, akin to binary search in an array. As we
//: traverse the tree to determine whether or not an element is in the tree,
//: we can rule out (up to) half of the remaining elements in every step.
//: For example, here is one possible definition of the `setContains`
//: function that determines whether or not an element occurs in the tree:
//: 

func setContains<T: Comparable>(x: T, tree: Tree<T>) -> Bool {
    switch tree {
        case Tree.Leaf:
            return false
        case let Tree.Node(left, y, right) where x == y.unbox:
            return true
        case let Tree.Node(left, y, right) where x < y.unbox:
            return setContains(x, left.unbox)
        case let Tree.Node(left, y, right) where x > y.unbox:
            return setContains(x, right.unbox)
        default:
            fatalError("The impossible occurred")
    }
}

//: 
//: The `setContains` function now distinguishes four possible cases:
//: 
//: -   If the `tree` is empty, the `x` is not in the tree and we return
//:     false.
//: -   If the `tree` is non-empty and the value stored at its root is equal
//:     to `x`, we return true.
//: -   If the `tree` is non-empty and the value stored at its root is
//:     greater than `x`, we know that if `x` is in the tree, it must be in
//:     the left subtree. Hence, we recursively search for `x` in the left
//:     subtree.
//: -   Similarly, if `x` is greater than the value stored at the root, we
//:     proceed by searching the right subtree.
//: 
//: Unfortunately, the Swift compiler is not clever enough to see that these
//: four cases cover all the possibilities, so we need to insert a dummy
//: default case.
//: 
//: Insertion searches through the binary search tree in exactly the same
//: fashion:
//: 

func setInsert<T: Comparable>(x: T, tree: Tree<T>) -> Tree<T> {
    switch tree {
        case Tree.Leaf:
            return single(x)
        case let Tree.Node(left, y, right) where x == y.unbox:
            return tree
        case let Tree.Node(left, y, right) where x < y.unbox:
            return Tree.Node(Box(setInsert(x, left.unbox)), 
                             y, right)
        case let Tree.Node(left, y, right) where x > y.unbox:
            return Tree.Node(left, y, 
                             Box(setInsert(x, right.unbox)))
        default:
            fatalError("The impossible occurred")
    }
}

//: 
//: Instead of checking whether or not the element occurs, `setInsert` finds
//: a suitable location to add the new element. If the tree is empty, it
//: builds a tree with a single element. If the element is already present,
//: it returns the original tree. Otherwise, the `setInsert` function
//: continues recursively, navigating to a suitable location to insert the
//: new element.
//: 
//: The worst-case performance of `setInsert` and `setContains` on binary
//: search trees is still linear — after all, we could have a very
//: unbalanced tree, where every left subtree is empty. More clever
//: implementations, such as 2-3 trees, AVL trees, or red-black trees, avoid
//: this by maintaining the invariant that each tree is suitably balanced.
//: Furthermore, we haven't written a `delete` operation, which would also
//: require rebalancing. These are tricky operations for which there are
//: plenty of well-documented implementations in the literature — once
//: again, this example serves as an illustration of working with recursive
//: enumerations and does not pretend to be a complete library.
//: 
//: Autocompletion Using Tries
//: --------------------------
//: 
//: Now that we've seen binary trees, this last section will cover a more
//: advanced and purely functional data structure. Suppose that we want to
//: write our own autocompletion algorithm — given a history of searches and
//: the prefix of the current search, we should compute an array of possible
//: completions.
//: 
//: Using arrays, the solution is entirely straightforward:
//: 
//:
//:    func autocomplete(history: [String], 
//:                       textEntered: String) -> [String] {
//:                       
//:        return history.filter { string in 
//:            string.hasPrefix(textEntered)
//:        }
//:    }
//:
//: 
//: Unfortunately, this function is not very efficient. For large histories
//: and long prefixes, it may be too slow. Once again, we could improve
//: performance by keeping the history sorted and using some kind of binary
//: search on the history array. Instead, we will explore a different
//: solution, using a custom data structure tailored for this kind of query.
//: 
//: *Tries*, also known as digital search trees, are a particular kind of
//: ordered tree. Typically, tries are used to look up a string, which
//: consists of a list of characters. Instead of storing strings in a binary
//: search tree, it can be more efficient to store them in a structure that
//: repeatedly branches over the strings' constituent characters.
//: 
//: Previously, the binary `Tree` type had two subtrees at every node.
//: Tries, on the other hand, do not have a fixed number of subtrees at
//: every node, but instead (potentially) have subtrees for every character.
//: For example, we could visualize a trie storing the string "cat," "car,"
//: "cart," and "dog" as follows:
//: 
//: *Playgrounds don't contain images, please see the book*
//: 
//: To determine if the string "care" is in the trie, we follow the path
//: from the root, along the edges labeled 'c,' 'a,' and 'r.' As the node
//: labeled 'r' does not have a child labeled with 'e,' the string "care" is
//: not in this trie. The string "cat" is in the trie, as we can follow a
//: path from the root along edges labeled 'c,' 'a,' and 't.'
//: 
//: How can we represent such tries in Swift? As a first attempt, we write a
//: struct storing a dictionary, mapping characters to subtries at every
//: node:
//: 
//:
//:    struct Trie {
//:        let children: [Character: Trie]
//:    }
//:
//: 
//: There are two improvements we would like to make to this definition.
//: First of all, we need to add some additional information to the node.
//: From the example trie above, you can see that by adding "cart" to the
//: trie, all the prefixes of "cart" — namely "c," "ca," and "car" — also
//: appear in the trie. As we may want to distinguish between prefixes that
//: are or are not in the trie, we will add an additional boolean, `isElem`,
//: to every node. This boolean indicates whether or not the current string
//: is in the trie. Finally, we can define a generic trie that is no longer
//: restricted to only storing characters. Doing so yields the following
//: definition of tries:
//: 

struct Trie<T : Hashable> {
    let isElem : Bool
    let children : [T: Trie<T>]
}

//: 
//: In the text that follows, we will sometimes refer to the keys of type
//: `[T]` as strings, and values of type `T` as characters. This is not very
//: precise — as `T` can be instantiated with a type different than
//: characters, and a string is not the same as `[Character]` — but we hope
//: it does appeal to the intuition of tries storing a collection of
//: strings.
//: 
//: Before defining our autocomplete function on tries, we will write a few
//: simple definitions to warm up. For example, the empty trie consists of a
//: node with an empty dictionary:
//: 

func empty<T: Hashable>() -> Trie<T> {
    return Trie(isElem:false,  children: [:])
}

//: 
//: If we had chosen to set the boolean stored in the empty trie to true
//: rather than false, the empty string would be a member of the empty trie
//: — which is probably not the behavior that we want.
//: 
//: Next, we define a function to flatten a trie into an array containing
//: all its elements:
//: 

func elements<T: Hashable>(trie: Trie<T>) -> [[T]] {
    var result: [[T]] = trie.isElem ? [[]] : []
    for (key, value) in trie.children {
        result += elements(value).map { xs in [key] + xs }
    }
    return result
}

//: 
//: This function is a bit tricky. It starts by checking if the current root
//: is marked as a member of the trie or not. If it is, the trie contains
//: the empty key; if it is not, the `result` variable is initialized to the
//: empty array. Next, it traverses the dictionary, computing the elements
//: of the subtries — this is done by the call `elements(value)`. Finally,
//: the 'character' associated with every subtrie is added to the front of
//: the elements of that subtrie — this is taken care of by the `map`
//: function.
//: 
//: Next, we would like to define lookup and insertion functions. Before we
//: do so, however, we will need a few auxiliary functions. We have
//: represented keys as an array. While our tries are defined as (recursive)
//: structs, arrays are not. Yet it can still be useful to traverse an array
//: recursively. To make this a bit easier, we define the following
//: extension on arrays:
//: 

extension Array {
    var decompose : (head: T, tail: [T])? {
      return (count > 0) ? (self[0], Array(self[1..<count])) : nil
    }
}

//: 
//: The `decompose` function checks whether or not an array is empty. If it
//: is empty, it returns `nil`; if the array is not empty, it returns a
//: tuple containing both the first element of the array and the tail or
//: remainder of the array, with the first element removed. We can
//: recursively traverse an array by repeatedly calling `decompose` until it
//: returns `nil` and the array is empty.
//: 
//: For example, we can use the `decompose` function to sum the elements of
//: an array recursively, without using a for loop or reduce:
//: 

func sum(xs: [Int]) -> Int {
    if let (head, tail) = xs.decompose {
        return (head + sum(tail))
    } else {
        return 0
    }
}

//: 
//: Another less obvious example for a recursive implementation using
//: `decompose` is to rewrite our `qsort` function from [Chapter
//: 6](#quickcheck):
//: 

func qsort(var input: [Int]) -> [Int] {
  if let (pivot, rest) = input.decompose {
        let lesser = rest.filter { $0 < pivot }
        let greater = rest.filter { $0 >= pivot }
        return qsort(lesser) + [pivot] + qsort(greater)
    } else {
        return []
    }
}

//: 
//: Back to our original problem — we can now use the `decompose` helper on
//: arrays to write a lookup function that, given an array of `T`s,
//: traverses a trie to determine whether or not the corresponding key is
//: stored:
//: 

func lookup<T: Hashable>(key: [T], trie: Trie<T>) -> Bool {
    if let (head, tail) = key.decompose {
        if let subtrie = trie.children[head] {
            return lookup(tail, subtrie)
        } else {
            return false
        }
    } else {
        return trie.isElem
    }
}

//: 
//: Here we can distinguish three cases:
//: 
//: -   The key is non-empty — in this case, we look up the subtrie
//:     corresponding to the first element of the key. If this also exists,
//:     we make a recursive call, looking up the tail of the key in this
//:     subtrie.
//: -   The key is non-empty, but the corresponding subtrie does not exist —
//:     in this case, we simply return false, as the key is not included in
//:     the trie.
//: -   The key is empty — in this case, we return `isElem`, the boolean
//:     indicating whether or not the string described by the current node
//:     is in the trie or not.
//: 
//: We can adapt `lookup` to return the subtrie, containing all the elements
//: that have some prefix:
//: 

func withPrefix<T: Hashable>(prefix: [T], 
                             trie: Trie<T>) -> Trie<T>? {

    if let (head, tail) = prefix.decompose {
        if let remainder = trie.children[head] {
            return withPrefix(tail, remainder)
        } else {
            return nil
        }
    } else {
        return trie
    }
}

//: 
//: The only difference with the `lookup` function is that we no longer
//: return the `isElem` boolean, but instead return the whole subtrie,
//: containing all the elements with the argument prefix.
//: 
//: Finally, we can redefine our `autocomplete` function to use the more
//: efficient tries data structure:
//: 

func autocomplete<T: Hashable>(key: [T], 
                               trie: Trie<T>) -> [[T]] {
    if let prefixTrie = withPrefix(key, trie) {
        return elements(prefixTrie)
    } else {
        return []
    }
}

//: 
//: To compute all the strings in a trie with a given prefix, we simply call
//: the `withPrefix` function and extract the elements from the resulting
//: trie, if it exists. If there is no subtrie with the given prefix, we
//: simply return the empty array.
//: 
//: We can use the same pattern of decomposing the key to create tries. For
//: example, we can create a new trie storing only a single element, as
//: follows:
//: 

func single<T: Hashable>(key : [T]) -> Trie<T> {
    if let (head,tail) = key.decompose {
        let children = [head: single(tail)]
        return Trie(isElem: false, children: children)
    } else {
        return Trie(isElem: true, children: [:])
    }
}

//: 
//: Once again, we distinguish two cases:
//: 
//: -   If the input key is empty, we create a new trie, storing the empty
//:     string (`isElem:true`) with no children.
//: 
//: -   If the input key is non-empty and can be decomposed in a `head` and
//:     `tail`, we recursively create a trie from the `tail`. We then create
//:     a new dictionary of children, storing this trie at the `head` entry.
//:     Finally, we create the trie from the dictionary, and as the input
//:     key is non-empty, we set `isElem` to `false`.
//: 
//: To populate a trie, we define the following insertion function:
//: 

func insert<T:Hashable>(key: [T], trie: Trie<T>) -> Trie<T> {
    if let (head,tail) = key.decompose {
        if let nextTrie = trie.children[head] {
            var newChildren = trie.children
            newChildren[head] = insert(tail,nextTrie)
            return Trie(isElem: trie.isElem, children: newChildren)
        } else {
            var newChildren = trie.children
            newChildren[head] = single(tail)
            return Trie(isElem: trie.isElem, children: newChildren)
        }
    } else {
      return Trie(isElem: true, children: trie.children)
    }
}

//: 
//: The insertion function distinguishes three cases:
//: 
//: -   If the key is non-empty and the `head` of the key already occurs in
//:     the `children` dictionary at the current node, we simply make a
//:     recursive call, inserting the `tail` of the key in the next trie.
//: 
//: -   If the key is non-empty and its first element, `head`, does not yet
//:     have an entry in the trie's `children` dictionary, we create a new
//:     trie storing the remainder of the key. To complete the insertion, we
//:     associate this trie with the `head` key at the current node.
//: 
//: -   If the key is empty, we set `isElem` to `true` and leave the
//:     remainder of trie unmodified.
//: 
//: ### String Tries
//: 
//: In order to use our autocompletion algorithm, we can now write a few
//: wrappers that make working with string tries a bit easier. First, we can
//: write a simple wrapper to build a trie from a list of words. It starts
//: with the empty trie, and then inserts each word, yielding a trie with
//: all the words combined. Because our tries work on arrays, we need to
//: convert every string into an array of characters.
//: 

func buildStringTrie(words: [String]) -> Trie<Character> {
    return reduce(words, empty()) { trie, word in
        insert(Array(word), trie)
    }
}

//: 
//: Finally, to get a list of all our autocompleted words, we can call our
//: previously defined `autocomplete` function, turning the result back into
//: strings. Note how we prepend the input string to each result. This is
//: because the `autocomplete` function only returns the rest of the word,
//: excluding the common prefix.
//: 

func autocompleteString(word: String,
                        knownWords: Trie<Character>)
                       -> [String] {
    return autocomplete(Array(word), knownWords).map {
      word + String($0)
    }
}

//: 
//: To test our functions, we can use a simple list of words, build a trie,
//: and list the autocompletions:
//: 
let contents = ["cat", "car", "cart", "dog"]
let trieOfWords: Trie<Character> = buildStringTrie(contents)
autocompleteString("car", trieOfWords)
//: 
//: Currently, our interface only allows us to insert arrays. It is easy to
//: create an alternative `insert` function that allows us to insert any
//: kind of collection. The type signature would be more complicated, but
//: the body of the function would stay the same.
//: 
//:
//:    func insertSlice<Key, E where
//:       Key: CollectionType, Key: Sliceable,
//:       E: Hashable, E == Key.Generator.Element,
//:       Key.SubSlice == Key> (key: Key, trie: Trie<E>) -> Trie<E> {
//:
//: 
//: This chapter comes with a sample project that loads all the words from
//: `/usr/share/dict/words`, and builds a trie of them using the
//: `buildStringTrie` function above. Building up a trie of almost 250,000
//: words takes up quite a bit of time. However, we could optimize this by
//: writing an alternative function to build a trie from an already sorted
//: list of words. This is also highly parallelizable; it would be possible
//: to build the trie for all words starting with letters from 'a' to 'm,'
//: and the letters from 'n' to 'z' in parallel, and combining the results.
//: 
//: Discussion
//: ----------
//: 
//: These are but two examples of writing efficient, immutable data
//: structures using enumerations and structs. There are many others in
//: Chris Okasaki's *Purely Functional Data Structures* [-@okasaki], which
//: is a standard reference on the subject. Interested readers may also want
//: to read Ralf Hinze and Ross Paterson's work on finger trees
//: [-@hinze-paterson], which are general-purpose purely functional data
//: structures with numerous applications. Finally,
//: [StackOverflow](http://objc.io/fpinswift/19) has a fantastic list of
//: more recent research in this area.
//: 
