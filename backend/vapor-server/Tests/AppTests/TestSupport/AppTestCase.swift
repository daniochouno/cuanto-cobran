import XCTVapor
import Foundation
@testable import App

/// Spin up a test `Application` against the `cuanto_cobran_test` database,
/// migrate it, run the body, then revert and shut down.
func withApp(_ body: (Application) async throws -> Void) async throws {
    setenv("DATABASE_NAME", "cuanto_cobran_test", 1)
    let app = try await Application.make(.testing)
    do {
        try await configure(app)
        try await app.autoRevert()   // clean slate if a prior run left tables
        try await app.autoMigrate()
        try await body(app)
        try await app.autoRevert()
    } catch {
        try? await app.autoRevert()
        try? await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}

/// Absolute path to the bundled `Retribuciones.xlsx` test fixture.
func fixtureXLSXPath() throws -> String {
    let url = try XCTUnwrap(
        Bundle.module.url(forResource: "Retribuciones", withExtension: "xlsx"),
        "Retribuciones.xlsx fixture missing from AppTests bundle"
    )
    return url.path
}
