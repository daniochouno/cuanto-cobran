// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "vapor-server",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "XLSXReader", targets: ["XLSXReader"]),
        .executable(name: "App", targets: ["App"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.99.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0")
    ],
    targets: [
        // Dependency-free OOXML reader — builds/tests offline without Vapor/Postgres.
        .target(
            name: "XLSXReader",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "XLSXReaderTests",
            dependencies: ["XLSXReader"],
            resources: [.copy("Resources/Retribuciones.xlsx")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        // Vapor application: ingestion + consultation API.
        .executableTarget(
            name: "App",
            dependencies: [
                "XLSXReader",
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                "App",
                .product(name: "XCTVapor", package: "vapor")
            ],
            resources: [.copy("Resources/Retribuciones.xlsx")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
