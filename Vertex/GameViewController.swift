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

struct States {
	let began = UIGestureRecognizerState.Began
	let ended = UIGestureRecognizerState.Ended
	let changed = UIGestureRecognizerState.Changed
	let cancelled = UIGestureRecognizerState.Cancelled
	let failed = UIGestureRecognizerState.Failed
	let possible = UIGestureRecognizerState.Possible
}

class GameViewController: UIViewController, SCNSceneRendererDelegate {

	let states = States()

    var fillLevel = 0.0
    let maxFill = 100.0
    let cyclesBetweenNextFill = 1
    let maxArea = 100.0
    var cycleCount = 0
    var sizeOfHole = 0.0
    var shapeUncovered = false
    var x: Float = 0.0
    var score = 0
    
    var numVertices = 3
    var holeNode = SCNNode()
    var firstHole = true
    var holePositions = [SCNVector3]()
    
    var fillNode = SCNNode()
    var fillPositions = [SCNVector3]()
    var firstFill = true

	var selectedNode:SCNNode? = nil
    
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
		configureGestures(scnView)
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
            fillLevel += fillSpace(sizeOfHole)
//            println(fillLevel)
        }
        
        drawFillLine(fillLevel)
        
        if (fillLevel >= maxFill) {
            // Game Over
        }
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
        
        scene.rootNode.addChildNode(squareNode)
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
        let minX = Float(0)
        let maxY = Float(5)
        let minY = Float(0)
        
        var xs = [Float]()
        var ys = [Float]()
        
        for ii in 0...(numVertices-1) {
            xs.append(Float(((Float(arc4random()) / Float(UINT32_MAX)) * maxX)))
            ys.append(Float(((Float(arc4random()) / Float(UINT32_MAX)) * maxY)))
        }
        
        
        if (firstHole) {
            (self.view as! SCNView).scene?.rootNode.addChildNode(holeNode)
            firstHole = false
        }

        
        //(self.view as! SCNView).scene?.rootNode.addChildNode(holeNode)
        
        holePositions = [SCNVector3]()
        
        for jj in 0...(numVertices-1) {
            holePositions.append(SCNVector3Make(Float(xs[jj]), Float(ys[jj]), 0.0))
        }
        
        var indices:[CInt] = [
            0, 1, 2,
        ]
        var indexData = NSData(bytes:&indices, length:sizeof(CInt) * indices.count)
        var element = SCNGeometryElement(data: indexData, primitiveType: SCNGeometryPrimitiveType.Triangles, primitiveCount: 2, bytesPerIndex: sizeof(CInt))
        var vertexSource = SCNGeometrySource(vertices: holePositions, count: numVertices)
        
        var hole = SCNGeometry(sources: [vertexSource], elements: [element])
        hole.firstMaterial!.diffuse.contents = UIColor.blueColor()
        var tempNode = SCNNode(geometry: hole)
        (self.view as! SCNView).scene?.rootNode.replaceChildNode(holeNode, with: tempNode)
        holeNode = tempNode
        
        return calcArea(holeNode, xVals: xs, yVals: ys)
    }
    
    func calcArea(node: SCNNode, xVals: [Float], yVals: [Float]) -> Double {
        var sum = 0.0

        for ii in 0...(numVertices-2) {
            sum += Double(xVals[ii]*yVals[ii+1] - yVals[ii]*xVals[ii+1])
        }

        sum += Double(xVals[numVertices-1]*yVals[0] - yVals[numVertices-1]*xVals[0])
        
        return 0.5 * Double(abs(sum))
        
    }
    
    func drawFillLine(newFill: Double) {
        
        if (firstFill) {
            (self.view as! SCNView).scene?.rootNode.addChildNode(fillNode)
            firstFill = false
        }
        
        var fillPlane = SCNPlane(width: 50, height: 0.1)
        fillPlane.firstMaterial!.diffuse.contents = UIColor.cyanColor()
        var tempNode = SCNNode(geometry: fillPlane)
        tempNode.position = SCNVector3(x: Float(-10), y: Float(newFill-10), z: Float(0))
        (self.view as! SCNView).scene?.rootNode.replaceChildNode(fillNode, with: tempNode)
        fillNode = tempNode

    }
    
    func fillSpace(size: Double) -> Double {
        return size/100
    }
    
    func isHoleCovered() -> Bool {
        return false
    }

	func configureGestures(view: SCNView) {
		let selectGesture = UITapGestureRecognizer(target: self, action: "handleSelect")
		selectGesture.numberOfTouchesRequired = 1
		if selectGesture.state == states.ended ||
			selectGesture.state == states.cancelled {
			selectedNode = nil
		}

		let dragGesture = UIPanGestureRecognizer(target: self, action: "handleDrag:")

		var gestureRecognizers = [AnyObject]()
		gestureRecognizers.append(dragGesture)
		if let existingGestureRecognizers = view.gestureRecognizers {
			gestureRecognizers.extend(existingGestureRecognizers)
		}
		view.gestureRecognizers = gestureRecognizers
	}

	func handleSelect(recognizer: UITapGestureRecognizer) {
		// retrieve the SCNView
		let scnView = self.view as! SCNView
		// check what nodes are tapped
		let p = recognizer.locationInView(scnView)
		if let hitResults = scnView.hitTest(p, options: nil) {
			// check that we clicked on at least one object
			if hitResults.count > 0 {
				// retrieved the first clicked object
				let result: AnyObject! = hitResults[0]
				if result.node.name == "Corner" {
					selectedNode = result.node
				}
			}
		}
	}

    func handleDrag(recognizer: UIPanGestureRecognizer) {
		let translation = recognizer.translationInView(self.view)
		if let view = recognizer.view {
			if selectedNode != nil {
			view.center = CGPoint(x:view.center.x + translation.x,
				y:view.center.y + translation.y)
			}
		}
		recognizer.setTranslation(CGPointZero, inView: self.view)
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
