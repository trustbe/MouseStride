import MouseStrideCore
#if canImport(Darwin)
import Darwin
#endif

// MARK: - Simple Test Harness

var totalTests = 0
var passedTests = 0
var failedTests: [(name: String, message: String)] = []

func test(_ name: String, _ body: () throws -> Void) {
    totalTests += 1
    do {
        try body()
        passedTests += 1
        print("  \u{2713} \(name)")
    } catch {
        failedTests.append((name: name, message: "\(error)"))
        print("  \u{2717} \(name): \(error)")
    }
}

struct AssertionError: Error, CustomStringConvertible {
    let description: String
}

func assertEqual<T: Equatable>(_ a: T, _ b: T, file: String = #file, line: Int = #line) throws {
    guard a == b else {
        throw AssertionError(description: "Expected \(a) == \(b) at \(file):\(line)")
    }
}

func assertApproxEqual(_ a: Double, _ b: Double, accuracy: Double = 0.0001, file: String = #file, line: Int = #line) throws {
    guard abs(a - b) < accuracy else {
        throw AssertionError(description: "Expected \(a) ≈ \(b) (accuracy \(accuracy)) at \(file):\(line)")
    }
}

func assertTrue(_ condition: Bool, _ message: String = "", file: String = #file, line: Int = #line) throws {
    guard condition else {
        throw AssertionError(description: "Assertion failed: \(message) at \(file):\(line)")
    }
}

func assertNotNil<T>(_ value: T?, _ message: String = "", file: String = #file, line: Int = #line) throws {
    guard value != nil else {
        throw AssertionError(description: "Expected non-nil: \(message) at \(file):\(line)")
    }
}

// MARK: - DistanceUnit Conversion Tests

func runDistanceUnitConversionTests() {
    print("\nDistanceUnit Conversions:")

    test("convert(fromMM:) — millimeters identity") {
        try assertEqual(DistanceUnit.millimeters.convert(fromMM: 1000), 1000)
    }

    test("convert(fromMM:) — centimeters") {
        try assertEqual(DistanceUnit.centimeters.convert(fromMM: 1000), 100)
    }

    test("convert(fromMM:) — meters") {
        try assertEqual(DistanceUnit.meters.convert(fromMM: 1000), 1.0)
    }

    test("convert(fromMM:) — kilometers") {
        try assertEqual(DistanceUnit.kilometers.convert(fromMM: 1_000_000), 1.0)
    }

    test("convert(fromMM:) — inches") {
        try assertApproxEqual(DistanceUnit.inches.convert(fromMM: 25.4), 1.0)
    }

    test("convert(fromMM:) — feet") {
        try assertApproxEqual(DistanceUnit.feet.convert(fromMM: 304.8), 1.0)
    }

    test("convert(fromMM:) — yards") {
        try assertApproxEqual(DistanceUnit.yards.convert(fromMM: 914.4), 1.0)
    }

    test("convert(fromMM:) — miles") {
        try assertApproxEqual(DistanceUnit.miles.convert(fromMM: 1_609_344), 1.0)
    }
}

// MARK: - DistanceUnit Format Tests

func runDistanceUnitFormatTests() {
    print("\nDistanceUnit Formatting:")

    test("format(mm:) — mm uses 0 decimals") {
        try assertEqual(DistanceUnit.millimeters.format(mm: 5.7), "6 mm")
    }

    test("format(mm:) — inches uses 0 decimals") {
        try assertEqual(DistanceUnit.inches.format(mm: 25.4), "1 in")
    }

    test("format(mm:) — cm uses 1 decimal") {
        try assertEqual(DistanceUnit.centimeters.format(mm: 155), "15.5 cm")
    }

    test("format(mm:) — meters uses 1 decimal") {
        try assertEqual(DistanceUnit.meters.format(mm: 1500), "1.5 m")
    }

    test("format(mm:) — km uses 1 decimal") {
        try assertEqual(DistanceUnit.kilometers.format(mm: 2_500_000), "2.5 km")
    }

    test("format(mm:) — feet uses 1 decimal") {
        try assertEqual(DistanceUnit.feet.format(mm: 457.2), "1.5 ft")
    }
}

// MARK: - DistanceUnit bestUnit Tests

func runDistanceUnitBestUnitTests() {
    print("\nDistanceUnit bestUnit:")

    test("bestUnit metric — below 10mm returns mm") {
        try assertEqual(DistanceUnit.bestUnit(forMM: 5, system: .metric), .millimeters)
    }

    test("bestUnit metric — 10mm returns cm") {
        try assertEqual(DistanceUnit.bestUnit(forMM: 10, system: .metric), .centimeters)
    }

    test("bestUnit metric — 1000mm returns m") {
        try assertEqual(DistanceUnit.bestUnit(forMM: 1000, system: .metric), .meters)
    }

    test("bestUnit metric — 1M mm returns km") {
        try assertEqual(DistanceUnit.bestUnit(forMM: 1_000_000, system: .metric), .kilometers)
    }

    test("bestUnit imperial — small returns inches") {
        try assertEqual(DistanceUnit.bestUnit(forMM: 100, system: .imperial), .inches)
    }

    test("bestUnit imperial — 304.8mm returns feet") {
        try assertEqual(DistanceUnit.bestUnit(forMM: 304.8, system: .imperial), .feet)
    }

    test("bestUnit imperial — 91440mm returns yards") {
        try assertEqual(DistanceUnit.bestUnit(forMM: 91_440, system: .imperial), .yards)
    }

    test("bestUnit imperial — 1609344mm returns miles") {
        try assertEqual(DistanceUnit.bestUnit(forMM: 1_609_344, system: .imperial), .miles)
    }
}

// MARK: - DistanceUnit autoFormat Tests

func runDistanceUnitAutoFormatTests() {
    print("\nDistanceUnit autoFormat:")

    test("autoFormat metric end-to-end") {
        try assertEqual(DistanceUnit.autoFormat(mm: 5, system: .metric), "5 mm")
        try assertEqual(DistanceUnit.autoFormat(mm: 150, system: .metric), "15.0 cm")
        try assertEqual(DistanceUnit.autoFormat(mm: 5000, system: .metric), "5.0 m")
        try assertEqual(DistanceUnit.autoFormat(mm: 2_500_000, system: .metric), "2.5 km")
    }

    test("autoFormat imperial end-to-end") {
        try assertEqual(DistanceUnit.autoFormat(mm: 25.4, system: .imperial), "1 in")
        try assertEqual(DistanceUnit.autoFormat(mm: 1_609_344, system: .imperial), "1.0 mi")
    }
}

// MARK: - DistanceUnit allTimeFormat Tests

func runDistanceUnitAllTimeFormatTests() {
    print("\nDistanceUnit allTimeFormat:")

    test("allTimeFormat below km threshold falls back to autoFormat") {
        try assertEqual(DistanceUnit.allTimeFormat(mm: 5000, system: .metric), "5.0 m")
    }

    test("allTimeFormat sticks to km once reached") {
        try assertEqual(DistanceUnit.allTimeFormat(mm: 1_000_000, system: .metric), "1.0 km")
        try assertEqual(DistanceUnit.allTimeFormat(mm: 50_000_000, system: .metric), "50.0 km")
    }

    test("allTimeFormat sticks to miles once reached") {
        try assertEqual(DistanceUnit.allTimeFormat(mm: 1_609_344, system: .imperial), "1.0 mi")
        try assertEqual(DistanceUnit.allTimeFormat(mm: 16_093_440, system: .imperial), "10.0 mi")
    }

    test("allTimeFormat imperial below threshold falls back") {
        try assertEqual(DistanceUnit.allTimeFormat(mm: 304.8, system: .imperial), "1.0 ft")
    }
}

// MARK: - URL Migration Tests

func readFile(_ path: String) throws -> String {
    guard let fp = fopen(path, "r") else {
        throw AssertionError(description: "File not found: \(path)")
    }
    defer { fclose(fp) }
    var content = ""
    var buffer = [CChar](repeating: 0, count: 4096)
    while fgets(&buffer, Int32(buffer.count), fp) != nil {
        content += String(cString: buffer)
    }
    return content
}

func runURLMigrationTests() {
    // Derive project root from #filePath
    var projectRoot = #filePath
    for _ in 0..<3 {
        if let idx = projectRoot.lastIndex(of: "/") {
            projectRoot = String(projectRoot[projectRoot.startIndex..<idx])
        }
    }

    print("\nURL Migration (trustbe.github.io → mousestride.trustbe.com):")

    let filesToCheck = [
        "docs/index.html",
        "docs/dashboard.html",
        "Sources/MouseStrideDaemon/App/AppDelegate.swift",
        "Sources/MouseStrideCore/DashboardService.swift",
        "homebrew/mousestride.rb",
        "README.md",
    ]

    test("No trustbe.github.io references in migrated files") {
        var violations: [String] = []
        for file in filesToCheck {
            let content = try readFile(projectRoot + "/" + file)
            let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
            for (index, line) in lines.enumerated() {
                if line.contains("trustbe.github.io") {
                    violations.append("\(file):\(index + 1)")
                }
            }
        }
        try assertTrue(violations.isEmpty, "Found old URLs: \(violations)")
    }

    test("docs/index.html og:url uses mousestride.trustbe.com") {
        let content = try readFile(projectRoot + "/docs/index.html")
        try assertTrue(content.contains("mousestride.trustbe.com"), "index.html should reference mousestride.trustbe.com")
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        let ogLine = lines.first { $0.contains("og:url") }
        try assertNotNil(ogLine, "index.html should have og:url meta tag")
        try assertTrue(ogLine!.contains("mousestride.trustbe.com"), "og:url should use mousestride.trustbe.com")
    }

    test("docs/dashboard.html og:url uses mousestride.trustbe.com/dashboard.html") {
        let content = try readFile(projectRoot + "/docs/dashboard.html")
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        let ogLine = lines.first { $0.contains("og:url") }
        try assertNotNil(ogLine, "dashboard.html should have og:url meta tag")
        try assertTrue(ogLine!.contains("mousestride.trustbe.com/dashboard.html"), "og:url should use mousestride.trustbe.com/dashboard.html")
    }

    test("AppDelegate.swift uses mousestride.trustbe.com/dashboard.html") {
        let content = try readFile(projectRoot + "/Sources/MouseStrideDaemon/App/AppDelegate.swift")
        try assertTrue(content.contains("mousestride.trustbe.com/dashboard.html"), "AppDelegate should use mousestride.trustbe.com/dashboard.html")
    }

    test("homebrew/mousestride.rb homepage is mousestride.trustbe.com") {
        let content = try readFile(projectRoot + "/homebrew/mousestride.rb")
        try assertTrue(content.contains("mousestride.trustbe.com"), "Homebrew cask homepage should be mousestride.trustbe.com")
    }
}

// MARK: - Run All

print("MouseStride Test Suite")
print("======================")

runDistanceUnitConversionTests()
runDistanceUnitFormatTests()
runDistanceUnitBestUnitTests()
runDistanceUnitAutoFormatTests()
runDistanceUnitAllTimeFormatTests()
runURLMigrationTests()

print("\n======================")
print("Results: \(passedTests)/\(totalTests) passed")
if !failedTests.isEmpty {
    print("\nFailed tests:")
    for f in failedTests {
        print("  \u{2717} \(f.name): \(f.message)")
    }
    exit(1)
}
print("All tests passed!")
