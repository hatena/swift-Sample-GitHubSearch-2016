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

protocol GitHubEndpoint: APIEndpoint {
    var path: String { get }
}

private let GitHubURL = NSURL(string: "https://api.github.com/")!

extension GitHubEndpoint {
    var URL: NSURL {
        return NSURL(string: path, relativeToURL: GitHubURL)!
    }
    var headers: Parameters? {
        return [
            "Accept": "application/vnd.github.v3+json",
        ]
    }
}

/**
 - SeeAlso: https://developer.github.com/v3/search/#search-repositories
 */
struct SearchRepositories: GitHubEndpoint {
    var path = "search/repositories"
    var query: Parameters? {
        return [
            "q"    : searchQuery,
            "page" : String(page),
        ]
    }
    typealias ResponseType = SearchResult<Repository>

    let searchQuery: String
    let page: Int
    init(searchQuery: String, page: Int) {
        self.searchQuery = searchQuery
        self.page = page
    }
}

/**
 Parse ISO 8601 format date string
 - SeeAlso: https://developer.github.com/v3/#schema
 */
private let dateFormatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    return formatter
}()

struct FormattedDateConverter: JSONValueConverter {
    typealias FromType = String
    typealias ToType = NSDate

    private let dateFormatter: NSDateFormatter

    func convert(key key: String, value: FromType) throws -> DateConverter.ToType {
        guard let date = dateFormatter.dateFromString(value) else {
            throw JSONDecodeError.UnexpectedValue(key: key, value: value, message: "Invalid date format for '\(dateFormatter.dateFormat)'")
        }
        return date
    }
}

/**
 Search result data
 - SeeAlso: https://developer.github.com/v3/search/
 */
struct SearchResult<ItemType: JSONDecodable>: JSONDecodable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [ItemType]

    init(JSON: JSONObject) throws {
        self.totalCount = try JSON.get("total_count")
        self.incompleteResults = try JSON.get("incomplete_results")
        self.items = try JSON.get("items")
    }
}

/**
 Repository data
 - SeeAlso: https://developer.github.com/v3/search/#search-repositories
 */
struct Repository: JSONDecodable {
    let id: Int
    let name: String
    let fullName: String
    let isPrivate: Bool
    let HTMLURL: NSURL
    let description: String?
    let fork: Bool
    let URL: NSURL
    let createdAt: NSDate
    let updatedAt: NSDate
    let pushedAt: NSDate?
    let homepage: String?
    let size: Int
    let stargazersCount: Int
    let watchersCount: Int
    let language: String?
    let forksCount: Int
    let openIssuesCount: Int
    let masterBranch: String?
    let defaultBranch: String
    let score: Double
    let owner: User

    init(JSON: JSONObject) throws {
        self.id = try JSON.get("id")
        self.name = try JSON.get("name")
        self.fullName = try JSON.get("full_name")
        self.isPrivate = try JSON.get("private")
        self.HTMLURL = try JSON.get("html_url")
        self.description = try JSON.get("description")
        self.fork = try JSON.get("fork")
        self.URL = try JSON.get("url")
        self.createdAt = try JSON.get("created_at", converter: FormattedDateConverter(dateFormatter: dateFormatter))
        self.updatedAt = try JSON.get("updated_at", converter: FormattedDateConverter(dateFormatter: dateFormatter))
        self.pushedAt = try JSON.get("pushed_at", converter: FormattedDateConverter(dateFormatter: dateFormatter))
        self.homepage = try JSON.get("homepage")
        self.size = try JSON.get("size")
        self.stargazersCount = try JSON.get("stargazers_count")
        self.watchersCount = try JSON.get("watchers_count")
        self.language = try JSON.get("language")
        self.forksCount = try JSON.get("forks_count")
        self.openIssuesCount = try JSON.get("open_issues_count")
        self.masterBranch = try JSON.get("master_branch")
        self.defaultBranch = try JSON.get("default_branch")
        self.score = try JSON.get("score")
        self.owner = try JSON.get("owner")
    }
}

/**
 User data
 - SeeAlso: https://developer.github.com/v3/search/#search-repositories
 */
struct User: JSONDecodable {
    let login: String
    let id: Int
    let avatarURL: NSURL
    let gravatarID: String
    let URL: NSURL
    let receivedEventsURL: NSURL
    let type: String

    init(JSON: JSONObject) throws {
        self.login = try JSON.get("login")
        self.id = try JSON.get("id")
        self.avatarURL = try JSON.get("avatar_url")
        self.gravatarID = try JSON.get("gravatar_id")
        self.URL = try JSON.get("url")
        self.receivedEventsURL = try JSON.get("received_events_url")
        self.type = try JSON.get("type")
    }
}
