package info.danielmartinez.cuantocobran.data

/** A minimal HTTP response: status code + raw body text. */
data class HttpResponse(val statusCode: Int, val body: String)

/** Thrown when a request fails at the transport level (no HTTP status). */
class HttpException(message: String, cause: Throwable? = null) : Exception(message, cause)

/**
 * Project-owned HTTP abstraction (Constitution Principle V: custom, no Ktor).
 * Implemented per platform via `expect`/`actual`.
 */
interface HttpClient {
    suspend fun get(url: String): HttpResponse
}

/** Creates the platform HTTP client (URLSession on iOS, HttpURLConnection on Android). */
expect fun platformHttpClient(): HttpClient
