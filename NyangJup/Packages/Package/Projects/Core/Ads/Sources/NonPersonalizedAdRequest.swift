import GoogleMobileAds

enum NonPersonalizedAdRequest {
    static func make() -> Request {
        let request = Request()
        let extras = Extras()
        extras.additionalParameters = ["npa": "1"]
        request.register(extras)
        return request
    }
}
