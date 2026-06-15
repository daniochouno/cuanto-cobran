package info.danielmartinez.cuantocobran.state

import info.danielmartinez.cuantocobran.data.SalariesApi
import info.danielmartinez.cuantocobran.domain.SalaryList
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/** Drives the salary list screen: Loading → Content / Empty / Error. */
class ListStateHolder(
    private val api: SalariesApi,
    private val scope: CoroutineScope,
) {
    private val _state = MutableStateFlow<UiState<SalaryList>>(UiState.Loading)
    val state: StateFlow<UiState<SalaryList>> = _state.asStateFlow()

    fun load() {
        _state.value = UiState.Loading
        scope.launch {
            _state.value = try {
                val list = api.fetchSalaries()
                if (list.items.isEmpty()) UiState.Empty else UiState.Content(list)
            } catch (e: Exception) {
                UiState.Error(ErrorKind.NETWORK, retryable = true)
            }
        }
    }
}
