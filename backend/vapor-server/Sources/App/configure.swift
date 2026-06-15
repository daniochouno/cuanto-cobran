import Vapor
import Fluent
import FluentPostgresDriver
import Foundation

/// Configures database, migrations, middleware, JSON coding, and routes.
public func configure(_ app: Application) async throws {
    // ISO-8601 timestamps to match the API contract's date-time fields.
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    ContentConfiguration.global.use(encoder: encoder, for: .json)
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    // PostgreSQL. Defaults suit a local Homebrew cluster (current user, no password).
    let configuration = SQLPostgresConfiguration(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? NSUserName(),
        password: Environment.get("DATABASE_PASSWORD"),
        database: Environment.get("DATABASE_NAME") ?? "cuanto_cobran",
        tls: .disable
    )
    app.databases.use(.postgres(configuration: configuration), as: .psql)

    app.migrations.add(CreateDatasetAndSalaryRecord())

    // Default error middleware (outer) handles unexpected errors; ApiErrorMiddleware
    // (inner) renders our domain errors as { code, message }.
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    app.middleware.use(ApiErrorMiddleware())

    try routes(app)
}
