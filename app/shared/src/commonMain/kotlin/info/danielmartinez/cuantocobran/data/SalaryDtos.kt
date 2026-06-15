package info.danielmartinez.cuantocobran.data

import info.danielmartinez.cuantocobran.domain.CellValue
import info.danielmartinez.cuantocobran.domain.DatasetInfo
import info.danielmartinez.cuantocobran.domain.LabeledValue
import info.danielmartinez.cuantocobran.domain.SalaryDetail
import info.danielmartinez.cuantocobran.domain.SalaryList
import info.danielmartinez.cuantocobran.domain.SalaryListItem
import info.danielmartinez.cuantocobran.domain.SalaryRecordDetail
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive

@Serializable
data class DatasetInfoDto(val lastUpdated: String) {
    fun toDomain() = DatasetInfo(lastUpdated = lastUpdated)
}

@Serializable
data class SalaryListItemDto(
    val id: String,
    val positionTitle: String,
    val institution: String,
    val salaryAmount: Double,
) {
    fun toDomain() = SalaryListItem(id, positionTitle, institution, salaryAmount)
}

@Serializable
data class SalaryListResponseDto(
    val dataset: DatasetInfoDto? = null,
    val items: List<SalaryListItemDto> = emptyList(),
) {
    fun toDomain() = SalaryList(dataset?.toDomain(), items.map { it.toDomain() })
}

@Serializable
data class LabeledValueDto(val label: String, val value: JsonElement) {
    fun toDomain() = LabeledValue(label, value.toCellValue())
}

@Serializable
data class SalaryRecordDetailDto(
    val id: String,
    val positionTitle: String,
    val institution: String,
    val salaryAmount: Double,
    val sourceRowNumber: Int,
    val extraFields: List<LabeledValueDto> = emptyList(),
) {
    fun toDomain() = SalaryRecordDetail(
        id = id,
        positionTitle = positionTitle,
        institution = institution,
        salaryAmount = salaryAmount,
        sourceRowNumber = sourceRowNumber,
        extraFields = extraFields.map { it.toDomain() },
    )
}

@Serializable
data class SalaryDetailResponseDto(
    val dataset: DatasetInfoDto,
    val record: SalaryRecordDetailDto,
) {
    fun toDomain() = SalaryDetail(dataset.toDomain(), record.toDomain())
}

@Serializable
data class ApiErrorDto(val code: String, val message: String)

private fun JsonElement.toCellValue(): CellValue {
    if (this is JsonNull) return CellValue.Empty
    val primitive = this as? JsonPrimitive ?: return CellValue.Text(toString())
    if (primitive.isString) return CellValue.Text(primitive.content)
    primitive.content.toDoubleOrNull()?.let { return CellValue.Number(it) }
    return CellValue.Text(primitive.content)
}
