package info.danielmartinez.cuantocobran.ui.strings

import info.danielmartinez.cuantocobran.state.ErrorKind

/** Centralized Spanish UI text (Constitution Principle III). */
object Strings {
    const val APP_TITLE = "Cuánto Cobran"
    const val LIST_TITLE = "Sueldos públicos"
    const val DETAIL_TITLE = "Detalle"

    const val LOADING = "Cargando…"
    const val EMPTY_TITLE = "Sin datos"
    const val EMPTY_MESSAGE = "Todavía no hay datos publicados."
    const val ERROR_NETWORK = "No se pudieron cargar los datos."
    const val ERROR_NOT_AVAILABLE = "El registro ya no está disponible."
    const val RETRY = "Reintentar"
    const val BACK = "Volver"

    const val INSTITUTION_LABEL = "Organismo"
    const val SALARY_LABEL = "Retribución"
    const val SOURCE_ROW_LABEL = "Fila de origen"

    fun lastUpdated(isoDate: String): String {
        val date = isoDate.substringBefore('T')
        return "Datos actualizados a $date"
    }

    fun errorMessage(kind: ErrorKind): String = when (kind) {
        ErrorKind.NETWORK -> ERROR_NETWORK
        ErrorKind.NOT_AVAILABLE -> ERROR_NOT_AVAILABLE
    }
}
