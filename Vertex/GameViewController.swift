//
//  GameViewController.swift
//  Vertex
//
//  Created by Noah Conley on 4/27/15.
//  Copyright (c) 2015 EECS370. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController, SCNSceneRendererDelegate {

    
    var fillLevel = 0.0
    let maxFill = 100.0
    let cyclesBetweenNextFill = 1000
    let maxArea = 100.0
    var cycleCount = 0
    var sizeOfHole = 0.0
    var shapeUncovered = false
    var x: Float = 0.0
    var score = 0
    
    var numVertices = 3
    var holeNode = SCNNode()
    var firstHole = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (self.view as! SCNView).delegate = self
        (self.view as! SCNView).playing = true
        
        // create a new scene
        let scene = SCNScene()
        
        var positions = [
            SCNVector3Make(-3,-1, 0),
            SCNVector3Make( 2,-1, 0),
            SCNVector3Make( 1, 3, 0),
            SCNVector3Make(-3, 0, 0)
        ]
        
        var indices:[CInt] = [
            // bottom
            0, 1, 2,
            0, 2, 3
        ]
        
        var indexData = NSData(bytes:&indices, length:sizeof(CInt) * indices.count)
        
        var corners:[CInt] = [0, 1, 2, 3]
        
        var cornerData = NSData(bytes:&corners, length:sizeof(CInt) * corners.count)
        
        var element = SCNGeometryElement(data: indexData, primitiveType: SCNGeometryPrimitiveType.Triangles, primitiveCount: 2, bytesPerIndex: sizeof(CInt))
        
        var vertexSource = SCNGeometrySource(vertices: positions, count: 4)
        
        var square = SCNGeometry(sources: [vertexSource], elements: [element])
        
        let squareNode = SCNNode(geometry: square)
        
        var sphere1 = SCNSphere()
        var sphere2 = SCNSphere()
        var sphere3 = SCNSphere()
        var sphere4 = SCNSphere()
        
        var spheres = [sphere1, sphere2, sphere3, sphere4]
        
        var index = 0
        for p in positions {
            spheres[index] = SCNSphere(radius: 0.125)
            var cornerNode = SCNNode(geometry: spheres[index])
            cornerNode.position = p
            squareNode.addChildNode(cornerNode)
        }
        
        scene.rootNode.addChildNode(squareNode)
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
//        scnView.allowsCameraControl = true
//        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.lightGrayColor()
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: "handleTap:")
        var gestureRecognizers = [AnyObject]()
        gestureRecognizers.append(tapGesture)
        if let existingGestureRecognizers = scnView.gestureRecognizers {
            gestureRecognizers.extend(existingGestureRecognizers)
        }
        scnView.gestureRecognizers = gestureRecognizers
        
    }
    
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        
        // If hole has been covered, generate new hole
        if (!shapeUncovered) {
            sizeOfHole = generateShape(numVertices)
            shapeUncovered = true
        } else {
            if (isHoleCovered()) {
                shapeUncovered = false
                score += Int(sizeOfHole)
            }
        }
            
        // Increment the cycle count
        cycleCount++
            
        // If needed, reset cycle count and fill space
        if (cycleCount == cyclesBetweenNextFill) {
            cycleCount = 0
            fillLevel = fillLevel + fillSpace(sizeOfHole)
        }
        
        if (fillLevel >= maxFill) {
            // Game Over
        }
        
        
    }
    
    func generateShape(numVertices: Int) -> Double {
        
        /*
        let screenSize = self.view.frame.size
        
        let maxX = Float(screenSize.width)
        let minX = Float(0)
        let maxY = Float(screenSize.height)
        let minY = Float(0)
        */
        
        let maxX = Float(3)
        let minX = Float(-3)
        let maxY = Float(5)
        let minY = Float(-5)
        
        var xs = [Int]()
        var ys = [Int]()
        
        for ii in 0...(numVertices-1) {
            xs.append(Int(((Float(arc4random()) / Float(UINT32_MAX)) * (maxX-minX)) - maxX))
            ys.append(Int(((Float(arc4random()) / Float(UINT32_MAX)) * (maxY-minY)) - maxY))
        }
        
        if (firstHole) {
            (self.view as! SCNView).scene?.rootNode.addChildNode(holeNode)
            firstHole = false
        }
        
        var positions = [SCNVector3]()
        
        for jj in 0...(numVertices-1) {
            positions.append(SCNVector3Make(Float(xs[jj]), Float(ys[jj]), 0.0))
        }
        
        var indices:[CInt] = [
            // bottom
            0, 1, 2,
            0, 2, 3
        ]
        
        var indexData = NSData(bytes:&indices, length:sizeof(CInt) * indices.count)
        
        var element = SCNGeometryElement(data: indexData, primitiveType: SCNGeometryPrimitiveType.Triangles, primitiveCount: 2, bytesPerIndex: sizeof(CInt))
        
        var vertexSource = SCNGeometrySource(vertices: positions, count: 4)
        
        var hole = SCNGeometry(sources: [vertexSource], elements: [element])
        
        var tempNode = SCNNode(geometry: hole)
        
        (self.view as! SCNView).scene?.rootNode.replaceChildNode(holeNode, with: tempNode)
        
        holeNode = tempNode
        
        return calcArea(holeNode, xVals: xs, yVals: ys)
    }
    
    func calcArea(node: SCNNode, xVals: [Int], yVals: [Int]) -> Double {
        var product = 1

        for ii in 0...(numVertices-2) {
            product *= (xVals[ii]*yVals[ii+1] - yVals[ii]*xVals[ii+1])
        }
        
        product *= (xVals[numVertices-1]*yVals[0] - yVals[numVertices-1]*xVals[0])
        
        return 0.5 * Double(product)
        
    }
    
    
    func fillSpace(size: Double) -> Double {
        return size/10
    }
    
    func isHoleCovered() -> Bool {
        return false
    }
    
    func handleTap(gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.locationInView(scnView)
        if let hitResults = scnView.hitTest(p, options: nil) {
            // check that we clicked on at least one object
            if hitResults.count > 0 {
                // retrieved the first clicked object
                let result: AnyObject! = hitResults[0]
                
                // get its material
                let material = result.node!.geometry!.firstMaterial!
                
                // highlight it
                SCNTransaction.begin()
                SCNTransaction.setAnimationDuration(0.5)
                
                // on completion - unhighlight
                SCNTransaction.setCompletionBlock {
                    SCNTransaction.begin()
                    SCNTransaction.setAnimationDuration(0.5)
                    
                    material.emission.contents = UIColor.blackColor()
                    
                    SCNTransaction.commit()
                }
                
                material.emission.contents = UIColor.redColor()
                
                SCNTransaction.commit()
            }
        }
    }
    
    
    
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
