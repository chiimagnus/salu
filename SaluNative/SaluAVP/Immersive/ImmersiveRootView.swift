import SwiftUI
import RealityKit
import UIKit
import GameCore

struct ImmersiveRootView: View {
    @Environment(RunSession.self) private var runSession

    private let nodeNamePrefix = "node:"
    private let roomPanelAttachmentId = "roomPanel"
    private let mapLayerPrefix = "mapLayer_floor_"
    private let uiLayerName = "uiLayer"

    var body: some View {
        RealityView { content, attachments in
            let mapRoot = RealityKit.Entity()
            mapRoot.name = "mapRoot"

            let mapLayer = RealityKit.Entity()
            mapLayer.name = "\(mapLayerPrefix)0"
            mapRoot.addChild(mapLayer)

            let uiLayer = RealityKit.Entity()
            uiLayer.name = uiLayerName
            mapRoot.addChild(uiLayer)

            content.add(mapRoot)
        } update: { content, attachments in
            guard let mapRoot = content.entities.first(where: { $0.name == "mapRoot" }) else { return }

            let uiLayer = mapRoot.findEntity(named: uiLayerName) ?? {
                let uiLayer = RealityKit.Entity()
                uiLayer.name = uiLayerName
                mapRoot.addChild(uiLayer)
                return uiLayer
            }()

            uiLayer.children.forEach { $0.removeFromParent() }

            guard let run = runSession.runState else {
                mapRoot.children.first(where: { $0.name.hasPrefix(mapLayerPrefix) })?.removeFromParent()
                return
            }

            // Only rebuild the map when entering a new floor/act.
            let desiredMapLayerName = "\(mapLayerPrefix)\(run.floor)"
            let existingMapLayer = mapRoot.children.first(where: { $0.name.hasPrefix(mapLayerPrefix) })
            let mapLayer: RealityKit.Entity

            if existingMapLayer?.name == desiredMapLayerName {
                mapLayer = existingMapLayer!
                updateMapState(run: run, in: mapLayer)
            } else {
                existingMapLayer?.removeFromParent()
                let newLayer = RealityKit.Entity()
                newLayer.name = desiredMapLayerName
                mapRoot.addChild(newLayer)
                addFloor(to: newLayer)
                renderMap(run: run, into: newLayer)
                mapLayer = newLayer
            }

            if let panel = attachments.entity(for: roomPanelAttachmentId) {
                panel.name = roomPanelAttachmentId
                panel.components.set(BillboardComponent())
                panel.components.set(InputTargetComponent())
                let (isVisible, position) = roomPanelPlacement(mapRoot: mapLayer, route: runSession.route)
                panel.isEnabled = isVisible
                panel.position = position
                uiLayer.addChild(panel)
            }
        } attachments: {
            Attachment(id: roomPanelAttachmentId) {
                RoomPanel(route: runSession.route) {
                    runSession.completeCurrentRoomAndReturnToMap()
                }
            }
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
    }

    private func roomPanelPlacement(mapRoot: RealityKit.Entity, route: RunSession.Route) -> (isVisible: Bool, position: SIMD3<Float>) {
        switch route {
        case .map:
            return (false, .zero)

        case .room(let nodeId, _):
            let nodeName = "\(nodeNamePrefix)\(nodeId)"
            if let node = mapRoot.findEntity(named: nodeName) {
                // Place the panel above the selected node; billboard will face the user.
                return (true, node.position + [0, 0.18, 0])
            }

            // Fallback: place in front of the map origin.
            return (true, [0, 0.25, -0.55])
        }
    }

    private func addFloor(to root: RealityKit.Entity) {
        let floor = RealityKit.Entity()
        floor.name = "floor"
        floor.components.set(CollisionComponent(shapes: [.generateBox(size: [2.8, 0.01, 4.2])]))
        floor.components.set(InputTargetComponent())
        root.addChild(floor)
    }

    private func updateMapState(run: RunState, in mapLayer: RealityKit.Entity) {
        // Map topology within the same floor doesn't change; only node state changes.
        for node in run.map {
            guard let entity = mapLayer.findEntity(named: "\(nodeNamePrefix)\(node.id)") as? ModelEntity else { continue }
            applyNodeAppearance(entity: entity, node: node, isCurrent: run.currentNodeId == node.id)
        }
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
        let (mesh, _, _) = nodeStyle(roomType: node.roomType)
        let entity = ModelEntity(mesh: mesh, materials: [])
        entity.name = "\(nodeNamePrefix)\(node.id)"
        entity.components.set(CollisionComponent(shapes: [.generateBox(size: [0.18, 0.18, 0.18])]))
        entity.components.set(InputTargetComponent())
        applyNodeAppearance(entity: entity, node: node, isCurrent: isCurrent)

        return entity
    }

    private func applyNodeAppearance(entity: ModelEntity, node: MapNode, isCurrent: Bool) {
        let (_, baseColor, metallic) = nodeStyle(roomType: node.roomType)

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

        entity.model?.materials = [SimpleMaterial(color: color, isMetallic: metallic)]

        let shouldShowHalo = node.isAccessible && !node.isCompleted
        let existingHalo = entity.children.first(where: { $0.name == "halo" })
        if shouldShowHalo {
            if existingHalo == nil {
                let halo = ModelEntity(
                    mesh: .generateCylinder(height: 0.004, radius: 0.085),
                    materials: [SimpleMaterial(color: .white.withAlphaComponent(0.2), isMetallic: false)]
                )
                halo.name = "halo"
                halo.position = [0, -0.06, 0]
                entity.addChild(halo)
            }
        } else {
            existingHalo?.removeFromParent()
        }
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

private struct RoomPanel: View {
    let route: RunSession.Route
    let onComplete: () -> Void

    var body: some View {
        Group {
            switch route {
            case .map:
                EmptyView()

            case .room(let nodeId, let roomType):
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(roomType.icon) \(roomType.displayName(language: .zhHans))")
                        .font(.headline)

                    Text("Node: \(nodeId)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Complete") {
                        onComplete()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private extension RunSession.Route {
    var isRoom: Bool {
        if case .room = self { return true }
        return false
    }
}
