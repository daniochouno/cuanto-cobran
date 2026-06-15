package info.danielmartinez.cuantocobran.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class NavigatorTest {

    @Test
    fun startsAtList() {
        val navigator = Navigator()
        assertEquals(Screen.List, navigator.current)
        assertFalse(navigator.canGoBack)
    }

    @Test
    fun navigateToDetailThenBack() {
        val navigator = Navigator()
        navigator.navigateTo(Screen.Detail("abc"))
        assertEquals(Screen.Detail("abc"), navigator.current)
        assertTrue(navigator.canGoBack)

        navigator.goBack()
        assertEquals(Screen.List, navigator.current)
        assertFalse(navigator.canGoBack)
    }

    @Test
    fun goBackAtRootIsNoOp() {
        val navigator = Navigator()
        navigator.goBack()
        assertEquals(Screen.List, navigator.current)
    }
}
