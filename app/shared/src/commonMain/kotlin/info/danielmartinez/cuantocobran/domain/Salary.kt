package info.danielmartinez.cuantocobran.domain

/** A cell value from the source spreadsheet: text, number, or empty. */
sealed interface CellValue {
    data class Text(val value: String) : CellValue
    data class Number(val value: Double) : CellValue
    data object Empty : CellValue
}

/** A labelled cell value (original column header + its value). */
data class LabeledValue(val label: String, val value: CellValue)

/** Freshness metadata for the active dataset (ISO-8601 timestamp). */
data class DatasetInfo(val lastUpdated: String)

/** A list entry — only the key fields shown in the list (FR-009). */
data class SalaryListItem(
    val id: String,
    val positionTitle: String,
    val institution: String,
    val salaryAmount: Double,
)

/** The full set of fields for one record (FR-010). */
data class SalaryRecordDetail(
    val id: String,
    val positionTitle: String,
    val institution: String,
    val salaryAmount: Double,
    val sourceRowNumber: Int,
    val extraFields: List<LabeledValue>,
)

/** The published list with its freshness; `dataset` is null when nothing is published. */
data class SalaryList(
    val dataset: DatasetInfo?,
    val items: List<SalaryListItem>,
)

/** A record detail together with the dataset freshness. */
data class SalaryDetail(
    val dataset: DatasetInfo,
    val record: SalaryRecordDetail,
)
