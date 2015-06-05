//
//  HelperMethods.swift
//  Dam It!
//
//  Created by Noah Conley on 6/5/15.
//  Copyright (c) 2015 EECS370. All rights reserved.
//

import UIKit
import SceneKit
import Darwin

func generateShapeFromNodes(vertices: [SCNNode], positions: [SCNVector3]) -> SCNNode {
	var indices = [CInt]()
	for i in 1 ... vertices.count - 2 {
		indices += [CInt(0), CInt(i), CInt(i + 1)]
	}

	let indexData = NSData(bytes:&indices, length:sizeof(CInt) * indices.count)
	let element = SCNGeometryElement(data: indexData, primitiveType: SCNGeometryPrimitiveType.Triangles, primitiveCount: indices.count / 3, bytesPerIndex: sizeof(CInt))
	let vertexSource = SCNGeometrySource(vertices: positions, count: vertices.count)
	let shape = SCNGeometry(sources: [vertexSource], elements: [element])
	shape.firstMaterial!.diffuse.contents = UIColor.greenColor()
	shape.firstMaterial!.doubleSided = true
	let node = SCNNode(geometry: shape)
	node.name = "Shape"

	let center = SCNVector3Make(
		(positions[0].x+positions[1].x+positions[2].x)/3,
		(positions[0].y+positions[1].y+positions[2].y)/3,
		0.1
	)
	for point in positions {
		node.addChildNode(generateNormal(center, point))
	}
	println(node)
	return node
}

func generateNormal(center: SCNVector3, point: SCNVector3) -> SCNNode {
	let p = SCNVector3Make(
		center.x + (center.x - point.x),
		center.y + (center.y - point.y),
		0.1
	)

	var indices: [CInt] = [ 0,1 ]

	var positions = [ center, p ]

	var geo = SCNGeometrySource(vertices: positions, count: 2)
	let indexData = NSData(bytes:&indices, length:sizeof(CInt) * indices.count)
	let element = SCNGeometryElement(data:indexData, primitiveType:SCNGeometryPrimitiveType.Line, primitiveCount: 1, bytesPerIndex:sizeof(CInt))
	let line = SCNGeometry(sources:[geo], elements:[element])
	line.firstMaterial!.doubleSided = true
	line.firstMaterial!.diffuse.contents = UIColor.blackColor()
	
	let node = SCNNode(geometry: line)
	node.name = "Normal"

	return node
}

func calcArea(xVals: [Float], yVals: [Float]) -> Double {
	var sum = 0.0

	/*
	for ii in 0...(numVertices-2) {
	sum += Double(xVals[ii]*yVals[ii+1] - yVals[ii]*xVals[ii+1])
	}

	sum += Double(xVals[numVertices-1]*yVals[0] - yVals[numVertices-1]*xVals[0])

	return Double(abs(sum))
	*/
	var tempSum: Float = (xVals[0]*yVals[1] + xVals[1]*yVals[2] + xVals[2]*yVals[0] - xVals[0]*yVals[2] - xVals[2]*yVals[1] - xVals[1]*yVals[0])
	sum = 0.5*abs(Double(tempSum))
	return sum
}

func d2r(angle: Float) -> Float {
	return Float(M_PI)/180*angle
}

func distanceFormula(x1: Float, x2: Float, y1: Float, y2: Float) -> Float {
	return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2))
}

func simpleDist(n: [Float]) -> Float {
	return sqrt(pow(n[0], 2) + pow(n[1], 2))
}

func fillSpace(size: Double) -> Double {
	return size/1000
}

func calcAngle(c: SCNVector3, p: SCNVector3) -> Float {
	var temp1 = p.y-c.y
	var temp2 = p.x-c.x
	var temp3 = atan2((p.y-c.y),(p.x-c.x)) * 180/Float(M_PI)
	var temp4 = (atan2((p.y-c.y),(p.x-c.x)) + d2r(360))%d2r(360) * 180/Float(M_PI)
	return (atan2((p.y-c.y),(p.x-c.x)) + d2r(360))%d2r(360)
}