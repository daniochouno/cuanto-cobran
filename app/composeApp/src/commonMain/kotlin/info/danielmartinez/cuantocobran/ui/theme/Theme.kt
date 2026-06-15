package info.danielmartinez.cuantocobran.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

/** Shared spacing tokens — the single source of layout rhythm (Principle III). */
object Dimens {
    val screenPadding = 16.dp
    val itemSpacing = 8.dp
    val sectionSpacing = 24.dp
}

private val colorScheme = lightColorScheme(
    primary = Color(0xFF1E5AA8),
    secondary = Color(0xFF4285F4),
)

/** The app's single Material 3 theme. */
@Composable
fun CuantoCobranTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = colorScheme,
        content = content,
    )
}
