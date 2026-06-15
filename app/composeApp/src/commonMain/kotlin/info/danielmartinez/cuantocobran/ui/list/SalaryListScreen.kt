package info.danielmartinez.cuantocobran.ui.list

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import info.danielmartinez.cuantocobran.data.SalariesApi
import info.danielmartinez.cuantocobran.domain.SalaryListItem
import info.danielmartinez.cuantocobran.state.ListStateHolder
import info.danielmartinez.cuantocobran.state.UiState
import info.danielmartinez.cuantocobran.ui.components.ErrorView
import info.danielmartinez.cuantocobran.ui.components.LoadingView
import info.danielmartinez.cuantocobran.ui.components.MessageView
import info.danielmartinez.cuantocobran.ui.strings.Strings
import info.danielmartinez.cuantocobran.ui.theme.Dimens
import info.danielmartinez.cuantocobran.util.CurrencyFormatter

/** The list screen: key fields per record + freshness, with explicit states. */
@Composable
fun SalaryListScreen(
    api: SalariesApi,
    listState: LazyListState,
    onSelect: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val scope = rememberCoroutineScope()
    val holder = remember { ListStateHolder(api, scope) }
    LaunchedEffect(Unit) { holder.load() }
    val state by holder.state.collectAsState()

    Column(modifier = modifier.fillMaxSize()) {
        Text(
            text = Strings.LIST_TITLE,
            style = MaterialTheme.typography.headlineSmall,
            modifier = Modifier.padding(Dimens.screenPadding),
        )
        when (val s = state) {
            is UiState.Loading -> LoadingView()
            is UiState.Empty -> MessageView(Strings.EMPTY_TITLE, Strings.EMPTY_MESSAGE)
            is UiState.Error -> ErrorView(
                message = Strings.errorMessage(s.kind),
                onRetry = if (s.retryable) ({ holder.load() }) else null,
            )
            is UiState.Content -> {
                s.value.dataset?.let { dataset ->
                    Text(
                        text = Strings.lastUpdated(dataset.lastUpdated),
                        style = MaterialTheme.typography.bodySmall,
                        modifier = Modifier.padding(horizontal = Dimens.screenPadding),
                    )
                }
                LazyColumn(state = listState, modifier = Modifier.fillMaxSize()) {
                    items(s.value.items, key = { it.id }) { item ->
                        SalaryRow(item, onClick = { onSelect(item.id) })
                        HorizontalDivider()
                    }
                }
            }
        }
    }
}

@Composable
private fun SalaryRow(item: SalaryListItem, onClick: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = Dimens.screenPadding, vertical = 12.dp),
    ) {
        Text(item.positionTitle, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.titleMedium)
        Text(item.institution, style = MaterialTheme.typography.bodyMedium)
        Text(CurrencyFormatter.formatEuro(item.salaryAmount), style = MaterialTheme.typography.bodyLarge)
    }
}
