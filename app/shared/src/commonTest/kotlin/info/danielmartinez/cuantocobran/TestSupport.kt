package info.danielmartinez.cuantocobran

import info.danielmartinez.cuantocobran.data.HttpClient
import info.danielmartinez.cuantocobran.data.HttpResponse

/** A scriptable [HttpClient] for tests: maps URLs (or suffixes) to canned responses. */
class FakeHttpClient : HttpClient {
    private val responses = mutableMapOf<String, HttpResponse>()
    var lastUrl: String? = null
        private set

    fun on(urlSuffix: String, status: Int, body: String): FakeHttpClient {
        responses[urlSuffix] = HttpResponse(status, body)
        return this
    }

    override suspend fun get(url: String): HttpResponse {
        lastUrl = url
        val match = responses.entries.firstOrNull { url.endsWith(it.key) }
        return match?.value ?: HttpResponse(500, "")
    }
}

/** Canned JSON bodies mirroring contracts/openapi.yaml (the shared contract fixtures). */
object Fixtures {
    val salariesListPopulated = """
        {
          "dataset": { "lastUpdated": "2026-06-15T10:03:52Z" },
          "items": [
            { "id": "11111111-1111-1111-1111-111111111111", "positionTitle": "PRESIDENTE DEL GOBIERNO", "institution": "Presidencia del Gobierno", "salaryAmount": 95943.96 },
            { "id": "22222222-2222-2222-2222-222222222222", "positionTitle": "MINISTRO", "institution": "Hacienda", "salaryAmount": 75000.0 }
          ]
        }
    """.trimIndent()

    val salariesListEmpty = """
        { "dataset": null, "items": [] }
    """.trimIndent()

    val salaryDetail = """
        {
          "dataset": { "lastUpdated": "2026-06-15T10:03:52Z" },
          "record": {
            "id": "11111111-1111-1111-1111-111111111111",
            "positionTitle": "PRESIDENTE DEL GOBIERNO",
            "institution": "Presidencia del Gobierno",
            "salaryAmount": 95943.96,
            "sourceRowNumber": 2,
            "extraFields": [
              { "label": "Ministerio", "value": "Presidencia del Gobierno" },
              { "label": "Año", "value": "2025" },
              { "label": "Cuota", "value": 12 },
              { "label": "Observaciones", "value": null }
            ]
          }
        }
    """.trimIndent()

    val recordNotAvailable = """
        { "code": "RECORD_NOT_AVAILABLE", "message": "El registro ya no está disponible." }
    """.trimIndent()
}
