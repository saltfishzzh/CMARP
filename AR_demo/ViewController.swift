import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    var planes = [UUID:Plane]() // 字典，存储场景中当前渲染的所有平面
    
    var theScale: Float = 1
    var tap_cnt = 0
    let object = SCNScene(named: "art.scnassets/city.DAE")!
    var speechRecognizer: SpeechRecognizer! = SpeechRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechRecognizer.load()
        speechRecognizer.start()
        setupScene()
        setupRecognizers()
        //getAndDrawFunc()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    

    func setupScene() {
        // 设置 ARSCNViewDelegate——此协议会提供回调来处理新创建的几何体
        sceneView.delegate = self
        
        // 显示统计数据（statistics）如 fps 和 时长信息
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        
        // 开启 debug 选项以查看世界原点并渲染所有 ARKit 正在追踪的特征点
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        
        let scene = SCNScene()
        sceneView.scene = scene
    }
    
    func setupSession() {
        // 创建 session 配置（configuration）实例
        let configuration = ARWorldTrackingConfiguration()
        
        // 明确表示需要追踪水平面，设置后 scene 被检测到时就会调用 ARSCNViewDelegate 方法
        configuration.planeDetection = .horizontal
        
        // 运行 view 的 session
        sceneView.session.run(configuration)
    }
    
    /**
     将新 node 映射到给定 anchor 时调用。
     
     @param renderer 将会用于渲染 scene 的 renderer。
     @param node 映射到 anchor 的 node。
     @param anchor 新添加的 anchor。
     */
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        // 检测到新平面时创建 SceneKit 平面以实现 3D 视觉化
        let plane = Plane(withAnchor: anchor)
        planes[anchor.identifier] = plane
        node.addChildNode(plane)
//        print("didAdd")
    }
    
    /**
     使用给定 anchor 的数据更新 node 时调用。
     
     @param renderer 将会用于渲染 scene 的 renderer。
     @param node 更新后的 node。
     @param anchor 更新后的 anchor。
     */
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let plane = planes[anchor.identifier] else {
            return
        }
        
        // anchor 更新后也需要更新 3D 几何体。例如平面检测的高度和宽度可能会改变，所以需要更新 SceneKit 几何体以匹配
        plane.update(anchor: anchor as! ARPlaneAnchor)
//        print("didUpdate")
    }
    
    /**
     从 scene graph 中移除与给定 anchor 映射的 node 时调用。
     
     @param renderer 将会用于渲染 scene 的 renderer。
     @param node 被移除的 node。
     @param anchor 被移除的 anchor。
     */
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // 如果多个独立平面被发现共属某个大平面，此时会合并它们，并移除这些 node
        planes.removeValue(forKey: anchor.identifier)
//        print("didRemove")
    }
    
    /**
     将要用给定 anchor 的数据来更新时 node 调用。

     @param renderer 将会用于渲染 scene 的 renderer。
     @param node 即将更新的 node。
     @param anchor 被更新的 anchor。
     */
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    
    // MARK: - GestureRecognizer
    
    func setupRecognizers() {
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTapFrom(recognizer:) ))
        tapGestureRecognizer.numberOfTapsRequired = 1
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(ViewController.handlePinchGesture(recognizer:)))
        sceneView.addGestureRecognizer(pinchGesture)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.handleLongPressGesture(recognizer:)))
        sceneView.addGestureRecognizer(longPressRecognizer)
        
        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(ViewController.handleRotationGesture(recognizer:)))
        sceneView.addGestureRecognizer(rotationGestureRecognizer)
    }
    
    @objc func handleTapFrom(recognizer: UITapGestureRecognizer) {
        // 获取屏幕空间坐标并传递给 ARSCNView 实例的 hitTest 方法
        let tapPoint = recognizer.location(in: sceneView)
        let result = sceneView.hitTest(tapPoint, types: .existingPlaneUsingExtent)
        
        // 如果射线与某个平面几何体相交，就会返回该平面，以离摄像头的距离升序排序
        // 如果命中多次，用距离最近的平面
        if let hitResult = result.first {
            insertGeometry(hitResult)
            asyncGetAndDraw()
        }
    }
    
    @objc func handlePinchGesture(recognizer: UIPinchGestureRecognizer) {
        let factor = recognizer.scale
        
        //状态是否结束，如果结束保存数据
        if recognizer.state == UIGestureRecognizerState.ended{
            theScale = theScale * Float(factor)
            object.rootNode.scale = SCNVector3Make(theScale, theScale, theScale)
        }
    }
    
    @objc func handleLongPressGesture(recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else { return }
        let longPressLocation = recognizer.location(in: sceneView)
        var hitTestOptions = [SCNHitTestOption: Any]()
        hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
        let results = sceneView.hitTest(longPressLocation, options: hitTestOptions)
        let hitResult = results.first!
//        let node: SCNNode = createNewBubbleNode("POI")
//        node.position = hitResult.worldCoordinates
        let localCoord = hitResult.worldCoordinates - hitResult.node.worldPosition
        if let name = hitResult.node.name {
            asyncPost(localCoord.x, localCoord.y, localCoord.z, "NewTest", name)
        }
        
    }
    
    private var startingRotation: Float = 0.0
    @objc func handleRotationGesture(recognizer: UIRotationGestureRecognizer) {
        let objectTemp = object.rootNode
        let pointOfView = sceneView.pointOfView
        if !sceneView.isNode(objectTemp, insideFrustumOf: pointOfView!) {
            return
        }
        if recognizer.state == .began {
            startingRotation = objectTemp.eulerAngles.y
        } else if recognizer.state == .changed {
            object.rootNode.eulerAngles.y = startingRotation - Float(recognizer.rotation)
        }
    }
    
    func insertGeometry(_ hitResult: ARHitTestResult) {

        let material = SCNMaterial()
        material.diffuse.contents = UIColor(displayP3Red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        material.ambient.contents = UIColor(displayP3Red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        material.specular.contents = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 1)
        material.shininess = 32.0
        object.rootNode.enumerateHierarchy{
            (cn,_) in cn.geometry?.materials = [material]
        }
        /*let n = s.rootNode.childNode(withName: "Circle05", recursively: false)!

        n.geometry?.materials = [lavaMaterial]
        n.scale = SCNVector3Make(theScale, theScale, theScale)*/
        object.rootNode.scale = SCNVector3Make(theScale, theScale, theScale)
        object.rootNode.position = SCNVector3Make(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
        
        //object.rootNode.position = SCNVector3Make(-1, -1, -1)
        print(hitResult.worldTransform.columns.3)
        
        tap_cnt = tap_cnt + 1
       
        sceneView.scene.rootNode.addChildNode(object.rootNode)
        print(object.rootNode.position)
        print(object.rootNode.worldTransform)
    }
    
    @IBOutlet weak var getAndDrawBtn: UIButton!
    
    @IBAction func getAndDraw(_ sender: Any) {
        asyncGetAndDraw()
    }

    struct Repo: Decodable {
        var title: String
        var x: String
        var y: String
        var z: String
        var content: String
    }

    struct POI {
        var content: String
        var id: Int
        var x: Float
        var y: Float
        var z: Float
    }

    func asyncGetAndDraw(){
        
        print("------ http_get_test -----")
        var POIs: [POI] = []
        let url:URL! = URL(string:"http://123.207.92.108/test.php?func=get");
        let session:URLSession = URLSession.shared
        
        let dataTask = session.dataTask(with: url) { (data, respond, error) in
            if let data = data {
                var i = 1
                if let repos = try? JSONDecoder().decode([Repo].self, from: data) {
                    for repo in repos {
                        if repo.title != "NewTest" {continue}
                        print("title", repo.title)
                        print("name", repo.content)
                        let x = (repo.x as NSString).floatValue
                        let y = (repo.y as NSString).floatValue
                        let z = (repo.z as NSString).floatValue
                        let tempPOI = POI(content: repo.content, id: i, x: x, y: y, z: z)
                        //print("tempPOI", tempPOI)
                        i = i + 1
                        POIs.append(tempPOI)
                    }
                    for POI in POIs {
                        guard let attachNode = self.object.rootNode.childNode(withName: POI.content, recursively: true) else {
                            return
                        }
                        if let temp = attachNode.childNode(withName: POI.content + "_POI_" + String(POI.id), recursively: true) {
                            print("delete", temp.name)
                            temp.removeFromParentNode()
                        }
                        
                        let node: SCNNode = self.createNewBubbleNode("POI")
                        node.name = POI.content + "_POI_" + String(POI.id)
                        node.position = SCNVector3Make(POI.x, POI.y, POI.z) + attachNode.worldPosition
                        print("z", node.position.z)
                        attachNode.addChildNode(node)
                    }
                } else {
                    print(data)
                    print("--- JSON parse failed ---")
                }
                
            } else {
                print("--- Get Error ---\n", error!)
            }
        }
        
        dataTask.resume()
    }

    func drawVirtualObjectsByGet(_ x: Float, _ y: Float, _ z: Float, _ sceneView: ARSCNView) {
        let pos = SCNVector3(x, y, z)
        let node: SCNNode = createNewBubbleNode("POI")
        node.position = pos
        sceneView.scene.rootNode.addChildNode(node)
    }

    func createNewBubbleNode(_ text : String) -> SCNNode {
        // Warning: Creating 3D Text is susceptible to crashing. To reduce chances of crashing; reduce number of polygons, letters, smoothness, etc.
        
        // TEXT BILLBOARD CONSTRAINT
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        let bubbleDepth : Float = 0.01 // the 'depth' of 3D text
        
        // BUBBLE-TEXT
        let bubble = SCNText(string: text, extrusionDepth: CGFloat(bubbleDepth))
        var font = UIFont(name: "Futura", size: 0.15)
        font = font?.withTraits(traits: .traitBold)
        bubble.font = font
        bubble.alignmentMode = kCAAlignmentCenter
        bubble.firstMaterial?.diffuse.contents = UIColor.orange
        bubble.firstMaterial?.specular.contents = UIColor.white
        bubble.firstMaterial?.isDoubleSided = true
        // bubble.flatness // setting this too low can cause crashes.
        bubble.chamferRadius = CGFloat(bubbleDepth)
        
        // BUBBLE NODE
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        // Centre Node - to Centre-Bottom point
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, bubbleDepth/2)
        // Reduce default text size
        bubbleNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        // CENTRE POINT NODE
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)
        
        // BUBBLE PARENT NODE
        let bubbleNodeParent = SCNNode()
        bubbleNodeParent.addChildNode(bubbleNode)
        bubbleNodeParent.addChildNode(sphereNode)
        bubbleNodeParent.constraints = [billboardConstraint]
        return bubbleNodeParent
    }

    func asyncPost(_ x: Float, _ y: Float, _ z: Float, _ title: String, _ content: String) {
        
        print("------ http_post_test -----")
        
        let url:URL! = URL(string:"http://123.207.92.108/test.php?func=new");
        
        var request:URLRequest = URLRequest.init(url: url)
        request.httpMethod = "POST"
        let body = "x=" + String(x) + "&y=" + String(y) + "&z=" + String(z) + "&title=" + title + "&content=" + content
        request.httpBody = body.data(using: .utf8)
        
        let session:URLSession = URLSession.shared
        
        let dataTask = session.dataTask(with: request) { (data, respond, error) in
            if let data = data {
                if let result = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
                    print("post success")
                }
            } else {
                print(error!)
            }
        }
        
        dataTask.resume()
    }
}
