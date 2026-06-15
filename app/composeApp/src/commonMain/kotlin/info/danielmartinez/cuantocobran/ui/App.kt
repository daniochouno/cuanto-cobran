package info.danielmartinez.cuantocobran.ui

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import info.danielmartinez.cuantocobran.data.SalariesApi
import info.danielmartinez.cuantocobran.data.platformHttpClient
import info.danielmartinez.cuantocobran.ui.detail.SalaryDetailScreen
import info.danielmartinez.cuantocobran.ui.list.SalaryListScreen
import info.danielmartinez.cuantocobran.ui.theme.CuantoCobranTheme

/** App root: builds the API client and switches between the two screens. */
@Composable
fun App() {
    CuantoCobranTheme {
        val api = remember { SalariesApi(platformHttpClient()) }
        val navigator = remember { Navigator() }
        // Hoisted above the screen switch so list scroll position survives
        // navigation to detail and back (US3 acceptance scenario 3).
        val listState = rememberLazyListState()

        Surface(modifier = Modifier.fillMaxSize()) {
            when (val screen = navigator.current) {
                is Screen.List -> SalaryListScreen(
                    api = api,
                    listState = listState,
                    onSelect = { id -> navigator.navigateTo(Screen.Detail(id)) },
                )
                is Screen.Detail -> SalaryDetailScreen(
                    api = api,
                    id = screen.id,
                    onBack = { navigator.goBack() },
                )
            }
        }
    }
}
