import Vapor
import Foundation

/// Admin endpoint that triggers ingestion of the configured `.xlsx` file.
/// No authentication in this increment (local trusted operator — see spec).
struct AdminController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let admin = routes.grouped("api", "v1", "admin")
        admin.post("ingest", use: ingest)
    }

    /// `POST /api/v1/admin/ingest` — reads `INGEST_FILE_PATH` (default
    /// `Retribuciones.xlsx` in the working directory) and replaces the dataset.
    @Sendable
    func ingest(req: Request) async throws -> IngestionReport {
        let path = Environment.get("INGEST_FILE_PATH") ?? "Retribuciones.xlsx"
        let fileName = (path as NSString).lastPathComponent

        guard FileManager.default.fileExists(atPath: path) else {
            throw ApiError.fileNotFound(fileName)
        }

        let service = IngestionService()
        return try await service.ingest(
            fileURL: URL(fileURLWithPath: path),
            sourceName: fileName,
            on: req.db
        )
    }
}
