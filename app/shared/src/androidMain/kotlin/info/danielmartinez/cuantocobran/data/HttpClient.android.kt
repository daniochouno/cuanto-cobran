package info.danielmartinez.cuantocobran.data

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.net.HttpURLConnection
import java.net.URL

/** Android HTTP client backed by HttpURLConnection on the IO dispatcher. */
private class AndroidHttpClient : HttpClient {
    override suspend fun get(url: String): HttpResponse = withContext(Dispatchers.IO) {
        val connection = URL(url).openConnection() as HttpURLConnection
        try {
            connection.requestMethod = "GET"
            connection.connectTimeout = 10_000
            connection.readTimeout = 10_000
            val status = connection.responseCode
            val stream = if (status in 200..299) connection.inputStream else connection.errorStream
            val body = stream?.bufferedReader()?.use(BufferedReader::readText).orEmpty()
            HttpResponse(statusCode = status, body = body)
        } catch (e: Exception) {
            throw HttpException("GET $url failed", e)
        } finally {
            connection.disconnect()
        }
    }
}

actual fun platformHttpClient(): HttpClient = AndroidHttpClient()
