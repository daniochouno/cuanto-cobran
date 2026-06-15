package info.danielmartinez.cuantocobran.data

import info.danielmartinez.cuantocobran.Fixtures
import info.danielmartinez.cuantocobran.domain.CellValue
import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class SalaryDtoTest {
    private val json = Json { ignoreUnknownKeys = true }

    @Test
    fun decodesPopulatedListToDomain() {
        val dto = json.decodeFromString(SalaryListResponseDto.serializer(), Fixtures.salariesListPopulated)
        val list = dto.toDomain()
        assertEquals("2026-06-15T10:03:52Z", list.dataset?.lastUpdated)
        assertEquals(2, list.items.size)
        assertEquals("PRESIDENTE DEL GOBIERNO", list.items.first().positionTitle)
        assertEquals(95943.96, list.items.first().salaryAmount)
    }

    @Test
    fun decodesEmptyListWithNullDataset() {
        val list = json.decodeFromString(SalaryListResponseDto.serializer(), Fixtures.salariesListEmpty).toDomain()
        assertNull(list.dataset)
        assertTrue(list.items.isEmpty())
    }

    @Test
    fun decodesDetailPreservingExtraFieldOrderAndTypes() {
        val detail = json.decodeFromString(SalaryDetailResponseDto.serializer(), Fixtures.salaryDetail).toDomain()
        assertEquals(2, detail.record.sourceRowNumber)
        val extras = detail.record.extraFields
        assertEquals(listOf("Ministerio", "Año", "Cuota", "Observaciones"), extras.map { it.label })
        assertEquals(CellValue.Text("Presidencia del Gobierno"), extras[0].value)
        assertEquals(CellValue.Text("2025"), extras[1].value)
        assertEquals(CellValue.Number(12.0), extras[2].value)
        assertEquals(CellValue.Empty, extras[3].value)
    }
}
