import UIKit
import SceneKit
import ARKit

class Line: SCNNode {
    
    var anchor: ARPlaneAnchor!
    var planeGeometry: SCNPlane!
    
    let w:CGFloat = 0.01
    let h:CGFloat = 0.2
    
    let color = UIColor(displayP3Red: 1, green: 0.5, blue: 0, alpha: 1)
    
    override init() {
        super.init()
        
        self.geometry = SCNPlane(width: w, height: h)
        self.transform = SCNMatrix4MakeRotation(Float(-.pi / 2.0), 1.0, 0.0, 0.0)
        
        let lavaMaterial = SCNMaterial()
        lavaMaterial.diffuse.contents = color
        
        self.geometry?.materials = [lavaMaterial]
        
//        n.scale = SCNVector3Make(1, 1, 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func lineBetweenNode(nodeA: SCNNode, nodeB: SCNNode) -> SCNNode {
        
        let positions: [Float32] = [nodeA.position.x, nodeA.position.y, nodeA.position.z, nodeB.position.x, nodeB.position.y, nodeB.position.z]
        
//        let positions: [Float32] = [A.x, A.y, A.z, B.x, B.y, B.z]
        let positionData = NSData(bytes: positions, length: MemoryLayout<Float32>.size*positions.count)
        let indices: [Int32] = [0, 1]
        let indexData = NSData(bytes: indices, length: MemoryLayout<Int32>.size * indices.count)
        
        let source = SCNGeometrySource(data: positionData as Data, semantic: SCNGeometrySource.Semantic.vertex, vectorCount: indices.count, usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: MemoryLayout<Float32>.size, dataOffset: 0, dataStride: MemoryLayout<Float32>.size * 3)
        let element = SCNGeometryElement(data: indexData as Data, primitiveType: SCNGeometryPrimitiveType.line, primitiveCount: indices.count, bytesPerIndex: MemoryLayout<Int32>.size)
        
        let line = SCNGeometry(sources: [source], elements: [element])
        
//        line.firstMaterial?.diffuse.contents = UIColor(displayP3Red: 1, green: 0.5, blue: 0, alpha: 1)
//        line.firstMaterial?.isDoubleSided = true
        
        return SCNNode(geometry: line)
    }
    
}

