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
        
        let textNode = SCNNode(geometry: text)
        
        guard let refNodeParent = refNode.parent, let boundingBox = refNode.geometry?.boundingBox else {
            assertionFailure("No parent!")
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
