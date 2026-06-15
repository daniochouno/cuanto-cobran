package info.danielmartinez.cuantocobran.data

/**
 * Base URL of the backend. Differs per platform: the Android emulator reaches the
 * host loopback at 10.0.2.2, the iOS simulator shares the host's 127.0.0.1.
 */
expect object ApiConfig {
    val baseUrl: String
}
