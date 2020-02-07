//
//  Promise.swift
//
//  Created by Gualtiero Frigerio on 07/02/2020.
//  Copyright © 2019 Gualtiero Frigerio. All rights reserved.
//

import Foundation

/// The possible value returned by a Promise
/// value is returned when the promise is fulfilled with a value
/// otherwise error is returned
enum PromiseReturn<T> {
    case value(T)
    case error(Error)
}

/// Class implementing the Future/Promise concept
/// After instantiating the Promise object you can reject or resolve the promise
/// and you can subscribe to it by calling observe and check for its return value
/// of type PromiseReturn
/// It is possible to chain multiple Promise object by using then
class Promise<T> {
    
    /// Subscribe to the Promise in order to observe its return value
    /// - Parameter callback: a closure accepting PromiseReturn as a parameter
    func observe(callback: @escaping (PromiseReturn<T>) -> Void) {
        callbacks.append(callback)
        if let result = result {
            callback(result)
        }
    }
    
    /// Rejects the Promise by sending the type error to the subscribers
    /// - Parameter error: the error to pass to the subscribers
    func reject(error:Error) {
        result = .error(error)
    }
    
    /// Fulfulls the Promise by sending the value to the subscribers
    /// - Parameter value: the value to pass to the subscribers
    func resolve(value:T) {
        result = .value(value)
    }
    
    /// Combines two Promise object by accepting a Promise and returning a new one
    /// You can use this function multiple times to chain multiple Promises.
    /// The function then takes a closure as parameter, returning a new Promise,
    /// and the function itself returns a Promise of the same type.
    /// A new promise of type P is created, then observe is called to wait for the current promise to be fulfilled or rejected.
    /// The parameter passed to this function returns a promise itself,
    /// so we can observe that and finally resolve or reject the new promise of type P we created at the beginning
    /// - Parameter block:  a closure returning a new Promise of type P
    /// - Returns: a Promise of type P, the same of the closure passed as a parameter
    func then<P>(_ block:@escaping(T) -> Promise<P>) -> Promise<P> {
        let thenPromise = Promise<P>()
        observe { currentPromiseReturn in
            switch currentPromiseReturn {
            case .value(let val):
                let promise = block(val)
                promise.observe { result in
                    switch result {
                    case .value(let value):
                        thenPromise.resolve(value: value)
                    case .error(let err):
                        thenPromise.reject(error: err)
                    }
                }
            case .error(let err):
                thenPromise.reject(error: err)
            }
        }
        return thenPromise
    }
    
    // MARK: - Private
    private var callbacks = [(PromiseReturn<T>) -> Void]()
    private var result:PromiseReturn<T>? {
        didSet {
            if let res = result {
                for callback in callbacks {
                    callback(res)
                }
            }
        }
    }
}
