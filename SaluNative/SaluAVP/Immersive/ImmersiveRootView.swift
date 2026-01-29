import SwiftUI
import RealityKit

import UIKit
import GameCore

struct ImmersiveRootView: View {
    @Environment(RunSession.self) private var runSession

    private let nodeNamePrefix = "node:"

    var body: some View {
        ZStack(alignment: .topLeading) {
            RealityView { content in
                let root = RealityKit.Entity()
                root.name = "root"
                content.add(root)
            } update: { content in
                guard let root = content.entities.first else { return }
                root.children.forEach { $0.removeFromParent() }

                addFloor(to: root)

                guard let run = runSession.runState else { return }
                renderMap(run: run, into: root)
            }
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        guard runSession.route == .map else { return }
                        guard value.entity.name.hasPrefix(nodeNamePrefix) else { return }
                        let nodeId = String(value.entity.name.dropFirst(nodeNamePrefix.count))
                        runSession.selectAccessibleNode(nodeId)
                    }
            )

            switch runSession.route {
            case .map:
                if runSession.runState == nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No run started")
                            .font(.headline)
                        Text("Start a run from the Control Panel.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(16)
                }

            case .room(let nodeId, let roomType):
                roomOverlay(nodeId: nodeId, roomType: roomType)
            }
        }
    }

    private func roomOverlay(nodeId: String, roomType: RoomType) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(roomType.icon) \(roomType.displayName(language: .zhHans))")
                .font(.headline)

            Text("Node: \(nodeId)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Complete") {
                runSession.completeCurrentRoomAndReturnToMap()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(16)
    }

    private func addFloor(to root: RealityKit.Entity) {
        let floor = ModelEntity(
            mesh: .generatePlane(width: 2.8, depth: 4.2),
            materials: [SimpleMaterial(color: .gray.withAlphaComponent(0.18), isMetallic: false)]
        )
        floor.name = "floor"
        floor.components.set(CollisionComponent(shapes: [.generateBox(size: [2.8, 0.01, 4.2])]))
        floor.components.set(InputTargetComponent())
        root.addChild(floor)
    }

    private func renderMap(run: RunState, into root: RealityKit.Entity) {
        let rowSpacing: Float = 0.18
        let colSpacing: Float = 0.22
        let baseZ: Float = -0.6
        let nodeY: Float = 0.08
        let edgeY: Float = 0.035

        let nodesByRow = Dictionary(grouping: run.map, by: \.row)
        let maxRow = run.map.maxRow

        var positionsByNodeId: [String: SIMD3<Float>] = [:]

        for row in 0...maxRow {
            let rowNodes = (nodesByRow[row] ?? []).sorted { $0.column < $1.column }
            let offset = Float(rowNodes.count - 1) / 2.0

            for node in rowNodes {
                let x = (Float(node.column) - offset) * colSpacing
                let z = baseZ - Float(node.row) * rowSpacing
                positionsByNodeId[node.id] = [x, nodeY, z]
            }
        }

        for node in run.map {
            guard let from = positionsByNodeId[node.id] else { continue }
            for toId in node.connections {
                guard let to = positionsByNodeId[toId] else { continue }
                let edge = makeEdgeEntity(from: [from.x, edgeY, from.z], to: [to.x, edgeY, to.z])
                root.addChild(edge)
            }
        }

        for node in run.map {
            guard let position = positionsByNodeId[node.id] else { continue }
            let isCurrent = (run.currentNodeId == node.id)
            let entity = makeNodeEntity(node: node, isCurrent: isCurrent)
            entity.position = position
            root.addChild(entity)
        }
    }

    private func makeEdgeEntity(from: SIMD3<Float>, to: SIMD3<Float>) -> ModelEntity {
        let direction = to - from
        let length = max(0.0001, simd_length(direction))
        let unit = direction / length

        let mesh = MeshResource.generateCylinder(height: length, radius: 0.004)
        let material = SimpleMaterial(color: .gray.withAlphaComponent(0.25), isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "edge"
        entity.position = (from + to) / 2
        entity.orientation = simd_quatf(from: [0, 1, 0], to: unit)
        return entity
    }

    private func makeNodeEntity(node: MapNode, isCurrent: Bool) -> ModelEntity {
        let (mesh, baseColor, metallic) = nodeStyle(roomType: node.roomType)

        let color: UIColor
        if node.isCompleted {
            color = .systemGray3
        } else if isCurrent {
            color = .systemYellow
        } else if node.isAccessible {
            color = baseColor
        } else {
            color = baseColor.withAlphaComponent(0.25)
        }

        let material = SimpleMaterial(color: color, isMetallic: metallic)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "\(nodeNamePrefix)\(node.id)"
        entity.components.set(CollisionComponent(shapes: [.generateBox(size: [0.18, 0.18, 0.18])]))
        entity.components.set(InputTargetComponent())

        if node.isAccessible {
            let halo = ModelEntity(
                mesh: .generateCylinder(height: 0.004, radius: 0.085),
                materials: [SimpleMaterial(color: .white.withAlphaComponent(0.2), isMetallic: false)]
            )
            halo.position = [0, -0.06, 0]
            entity.addChild(halo)
        }

        return entity
    }

    private func nodeStyle(roomType: RoomType) -> (mesh: MeshResource, color: UIColor, metallic: Bool) {
        switch roomType {
        case .start:
            return (.generateCylinder(height: 0.14, radius: 0.045), .systemMint, false)
        case .battle:
            return (.generateSphere(radius: 0.055), .systemBlue, true)
        case .elite:
            return (.generateBox(size: 0.11), .systemOrange, true)
        case .rest:
            return (.generateCylinder(height: 0.12, radius: 0.05), .systemGreen, false)
        case .shop:
            return (.generateCone(height: 0.14, radius: 0.07), .systemTeal, false)
        case .event:
            return (.generateSphere(radius: 0.055), .systemPurple, false)
        case .boss:
            return (.generateBox(size: 0.14), .systemRed, true)
        }
    }
}
