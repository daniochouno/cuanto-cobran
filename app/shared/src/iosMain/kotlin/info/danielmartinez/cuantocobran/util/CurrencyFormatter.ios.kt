package info.danielmartinez.cuantocobran.util

import platform.Foundation.NSLocale
import platform.Foundation.NSNumber
import platform.Foundation.NSNumberFormatter
import platform.Foundation.NSNumberFormatterCurrencyStyle

actual object CurrencyFormatter {
    private val formatter = NSNumberFormatter().apply {
        numberStyle = NSNumberFormatterCurrencyStyle
        locale = NSLocale(localeIdentifier = "es_ES")
    }

    actual fun formatEuro(amount: Double): String =
        formatter.stringFromNumber(NSNumber(double = amount)) ?: "$amount €"
}
