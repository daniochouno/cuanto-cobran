package info.danielmartinez.cuantocobran.data

/** The Android emulator reaches the host machine's loopback at 10.0.2.2. */
actual object ApiConfig {
    actual val baseUrl: String = "http://10.0.2.2:8080"
}
