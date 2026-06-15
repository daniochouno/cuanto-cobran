package info.danielmartinez.cuantocobran.ui

import androidx.compose.runtime.mutableStateListOf

/** The app's two destinations. */
sealed interface Screen {
    data object List : Screen
    data class Detail(val id: String) : Screen
}

/**
 * A minimal back-stack navigator (Constitution Principle V: two screens do not
 * justify a navigation library). Backed by snapshot state so Compose recomposes
 * on changes.
 */
class Navigator(initial: Screen = Screen.List) {
    private val stack = mutableStateListOf(initial)

    val current: Screen get() = stack.last()
    val canGoBack: Boolean get() = stack.size > 1

    fun navigateTo(screen: Screen) {
        stack.add(screen)
    }

    /** Pop the top destination; no-op at the root. */
    fun goBack() {
        if (canGoBack) stack.removeAt(stack.lastIndex)
    }
}
