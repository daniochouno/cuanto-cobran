package info.danielmartinez.cuantocobran.state

import info.danielmartinez.cuantocobran.data.RecordNotAvailableException
import info.danielmartinez.cuantocobran.data.SalariesApi
import info.danielmartinez.cuantocobran.domain.SalaryDetail
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/** Drives the record detail screen: Loading → Content / Error(not-available|network). */
class DetailStateHolder(
    private val api: SalariesApi,
    private val scope: CoroutineScope,
) {
    private val _state = MutableStateFlow<UiState<SalaryDetail>>(UiState.Loading)
    val state: StateFlow<UiState<SalaryDetail>> = _state.asStateFlow()

    fun load(id: String) {
        _state.value = UiState.Loading
        scope.launch {
            _state.value = try {
                UiState.Content(api.fetchSalaryDetail(id))
            } catch (e: RecordNotAvailableException) {
                UiState.Error(ErrorKind.NOT_AVAILABLE, retryable = false)
            } catch (e: Exception) {
                UiState.Error(ErrorKind.NETWORK, retryable = true)
            }
        }
    }
}
