//
//  ViewController.swift
//  AR Sumikko
//
//  Created by Kenneth Wong on 21/12/2020.
//  Copyright © 2020 Kenneth Wong. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var animations = [String: CAAnimation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        sceneView.autoenablesDefaultLighting = true
        
        loadAnimations()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        
        if let imageToTrack = ARReferenceImage.referenceImages(inGroupNamed: "Coasters", bundle: Bundle.main){
            
            configuration.trackingImages = imageToTrack
            
            configuration.maximumNumberOfTrackedImages = 2
            
            print("detected images added")
            
        }
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {

        let rootNode = SCNNode()
        
        DispatchQueue.main.async {
            
        if let imageAnchor = anchor as? ARImageAnchor {
            
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width
                , height: imageAnchor.referenceImage.physicalSize.height)
            
            plane.firstMaterial?.diffuse.contents = UIColor(white: 1.0, alpha: 0.5)
            
            let planeNode = SCNNode(geometry: plane)
            
            planeNode.eulerAngles.x = -.pi/2
            
            planeNode.name = "planeNode"
            
            rootNode.addChildNode(planeNode)
            
            // Add reference image to be identified
            if imageAnchor.referenceImage.name == "tempura_coaster" {
                
                // Add 3D model to be shown
                guard let sumikkoScene = SCNScene(named: "art.scnassets/tempura_0001_idle.dae") else {fatalError("model not imported")}
                
                let sumikkoNode = SCNNode()
                
                sumikkoNode.name = "sumikkoNode"
                
                for childNode in sumikkoScene.rootNode.childNodes {
                    
                    sumikkoNode.addChildNode(childNode)
                    
                }
                
                sumikkoNode.simdScale = simd_float3(3, 3, 3)

                sumikkoNode.eulerAngles.x = .pi/2

                sumikkoNode.position.z = 0.04
                            
                planeNode.addChildNode(sumikkoNode)
                        
            }
                
            }
            
            }
        return rootNode
    }
    
    
    // Pre-load animation into 3D model
    func loadAnimations() {
        let sceneURL = Bundle.main.url(forResource: "art.scnassets/tempura_0001_shakehands", withExtension: "dae")
    
        let sceneSource = SCNSceneSource(url: sceneURL!, options: nil)
        
        if let animationObject = sceneSource?.entryWithIdentifier("tempura_0001_shakehands-1", withClass: CAAnimation.self){
            
            animationObject.repeatCount = 1
            
            animationObject.fadeInDuration = CGFloat(1)

            animationObject.fadeOutDuration = CGFloat(0.5)
            
            animations["shakehands"] = animationObject
            
        }
    }
        
    // Action when user touches 3D model
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let location = touches.first!.location(in: sceneView)
        
        var hitTestOptions = [SCNHitTestOption: Any]()
        
        hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
        
        let hitResults: [SCNHitTestResult] = sceneView.hitTest(location, options: hitTestOptions)
        
        // When user touches the 3D model
        if hitResults.first != nil {
            // Character shakes hands
            playAnimation(key: "shakehands")
        } else {
            // When user touches again, character stops and shakes hands again 
            stopAnimation(key: "shakehands")
        }
    
    }
    
    func playAnimation(key: String){
        
        // Add root node for landing spot of 3D model
        let rootNode = sceneView.scene.rootNode
        
        guard let planeNode = rootNode.childNode(withName: "planeNode", recursively: true) else {fatalError("can't find plane node")}
        
        guard let sumikkoNode = planeNode.childNode(withName: "sumikkoNode", recursively: true) else {fatalError("can't find sumikko node")}
        
        print(sumikkoNode)
        
        sumikkoNode.addAnimation(animations[key]!, forKey: key)
        
    }
    
    func stopAnimation(key: String){
        sceneView.scene.rootNode.removeAnimation(forKey: key, blendOutDuration: CGFloat(0.5))
    }
            
}
