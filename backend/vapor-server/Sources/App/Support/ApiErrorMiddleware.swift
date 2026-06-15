import Vapor

/// Catches `ApiError` and renders it as the contract's `{ code, message }` body
/// with the appropriate HTTP status. Other errors propagate to Vapor's default
/// `ErrorMiddleware`.
struct ApiErrorMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        do {
            return try await next.respond(to: request)
        } catch let error as ApiError {
            let response = Response(status: error.status)
            try response.content.encode(ApiErrorBody(code: error.code, message: error.message))
            return response
        }
    }
}
