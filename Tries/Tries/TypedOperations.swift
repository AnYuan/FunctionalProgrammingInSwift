//
//  TypedOperations.swift
//  Tries
//
//  Created by Chris Eidhof on 02/04/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import Foundation


private class ResultOperation: NSBlockOperation {
    var result: AnyObject?
    init(block: () -> AnyObject, completion: AnyObject -> ()) {
        super.init()
        addExecutionBlock({ [weak self] in
            self?.result = block()
            })
        self.completionBlock = {
            mainThread { [weak self] in
                
                if let strongSelf = self,
                    res: AnyObject = strongSelf.result
                    where self?.cancelled == false
                {
                    completion(res)
                }
            }
        }
    }
}

// completion always gets called on the main  thread
func asyncBlock<A>(block: () -> A, completion: A -> ()) -> NSBlockOperation {
    let boxed: () -> Box<A> = { Box(block()) }
    return ResultOperation(block: boxed, completion: { result in
        if let box = result as? Box<A> {
            completion(box.unbox)
        }
    })
}

func mainThread(block: () -> ()) {
    dispatch_async(dispatch_get_main_queue(), block)
}