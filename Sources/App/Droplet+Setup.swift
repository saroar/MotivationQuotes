@_exported import Vapor

extension Droplet {
    public func setup() throws {
        try setupRoutes()
        try collection(GeneralRoutes(self))
        // Do any additional droplet setup
    }
}
