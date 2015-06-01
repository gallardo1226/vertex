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

struct vector {
    var vec = SCNVector3()
    var angle: Float = 0
}


class GameViewController: UIViewController, SCNSceneRendererDelegate {
    var fillLevel = 0.0
    let maxFill = 16.0
    let cyclesBetweenNextFill = 1
    let maxArea = 100.0
    var cycleCount = 0
    var sizeOfHole = 0.0
    var shapeUncovered = false
    var x: Float = 0.0
    var score = 0
    var winScore = 5
    
    var tempCounter = 1000
    
    var numVertices = 3
    var holeNode = SCNNode()
    var firstHole = true
    var holePositions = [SCNVector3]()
    
    var fillNode = SCNNode()
    var fillPositions = [SCNVector3]()
    var firstFill = true
    
    var waterNode = SCNNode()
    
    var spillNode = SCNNode()
    var spillTriNode = SCNNode()
    var spillPositions = [SCNVector3]()
    var firstSpill = true
    var zerothSpillIsHigher = true
    var zerothSpillIsFarther = false
    
    var scoreLabel = UILabel()
    
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
        
        var scoreLabel = UILabel()
        scoreLabel.text = "0"
        scoreLabel.textColor = UIColor.yellowColor()
        scoreLabel.center = CGPointMake(0, 0)
        var view = SCNView()
        
    }
    
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        /*
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
        */
        if (tempCounter >= 100) {
            sizeOfHole = generateShape(numVertices)
            score += 1
            scoreLabel.text = String(score)
            tempCounter = 0
        }
        
        //drawSpillLine()
        
        tempCounter++
        
        // Increment the cycle count
        cycleCount++
            
        // If needed, reset cycle count and fill space
        if (cycleCount == cyclesBetweenNextFill) {
            cycleCount = 0
            if (fillLevel <= maxFill) {
                fillLevel += fillSpace(sizeOfHole)
            }
            
            //println(fillLevel)
        }
        
        drawFillLine(fillLevel)
        
        if (fillLevel > maxFill) {
            // Game Over
        }
        
        if (score >= winScore) {
            numVertices += 1
            fillLevel = 0.0
            score = 0
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
        let screenSize = (self.view as! SCNView).window?.bounds
        
        let maxX = Float(screenSize.width)
        let minX = Float(0)
        let maxY = Float(screenSize.height)
        let minY = Float(0)
        */
        
        let maxX = Float(5)
        let minX = Float(-5)
        let maxY = Float(7)
        let minY = Float(-7)
        
        var xs = [Float]()
        var ys = [Float]()
        
        do {
        
            xs = [Float]()
            ys = [Float]()
            
            for ii in 0...(numVertices-1) {
                xs.append(Float(((Float(arc4random()) / Float(UINT32_MAX)) * (maxX - minX)) - maxX))
                ys.append(Float(((Float(arc4random()) / Float(UINT32_MAX)) * (maxY - minY)) - maxY))
            }
        
        } while (distantEnough(xs, yVals: ys) && fatEnough(xs, yVals: ys) && (calcArea(xs, yVals: ys) < 1.5) && (calcArea(xs, yVals: ys) >= 3))
        
        if (firstHole) {
            (self.view as! SCNView).scene?.rootNode.addChildNode(holeNode)
            firstHole = false
        }

        holePositions = [SCNVector3]()
        spillPositions = [SCNVector3]()
        spillPositions = findSpillPoints(xs, yVals: ys)
        
        for jj in 0...(numVertices-1) {
            holePositions.append(SCNVector3Make(Float(xs[jj]), Float(ys[jj]), 0))
        }
        
        holePositions = sortPoints(holePositions)

        var indices = [CInt]()
        var index: CInt = 1
        
        for ii in 0...(numVertices-3) {
            indices.append(CInt(0))
            indices.append(index)
            indices.append(index+1)
            index++
        }
        
        var indexData = NSData(bytes:&indices, length:sizeof(CInt) * indices.count)
        var element = SCNGeometryElement(data: indexData, primitiveType: SCNGeometryPrimitiveType.Triangles, primitiveCount: numVertices-2, bytesPerIndex: sizeof(CInt))
        var vertexSource = SCNGeometrySource(vertices: holePositions, count: numVertices)
        
        var hole = SCNGeometry(sources: [vertexSource], elements: [element])
        hole.firstMaterial!.diffuse.contents = UIColor.blueColor()
        var tempNode = SCNNode(geometry: hole)
        (self.view as! SCNView).scene?.rootNode.replaceChildNode(holeNode, with: tempNode)
        holeNode = tempNode
        
        return calcArea(xs, yVals: ys)
    }
    
    func calcArea(xVals: [Float], yVals: [Float]) -> Double {
        var sum = 0.0

        for ii in 0...(numVertices-2) {
            sum += Double(xVals[ii]*yVals[ii+1] - yVals[ii]*xVals[ii+1])
        }

        sum += Double(xVals[numVertices-1]*yVals[0] - yVals[numVertices-1]*xVals[0])
        
        return 0.15 * Double(abs(sum))
        
    }
    
    func sortPoints(hp: [SCNVector3]) -> [SCNVector3] {
        
        var minX = MAXFLOAT
        var maxX = -1*MAXFLOAT
        var minY = MAXFLOAT
        var maxY = -1*MAXFLOAT
        
        for ii in 0...(numVertices-1) {
            if (hp[ii].x < minX) {
                minX = hp[ii].x
            }
            if (hp[ii].x > maxX) {
                maxX = hp[ii].x
            }
            if (hp[ii].y < minY) {
                minY = hp[ii].y
            }
            if (hp[ii].y > maxY) {
                maxY = hp[ii].y
            }
        }
        
        var center = SCNVector3Make(maxX-minX, maxY-minY, 0)
        
        var vectorArray = [vector]()
        
        for jj in 0...(numVertices-1) {
            var tempVec = vector(vec: hp[jj], angle: atan2(hp[jj].x - center.x, hp[jj].y - center.y))
            vectorArray.append(tempVec)
        }
        
        vectorArray.sort({$0.angle < $1.angle})
        
        var newArray = [SCNVector3]()
        
        for kk in 0...(numVertices-1) {
            newArray.append(vectorArray[kk].vec)
        }
        
        return newArray
        
    }
    
    func distantEnough(xVals: [Float], yVals: [Float]) -> Bool {
        var isBigEnough = true
        
        for ii in 0...(numVertices-1) {
            
            if (sqrt(pow((xVals[ii]-xVals[(ii+1)%numVertices]), 2) + pow((yVals[ii]-yVals[(ii+1)%numVertices]), 2)) < 0.5) {
                isBigEnough = false
            }
        }
        
        return isBigEnough
    }
    
    func fatEnough(xVals: [Float], yVals: [Float]) -> Bool {
        var isFatEnough = true
        
        var vectors = [SCNVector3]()
        
        for ii in 0...(numVertices-1) {
            
            vectors.append(SCNVector3Make(xVals[(numVertices+ii-1)%numVertices] - xVals[ii], yVals[(numVertices+ii-1)%numVertices] - yVals[ii], 0))
            vectors.append(SCNVector3Make(xVals[ii] - xVals[(ii+1)%numVertices], yVals[ii] - yVals[(ii+1)%numVertices], 0))
            
        }
        
        for ii in 0...(numVertices-1) {
            
            var dotProduct = (vectors[2*ii].x*vectors[2*ii+1].x) + (vectors[2*ii].y*vectors[2*ii+1].y)
            var distProduct = simpleDist([vectors[2*ii].x, vectors[2*ii].y]) * simpleDist([vectors[2*ii+1].x, vectors[2*ii+1].y])
            
            var x = acos(dotProduct/distProduct)
            
            
            if (x >= 0) {
                if (x < 3.14/6 || x > (5*3.14)/6) {
                    isFatEnough = false
                }
            } else {
                if (x > -3.14/6 || x < (-5*3.14)/6) {
                    isFatEnough = false
                }
            }
        }
        
        return isFatEnough
    }
    
    func distanceFormula(x1: Float, x2: Float, y1: Float, y2: Float) -> Float {
        return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2))
    }
    
    func simpleDist(n: [Float]) -> Float {
        return sqrt(pow(n[0], 2) + pow(n[1], 2))
    }
    
    func drawFillLine(newFill: Double) {
        
        if (firstFill) {
            (self.view as! SCNView).scene?.rootNode.addChildNode(fillNode)
            (self.view as! SCNView).scene?.rootNode.addChildNode(waterNode)
            firstFill = false
        }
        
        var fillPlane = SCNPlane(width: 13, height: 0.1)
        fillPlane.firstMaterial!.diffuse.contents = UIColor.cyanColor()
        var tempNode = SCNNode(geometry: fillPlane)
        tempNode.position = SCNVector3(x: Float(0), y: Float(newFill-8), z: Float(0))
        (self.view as! SCNView).scene?.rootNode.replaceChildNode(fillNode, with: tempNode)
        fillNode = tempNode
        
        var waterPlane = SCNPlane(width: 13, height: 20)
        waterPlane.firstMaterial!.diffuse.contents = UIColor.cyanColor()
        var tempNode2 = SCNNode(geometry: waterPlane)
        tempNode2.position = SCNVector3(x: Float(0), y: Float(newFill-8-10), z: Float(0))
        tempNode2.opacity = 0.5
        (self.view as! SCNView).scene?.rootNode.replaceChildNode(waterNode, with: tempNode2)
        waterNode = tempNode2

    }
    
    func drawSpillLine() {
        
        if (firstSpill) {
            (self.view as! SCNView).scene?.rootNode.addChildNode(spillNode)
            (self.view as! SCNView).scene?.rootNode.addChildNode(spillTriNode)
            firstSpill = false
        }
        
        var w: Float = abs(spillPositions[0].x - spillPositions[1].x)
        var h: Float = abs(Float(spillPositions[0].y) - Float(fillLevel) - Float(8))
        var hTri: Float = abs(spillPositions[0].y - spillPositions[1].y)
        var leastX: Float = 0
        var greatestY: Float = 0
        
        if (zerothSpillIsFarther) {
            leastX = spillPositions[1].x
        } else {
            leastX = spillPositions[0].x
        }
        
        
        if (spillPositions[0].y < Float(fillLevel-8)) {
            var tempNode = SCNNode()
            (self.view as! SCNView).scene?.rootNode.replaceChildNode(spillTriNode, with: tempNode)
            spillTriNode = tempNode
            
            var tempNode2 = SCNNode()
            (self.view as! SCNView).scene?.rootNode.replaceChildNode(spillNode, with: tempNode2)
            spillNode = tempNode2
            
        } else {
            
            let positions = [
                SCNVector3Make(spillPositions[0].x, spillPositions[1].y, 0),
                SCNVector3Make(spillPositions[1].x, spillPositions[1].y, 0),
                SCNVector3Make(spillPositions[1].x, spillPositions[0].y, 0)
            ]
            var indices:[CInt] = [
                0, 1, 2
            ]
            let indexData = NSData(bytes:&indices, length:sizeof(CInt) * indices.count)
            var corners:[CInt] = [0, 1, 2]
            let cornerData = NSData(bytes:&corners, length:sizeof(CInt) * corners.count)
            let element = SCNGeometryElement(data: indexData, primitiveType: SCNGeometryPrimitiveType.Triangles, primitiveCount: 1, bytesPerIndex: sizeof(CInt))
            let vertexSource = SCNGeometrySource(vertices: positions, count: 3)
            let triangle = SCNGeometry(sources: [vertexSource], elements: [element])
            triangle.firstMaterial!.diffuse.contents = UIColor.blueColor()
            let triangleNode = SCNNode(geometry: triangle)
            (self.view as! SCNView).scene?.rootNode.replaceChildNode(spillTriNode, with: triangleNode)
            spillTriNode = triangleNode
            
            var spillPlane = SCNPlane(width: CGFloat(w), height: CGFloat(h))
            spillPlane.firstMaterial!.diffuse.contents = UIColor.blueColor()
            var tempNode = SCNNode(geometry: spillPlane)
            tempNode.position = SCNVector3(x: Float(leastX+(0.5*w)), y: Float(spillPositions[0].y-Float(0.5*h)), z: Float(0))
            (self.view as! SCNView).scene?.rootNode.replaceChildNode(spillNode, with: tempNode)
            spillNode = tempNode
            
        }


        
        
        
        
        /*
        var spillPlane = SCNPlane(width: CGFloat(w), height: CGFloat(h))
        spillPlane.firstMaterial!.diffuse.contents = UIColor.blueColor()
        var tempNode = SCNNode(geometry: spillPlane)
        tempNode.position = SCNVector3(x: Float(leastX+(0.5*w)), y: Float(greatestY-(0.5*h)), z: Float(0))
        (self.view as! SCNView).scene?.rootNode.replaceChildNode(spillNode, with: tempNode)
        spillNode = tempNode
        */
    }
    
    func findSpillPoints(xVals: [Float], yVals: [Float]) -> [SCNVector3] {
        var minIndex = 0
        var points = [SCNVector3]()
        
        for ii in 0...(numVertices-1) {
            if (yVals[ii] <= yVals[minIndex]) {
                minIndex = ii
            }
        }
        
        var v1 = SCNVector3Make(xVals[(numVertices+minIndex-1)%numVertices]-xVals[minIndex], yVals[(numVertices+minIndex-1)%numVertices]-yVals[minIndex], 0)
        var v2 = SCNVector3Make(xVals[(minIndex+1)%numVertices]-xVals[minIndex], yVals[(minIndex+1)%numVertices]-yVals[minIndex], 0)
        
        /*
        if (yVals[(numVertices+minIndex-1)%numVertices] > yVals[(minIndex+1)%numVertices]) {
            zerothSpillIsHigher = true
        } else {
            zerothSpillIsHigher = false
        }
        */
        
        /*
        if (xVals[(numVertices+minIndex-1)%numVertices] > xVals[(minIndex+1)%numVertices]) {
            zerothSpillIsFarther = false
        } else {
            zerothSpillIsFarther = true
        }
        */
        
        var d1 = simpleDist([v1.x, v1.y])
        var d2 = simpleDist([v2.x, v2.y])
        
        points.append(SCNVector3Make(xVals[minIndex], yVals[minIndex], 0))
        if (zerothSpillIsHigher) {
            points.append(SCNVector3Make(xVals[minIndex]+(v2.x*0.15), yVals[minIndex]+(v2.y*0.15), 0))
        } else {
            points.append(SCNVector3Make(xVals[minIndex]+(v1.x*0.15), yVals[minIndex]+(v1.y*0.15), 0))
        }
        
        if (points[0].x < points[1].x) {
            zerothSpillIsFarther = false
        } else {
            zerothSpillIsFarther = true
        }
        
        return points
        
    }
    
    
    func fillSpace(size: Double) -> Double {
        return size/300
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
                
                if result.node.name == "Corner" {
                    println("Found corner")
                }
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
