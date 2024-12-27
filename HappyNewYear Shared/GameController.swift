//
//  GameController.swift
//  HappyNewYear Shared
//
//  Created by Siarhei Yakushevich on 27/12/2024.
//

import SceneKit

#if os(macOS)
    typealias SCNColor = NSColor
    typealias SCNFont = NSFont
#else
    typealias SCNColor = UIColor
    typealias SCNFont = UIFont
#endif


@MainActor
class GameController: NSObject, SCNSceneRendererDelegate {

    let scene: SCNScene
    let sceneRenderer: SCNSceneRenderer
    let treeNode: SCNNode
    //let textNode: SCNNode
    weak var spotLightNode: SCNNode!
    
    init(sceneRenderer renderer: SCNSceneRenderer) {
        sceneRenderer = renderer
        let scene = SCNScene(named: "xmasTree.scn")!
        self.scene = scene
        treeNode = scene.rootNode.childNode(withName: "tree", recursively: false)!
        super.init()
        
        /*if let tree = scene.rootNode.childNode(withName: "tree", recursively: true) {
            tree.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
        }*/
        
        setupScene()
        
        sceneRenderer.scene = scene
        sceneRenderer.delegate = self
    }
    
    private func runFlow(original: SCNVector3) async {
        
        //let position = treeNode.position
        treeNode.isHidden = false
        //var animation = SCNAnimation()
        //animation.duration = 2
        let cycleDuration = TimeInterval(2)
        let moveDuration = TimeInterval(3)
        //let angle = treeNode.eulerAngles
        let rotate = SCNAction.rotate(by: .pi * 2, around: .init(0, 1, 0), duration: cycleDuration)
        let count = Int(ceil(moveDuration/cycleDuration))
        let repetedRotation = SCNAction.repeat(rotate,
                                               count: count)//repeatForever(rotate)
        let moveAction = SCNAction.move(to: original, duration: moveDuration)
        await treeNode.runAction(SCNAction.group([repetedRotation, moveAction]))
        
        await setupTextNode(refNode: treeNode)
        
    }
    
    /*func bendTextAlongArc(textGeometry: SCNGeometry, arcRadius: Float, startAngle: Float, endAngle: Float) -> SCNGeometry {
        guard let mesh = textGeometry as? SCNMesh else { return textGeometry }
        
        var vertices = mesh.vertices
        let numVertices = vertices.count
        
        for i in 0..<numVertices {
            let vertex = vertices[i]
            let angle = Float(i) * (endAngle - startAngle) / Float(numVertices - 1) + startAngle
            
            // Calculate the new position based on the arc
            let newX = vertex.x * cos(angle) - vertex.z * sin(angle)
            let newY = vertex.y
            let newZ = vertex.x * sin(angle) + vertex.z * cos(angle)
            
            // Scale the vertex along the arc
            let scaleFactor = arcRadius / sqrt(newX * newX + newY * newY + newZ * newZ)
            vertices[i] = SCNVector3(x: newX * scaleFactor, y: newY * scaleFactor, z: newZ * scaleFactor)
        }
        
        let deformedMesh = SCNMesh(mesh: .vertexBuffer, vertices: vertices, indices: mesh.indices)
        return SCNGeometry(mesh: deformedMesh)
    } */
    
    func bendMesh(of geometry: SCNGeometry, alongAxis axis: String, radius: CGFloat) -> SCNGeometry! {
        guard let vertexSource = geometry.sources(for: .vertex).first else {
            print("No vertex source found")
            return nil
        }

        // Access vertex data
        let data = vertexSource.data
        let stride = vertexSource.dataStride
        let offset = vertexSource.dataOffset
        let count = vertexSource.vectorCount

        var newVertexData = Data(capacity: data.count)

        // Bending transformation
        let bendFunction: (SCNVector3) -> SCNVector3 = { vertex in
            var newVertex = vertex
            
            switch axis.lowercased() {
            case "x":
                let theta = vertex.x / radius
                newVertex.x = radius * sin(theta)
                newVertex.z = radius * (1 - cos(theta))
            case "z":
                let theta = vertex.z / radius
                newVertex.z = radius * sin(theta)
                newVertex.x = radius * (1 - cos(theta))
            default:
                print("Invalid axis. Use 'x' or 'z'.")
            }
            
            return newVertex
        }

        // Modify vertex positions
        data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            for i in 0..<count {
                let byteIndex = i * stride + offset
                let floatPointer = buffer.baseAddress!.advanced(by: byteIndex).assumingMemoryBound(to: Float.self)
                let originalVertex = SCNVector3(floatPointer[0], floatPointer[1], floatPointer[2])
                let modifiedVertex = bendFunction(originalVertex)
                newVertexData.append(contentsOf: [modifiedVertex.x, modifiedVertex.y, modifiedVertex.z].map { UInt8($0.bitPattern) })
            }
        }

        // Create a new geometry source with modified vertices
        let newVertexSource = SCNGeometrySource(
            data: newVertexData,
            semantic: .vertex,
            vectorCount: count,
            usesFloatComponents: true,
            componentsPerVector: vertexSource.componentsPerVector,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: offset,
            dataStride: stride
        )

        // Reuse geometry elements (topology remains the same)
        guard geometry.elementCount != 0 else {
            return geometry
        }
        return SCNGeometry(sources: [newVertexSource], elements: geometry.elements)
    }
    
    func createTextOnArc(text: String, radius: CGFloat, startAngle: CGFloat, angularSpan: CGFloat) -> SCNNode {
        let parentNode = SCNNode() // Container node for the text

        // Calculate the angle per character
        let anglePerCharacter = angularSpan / CGFloat(text.count)
        
        for (index, character) in text.enumerated() {
            // Create SCNText for each character
            let charGeometry = SCNText(string: String(character), extrusionDepth: 0)
            charGeometry.font = SCNFont.preferredFont(forTextStyle: .body)
            charGeometry.flatness = 0.1
            charGeometry.firstMaterial?.diffuse.contents = SCNColor.white
            
            // Create a node for the character
            let charNode = SCNNode(geometry: charGeometry)
            
            // Calculate the angle for this character
            let angle = startAngle + anglePerCharacter * CGFloat(index)
            
            // Calculate the position on the arc
            let x = radius * cos(angle)
            let y = radius * sin(angle)
            
            charNode.position = SCNVector3(x, y, 0)
            
            // Rotate the character to align with the arc
            charNode.eulerAngles = SCNVector3(0, 0, angle)
            
            // Add the character node to the parent node
            parentNode.addChildNode(charNode)
        }
        
        return parentNode
    }

    
    /*
     // Example usage
    let text = "Hello, SceneKit!"
    let radius: CGFloat = 10.0
    let startAngle: CGFloat = -.pi / 4 // Start at -45 degrees
    let angularSpan: CGFloat = .pi / 2 // Span 90 degrees
    let fontSize: CGFloat = 1.0

    let arcTextNode = createTextOnArc(text: text, radius: radius, startAngle: startAngle, angularSpan: angularSpan, fontSize: fontSize)
     */
    
    private func setupTextNode(refNode: SCNNode) async {
        let text = SCNText()
        
        text.string = "Happy New Year!"
        text.font = .preferredFont(forTextStyle: .body)
        text.firstMaterial?.diffuse.contents = SCNColor.yellow
        text.firstMaterial?.emission.contents = SCNColor.red
        text.firstMaterial?.shininess = 1.0
        text.firstMaterial?.isDoubleSided = true
        text.flatness = 0.1
        
        text.isWrapped = true
        text.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        text.truncationMode = CATextLayerTruncationMode.none.rawValue
        var rect = CGRect(origin: .zero, size: text.textSize)
        rect.size.width *= 0.8
        rect.size.height *= 2
        rect = rect.applying(.init(translationX: -rect.midX, y: -rect.midY))
        rect.size.height *= 2
        text.containerFrame = rect
        
        let textNode = SCNNode(geometry: text)//bendMesh(of: text, alongAxis: "x", radius: 10.0) ?? text)
        //debugPrint("!!! text size \(text.textSize)")
        
        /*let text = "Hello, SceneKit!"
        let radius: CGFloat = 10.0
        let startAngle: CGFloat = -.pi / 4 * 0 // Start at -45 degrees
        let angularSpan: CGFloat = .pi / 4 * 0 // Span 90 degrees
        
        let textNode = createTextOnArc(text: text, radius: radius, startAngle: startAngle, angularSpan: angularSpan)*/
        
        guard let refNodeParent = refNode.parent, let boundingBox = refNode.geometry?.boundingBox else {
            assertionFailure("No paretn!")
            return
        }
        
        textNode.opacity = 0
        var position = refNode.position
        position.y += ceil((boundingBox.max.y - boundingBox.min.y) * 0.1)
        textNode.position = position
        refNodeParent.addChildNode(textNode)
        
        let positionAction = SCNAction.sequence([.fadeIn(duration: 0.2), //.move(to: position, duration: 0.5),
                                                 .move(by: .init(x: 0, y: 0, z: 10),
                                                       duration: 0.25)])
        await textNode.runAction(positionAction)
        
        let textKeyPath = "extrusionDepth"
        let depthAnimation = CABasicAnimation(keyPath: textKeyPath)
        depthAnimation.duration = 0.1
        depthAnimation.fromValue = text.extrusionDepth
        depthAnimation.toValue = text.extrusionDepth + 1
        
        let caDepthAnimation = SCNAnimation(caAnimation: depthAnimation)
        caDepthAnimation.isAppliedOnCompletion = true
        
        text.addAnimation(caDepthAnimation, forKey: "depth")
        text.chamferRadius = 0.1
        
        caDepthAnimation.animationDidStop = { [weak self] animation, _, finished in
            guard finished, animation.keyPath == textKeyPath else {
                return
            }
            let basicDuration = TimeInterval(0.2)
            self?.spotLightNode.runAction(.fadeIn(duration: basicDuration))
            let positions: [SCNVector3] = [.init(4, 9, 8), .init(-4, 4, 10), .init(2, 20, 4)]
            let colors: [SCNColor] = [.init(.blue), .init(.red), .init(.pink)]
            assert(positions.count == colors.count)
            
            zip(positions, colors).forEach { position, color in
                //TODO: display light on the tree...
                let geometry = SCNCapsule(capRadius: 0.5, height: 1)//SCNSphere(radius: 1)
                let node = SCNNode(geometry: geometry)
                let light = SCNLight()
                light.type = .omni
                light.intensity = 10
                light.color = SCNColor.white
                
                /*let depthAnimation = CABasicAnimation(keyPath: "intensity")
                depthAnimation.duration = basicDuration
                depthAnimation.fromValue = light.intensity
                depthAnimation.toValue = light.intensity * 1.2
                
                let caDepthAnimation = SCNAnimation(caAnimation: depthAnimation)
                caDepthAnimation.autoreverses = true
                caDepthAnimation.repeatCount = .infinity //forever...
                light.addAnimation(caDepthAnimation, forKey: "intensity") */
                
                node.light = light
                geometry.firstMaterial?.diffuse.contents = color
                
                node.position = position
                self?.treeNode.addChildNode(node)
            }
        }
    }
    
    private func setupScene() {
        // move down...
        treeNode.isHidden = true
        treeNode.simdPosition = .zero
        let original = treeNode.position
        
        var position = original
        position.y += 100
        
        // move up...
        treeNode.localTranslate(by: position)
        
        let camera = SCNCamera()
        camera.zNear = 0
        camera.zFar = 100
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.simdPosition = .init(x: 0, y: Float(treeNode.boundingSphere.center.y), z: Float(0.5 * (camera.zFar - camera.zNear)))
        scene.rootNode.addChildNode(cameraNode)
        
        let spotLight = SCNLight()
        spotLight.type = .spot
        spotLight.color = SCNColor.white
        spotLight.castsShadow = true // Enable shadows
        spotLight.spotInnerAngle = 20
        spotLight.spotOuterAngle = 90
        let spotLightNode = SCNNode()
        spotLightNode.light = spotLight
        spotLightNode.position = cameraNode.position
        spotLightNode.look(at: SCNVector3(0, 0, 0)) // Pointing at the origin
        scene.rootNode.addChildNode(spotLightNode)
        spotLightNode.opacity = 0
        self.spotLightNode = spotLightNode
        
        sceneRenderer.pointOfView = cameraNode
        //sceneRenderer.debugOptions = [.showCameras, .showBoundingBoxes]
        Task { @MainActor [original] in
            await self.runFlow(original: original)
        }
    }
    
    func highlightNodes(atPoint point: CGPoint) {
        let hitResults = self.sceneRenderer.hitTest(point, options: [:])
        for result in hitResults {
            // get its material
            guard let material = result.node.geometry?.firstMaterial else {
                return
            }
            
            let original = material.emission.contents
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = original
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = SCNColor.red
            
            SCNTransaction.commit()
        }
    }
    
    nonisolated func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Called before each frame is rendered on the SCNSceneRenderer thread
    }

}
