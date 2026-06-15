package info.danielmartinez.cuantocobran.util

import java.text.NumberFormat
import java.util.Locale

actual object CurrencyFormatter {
    private val formatter = NumberFormat.getCurrencyInstance(Locale("es", "ES"))

    actual fun formatEuro(amount: Double): String = formatter.format(amount)
}
