package info.danielmartinez.cuantocobran.state

/** Why a screen is in the error state (the UI maps these to Spanish messages). */
enum class ErrorKind {
    /** The backend was unreachable or returned an unexpected status. */
    NETWORK,

    /** The requested record no longer exists in the active dataset (FR-013). */
    NOT_AVAILABLE,
}

/** Explicit UI state for every data-loading screen (Constitution Principle III). */
sealed interface UiState<out T> {
    data object Loading : UiState<Nothing>
    data class Content<T>(val value: T) : UiState<T>
    data object Empty : UiState<Nothing>
    data class Error(val kind: ErrorKind, val retryable: Boolean) : UiState<Nothing>
}
