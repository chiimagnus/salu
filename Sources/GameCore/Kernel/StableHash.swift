/// Stable hashing utilities (pure Swift, deterministic).
///
/// - Important: Do NOT use `String.hashValue` for determinism. Swift's hashing is intentionally randomized
///   across processes and versions.
public enum StableHash {
    /// FNV-1a 64-bit hash for UTF-8 bytes.
    ///
    /// Deterministic across platforms and runs.
    public static func fnv1a64(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        return hash
    }
}

