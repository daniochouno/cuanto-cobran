package info.danielmartinez.cuantocobran.util

/** Formats a euro amount in Spanish convention (e.g. `95.943,96 €`). */
expect object CurrencyFormatter {
    fun formatEuro(amount: Double): String
}
