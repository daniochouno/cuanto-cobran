@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package info.danielmartinez.cuantocobran.state

import info.danielmartinez.cuantocobran.Fixtures
import info.danielmartinez.cuantocobran.FakeHttpClient
import info.danielmartinez.cuantocobran.data.SalariesApi
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs

class StateHolderTest {

    private fun api(client: FakeHttpClient) = SalariesApi(client = client, baseUrl = "http://test")

    @Test
    fun listLoadsContent() = runTest {
        val client = FakeHttpClient().on("/api/v1/salaries", 200, Fixtures.salariesListPopulated)
        val holder = ListStateHolder(api(client), this)
        holder.load()
        advanceUntilIdle()
        val state = assertIs<UiState.Content<*>>(holder.state.value)
        val list = state.value as info.danielmartinez.cuantocobran.domain.SalaryList
        assertEquals(2, list.items.size)
    }

    @Test
    fun listEmptyState() = runTest {
        val client = FakeHttpClient().on("/api/v1/salaries", 200, Fixtures.salariesListEmpty)
        val holder = ListStateHolder(api(client), this)
        holder.load()
        advanceUntilIdle()
        assertIs<UiState.Empty>(holder.state.value)
    }

    @Test
    fun listErrorStateIsRetryable() = runTest {
        val client = FakeHttpClient().on("/api/v1/salaries", 500, "")
        val holder = ListStateHolder(api(client), this)
        holder.load()
        advanceUntilIdle()
        val error = assertIs<UiState.Error>(holder.state.value)
        assertEquals(ErrorKind.NETWORK, error.kind)
        assertEquals(true, error.retryable)
    }

    @Test
    fun detailLoadsContent() = runTest {
        val id = "11111111-1111-1111-1111-111111111111"
        val client = FakeHttpClient().on("/api/v1/salaries/$id", 200, Fixtures.salaryDetail)
        val holder = DetailStateHolder(api(client), this)
        holder.load(id)
        advanceUntilIdle()
        assertIs<UiState.Content<*>>(holder.state.value)
    }

    @Test
    fun detailNotAvailableStateIsNotRetryable() = runTest {
        val client = FakeHttpClient().on("/api/v1/salaries/missing", 404, Fixtures.recordNotAvailable)
        val holder = DetailStateHolder(api(client), this)
        holder.load("missing")
        advanceUntilIdle()
        val error = assertIs<UiState.Error>(holder.state.value)
        assertEquals(ErrorKind.NOT_AVAILABLE, error.kind)
        assertEquals(false, error.retryable)
    }
}
