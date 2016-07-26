// The MIT License (MIT)
//
// Copyright (c) 2016 Hatena Co., Ltd.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import Foundation

enum APIError: ErrorType {
    case EmptyBody
    case UnexpectedResponseType
}

enum HTTPMethod: String {
    case OPTIONS
    case GET
    case HEAD
    case POST
    case PUT
    case DELETE
    case TRACE
    case CONNECT
}

protocol APIEndpoint {
    var URL: NSURL { get }
    var method: HTTPMethod { get }
    var query: Parameters? { get }
    var headers: Parameters? { get }
    associatedtype ResponseType: JSONDecodable
}

extension APIEndpoint {
    var method: HTTPMethod {
        return .GET
    }
    var query: Parameters? {
        return nil
    }
    var headers: Parameters? {
        return nil
    }
}

extension APIEndpoint {
    private var URLRequest: NSURLRequest {
        let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: true)
        components?.queryItems = query?.parameters.map(NSURLQueryItem.init)
        let req = NSMutableURLRequest(URL: components?.URL ?? URL)
        req.HTTPMethod = method.rawValue
        for case let (key, value?) in headers?.parameters ?? [:] {
            req.addValue(value, forHTTPHeaderField: key)
        }
        return req
    }

    func request(session: NSURLSession, callback: (APIResult<ResponseType>) -> Void) -> NSURLSessionDataTask {
        let task = session.dataTaskWithRequest(URLRequest) { (data, response, error) in
            if let e = error {
                callback(.Failure(e))
            } else if let data = data {
                do {
                    guard let dic = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject] else {
                        throw APIError.UnexpectedResponseType
                    }
                    let response = try ResponseType(JSON: JSONObject(JSON: dic))
                    callback(.Success(response))
                } catch {
                    callback(.Failure(error))
                }
            } else {
                callback(.Failure(APIError.EmptyBody))
            }
        }
        task.resume()
        return task
    }
}

enum APIResult<Response> {
    case Success(Response)
    case Failure(ErrorType)
}

struct Parameters: DictionaryLiteralConvertible {
    typealias Key = String
    typealias Value = String?
    private(set) var parameters: [Key: Value] = [:]

    init(dictionaryLiteral elements: (Parameters.Key, Parameters.Value)...) {
        for case let (key, value?) in elements {
            parameters[key] = value
        }
    }
}
