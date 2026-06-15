package info.danielmartinez.cuantocobran.data

import info.danielmartinez.cuantocobran.domain.SalaryDetail
import info.danielmartinez.cuantocobran.domain.SalaryList
import kotlinx.serialization.json.Json

/** Raised when a requested record is not in the active dataset (HTTP 404, FR-013). */
class RecordNotAvailableException : Exception("RECORD_NOT_AVAILABLE")

/** Client for the backend salary API. */
class SalariesApi(
    private val client: HttpClient,
    private val baseUrl: String = ApiConfig.baseUrl,
    private val json: Json = Json { ignoreUnknownKeys = true },
) {
    /** `GET /api/v1/salaries`. */
    suspend fun fetchSalaries(): SalaryList {
        val response = client.get("$baseUrl/api/v1/salaries")
        if (response.statusCode != 200) {
            throw HttpException("Unexpected status ${response.statusCode}")
        }
        return json.decodeFromString(SalaryListResponseDto.serializer(), response.body).toDomain()
    }

    /** `GET /api/v1/salaries/{id}`. Throws [RecordNotAvailableException] on 404. */
    suspend fun fetchSalaryDetail(id: String): SalaryDetail {
        val response = client.get("$baseUrl/api/v1/salaries/$id")
        when (response.statusCode) {
            200 -> return json.decodeFromString(SalaryDetailResponseDto.serializer(), response.body).toDomain()
            404 -> throw RecordNotAvailableException()
            else -> throw HttpException("Unexpected status ${response.statusCode}")
        }
    }
}
