/// Deterministic seed derivation helpers.
///
/// Used to split a single run seed into stable sub-seeds (battle / event / reward / shop ...) without
/// introducing shared RNG state.
public enum SeedDerivation {
    /// Derive a deterministic seed for a battle instance.
    ///
    /// - Parameters:
    ///   - runSeed: The run seed.
    ///   - floor: The current act/floor number (1-based in `RunState`).
    ///   - nodeId: The map node id (e.g. "3_1").
    public static func battleSeed(runSeed: UInt64, floor: Int, nodeId: String) -> UInt64 {
        var s = runSeed
        s ^= StableHash.fnv1a64(nodeId)
        s ^= UInt64(floor) &* 1_000_000_000
        s ^= 0xBA77_EEED_0000_0000
        return s
    }
}

