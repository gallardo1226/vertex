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

class GameViewController: UIViewController {
    // Geometry
    var geometryNode: SCNNode = SCNNode()
    
    // Gestures
    var currentAngle: Float = 0.0

    
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
        
//        addPlayerSquare(scene)
        addPlayerTriangle(scene)
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        // create and add a light to the scene
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.whiteColor()
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
    
    func addPlayerTriangle(scene: SCNScene) {
        let positions = [
            SCNVector3Make(-1,-sqrt(3) / 2, 0),
            SCNVector3Make( 1,-sqrt(3) / 2, 0),
            SCNVector3Make( 0, sqrt(3) / 2, 0)
        ]
        let normals = [
            SCNVector3Make( -0.5, 0, 0),
            SCNVector3Make( 0.5, 0, 0),
            SCNVector3Make(-sqrt(3) / 2, 0, 0)
        ]
        var indices:[CInt] = [
            0, 1, 2
        ]
        let indexData = NSData(bytes:&indices, length:sizeof(CInt) * indices.count)
        var corners:[CInt] = [0, 1, 2]
        let cornerData = NSData(bytes:&corners, length:sizeof(CInt) * corners.count)
        let element = SCNGeometryElement(data: indexData, primitiveType: SCNGeometryPrimitiveType.Triangles, primitiveCount: 1, bytesPerIndex: sizeof(CInt))
        let vertexSource = SCNGeometrySource(vertices: positions, count: 3)
        let normalSource = SCNGeometrySource(normals:normals,
                count: 3)
        let triangle = SCNGeometry(sources: [vertexSource], elements: [element])
        triangle.firstMaterial!.diffuse.contents = UIColor.greenColor()
        let triangleNode = SCNNode(geometry: triangle)
        for p in positions {
            var sphere = SCNSphere(radius: 0.125)
            var cornerNode = SCNNode(geometry: sphere)
            cornerNode.position = p
            cornerNode.name = "Corner"
            triangleNode.addChildNode(cornerNode)
        }
        scene.rootNode.addChildNode(triangleNode)
    }
    
    func addPlayerSquare(scene: SCNScene) {
        let positions = [
            SCNVector3Make(-1,-1, 0),
            SCNVector3Make( 1,-1, 0),
            SCNVector3Make( 1, 1, 0),
            SCNVector3Make(-1, 1, 0)
        ]
        let normals = [
            SCNVector3Make( 0, -1, 0),
            SCNVector3Make( 0, 1, 0),
            SCNVector3Make(-1, 0, 0),
            SCNVector3Make( 1, 0, 0)
        ]
        var indices:[CInt] = [
            0, 1, 2,
            0, 2, 3
        ]
        let indexData = NSData(bytes:&indices, length:sizeof(CInt) * indices.count)
        var corners:[CInt] = [0, 1, 2, 3]
        let cornerData = NSData(bytes:&corners, length:sizeof(CInt) * corners.count)
        let element = SCNGeometryElement(data: indexData, primitiveType: SCNGeometryPrimitiveType.Triangles, primitiveCount: 2, bytesPerIndex: sizeof(CInt))
        let vertexSource = SCNGeometrySource(vertices: positions, count: 4)
        let normalSource = SCNGeometrySource(normals: normals,
            count: 4)
        let square = SCNGeometry(sources: [vertexSource], elements: [element])
        square.firstMaterial!.diffuse.contents = UIColor.purpleColor()
        let squareNode = SCNNode(geometry: square)
        
        for p in positions {
            let sphere = SCNSphere(radius: 0.125)
            let cornerNode = SCNNode(geometry: sphere)
            cornerNode.position = p
            squareNode.addChildNode(cornerNode)
        }
        
        scene.rootNode.addChildNode(squareNode)
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
                
                if result.node.name == "Corner" {
                    println("Found corner")
                }
            }
        }
    }
    
    func panGesture(sender: UIPanGestureRecognizer) {
        let translation = sender.translationInView(sender.view!)
        var newAngle = (Float)(translation.x)*(Float)(M_PI)/180.0
        newAngle += currentAngle
        
        geometryNode.transform = SCNMatrix4MakeRotation(newAngle, 0, 1, 0)
        
        if(sender.state == UIGestureRecognizerState.Ended) {
            currentAngle = newAngle
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
