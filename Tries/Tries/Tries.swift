//
//  Tries.swift
//  Tries
//
//  Created by Chris Eidhof on 02/04/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.


import Foundation


public class Box<T> {
    public let unbox: T
    public init(_ value: T) { self.unbox = value }
}
public func all<T> (xs : [T], predicate : T -> Bool) -> Bool {
    for x in xs {
        if !predicate(x) {
            return false
        }
    }
    return true
}

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

enum Tree<T> {
    case Leaf
    case Node(Box<Tree<T>>, Box<T>, Box<Tree<T>>)
}

let leaf: Tree<Int> = Tree.Leaf

let five: Tree<Int> = Tree.Node(Box(leaf), Box(5), Box(leaf))

func single<T>(x: T) -> Tree<T> {
    return Tree.Node(Box(Tree.Leaf), Box(x), Box(Tree.Leaf))
}

func count<T>(tree: Tree<T>) -> Int {
    switch tree {
    case let Tree.Leaf:
        return 0
    case let Tree.Node(left, x, right):
        return 1 + count(left.unbox) +
            count(right.unbox)
    }
}

func elements<T>(tree: Tree<T>) -> [T] {
    switch tree {
    case let Tree.Leaf:
        return []
    case let Tree.Node(left, x, right):
        return elements(left.unbox) + [x.unbox] +
            elements(right.unbox)
    }
}

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





struct Trie<T : Hashable> {
    let isElem : Bool
    let children : [T: Trie<T>]
}

func empty<T: Hashable>() -> Trie<T> {
    return Trie(isElem:false,  children: [T: Trie<T>]())
}

func elements<T: Hashable>(trie: Trie<T>) -> [[T]] {
    var result: [[T]] = trie.isElem ? [[]] : []
    for (key, value) in trie.children {
        result += elements(value).map {xs in [key] + xs}
    }
    return result
}

extension Array {
    var decompose : (head: T, tail: [T])? {
        return (count > 0) ? (self[0], Array(self[1..<count])) : nil
    }
}

func sum(xs: [Int]) -> Int {
    if let (head, tail) = xs.decompose {
        return (head + sum(tail))
    } else {
        return 0
    }
}

func qsort(var input: [Int]) -> [Int] {
    if let (pivot, rest) = input.decompose {
        let lesser = rest.filter { $0 < pivot }
        let greater = rest.filter { $0 >= pivot }
        return qsort(lesser) + [pivot] + qsort(greater)
    } else {
        return []
    }
}

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

func autocomplete<T: Hashable>(key: [T],
    trie: Trie<T>) -> [[T]] {
        if let prefixTrie = withPrefix(key, trie) {
            return elements(prefixTrie).map { element in
                key + element
            }
        } else {
            return []
        }
}

func single<T: Hashable, C where C: CollectionType, C: Sliceable, T: Hashable, T == C.Generator.Element, C.SubSlice == C>(key : C) -> Trie<T> {
    if let (head,tail) = decompose(key) {
        let children = [head: single(tail)]
        return Trie(isElem: false, children: children)
    } else {
        return Trie(isElem: true, children: [:])
    }
}

func insert<T:Hashable>(key: [T], trie: Trie<T>) -> Trie<T> {
    return insertSlice(key[key.startIndex..<key.endIndex], trie)
}

func insertSlice<C, T where C: CollectionType, C: Sliceable, T: Hashable, T == C.Generator.Element, C.SubSlice == C>(key: C, trie: Trie<T>) -> Trie<T> {
    if let (head,tail) = decompose(key) {
        if let nextTrie = trie.children[head] {
            var newChildren = trie.children
            newChildren[head] = insertSlice(tail,nextTrie)
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



func decompose<C, T where C: CollectionType, C: Sliceable, T == C.Generator.Element, C.SubSlice == C>(coll: C) -> (T, C)? {
    if count(coll) > 0 {
        if let head = first(coll) {
            let tail = dropFirst(coll)
            return (head, tail)
        }
    }
    return nil
}

func autocompleteString(word: String, knownWords: Trie<Character>) -> [String] {
    return autocomplete(Array(word), knownWords).map { String($0) }
}

func buildStringTrie(words: [String], callback: Double -> ()) -> Trie<Character> {
    var count = 0
    let granularity = words.count/100
    return reduce(words, empty()) { trie, word in
        count++
        if (count % granularity == 0) {
            callback(Double(count) / Double(words.count))
        }
        return insertSlice(word, trie)
    }
}