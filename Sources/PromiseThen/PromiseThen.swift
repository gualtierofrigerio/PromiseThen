//
//  Promise.swift
//
//  Created by Gualtiero Frigerio on 07/02/2020.
//  Copyright © 2019 Gualtiero Frigerio. All rights reserved.
//

import Foundation

/// Implement this protocol to pass an object to a Promise that can
/// be cancelled.
/// For example if you use a Promise to start a URLSessionDataTask you can
/// cancel it by wrapping the task into a type conforming to CancellableTask
public protocol CancellableTask {
    /// Cancel the task
    func cancel()
}

/// Class implementing the Future/Promise concept
/// After instantiating the Promise object you can reject or resolve the promise
/// and you can subscribe to it by calling observe and check for its return value
/// of type Result
/// It is possible to chain multiple Promise object by using then
public class Promise<T> {
    
    /// Empty initialiser needed to instantiate the class outside the package
    public init() {
        
    }
    
    /// Calls cancell on the CancebleTask object if it was set via setCancellableTask
    public func cancel() {
        cancellableTask?.cancel()
    }

    /// Subscribe to the Promise in order to observe its return value
    /// - Parameter callback: a closure accepting Result as a parameter
    public func observe(callback: @escaping (Result<T, Error>) -> Void) {
        callbacks.append(callback)
        if let result = result {
            callback(result)
        }
    }
    
    /// Rejects the Promise by sending the type error to the subscribers
    /// - Parameter error: the error to pass to the subscribers
    public func reject(error: Error) {
        result = .failure(error)
    }
    
    /// Fulfulls the Promise by sending the value to the subscribers
    /// - Parameter value: the value to pass to the subscribers
    public func resolve(value: T) {
        result = .success(value)
    }
    
    /// Sets an object conforming to CancellableTask
    /// This task can be cancelled by calling cancel() on the Promise
    /// - Parameter task: the CancellableTask to set
    public func setCancellableTask(_ task: CancellableTask) {
        cancellableTask = task
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
    public func then<P>(_ block: @escaping(T) -> Promise<P>) -> Promise<P> {
        let thenPromise = Promise<P>()
        observe { currentPromiseResult in
            switch currentPromiseResult {
            case .success(let val):
                let promise = block(val)
                promise.observe { result in
                    switch result {
                    case .success(let value):
                        thenPromise.resolve(value: value)
                    case .failure(let err):
                        thenPromise.reject(error: err)
                    }
                }
            case .failure(let err):
                thenPromise.reject(error: err)
            }
        }
        return thenPromise
    }
    
    // MARK: - Private
    private var callbacks = [(Result<T, Error>) -> Void]()
    private var cancellableTask: CancellableTask?
    private var result: Result<T,Error>? {
        didSet {
            if let res = result {
                for callback in callbacks {
                    callback(res)
                }
            }
            callbacks.removeAll()
        }
    }
}

