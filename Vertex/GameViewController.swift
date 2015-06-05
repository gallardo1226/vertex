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
import Darwin

struct vector {
    var vec = SCNVector3()
    var distance: Float = 0
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
    var totalScore = 0
    var level = 1
    var fillParam: Float = 1000
    
    var tempCounter = 1000
    
    var numVertices = 3
    var holeNode = SCNNode()
    var firstHole = true
    var holePositions = [SCNVector3]()
    
    var fillNode = SCNNode()
    var fillPositions = [SCNVector3]()
    var firstFill = true

	var selectedNodes = [SCNNode]()
	let player = SCNNode()
	var dragPoint:CGPoint? = nil
    
    var waterNode = SCNNode()
    
    var spillNode = SCNNode()
    var spillTriNode = SCNNode()
    var spillPositions = [SCNVector3]()
    var firstSpill = true
    var zerothSpillIsHigher = true
    var zerothSpillIsFarther = false
    
    var scoreLabel = UILabel()
    
    var confiningAngle: Float = 0
    var xLimit = 0.5
    var yLimit = 0.5
    
    var shapeCenter = SCNVector3()
    var linesNode = [SCNNode]()
    var LN = SCNNode()

    
    var scene = SCNScene()
    
    var minX: Float = -5
    var maxX: Float = 5
    var minY: Float = -7
    var maxY: Float = 7
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (self.view as! SCNView).delegate = self
        (self.view as! SCNView).playing = true
        
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
        
        // configure the view
        scnView.backgroundColor = UIColor.lightGrayColor()
        
        // configure gestures
		configureGestures(scnView)

		// create player node
		player.name = "Player"
		scene.rootNode.addChildNode(player)
    }

    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        
        confiningAngle = d2r((180)*Float(numVertices-2)/Float(numVertices))
        // If hole has been covered, generate new hole
        if (!shapeUncovered) {
			sizeOfHole = generateShape(numVertices)
			var playerNodes = player.childNodes as! [SCNNode]
			for node in playerNodes {
				node.removeFromParentNode()
			}
			player.addChildNode(addPlayerTriangle())
            shapeUncovered = true
        } else {
            if (isHoleCovered()) {
                shapeUncovered = false
                score += 1
            }
        }

        // Increment the cycle count
        cycleCount++
            
        // If needed, reset cycle count and fill space
        if (cycleCount == cyclesBetweenNextFill) {
            cycleCount = 0
            if (fillLevel <= maxFill) {
                fillLevel += fillSpace(0.5*sizeOfHole)
            }
            
            //println(fillLevel)
        }
        
        drawFillLine(fillLevel)

        if (fillLevel > maxFill) {
            performSegueWithIdentifier("GameOver", sender: nil)
        }
        
        if (score >= winScore) {
            fillLevel = 0.0
            score = 0
            totalScore += score*level
            level++
            fillParam *= 0.9
        }
        
        //println(scene.rootNode.childNodes)
        
    }

    func addPlayerTriangle() -> SCNNode {
        let positions = [
            SCNVector3Make(-1,-sqrt(3) / 2, 0),
            SCNVector3Make( 1,-sqrt(3) / 2, 0),
            SCNVector3Make( 0, sqrt(3) / 2, 0)
        ]
		var nodes = [SCNNode]()
        var vertexVectors = [SCNVector3]()
        for p in positions {
            vertexVectors.append(p)
            var sphere = SCNSphere(radius: 0.285)
            var cornerNode = SCNNode(geometry: sphere)
            cornerNode.position = p
            cornerNode.name = "Handle"
			nodes.append(cornerNode)
			player.addChildNode(cornerNode)
        }
        
        shapeCenter = SCNVector3Make((vertexVectors[0].x+vertexVectors[1].x+vertexVectors[2].x)/3, (vertexVectors[0].y+vertexVectors[1].y+vertexVectors[2].y)/3, 0)
        
		return generateShapeFromNodes(nodes, positions)
    }

    func generateShape(numVertices: Int) -> Double {
        
        var xs = [Float]()
        var ys = [Float]()
        var bxs = [Float]()
        var bys = [Float]()
        var barys = [Float]()
        
        var centerX = Float(((Float(arc4random()) / Float(UINT32_MAX)) * (maxX - minX - 1)) - maxX - 0.5)
        var centerY = Float(((Float(arc4random()) / Float(UINT32_MAX)) * (maxY - minY - 1)) - maxY - 0.5)
        var rotationAngle = Float(((Float(arc4random()) / Float(UINT32_MAX)) * d2r(360)))
        
        var currentAngle = (d2r(90) - confiningAngle + d2r(360))
        
        // Find binding points
        for ii in 0...(numVertices-1) {
            var tempX = centerX
            var tempY = centerY
            
            if ((currentAngle+d2r(360))%d2r(360) > d2r(0) && (currentAngle+d2r(360))%d2r(360) <= d2r(90)) {
                
                if ((maxX-centerX)/cos(currentAngle) < (maxY - centerY)/sin(currentAngle)) {
                    tempX = maxX
                    tempY = (maxX-centerX)*tan(currentAngle) + centerY
                    println("1, Y")
                    println(currentAngle)
                    println(tan(currentAngle))
                } else {
                    tempX = (maxY-centerY)/tan(currentAngle) + centerX
                    tempY = maxY
                    println("1, X")
                    println(currentAngle)
                    println(tan(currentAngle))
                }
                
            } else if ((currentAngle+d2r(360))%d2r(360) > d2r(90) && (currentAngle+d2r(360))%d2r(360) <= d2r(180)) {
                
                if ((centerX-minX)/cos(currentAngle) < (maxY - centerY)/sin(currentAngle)) {
                    tempX = minX
                    tempY = -(centerX-minX)*tan(currentAngle) + centerY
                    
                } else {
                    tempX = centerX + (maxY-centerY)/tan(currentAngle)
                    tempY = maxY
                    
                }
                
            } else if ((currentAngle+d2r(360))%d2r(360) > d2r(180) && (currentAngle+d2r(360))%d2r(360) <= d2r(270)) {
                
                if ((centerX-minX)/cos(currentAngle) < (centerY-minY)/sin(currentAngle)) {
                    tempX = minX
                    tempY = centerY - (centerX-minX)*tan(currentAngle)
                    
                } else {
                    tempX = centerX - (centerY-minY)/tan(currentAngle)
                    tempY = minY
                    
                }
                
            } else {
                
                if ((maxX-centerX)/cos(currentAngle) < (centerY-minY)/sin(currentAngle)) {
                    tempX = maxX
                    tempY = centerY + (maxX-centerX)*tan(currentAngle)
                    
                } else {
                    tempX = -(centerY-minY)/tan(currentAngle) + centerX
                    tempY = minY
                    
                }
                
            }
            
            println(tempX)
            println(tempY)
            
            if (tempX < minX) {
                tempX = 0.75*minX
            } else if (tempX > maxX) {
                tempX = 0.75*maxX
            }
            
            if (tempY < minY) {
                tempY = 0.75*minY
            } else if (tempY > maxY) {
                tempY = 0.75*maxY
            }
            
            bxs.append(tempX)
            bys.append(tempY)

            
            currentAngle += 2*confiningAngle
            currentAngle = currentAngle%d2r(360)
        }
        println(" ")
        
        var sum: Float = 0
        
        // Calc barycentric coordinates
        for ii in 0...2 {
            var temp = (Float(arc4random()) / Float(UINT32_MAX))
            barys.append(temp)
            sum += temp
        }
        
        // Normalize barys
        for ii in 0...2 {
            barys[ii] /= sum
        }
        
        //do {
        
            for ii in 0...(numVertices-1) {
                
                xs.append(barys[0]*centerX + barys[1]*bxs[ii] + barys[2]*bxs[(ii+1)%numVertices])
                ys.append(barys[0]*centerY + barys[1]*bys[ii] + barys[2]*bys[(ii+1)%numVertices])
                
            }
            
        //} while (distantEnough(xs, yVals: ys) && fatEnough(xs, yVals: ys))
        
        
        holePositions = [SCNVector3]()
        
        for jj in 0...(numVertices-1) {
            holePositions.append(SCNVector3Make(Float(xs[jj]), Float(ys[jj]), -0.01))
        }
        
        //holePositions = sortPoints(holePositions, center: SCNVector3Make(centerX, centerY, 0))
        
        var indices = [CInt]()
        
        for ii in 0...(numVertices-3) {
            indices.append(CInt(0))
            indices.append(ii+1)
            indices.append(ii+2)
        }
        
        if (firstHole) {
            scene.rootNode.addChildNode(holeNode)
            scene.rootNode.addChildNode(LN)
            firstHole = false
        }
        
        var indexData = NSData(bytes:&indices, length:sizeof(CInt) * indices.count)
        var element = SCNGeometryElement(data: indexData, primitiveType: SCNGeometryPrimitiveType.Triangles, primitiveCount: numVertices - 2, bytesPerIndex: sizeof(CInt))
        var vertexSource = SCNGeometrySource(vertices: holePositions, count: numVertices)
        
        var hole = SCNGeometry(sources: [vertexSource], elements: [element])
        hole.firstMaterial!.doubleSided = true
        hole.firstMaterial!.diffuse.contents = UIColor.blueColor()
        var tempNode = SCNNode(geometry: hole)
        scene.rootNode.replaceChildNode(holeNode, with: tempNode)
        holeNode = tempNode
        
        /*
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
        var element = SCNGeometryElement(data: indexData, primitiveType: SCNGeometryPrimitiveType.Line, primitiveCount: numVertices, bytesPerIndex: sizeof(CInt))
        var vertexSource = SCNGeometrySource(vertices: holePositions, count: numVertices)
        
        var hole = SCNGeometry(sources: [vertexSource], elements: [element])
        hole.firstMaterial!.diffuse.contents = UIColor.blueColor()
        var tempNode = SCNNode(geometry: hole)
        (self.view as! SCNView).scene?.rootNode.replaceChildNode(holeNode, with: tempNode)
        holeNode = tempNode
        */
        return calcArea(xs, ys)

    }
    
    func sortPoints(hp: [SCNVector3], center: SCNVector3) -> [SCNVector3] {
        
        var minX = MAXFLOAT
        var maxX = -1*MAXFLOAT
        var minY = MAXFLOAT
        var maxY = -1*MAXFLOAT
        /*
        for ii in 0...(numVertices-1) {
            if (hp[ii].x < minX) {
                hp[ii].x = minX
            }
            if (hp[ii].x > maxX) {
                hp[ii].x = maxX
            }
            if (hp[ii].y < minY) {
                hp[ii].y = minY
            }
            if (hp[ii].y > maxY) {
                hp[ii].y = maxY
            }
        }
        */
        var vectorArray = [vector]()
        
        for jj in 0...(numVertices-1) {
            var dist = sqrt(pow(center.x - hp[jj].x, 2) + pow(center.y - hp[jj].y, 2))
            //var tempVec = vector(vec: hp[jj], angle: atan2(hp[jj].x - center.x, hp[jj].y - center.y))
            var tempVec = vector(vec: hp[jj], distance: dist)
            vectorArray.append(tempVec)
        }
        
        vectorArray.sort({$0.distance < $1.distance})
        
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
    
    func isHoleCovered() -> Bool {
        
        var bools = [false, false, false]
        var summaryBool = true
        
        for ii in 0...(numVertices-1) {
            var vertexArray = player.childNodes as! [SCNNode]
            var vertex = vertexArray[ii].position
            
            for jj in 0...(numVertices-1) {
                if (sqrt(pow(vertex.x - holePositions[jj].x, 2) + pow(vertex.y - holePositions[jj].y, 2)) <= 0.25) {
                    bools[jj] = true
                }
            }
        }
        var num = 0
        for ii in 0...(numVertices-1) {
            if (!bools[ii]) {
                summaryBool = false
            } else {
                num++
            }
        }
        println(num)
        return summaryBool
    }

	func configureGestures(view: SCNView) {
		let selectGesture = UILongPressGestureRecognizer(target: self, action: "handleSelect:")
		selectGesture.minimumPressDuration = 0
		selectGesture.allowableMovement = CGFloat.max
		
		var gestureRecognizers = [AnyObject]()
		gestureRecognizers.append(selectGesture)
		if let existingGestureRecognizers = view.gestureRecognizers {
			gestureRecognizers.extend(existingGestureRecognizers)
		}
		view.gestureRecognizers = gestureRecognizers
	}

	func handleSelect(recognizer: UILongPressGestureRecognizer) {
		let scnView = self.view as! SCNView
		if recognizer.state == States.began {
			let p = recognizer.locationInView(scnView)
			if let hitResults = scnView.hitTest(p, options: nil) {
				if hitResults.count > 0 {
					let result: AnyObject! = hitResults[0]
					if result.node.name == "Handle" {
						result.node.geometry?.firstMaterial?.diffuse.contents = UIColor.redColor()
						selectedNodes.append(result.node)
						dragPoint = p
					} else if result.node.name == "Shape" {
						let children = player.childNodes as! [SCNNode]
						for i in 0 ... children.count - 2 {
							children[i].geometry?.firstMaterial?.diffuse.contents = UIColor.redColor()
							selectedNodes.append(children[i])
						}
						dragPoint = p
					}
				}
			}
		}
		if recognizer.state == States.changed {
			let p = recognizer.locationInView(scnView)
			if let point = dragPoint as CGPoint! {
				let xDiff = Float(p.x - point.x) / 38.5
				let yDiff = Float(p.y - point.y) / 38.5
				if selectedNodes.count == 1 {
					let node = selectedNodes[0]
					
                    let newDiffs = adjustPositions(node.position.x, y: node.position.y, xDiff: xDiff, yDiff: yDiff, center: shapeCenter)
                    
                    node.position = SCNVector3(
						x: node.position.x + newDiffs[0],
						y: node.position.y - newDiffs[1],
						z: node.position.z
					)
				}

				if selectedNodes.count > 1 {
					
                    var xD = xDiff
                    var yD = yDiff
                    
                    for node in selectedNodes {
						
                        if (node.position.x + xDiff > maxX || node.position.x + xDiff < minX) {
                            xD = 0
                        }
                        if (node.position.y - yDiff > maxY || node.position.y - yDiff < minY) {
                            yD = 0
                        }
                        
                        node.position = SCNVector3(
							x: node.position.x + xD,
							y: node.position.y - yD,
							z: node.position.z
						)
					}
				}
				let children = player.childNodes as! [SCNNode]
				var handles = [SCNNode]()
				for i in 0 ... children.count - 2 {
						handles.append(children[i])
					}
				var positions = [SCNVector3]()
				for handle in handles {
					positions.append(handle.position)
				}
				player.replaceChildNode(children.last!, with: generateShapeFromNodes(handles, positions))
				dragPoint = p
			}
		}
		if recognizer.state == States.ended {
			for node in selectedNodes {
				node.geometry?.firstMaterial?.diffuse.contents = UIColor.whiteColor()
			}
			selectedNodes = []
			dragPoint = nil
            let allVerts = player.childNodes as! [SCNNode]
            var vertexVectors = [SCNVector3]()
            for v in allVerts {
                vertexVectors.append(v.position)
            }
            shapeCenter = SCNVector3Make((vertexVectors[0].x+vertexVectors[1].x+vertexVectors[2].x)/3, (vertexVectors[0].y+vertexVectors[1].y+vertexVectors[2].y)/3, 0)
            println(shapeCenter)
		}
	}
    
    func adjustPositions(x: Float, y: Float, xDiff: Float, yDiff: Float, center: SCNVector3) -> [Float] {
        
        var newXDiff = xDiff
        var newYDiff = yDiff
        
        var angle = calcAngle(center, SCNVector3Make(x, y, 0))
        var deg = angle*180/Float(M_PI)
        var newAngle = calcAngle(center, SCNVector3Make(x + xDiff, y - yDiff, 0))
        
        if (angle > d2r(90) - confiningAngle && angle < d2r(90) + confiningAngle) {
            
            if (newAngle <= d2r(90) - confiningAngle || newAngle >= d2r(90) + confiningAngle) {// || (y - yDiff) <= center.y) {
                newXDiff = 0
                newYDiff = 0
            }
            
        } else if (angle >= d2r(90) + confiningAngle && angle < d2r(90) + 3*confiningAngle) {
            
            if (newAngle <= d2r(90) + confiningAngle || newAngle >= d2r(90) + 3*confiningAngle) {// || (x + xDiff) >= center.x) {
                newXDiff = 0
                newYDiff = 0
            }
            
        } else {
            
            if (!(newAngle >= d2r(90) + 3*confiningAngle || newAngle <= d2r(90) - confiningAngle)) {// || (x + xDiff) <= center.x)) {
                newXDiff = 0
                newYDiff = 0
            }
        }
        
        if ((x + newXDiff) < minX) {
            newXDiff = 0
        }
        if ((x + newXDiff) > maxX) {
            newXDiff = 0
        }
        if ((y - yDiff) < minY) {
            newYDiff = 0
        }
        if ((y - yDiff) > maxY) {
            newYDiff = 0
        }
        
        return [newXDiff, newYDiff]
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "GameOver") {
            let vc:EndViewController = segue.destinationViewController as! EndViewController
            vc.scoreLabel.text = String(totalScore)
            vc.levelLabel.text = String(level)
        }
    }

}
