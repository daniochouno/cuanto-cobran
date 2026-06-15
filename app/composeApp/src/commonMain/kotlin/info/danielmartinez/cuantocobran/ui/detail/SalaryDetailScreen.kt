package info.danielmartinez.cuantocobran.ui.detail

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import info.danielmartinez.cuantocobran.data.SalariesApi
import info.danielmartinez.cuantocobran.domain.CellValue
import info.danielmartinez.cuantocobran.domain.SalaryRecordDetail
import info.danielmartinez.cuantocobran.state.DetailStateHolder
import info.danielmartinez.cuantocobran.state.UiState
import info.danielmartinez.cuantocobran.ui.components.ErrorView
import info.danielmartinez.cuantocobran.ui.components.LoadingView
import info.danielmartinez.cuantocobran.ui.strings.Strings
import info.danielmartinez.cuantocobran.ui.theme.Dimens
import info.danielmartinez.cuantocobran.util.CurrencyFormatter

/** The detail screen: every ingested field for a record, with a back action. */
@Composable
fun SalaryDetailScreen(
    api: SalariesApi,
    id: String,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val scope = rememberCoroutineScope()
    val holder = remember(id) { DetailStateHolder(api, scope) }
    LaunchedEffect(id) { holder.load(id) }
    val state by holder.state.collectAsState()

    Column(modifier = modifier.fillMaxSize()) {
        TextButton(onClick = onBack, modifier = Modifier.padding(horizontal = Dimens.itemSpacing)) {
            Text("← ${Strings.BACK}")
        }
        when (val s = state) {
            is UiState.Loading -> LoadingView()
            is UiState.Empty -> ErrorView(Strings.ERROR_NOT_AVAILABLE, onRetry = null)
            is UiState.Error -> ErrorView(
                message = Strings.errorMessage(s.kind),
                onRetry = if (s.retryable) ({ holder.load(id) }) else null,
            )
            is UiState.Content -> DetailContent(s.value.record, s.value.dataset.lastUpdated)
        }
    }
}

@Composable
private fun DetailContent(record: SalaryRecordDetail, lastUpdated: String) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(Dimens.screenPadding),
    ) {
        Text(record.positionTitle, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Field(Strings.INSTITUTION_LABEL, record.institution)
        Field(Strings.SALARY_LABEL, CurrencyFormatter.formatEuro(record.salaryAmount))
        Field(Strings.SOURCE_ROW_LABEL, record.sourceRowNumber.toString())
        HorizontalDivider(modifier = Modifier.padding(vertical = Dimens.itemSpacing))
        record.extraFields.forEach { field ->
            Field(field.label, field.value.display())
        }
        Text(
            text = Strings.lastUpdated(lastUpdated),
            style = MaterialTheme.typography.bodySmall,
            modifier = Modifier.padding(top = Dimens.sectionSpacing),
        )
    }
}

@Composable
private fun Field(label: String, value: String) {
    Column(modifier = Modifier.fillMaxWidth().padding(vertical = Dimens.itemSpacing)) {
        Text(label, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold)
        Text(value, style = MaterialTheme.typography.bodyLarge)
    }
}

private fun CellValue.display(): String = when (this) {
    is CellValue.Text -> value
    is CellValue.Number -> {
        if (value == value.toLong().toDouble()) value.toLong().toString() else value.toString()
    }
    CellValue.Empty -> "—"
}
