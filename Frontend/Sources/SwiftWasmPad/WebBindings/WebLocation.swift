import JavaScriptKit

struct Location {
    private let location = JSObject.global.location.object!
    var pathname: String { location.pathname.string! }
    var href: String { location.href.string! }
    var search: String { location.search.string! }
}

let location = Location()
