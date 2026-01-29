import SwiftUI
import RealityKit

struct ImmersiveRootView: View {
    @State private var isMarkerSelected = false

    var body: some View {
        RealityView { content in
            let root = Entity()

            let floor = ModelEntity(
                mesh: .generatePlane(width: 2.0, depth: 2.0),
                materials: [SimpleMaterial(color: .gray.withAlphaComponent(0.25), isMetallic: false)]
            )
            floor.name = "floor"
            floor.components.set(CollisionComponent(shapes: [.generateBox(size: [2.0, 0.01, 2.0])]))
            root.addChild(floor)

            let marker = ModelEntity(
                mesh: .generateBox(size: 0.12),
                materials: [SimpleMaterial(color: isMarkerSelected ? .systemGreen : .systemBlue, isMetallic: true)]
            )
            marker.name = "marker"
            marker.position = [0, 0.06, -0.4]
            marker.components.set(CollisionComponent(shapes: [.generateBox(size: [0.12, 0.12, 0.12])]))
            root.addChild(marker)

            content.add(root)
        } update: { content in
            guard let root = content.entities.first,
                  let marker = root.findEntity(named: "marker") as? ModelEntity
            else { return }

            marker.model?.materials = [
                SimpleMaterial(color: isMarkerSelected ? .systemGreen : .systemBlue, isMetallic: true)
            ]
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    if value.entity.name == "marker" {
                        isMarkerSelected.toggle()
                    }
                }
        )
    }
}

