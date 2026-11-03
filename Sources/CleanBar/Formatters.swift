import Foundation

public enum Formatters {
    public nonisolated(unsafe) static let file: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f
    }()
    
    public nonisolated(unsafe) static let memory: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .memory
        return f
    }()
    
    @inline(__always)
    public static func fileString(from bytes: Int64) -> String {
        file.string(fromByteCount: bytes)
    }
    
    @inline(__always)
    public static func memoryString(from bytes: UInt64) -> String {
        memory.string(fromByteCount: Int64(bytes))
    }
    
    @inline(__always)
    public static func memoryString(from bytes: Int64) -> String {
        memory.string(fromByteCount: bytes)
    }
}
