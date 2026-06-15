import Vapor

/// Registers all HTTP routes.
func routes(_ app: Application) throws {
    app.get("api", "v1", "health") { _ async -> [String: String] in
        ["status": "ok"]
    }

    try app.register(collection: SalariesController())
    try app.register(collection: AdminController())
}
