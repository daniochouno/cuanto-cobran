package info.danielmartinez.cuantocobran.data

import info.danielmartinez.cuantocobran.Fixtures
import info.danielmartinez.cuantocobran.FakeHttpClient
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class SalariesApiTest {

    private fun api(client: FakeHttpClient) = SalariesApi(client = client, baseUrl = "http://test")

    @Test
    fun fetchSalariesReturnsItems() = runTest {
        val client = FakeHttpClient().on("/api/v1/salaries", 200, Fixtures.salariesListPopulated)
        val list = api(client).fetchSalaries()
        assertEquals(2, list.items.size)
        assertTrue(client.lastUrl!!.endsWith("/api/v1/salaries"))
    }

    @Test
    fun fetchSalariesEmpty() = runTest {
        val client = FakeHttpClient().on("/api/v1/salaries", 200, Fixtures.salariesListEmpty)
        assertTrue(api(client).fetchSalaries().items.isEmpty())
    }

    @Test
    fun fetchSalariesNon200Throws() = runTest {
        val client = FakeHttpClient().on("/api/v1/salaries", 503, "")
        assertFailsWith<HttpException> { api(client).fetchSalaries() }
    }

    @Test
    fun fetchDetailReturnsRecord() = runTest {
        val id = "11111111-1111-1111-1111-111111111111"
        val client = FakeHttpClient().on("/api/v1/salaries/$id", 200, Fixtures.salaryDetail)
        val detail = api(client).fetchSalaryDetail(id)
        assertEquals(id, detail.record.id)
        assertEquals(4, detail.record.extraFields.size)
    }

    @Test
    fun fetchDetail404ThrowsRecordNotAvailable() = runTest {
        val client = FakeHttpClient().on("/api/v1/salaries/missing", 404, Fixtures.recordNotAvailable)
        assertFailsWith<RecordNotAvailableException> { api(client).fetchSalaryDetail("missing") }
    }
}
