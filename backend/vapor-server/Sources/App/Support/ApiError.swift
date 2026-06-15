import Vapor

/// Domain error rendered to clients as `{ "code": ..., "message": ... }`
/// with a specific HTTP status (see `ApiErrorMiddleware` and contracts/openapi.yaml).
struct ApiError: Error, Sendable {
    let status: HTTPResponseStatus
    let code: String
    let message: String

    static let recordNotAvailable = ApiError(
        status: .notFound,
        code: "RECORD_NOT_AVAILABLE",
        message: "El registro ya no está disponible."
    )

    static let ingestionInProgress = ApiError(
        status: .conflict,
        code: "INGESTION_IN_PROGRESS",
        message: "Ya hay una ingesta en curso."
    )

    static let invalidFile = ApiError(
        status: .unprocessableEntity,
        code: "INVALID_FILE",
        message: "El archivo no es un .xlsx legible."
    )

    static func fileNotFound(_ name: String) -> ApiError {
        ApiError(
            status: .notFound,
            code: "FILE_NOT_FOUND",
            message: "No se encontró \(name) en la ruta configurada."
        )
    }

    static func missingRequiredColumns(_ columns: [String]) -> ApiError {
        ApiError(
            status: .unprocessableEntity,
            code: "MISSING_REQUIRED_COLUMNS",
            message: "Faltan columnas obligatorias: \(columns.joined(separator: ", "))."
        )
    }
}

/// JSON body shape for an API error response.
struct ApiErrorBody: Content {
    let code: String
    let message: String
}
