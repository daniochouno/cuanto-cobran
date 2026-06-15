package info.danielmartinez.cuantocobran.data

/** The iOS simulator shares the host machine's loopback address. */
actual object ApiConfig {
    actual val baseUrl: String = "http://127.0.0.1:8080"
}
