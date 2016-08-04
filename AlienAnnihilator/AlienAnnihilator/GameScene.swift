//
//  GameScene.swift
//  AlienAnnihilator
//
//  Created by Sam Cohen on 7/14/16.
//  Copyright (c) 2016 GuacGetters. All rights reserved.

//Adding a power up where the bullets slow down so they just keep killling things that go into them??
//Get global timer for everything- alien spwans, when to add new alein types, ect.
//Kills should be a currency of sorts
//





import SpriteKit

//Set up the physics catagories for collisions (each bit of the 32 is a catagory)
struct PhysicsCategory {
    static let None      :  UInt32 = 0;
    static let All       :  UInt32 = UInt32.max
    static let Alien     :  UInt32 = 0b1
    static let Laser     :  UInt32 = 0b10
    static let Ship      :  UInt32 = 0b11
}

var controlVector:CGVector = CGVector(dx: 0, dy: 0)

class GameScene: SKScene, SKPhysicsContactDelegate {

    
    var alienSprites:[Alien] = []
    
    
    //Multiplers ordered as: speed, spawn time, lives?
    var normAlienMultiplers:[CGFloat] = [1.0, 0.01, 1.0]
    var downAlienMultiplers:[CGFloat] = [1.0, 0.01, 1.0]
    var behindAlienMultiplers:[CGFloat] = [1.0, 0.01, 1.0]
    
    
    var downNotCalledYet = true
    var behindNotCalledYet = true
    

    
    
    //Build the Aliens killed Label
    private var aliensKilled = 0 {
        didSet{
            self.aliensKilledLabel?.text = "Dead Foes: "+String(aliensKilled)
        }
    }
    private var aliensKilledLabel:SKLabelNode?
    
    //Instantiate the ship
    var aShip = Ship(startPosition: CGPoint(x:50,y:200), controllerVector: controlVector)
    
    //Build the shipLives label
    private var shipLives = 3 {
        didSet{
            self.shipLivesLabel?.text = "Lives: " + String(shipLives)
        }
    }
    private var shipLivesLabel:SKLabelNode?
    
    
    
    private var gameOver = 0 {
        
        didSet{
            self.gameOverLabel?.text = " "
        }
    }
    private var gameOverLabel:SKLabelNode?
    

    //controller configthis is the way to d
    let controlStick = SKSpriteNode(imageNamed: "Sprites/controlStick2.png")
    let controlBase = SKSpriteNode(imageNamed: "Sprites/controlBase.png")
    var controllerOn:Bool = false
    
    
    override func didMoveToView(view: SKView) {
        
        //So when we go back to scene the ship isnt moving from the last played game
        controlVector = CGVector(dx: 0,dy: 0)

        
        
        
        
        
        let aliensKilledLabel = SKLabelNode(fontNamed: "Times New Roman")
        //aliensKilledLabel.text = aliensKilled.description
        aliensKilledLabel.text = "Foes Killed': " + String(aliensKilled)
        aliensKilledLabel.fontSize = 14
        aliensKilledLabel.position = CGPoint(x:CGRectGetMidX(self.frame)*0.8,y:CGRectGetMidY(self.frame)*0.1)
        self.addChild(aliensKilledLabel)
        self.aliensKilledLabel = aliensKilledLabel
        
        
        let shipLivesLabel = SKLabelNode(fontNamed: "Times New Roman")
        shipLivesLabel.text = "Lives: " + String(aShip.lives)
        shipLivesLabel.fontSize = 14
        shipLivesLabel.position = CGPoint(x:CGRectGetMidX(self.frame)*1.3,y:CGRectGetMidY(self.frame)*0.1)
        self.addChild(shipLivesLabel)
        self.shipLivesLabel = shipLivesLabel
        
        
        let gameOverLabel = SKLabelNode(fontNamed: "Times New Roman")
        gameOverLabel.fontSize = 50
        gameOverLabel.position = CGPoint(x:CGRectGetMidX(self.frame),y:CGRectGetMidY(self.frame)*0.8)
        gameOverLabel.zPosition = 3
        gameOverLabel.fontColor = SKColor.redColor()
        self.gameOverLabel = gameOverLabel
        
        
        //Set up the scene structure
        backgroundColor = SKColor.blackColor()
        
        addChild(aShip)
        self.addChild(gameOverLabel)

        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0)
        
        /* Set up for the controller */
        //Establish the base
        controlBase.position = CGPoint(x:size.width*0.1, y:size.height*0.1)
        controlBase.size = CGSize(width: 100, height: 100)
        controlBase.zPosition = 1
        addChild(controlBase)
        
        //Establish the stick
        controlStick.position = controlBase.position
        controlStick.size = CGSize(width: 50, height: 50)
        controlStick.zPosition = 2
        addChild(controlStick)

        //Make semi-transparent
        controlBase.alpha = 0.5
        controlStick.alpha = 0.5
        
        
        
        //Building the aliens

        runAction(SKAction.repeatActionForever(SKAction.sequence([
            SKAction.runBlock(addNormAlien),
            SKAction.waitForDuration(Double(random(1,max: 4))-Double(normAlienMultiplers[1])),
            SKAction.runBlock(updateNormMultipliers)
            ])))

    }
    
    func startSpawningDown(){
        runAction(SKAction.repeatActionForever(SKAction.sequence([
            SKAction.runBlock(addDownAlien),
            SKAction.waitForDuration(Double(random(6,max: 8))-Double(downAlienMultiplers[1])),
            SKAction.runBlock(updateDownMultipliers)
            ])))
    }
    
    func startSpawningBehind(){
        runAction(SKAction.repeatActionForever(SKAction.sequence([
            SKAction.runBlock(addBehindAlien),
            SKAction.waitForDuration(Double(random(8,max: 12))-Double(behindAlienMultiplers[1])),
            SKAction.runBlock(updateBehindMultipliers)
            ])))
    }
    
    
    
    
    func killOffAlien(alien:SKNode){
        
        func stopMotion(){
            alien.physicsBody?.categoryBitMask = 0
            alien.physicsBody?.collisionBitMask = 0
            alien.physicsBody?.contactTestBitMask = 0
            
            alien.physicsBody?.dynamic = false
            alien.physicsBody?.velocity = CGVector(dx:0, dy:0)
        }

        
        func removeAlien(){
            alien.removeFromParent()
        }
        
        let stopMoving = SKAction.runBlock(stopMotion)
        let fadeOut = SKAction.fadeOutWithDuration(1)
        let removeFromParent = SKAction.runBlock(removeAlien)
        let color = SKAction.colorizeWithColor(SKColor.redColor(), colorBlendFactor: 0.7, duration: 0)
        
        let die = SKAction.sequence([stopMoving, color, fadeOut, removeFromParent])

        alien.runAction(die)
    }
    
    
    
    
    func alien_laser_contact(contact:SKPhysicsContact){
        var alien:SKNode? = nil
        if contact.bodyA.categoryBitMask == PhysicsCategory.Alien && contact.bodyB.categoryBitMask == PhysicsCategory.Laser{
            alien = contact.bodyA.node
        }
        else if contact.bodyB.categoryBitMask == PhysicsCategory.Alien && contact.bodyA.categoryBitMask == PhysicsCategory.Laser{
            alien = contact.bodyB.node
        }
        else{
            //            print("tits")
            return
        }

        
//        SKAction *pulseRed = [SKAction sequence:@[
//        [SKAction colorizeWithColor:[SKColor redColor] colorBlendFactor:1.0 duration:0.15],
//        [SKAction waitForDuration:0.1],
//        [SKAction colorizeWithColorBlendFactor:0.0 duration:0.15]]];     [monsterSprite runAction: pulseRed];

//        let red = [SKAction colorizeWithColor:[SKColor redColor] colorBlendFactor:1.0 duration:0.15]

//        func stopMotion(){
//            alien?.physicsBody?.categoryBitMask = 0
//            alien?.physicsBody?.collisionBitMask = 0
//            alien?.physicsBody?.contactTestBitMask = 0
//            
//            alien?.physicsBody?.dynamic = false
//            alien?.physicsBody?.velocity = CGVector(dx:0, dy:0)
//            
//        }
//        
//        func removeAlien(){
//            alien?.removeFromParent()
//            print("hellllllllllllllooooooooo")
//        }
//        
//        let stopMoving = SKAction.runBlock(stopMotion)
//        let fadeOut = SKAction.fadeOutWithDuration(1)
//        let removeFromParent = SKAction.runBlock(removeAlien)
//        
//        let die = SKAction.sequence([stopMoving, fadeOut, removeFromParent])
//        

//        alien?.runAction(die)
        
        

        
//        alien?.removeFromParent()
        aliensKilled = aliensKilled + 1
        aShip.lives = aShip.lives - 1
        
        killOffAlien((alien)!)
        
        if(aliensKilled > 1 && downNotCalledYet){
            startSpawningDown()
            downNotCalledYet = false
        }
        if(aliensKilled > 3 && behindNotCalledYet){
            startSpawningBehind()
            behindNotCalledYet = false
        }
    }
    
    
    
    
    
    func alien_ship_contact(contact:SKPhysicsContact){
        var alien:SKNode? = nil
        
        if contact.bodyA.categoryBitMask == PhysicsCategory.Alien && contact.bodyB.categoryBitMask == PhysicsCategory.Ship{
            alien = contact.bodyA.node
            
        }
        else if contact.bodyB.categoryBitMask == PhysicsCategory.Alien && contact.bodyA.categoryBitMask == PhysicsCategory.Ship{
            alien = contact.bodyB.node

        }
        else{
            return
        }

        aliensKilled = aliensKilled + 1
        shipLives = shipLives-1
        aShip.lives = aShip.lives - 1
        
        killOffAlien((alien)!)
        
        if(shipLives<1){
            print("asda")
            gameOver = 1
        }
        
        
    }
    
    
    
    func didBeginContact(contact:SKPhysicsContact){
        print(aShip.lives)
        alien_laser_contact(contact)
        alien_ship_contact(contact)
        
//        let loseAction = SKAction.runBlock() {
        func gameOver(){
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameOverScene(size: self.size, aliensKilled: self.aliensKilled)
            //self.view?.presentScene(gameOverScene, transition: reveal)
            self.view?.presentScene(gameOverScene, transition: SKTransition.fadeWithColor(SKColor.redColor(), duration: 3))
        }
        
        if(shipLives<1){
            gameOver()
        }
        
        
    }
    
    
    
    //Define random function
//    func random(min:UInt32, max:UInt32) -> UInt32{
//        return UInt32(arc4random_uniform(max - min) + min)
//      //return CGFloat(arc4random_uniform(2))*(max-min) + min
//    }
    func random(min:UInt32, max:UInt32) -> CGFloat{
        return CGFloat(arc4random_uniform(max - min) + min)
        //return CGFloat(arc4random_uniform(2))*(max-min) + min
    }
    
    

    
    //Make all this code way more compact later
    func updateNormMultipliers(){
        normAlienMultiplers[0] = normAlienMultiplers[0]*1.01
        normAlienMultiplers[1] = normAlienMultiplers[1]*1.01
    }
    func updateDownMultipliers(){
        downAlienMultiplers[0] = downAlienMultiplers[0]*1.01
        downAlienMultiplers[1] = downAlienMultiplers[1]*1.01
    }
    func updateBehindMultipliers(){
        behindAlienMultiplers[0] = behindAlienMultiplers[0]*1.01
        behindAlienMultiplers[1] = behindAlienMultiplers[1]*1.01
    }
    
    func addNormAlien(){

        let mult = normAlienMultiplers
        
        let alienInst = normAlien(startPos:CGPoint(x: 10,y: 10), speed: random(UInt32(10),max: UInt32(50))*mult[0])
        let yStart = random(UInt32(alienInst.size.height/2), max: UInt32(size.height-alienInst.size.height))
        alienInst.position = CGPoint(x:size.width+alienInst.size.width/2, y:CGFloat(yStart))
        
//        if(shipLives < 1){
//            print("Hello")
//            alienInst.physicsBody?.categoryBitMask = 0
//        }
//
//        let animate = SKAction.animateWithTextures(trumpTextures, timePerFrame: 1)//SKAction animateWithTextures:monsterWalkTextures timePerFrame:0.1]
        
        
        alienSprites.append(alienInst)
        addChild(alienInst)
    }
    
    func addDownAlien(){
        
        let mult = downAlienMultiplers
        
        let alienInst = downAlien(startPos:CGPoint(x: 10,y: 10),speed: random(UInt32(5),max: UInt32(25))*mult[0])
        //this line makes no sense, maybe use lasy variables or something
        let xStart = random(UInt32(alienInst.size.width/2), max: UInt32(size.width-alienInst.size.width))
        alienInst.position = CGPoint(x: xStart, y:CGFloat(size.height + alienInst.size.width/2))
//        if(shipLives < 1){
//            print("Hello")
//            alienInst.physicsBody?.categoryBitMask = 0
//        }
        addChild(alienInst)
    }
    
    func addBehindAlien(){
        
        let mult = behindAlienMultiplers
        
        let alienInst = behindAlien(startPos:CGPoint(x: 10,y: 10),speed: random(UInt32(5),max: UInt32(10))*mult[0])
        let yStart = random(UInt32(alienInst.size.height/2), max: UInt32(size.height-alienInst.size.height))
        alienInst.position = CGPoint(x: -alienInst.size.width/2, y:CGFloat(yStart))
//        if(shipLives < 1){
//            print("Hello")
//            alienInst.physicsBody?.categoryBitMask = 0
//        }
        addChild(alienInst)
    }
    
    
    
    

    
    func normalizeVector(v:CGVector) -> CGVector{
        let length: CGFloat = sqrt((v.dx*v.dx)+(v.dy*v.dy))
        let ans:CGVector = CGVector(dx:v.dx/length,dy:v.dy/length)
        return ans
    }
    
    


    
//    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        for touch : AnyObject in touches {
//            let location = touch.locationInNode(self)
//            let actionBouger = SKAction.moveTo(CGPoint(x: location.x, y: location.y), duration: 2.5)
//            ship.runAction(actionBouger)
//            let dx = location.x - ship.position.x
//            let dy = location.y - ship.position.y
//            var angleInRadians = atan2(dy, dx) - CGFloat(M_PI_2)
//            if(angleInRadians < 0){
//                angleInRadians = angleInRadians + 2 * CGFloat(M_PI)
//            }
//            ship.zRotation = angleInRadians
//            let actionAngle = SKAction.rotateToAngle(angleInRadians, duration: 0)
//            ship.runAction(actionAngle)
//        }
//    }
    

    
    //A dictionary to hold all touch start locations
    var startingTouches = [UITouch : CGPoint]()
    
    func goToGameScene(){
        let gameScene:GameScene = GameScene(size: self.view!.bounds.size) // create your new scene
        let transition = SKTransition.fadeWithDuration(1.0) // create type of transition (you can check in documentation for more transtions)
        gameScene.scaleMode = SKSceneScaleMode.Fill
        self.view!.presentScene(gameScene, transition: transition)
    }
    

    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        for touch : AnyObject in touches {
            let location = touch.locationInNode(self)
            startingTouches[touch as! UITouch] = location
            
            if(CGRectContainsPoint(controlBase.frame, location)){
                controllerOn = true
            }
            else{
                controllerOn = false
                
                aShip.gun.shoot()
            }
            
//            if(CGRectContainsPoint(aShip.frame, location)){
//                goToGameScene()
//            }
            
        }
    }

    
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch : AnyObject in touches {
            let location = touch.locationInNode(self)

            //The starting location of the given touch we're working with
            let touchStartPoint:CGPoint = startingTouches[touch as! UITouch]!
            
            
            //Play with this - Is it better than using the controller on??? (Note: u can move into the frame of the controller and move it)
            //if(controllerOn == true){
            if(CGRectContainsPoint(controlBase.frame, location)){
            
                let joyVector = CGVector(dx:location.x - controlBase.position.x, dy:location.y - controlBase.position.y)
                
                
                //Get angle between two components opp/adj of controlStick vector with arctan
                let angle = atan2(joyVector.dy, joyVector.dx)
                //Revise this- it's unneccasary because I normalize the vector anyway
                let length:CGFloat = controlBase.frame.size.height
                let xDist:CGFloat = sin(angle - 1.5879633) * length
                let yDist:CGFloat = cos(angle - 1.57879633) * length
                
                //Keep the stick on its "base"
                if(CGRectContainsPoint(controlBase.frame, location)){
                    controlStick.position = location
                }
                else{
                    controlStick.position = CGPoint(x:controlBase.position.x - xDist, y:controlBase.position.y - yDist)
                }

            
                //Float bc cosf only takes floats not CGFloats -> what is the real difference?
                //let degree = angle * CGFloat(180/M_PI)
                //var calcRotation:Float = Float(angle-1.57879633) + Float(M_PI_2)
                //let xVelocity = 50 * CGFloat(cosf(calcRotation))
                //let yVelocity = 50 * CGFloat(sinf(calcRotation))
                
                let v:CGVector = CGVector(dx:joyVector.dx,dy:joyVector.dy)
                let unitVector:CGVector = normalizeVector(v)
                controlVector = CGVector(dx:unitVector.dx,dy:unitVector.dy)
                
//                //Screen boundries (Loop ship position)
//                if(aShip.position.x > self.size.width){
//                    aShip.position.x = 0
//                }
//                if(aShip.position.x < 0){
//                    aShip.position.x = self.size.width
//                }
//                if(aShip.position.y > self.size.height + aShip.size.height/2){
//                    aShip.position.y = 0
//                }
//                if(aShip.position.y < 0){
//                    aShip.position.y = self.size.height - aShip.size.height/2
//                }
 
            }
        }
        

    }

    
    func resetController(){
        let move:SKAction = SKAction.moveTo(controlBase.position, duration: 0.2)
        //Causes the animation to slow as it progresses
        move.timingMode = .EaseOut
        controlStick.runAction(move)
        controlVector = CGVector(dx:0,dy:0)
    }
    
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        for touch : AnyObject in touches {
            
            //Does this make any more sense than the commented code below it?
            //difference is that this code if speaking strictly about touch's location at start time rather than location at end time!
            if(CGRectContainsPoint(controlBase.frame, startingTouches[touch as! UITouch]!)){
                resetController()
            }

            //REmove the touch
            startingTouches.removeValueForKey(touch as! UITouch)
        }

    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */

        // list all values
//        print("Values of startingTouches: ")
//        for (key, value) in startingTouches {
//            print(value)
//        }
        
        print(aShip.position)
        aShip.updateShipProperties(shipVelocity: controlVector, laserStartPos: CGPoint(x:0,y:0))
        
        if(shipLives<1){
            enumerateChildNodesWithName("normAlien", usingBlock: gameOverBounceMode)
            enumerateChildNodesWithName("downAlien", usingBlock: gameOverBounceMode)
            enumerateChildNodesWithName("behindAlien", usingBlock: gameOverBounceMode)

        }
        
        //Screen boundries (Loop ship position)
        if(aShip.position.x > self.size.width){
            aShip.position.x = 0
        }
        if(aShip.position.x < 0){
            aShip.position.x = self.size.width
        }
        if(aShip.position.y > self.size.height + aShip.size.height/2){
            aShip.position.y = 0
        }
        if(aShip.position.y < 0){
            aShip.position.y = self.size.height - aShip.size.height/2
        }
        
        
    }


    func gameOverBounceMode(node:SKNode, abool:UnsafeMutablePointer<ObjCBool>){
//        node.physicsBody?.velocity = CGVector(dx:0,dy:0)
        node.physicsBody?.categoryBitMask = 0
    }
    

    
    
    
//---------------------------------------------------------------------------------------------------------------------------------------------

    
    class GenericGun:SKNode{

        var laser: Laser = Laser()
        
        //Loading time properties of the gun
        var loadingTime:NSTimer?
        var stillLoading: Bool
        
        //Questionable
        override init(){
            
            stillLoading = false
            
            super.init()
        }
    
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        //Ready the laser for fire
        func addLaser(){
            laser = Laser()
            laser.position = self.position//CGPointMake(50,-18) //to get to the barrel of the gun
            self.addChild(laser)
        }
        
        //Ready laser and apply a foward velocity to it
        func shoot(){
            
            //We cannot shoot if we're still loading the gun
            if(stillLoading){
                return
            }
            
            //If the gun is done loading we can shoot
            addLaser()
            self.laser.physicsBody!.velocity = CGVector(dx:500,dy:0)
            
            //After shooting start loading gun timer again
            stillLoading = true
            self.loadingTime = NSTimer.scheduledTimerWithTimeInterval(0, target: self, selector: #selector(GenericGun.finishLoading), userInfo: nil, repeats: false)

        }

        //Method that is called by the scheduledTimer after a shot and wait time
        func finishLoading(){
            self.loadingTime?.invalidate()
            stillLoading = false
        }
        


    }
    
    
    class Laser:SKSpriteNode{
        
        init(){
            
            let laser = SKTexture(imageNamed: "Sprites/laser.jpg")
            
            super.init(texture: laser, color: UIColor.clearColor(), size: laser.size())
            self.setScale(2)
            //Laser physics
            self.physicsBody = SKPhysicsBody(circleOfRadius: laser.size().width/2)
            self.physicsBody?.dynamic = true
            self.physicsBody?.categoryBitMask = PhysicsCategory.Laser
            self.physicsBody?.contactTestBitMask = PhysicsCategory.Alien
            self.physicsBody?.collisionBitMask = PhysicsCategory.None
            self.physicsBody?.collisionBitMask = 0;
            self.physicsBody?.usesPreciseCollisionDetection = true
            self.physicsBody?.linearDamping = 0.0;
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    

    //Ship class-------------------------
    
    class Ship:SKSpriteNode{
        
        static var shipState = "norm"
        var laser: Laser = Laser()
        
        //A dictionary with String keys and AnyType array values
        static var shipTypes: [String: [Any]] = [
            
            //Array structure: ship/laser textures, fireRate, health stats (maybe invincible on one?)
            "norm":[SKTexture(imageNamed:"Sprites/fullShip.png"), SKTexture(imageNamed:"Sprites/laser.jpg"),7],
            "rapid":[SKTexture(imageNamed:"Sprites/fullShip.png"),7],
            "bazooka":[SKTexture(imageNamed:"Sprites/fullShip.png"),7]
        ]
        
        //All variables as to allow for powerups?
        var moveSpeed:CGFloat
        
        var lives:Int
        
        var lasers = [SKSpriteNode]()
        var canShoot = false

    
        
        let gun = GenericGun()
        
        
        
        
        static var shipImage = SKTexture(imageNamed:"Sprites/fullShip.png")//: Int = Int(shipTypes[shipState]![0])
        
        
        init(startPosition startPos:CGPoint, controllerVector:CGVector){
            
            self.lives = 3
            
            self.moveSpeed = 200

            
            //Call super initilizer
            super.init(texture: Ship.shipImage, color: UIColor.clearColor(), size: Ship.shipImage.size())
            
            gun.position = CGPointMake(95,-10)
            self.addChild(gun)

            
            self.setScale(0.2)
            //Position is an property of SKSpriteNode so super must be called first
            self.position = startPos
            
            //Physics of the ship
            self.physicsBody = SKPhysicsBody(circleOfRadius: self.size.width/2)
            self.physicsBody?.dynamic = true
            self.physicsBody?.categoryBitMask = PhysicsCategory.Ship
            self.physicsBody?.collisionBitMask = 0
            self.physicsBody?.contactTestBitMask = PhysicsCategory.Alien
            self.physicsBody?.allowsRotation = false
            self.physicsBody?.angularVelocity = CGFloat(0)
            self.physicsBody?.affectedByGravity = false //TBD
            
            self.physicsBody?.velocity.dx = controllerVector.dx * moveSpeed
            self.physicsBody?.velocity.dy = controllerVector.dy * moveSpeed
            
        }
        
        

        
        func updateVelocity(v:CGVector){
            self.physicsBody?.velocity.dx = v.dx * moveSpeed
            self.physicsBody?.velocity.dy = v.dy * moveSpeed
        }
        
        func updateShipProperties(shipVelocity v:CGVector,laserStartPos laserStart:CGPoint){
            updateVelocity(v)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
    
    
    

    
    
    
    //Generic alien type: a blue-print of sorts
    class Alien:SKSpriteNode{
        
        static func normalizeVector(vector:CGVector) -> CGVector{
            let len = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
            
            return CGVector(dx:vector.dx / len, dy:vector.dy / len)
        }
        
        let velocityVector:CGVector
        let startPos:CGPoint
        
        init(texture:SKTexture, startPosition startPos:CGPoint,moveSpeed: CGFloat,velocityVector:CGVector){
            
            self.velocityVector = Alien.normalizeVector(velocityVector)
            self.startPos = startPos

            //Makes sure the SKSpriteNode is initialized before modifying its properties
            super.init(texture: texture, color: UIColor.clearColor(), size: texture.size())
            
            self.setScale(0.2)

            //PhysicsBody is a property of super so super.init must be called first (init SKSpriteNode)
            self.physicsBody = SKPhysicsBody(circleOfRadius: self.size.width/2) //Why THE FUCK IS THIS* NOT AN OPTIONAL?
            self.physicsBody?.dynamic = true
            self.physicsBody?.categoryBitMask = PhysicsCategory.Alien //physicsBody?. is optional chaining?
            self.physicsBody?.collisionBitMask = PhysicsCategory.Laser //Do I need this? or jsut use in laser class
            self.physicsBody?.contactTestBitMask = PhysicsCategory.Laser
            self.physicsBody?.usesPreciseCollisionDetection = true
            self.physicsBody?.linearDamping = 0.0;
            
            //Motion
            self.physicsBody?.velocity.dx = velocityVector.dx * moveSpeed
            self.physicsBody?.velocity.dy = velocityVector.dy * moveSpeed
            
            self.position = startPos
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    

    class normAlien:Alien{
        
        static let alienImage = SKTexture(imageNamed:"Sprites/trumpFace.png")
        
        
        init(startPos:CGPoint,speed: CGFloat){
            
            super.init(texture:normAlien.alienImage, startPosition: startPos, moveSpeed:speed, velocityVector:CGVector(dx: -1,dy: 0))
            //Trump set scale size
            self.setScale(0.24)
            self.name = "normAlien"
            
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    
    //Downward alien with Mikes face
    class downAlien:Alien{
        
        static let alienImage = SKTexture(imageNamed:"Sprites/mikeFace2.png")
        
        init(startPos:CGPoint,speed: CGFloat){
            
            super.init(texture:downAlien.alienImage, startPosition: startPos, moveSpeed:speed, velocityVector:CGVector(dx: 0,dy: -1))
            //Mike set scale size
            self.setScale(0.5)
            self.name = "downAlien"
            
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    }
    
    
    class behindAlien:Alien{
        
        static let alienImage = SKTexture(imageNamed:"Sprites/alien.png")
        
        init(startPos:CGPoint,speed: CGFloat){
            
            super.init(texture:behindAlien.alienImage, startPosition: startPos, moveSpeed:speed, velocityVector:CGVector(dx: 1,dy: 0))
            //Alien set scale size
            self.setScale(0.1)
            self.name = "behindAlien"
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    





}





































