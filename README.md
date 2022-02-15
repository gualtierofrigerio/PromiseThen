# PromiseThen

An implementation of Future and Promises with the ability to chain multiple Promises.
See my blog post [Callbacks vs Promises](https://www.gfrigerio.com/callbacks-vs-promises/) for examples and details 

## How to use it

Use a Promise to avoid completion handlers

```swift
func getData(atURL url: URL) -> Promise<Data> {
    let promise = Promise<Data>()
    let session = URLSession.shared
    let task = session.dataTask(with: url) { (data, response, error) in
        if let err = error {
            promise.reject(error: err)
        }
        else {
            if let data = data {
                promise.resolve(value: data)
            }
            else {
                let unknowError = NSError(domain: "", code : 0, userInfo: nil)
                promise.reject(error: unknowError)
            }
        }
    }
    task.resume()
    return promise
}


let p = getData()
p.observe { promiseReturn in
    switch promiseReturn {
    case .success(let data):
        // here is our data!
    case .error(let error):
        // we have an error :(
    }
```

it is possible to chain multiple operations by calling then

```swift
func getUsersWithMergedData() -> Promise<[User]> {
    return getPictures().then({self.addPicturesToAlbums($0)})
                        .then({self.addAlbumsToUsers($0)})
}
```

you can optionally specify an object conforming to CancellableTask to cancel a task from the Promise.
This example cancels a URLSessionDataTask

```swift
struct URLCancellableTask: CancellableTask {
    var dataTask: URLSessionDataTask
    
    func cancel() {
        dataTask.cancel()
    }
}

func getData(atURL url: URL) -> Promise<Data> {
    let promise = Promise<Data>()
    let session = URLSession.shared
    let task = session.dataTask(with: url) { (data, response, error) in
        if let error = error {
            promise.reject(error: NetworkClientError.networkError(error))
            return
        }
        if let data = data {
            promise.resolve(value: data)
        }
        else {
            promise.reject(error: NetworkClientError.noData)
        }
    }
    promise.setCancellableTask(URLCancellableTask(dataTask: task))
    task.resume()
    return promise
}

let promise = getData(atURL: url)
promise.cancel()
```

## How to install

Use SPM by importing the package at this link https://github.com/gualtierofrigerio/PromiseThen.git
