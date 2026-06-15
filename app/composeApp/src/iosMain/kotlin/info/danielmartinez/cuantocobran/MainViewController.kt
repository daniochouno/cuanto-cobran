package info.danielmartinez.cuantocobran

import androidx.compose.ui.window.ComposeUIViewController
import info.danielmartinez.cuantocobran.ui.App
import platform.UIKit.UIViewController

/** Entry point consumed by the iOS app wrapper (iosApp Xcode project). */
@Suppress("unused", "FunctionName")
fun MainViewController(): UIViewController = ComposeUIViewController { App() }
