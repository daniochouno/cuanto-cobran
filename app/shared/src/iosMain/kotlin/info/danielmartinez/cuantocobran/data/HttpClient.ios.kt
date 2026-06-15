package info.danielmartinez.cuantocobran.data

import kotlinx.cinterop.BetaInteropApi
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.coroutines.suspendCancellableCoroutine
import platform.Foundation.NSData
import platform.Foundation.NSError
import platform.Foundation.NSHTTPURLResponse
import platform.Foundation.NSString
import platform.Foundation.NSURL
import platform.Foundation.NSURLRequest
import platform.Foundation.NSURLSession
import platform.Foundation.NSURLResponse
import platform.Foundation.NSUTF8StringEncoding
import platform.Foundation.create
import platform.Foundation.dataTaskWithRequest
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/** iOS HTTP client backed by NSURLSession. */
@OptIn(ExperimentalForeignApi::class, BetaInteropApi::class)
private class IosHttpClient : HttpClient {
    override suspend fun get(url: String): HttpResponse {
        val nsUrl = NSURL(string = url)
        val request = NSURLRequest(uRL = nsUrl)
        return suspendCancellableCoroutine { continuation ->
            val task = NSURLSession.sharedSession.dataTaskWithRequest(request) {
                data: NSData?, response: NSURLResponse?, error: NSError? ->
                if (error != null) {
                    continuation.resumeWithException(HttpException("GET $url failed: ${error.localizedDescription}"))
                    return@dataTaskWithRequest
                }
                val status = (response as? NSHTTPURLResponse)?.statusCode?.toInt() ?: -1
                val body = data?.let {
                    NSString.create(data = it, encoding = NSUTF8StringEncoding)?.toString()
                }.orEmpty()
                continuation.resume(HttpResponse(statusCode = status, body = body))
            }
            continuation.invokeOnCancellation { task.cancel() }
            task.resume()
        }
    }
}

actual fun platformHttpClient(): HttpClient = IosHttpClient()
