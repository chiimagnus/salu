import Foundation
import GameCore

/// 历史记录服务
/// 管理战斗历史记录的读取、添加和清除
/// 通过依赖注入 BattleHistoryStore 实现，避免单例模式
final class HistoryService: @unchecked Sendable {
    
    private let store: BattleHistoryStore
    private var cachedRecords: [BattleRecord]?
    
    init(store: BattleHistoryStore) {
        self.store = store
    }
    
    // MARK: - Public API
    
    /// 添加新的战斗记录
    func addRecord(_ record: BattleRecord) {
        do {
            try store.append(record)
            cachedRecords = nil  // 清除缓存
        } catch {
            // 保存失败，静默处理
        }
    }
    
    /// 获取所有记录
    func getAllRecords() -> [BattleRecord] {
        if let cached = cachedRecords {
            return cached
        }
        
        do {
            let records = try store.load()
            cachedRecords = records
            return records
        } catch {
            return []
        }
    }
    
    /// 获取最近 N 条记录
    func getRecentRecords(_ count: Int) -> [BattleRecord] {
        let allRecords = getAllRecords()
        return Array(allRecords.suffix(count))
    }
    
    /// 获取统计数据
    func getStatistics() -> BattleStatistics {
        let records = getAllRecords()
        return BattleStatistics(records: records)
    }
    
    /// 清空历史记录
    func clearHistory() {
        do {
            try store.clear()
            cachedRecords = []
        } catch {
            // 清空失败，静默处理
        }
    }
    
    /// 记录数量
    var recordCount: Int {
        getAllRecords().count
    }
}
