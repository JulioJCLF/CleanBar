import XCTest
@testable import CleanBar

final class CleanBarTests: XCTestCase {
    func testDiskSpaceFormatters() {
        let text = Formatters.fileString(from: 1_073_741_824)
        XCTAssertFalse(text.isEmpty)
    }
    
    func testMemoryFormatters() {
        let text = Formatters.memoryString(from: 8_589_934_592)
        XCTAssertFalse(text.isEmpty)
    }
    
    func testHealthScoreCalculation() {
        let state = AppState.shared
        XCTAssertGreaterThanOrEqual(state.macHealthScore, 0)
        XCTAssertLessThanOrEqual(state.macHealthScore, 100)
    }
    
    func testSystemMonitorTelemetry() {
        let disk = SystemMonitor.shared.getDiskSpace()
        XCTAssertGreaterThan(disk.totalBytes, 0)
        
        let mem = SystemMonitor.shared.getMemoryInfo()
        XCTAssertGreaterThan(mem.totalBytes, 0)
    }
    
    func testProcessProtectionGuardrails() {
        let launchdItem = ProcessInfoItem(
            pid: 1,
            name: "launchd",
            cpuPercent: 0.1,
            memPercent: 0.2,
            fullCommand: "/sbin/launchd"
        )
        XCTAssertTrue(launchdItem.isSystemCritical)
        
        // Ensure terminateProcess refuses to kill PID <= 1
        let killed = ProcessMonitor.shared.terminateProcess(pid: 1)
        XCTAssertFalse(killed)
        
        // Ensure terminateProcess refuses to kill self
        let killedSelf = ProcessMonitor.shared.terminateProcess(pid: Int(getpid()))
        XCTAssertFalse(killedSelf)
    }
    
    func testLocalizationDictionaries() {
        let pt = Strings(lang: .portuguese)
        let en = Strings(lang: .english)
        
        XCTAssertEqual(pt.dashboardTab, "Visão Geral")
        XCTAssertEqual(en.dashboardTab, "Overview")
        XCTAssertEqual(pt.deepCleanTab, "Limpeza Profunda")
        XCTAssertEqual(en.deepCleanTab, "Deep Clean")
    }
}
