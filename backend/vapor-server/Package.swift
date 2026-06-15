// swift-tools-version:6.0
import PackageDescription

// NOTE: This package currently exposes only the dependency-free `XLSXReader`
// library so it builds and tests offline without PostgreSQL. The Vapor `App`
// executable and its Fluent/Postgres targets are added in the persistence phase
// (tasks T009+), at which point `App` will depend on `XLSXReader`.
let package = Package(
    name: "vapor-server",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "XLSXReader", targets: ["XLSXReader"])
    ],
    targets: [
        .target(
            name: "XLSXReader",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "XLSXReaderTests",
            dependencies: ["XLSXReader"],
            resources: [.copy("Resources/Retribuciones.xlsx")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
