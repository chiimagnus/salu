// RunSnapshot <-> RunState mapping lives in GameCore (pure logic, no I/O).

public enum RunSnapshotMapper {
    public enum LoadError: Error, Sendable, Equatable {
        case incompatibleVersion(Int)
        case invalidRoomType(String)
    }

    public static func makeSnapshot(from run: RunState) -> RunSnapshot {
        RunSnapshot(
            version: RunSaveVersion.current,
            seed: run.seed,
            floor: run.floor,
            maxFloor: run.maxFloor,
            gold: run.gold,
            mapNodes: run.map.map { node in
                RunSnapshot.NodeData(
                    id: node.id,
                    row: node.row,
                    column: node.column,
                    roomType: node.roomType.rawValue,
                    connections: node.connections,
                    isCompleted: node.isCompleted,
                    isAccessible: node.isAccessible
                )
            },
            currentNodeId: run.currentNodeId,
            player: RunSnapshot.PlayerData(
                maxHP: run.player.maxHP,
                currentHP: run.player.currentHP,
                statuses: Dictionary(
                    uniqueKeysWithValues: run.player.statuses.all.map { ($0.id.rawValue, $0.stacks) }
                )
            ),
            deck: run.deck.map { card in
                RunSnapshot.CardData(id: card.id, cardId: card.cardId.rawValue)
            },
            relicIds: run.relicManager.all.map(\.rawValue),
            isOver: run.isOver,
            won: run.won
        )
    }

    public static func loadRunState(from snapshot: RunSnapshot) throws -> RunState {
        guard RunSaveVersion.isCompatible(snapshot.version) else {
            throw LoadError.incompatibleVersion(snapshot.version)
        }

        let map: [MapNode] = try snapshot.mapNodes.map { node in
            guard let roomType = RoomType(rawValue: node.roomType) else {
                throw LoadError.invalidRoomType(node.roomType)
            }
            return MapNode(
                id: node.id,
                row: node.row,
                column: node.column,
                roomType: roomType,
                connections: node.connections,
                isCompleted: node.isCompleted,
                isAccessible: node.isAccessible
            )
        }

        var player = Entity(id: "player", name: LocalizedText("安德", "Ander"), maxHP: snapshot.player.maxHP)
        player.currentHP = snapshot.player.currentHP
        for (raw, stacks) in snapshot.player.statuses {
            player.statuses.set(StatusID(raw), stacks: stacks)
        }

        let deck = snapshot.deck.map { Card(id: $0.id, cardId: CardID($0.cardId)) }
        var relicManager = RelicManager()
        for raw in snapshot.relicIds {
            relicManager.add(RelicID(raw))
        }

        var run = RunState(
            player: player,
            deck: deck,
            gold: snapshot.gold,
            relicManager: relicManager,
            map: map,
            seed: snapshot.seed,
            floor: snapshot.floor,
            maxFloor: snapshot.maxFloor
        )
        run.currentNodeId = snapshot.currentNodeId
        run.isOver = snapshot.isOver
        run.won = snapshot.won
        return run
    }
}

