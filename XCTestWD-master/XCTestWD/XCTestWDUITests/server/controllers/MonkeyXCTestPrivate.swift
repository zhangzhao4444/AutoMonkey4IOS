//
//  MonkeyXCTestPrivate.swift
//  FastMonkey
//
//  fixed by zhangzhao on 2017/7/17.

import UIKit
import XCTest

var orientationValue: UIDeviceOrientation = .portrait

/**
    Extension using private funcctions from the XCTest API
    to generate events.

    The public XCTest API is far too slow for useful random testing,
    so currently using private APIs is the only option.

    As this code is only used in your tests, and never
    distributed, it will not cause problems with App Store
    approval.
*/
extension Monkey {
    public var sharedXCEventGenerator: XCEventGenerator {
        let generatorClass = unsafeBitCast(NSClassFromString("XCEventGenerator"),to: XCEventGenerator.Type.self)
        return generatorClass.sharedGenerator()
    }

    /**
        Add a sane default set of event generation actions
        using the private XCTest API. Use this function if you
        just want to generate some events, and do not have
        strong requirements on exactly which ones you need.
    */
    public func addDefaultXCTestPrivateActions() {
        //addXCTestElementTapAction(weight: 10)
    
        addXCTestTapAction(weight: 35)
        addXCTestLongPressAction(weight: 1)
        addXCTestDragAction(weight: 1)
        addXCTestPinchCloseAction(weight: 1)
        addXCTestPinchOpenAction(weight: 1)
        addXCTestRotateAction(weight: 1)
        addXCTestSlipScreenAction(weight: 6)
        //addXCTestOrientationAction(weight: 1) // TODO: Investigate why this does not work.
    }

    /**
        Add an action that generates a tap, with a possibility for
        multiple taps with multiple fingers, using the private
        XCTest API.

        - parameter weight: The relative probability of this
          event being generated. Can be any value larger than
          zero. Probabilities will be normalised to the sum
          of all relative probabilities.
        - parameter multipleTapProbability: Probability that
          the tap event will tap multiple times. Between 0 and 1.
        - parameter multipleTouchProbability: Probability that
          the tap event will use multiple fingers. Between 0 and 1.
    */
    public func addXCTestTapAction(weight: Double, multipleTapProbability: Double = 0.05,
    multipleTouchProbability: Double = 0.05) {
        addAction(weight: weight) { [weak self] in
            let numberOfTaps: UInt
            if self!.r.randomDouble() < multipleTapProbability {
                numberOfTaps = UInt(self!.r.randomUInt32() % 2) + 2
            } else {
                numberOfTaps = 1
            }
            
            let locations: [CGPoint]
            if self!.r.randomDouble() < multipleTouchProbability {
                let numberOfTouches = Int(self!.r.randomUInt32() % 3) + 2
                let rect = self!.randomRect()
                locations = (1...numberOfTouches).map { _ in
                    self!.randomPoint(inRect: rect)
                }
            } else {
                locations = [ self!.randomPoint() ]
            }
            
            let semaphore = DispatchSemaphore(value: 0)
            self!.sharedXCEventGenerator.tapAtTouchLocations(locations, numberOfTaps: numberOfTaps, orientation: orientationValue) {
                semaphore.signal()
            }
            let useStr="Tap \(String(describing: locations))"
            NSLog("XCTestMonkey:%@",useStr)
            semaphore.wait()
        }
    }
    
    public func addXCTestElementTapAction(weight: Double) {
        addAction(weight: weight){[weak self] in
            let numberOfTaps: UInt = 1
            do{
                usleep(200000)
                let session = try XCTestWDSessionManager.singleton.checkDefaultSessionthrow()
                let root = session.application
                if root == nil{
                    return
                }
                let points = try? XCTestWDFindElementUtils.tree(underElement: root!)
                if points == nil  || points??.count == 0 {
                    return
                }
                let index = self?.randomInt(lessThan: (points??.count)!)
                let point = points??[index!]
                let locations:[CGPoint] = [point!]
                let semaphore = DispatchSemaphore(value: 0)
                self!.sharedXCEventGenerator.tapAtTouchLocations(locations, numberOfTaps: numberOfTaps, orientation: orientationValue) {
                    semaphore.signal()
                }
                semaphore.wait()
            }catch{
                return
            }
            
        }
    }
    
    public func addXCTestElementclick(element:XCUIElement){
        addAction(){ [weak self] in
            let rect = element.wdRect()
            let point = CGPoint(x:rect["x"]!,y:rect["y"]!)
            let locations = [point]
            let semaphore = DispatchSemaphore(value: 0)
            let numberOfTaps = 1
            
            //let rect = element.wdRect()
            //let x = rect["x"]
            //let y = rect["y"]
            //let coordinate = XCUICoordinate.init(element:application, normalizedOffset: CGVector.init())
            //let triggerCoordinate = XCUICoordinate.init(coordinate: coordinate, pointsOffset: CGVector.init(dx: x!, dy: y!))
            //triggerCoordinate?.tap()
            
            self!.sharedXCEventGenerator.tapAtTouchLocations(locations, numberOfTaps: UInt(numberOfTaps), orientation: orientationValue) {
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
    
    public func addXCTestElementsetvalue(element:XCUIElement ,text:String){
        addAction(){
            let semaphore = DispatchSemaphore(value: 0)
            XCTestDaemonsProxy.testRunnerProxy()._XCT_send(text, maximumFrequency: 60) { (error) in
                semaphore.signal()
                if error != nil {
                    NSLog("Error occured in sending key: \(error.debugDescription)")
                }
            }
            semaphore.wait()
        }
    }
    
    public func addXCTestPasswordAction(application:XCUIApplication){
        addAction(){ [weak self] in
            do{
                let session = try XCTestWDSessionManager.singleton.checkDefaultSessionthrow()
                let root = session.application
                if root != nil{
                    let usage = "xpath"
                    let tag = "//XCUIElementTypeButton[@name='1']"
                    let delete = "//XCUIElementTypeButton[@name='mm keyboard delete']"
                    var element = try? XCTestWDFindElementUtils.filterElement(usingText: usage, withvalue: delete, underElement: root!)
                    if let element = element {
                        if element != nil {
                            let rect = element?.wdFrame()
                            let locations: [CGPoint]
                            locations = [self!.randomPoint(inRect: rect!)]
                            var loop = 1
                            while loop<7 {
                                let numberOfTaps: UInt = 1
                                let semaphore = DispatchSemaphore(value: 0)
                                self!.sharedXCEventGenerator.tapAtTouchLocations(locations, numberOfTaps: numberOfTaps, orientation: orientationValue) {
                                    semaphore.signal()
                                }
                                let useStr="Delete password \(String(describing: locations))"
                                NSLog("XCTestMonkey:%@",useStr)
                                semaphore.wait()
                                usleep(500000)
                                loop = loop + 1
                            }
                        }
                    }
                    
                    element = try? XCTestWDFindElementUtils.filterElement(usingText: usage, withvalue: tag, underElement: root!)
                    if let element = element {
                        if element != nil {
                            NSLog("XCTestMonkey:password find?\(String(describing: element))")
                            let rect = element?.wdFrame()
                            let locations: [CGPoint]
                            locations = [self!.randomPoint(inRect: rect!)]
                            var loop = 1
                            while loop<7 {
                                let numberOfTaps: UInt = 1
                                let semaphore = DispatchSemaphore(value: 0)
                                self!.sharedXCEventGenerator.tapAtTouchLocations(locations, numberOfTaps: numberOfTaps, orientation: orientationValue) {
                                    semaphore.signal()
                                }
                                let useStr="Input password \(String(describing: locations))"
                                NSLog("XCTestMonkey:%@",useStr)
                                semaphore.wait()
                                usleep(500000)
                                loop = loop + 1
                            }
                        }
                    }
                    let usagename = "class name"
                    let navibar = "XCUIElementTypeNavigationBar"
                    element = try? XCTestWDFindElementUtils.filterElement(usingText: usagename, withvalue: navibar, underElement: root!)
                    if let element = element {
                        if element != nil {
                            let back = element?.children(matching:.button)
                            let rect = back?.firstMatch.wdFrame()
                            if let rect = rect {
                                var loop = 1
                                while loop<4 {
                                    let numberOfTaps: UInt = 1
                                    let locations: [CGPoint]
                                    locations = [self!.randomPoint(inRect: rect)]
                                    let semaphore = DispatchSemaphore(value: 0)
                                    self!.sharedXCEventGenerator.tapAtTouchLocations(locations, numberOfTaps: numberOfTaps, orientation: orientationValue) {
                                        semaphore.signal()
                                    }
                                    let useStr="Bact to Main screen Tap \(String(describing: locations))"
                                    NSLog("XCTestMonkey:%@",useStr)
                                    semaphore.wait()
                                    usleep(500000)
                                    loop = loop + 1
                                }
                            }
                        }
                    }
                    return
                }
            }catch{
                return
            }
        }
    }
    
    public func addXCTestLoginAction(application:XCUIApplication,username:String,password:String) {
        addAction(){ [weak self] in
            do{
                let session = try XCTestWDSessionManager.singleton.checkDefaultSessionthrow()
                let root = session.application
                if root == nil{
                    return
                }
                let usage = "xpath"
                let userName = "//XCUIElementTypeTextField"
                let passwd = "//XCUIElementTypeSecureTextField"
                let button = "//XCUIElementTypeButton[@name='登录']"
                
                var element = try? XCTestWDFindElementUtils.filterElement(usingText: usage, withvalue: userName, underElement: root!)
                
                if let element = element {
                    if let element = element {
                        NSLog("XCTestMonkey:loginuser find?\(String(describing: element))")
                        let value = username
                        let rect = element.wdRect()
                        let point = CGPoint(x:rect["x"]!,y:rect["y"]!)
                        let locations = [point]
                        let semaphore = DispatchSemaphore(value: 0)
                        let numberOfTaps = 1
                        self!.sharedXCEventGenerator.tapAtTouchLocations(locations, numberOfTaps: UInt(numberOfTaps), orientation: orientationValue) {
                            semaphore.signal()
                        }
                        semaphore.wait()
                        self?.sleep(1)
                        XCTestDaemonsProxy.testRunnerProxy()._XCT_send(value, maximumFrequency: 60) { (error) in
                            semaphore.signal()
                            if error != nil {
                                NSLog("Error occured in sending key: \(error.debugDescription)")
                            }
                        }
                        semaphore.wait()
                    }
                    else{
                        return
                    }
                }
                
                element = try? XCTestWDFindElementUtils.filterElement(usingText: usage, withvalue: passwd, underElement: root!)
                if let element = element {
                    if let element = element {
                        NSLog("XCTestMonkey:passwd find?\(String(describing: element))")
                        let value = password
                        let rect = element.wdRect()
                        let point = CGPoint(x:rect["x"]!,y:rect["y"]!)
                        let locations = [point]
                        let semaphore = DispatchSemaphore(value: 0)
                        let numberOfTaps = 1
                        self!.sharedXCEventGenerator.tapAtTouchLocations(locations, numberOfTaps: UInt(numberOfTaps), orientation: orientationValue) {
                            semaphore.signal()
                        }
                        semaphore.wait()
                        self?.sleep(1)
                        XCTestDaemonsProxy.testRunnerProxy()._XCT_send(value, maximumFrequency: 60) { (error) in
                            semaphore.signal()
                            if error != nil {
                                NSLog("Error occured in sending key: \(error.debugDescription)")
                            }
                        }
                        semaphore.wait()
                    }
                    else{
                        return
                    }
                }
                
                element = try? XCTestWDFindElementUtils.filterElement(usingText: usage, withvalue: button, underElement: root!)
                if let element = element {
                    if let element = element {
                        NSLog("XCTestMonkey:login button find?\(String(describing: element))")
                        let rect = element.wdRect()
                        let point = CGPoint(x:rect["x"]!,y:rect["y"]!)
                        let locations = [point]
                        let semaphore = DispatchSemaphore(value: 0)
                        let numberOfTaps = 1
                        self!.sharedXCEventGenerator.tapAtTouchLocations(locations, numberOfTaps: UInt(numberOfTaps), orientation: orientationValue) {
                            semaphore.signal()
                        }
                        semaphore.wait()
                    }
                    else{
                        return
                    }
                }
            }catch{
                return
            }
        }
    }
    

    /**
        Add an action that generates a long press event
        using the private XCTest API.

        - Parameter weight: The relative probability of this
          event being generated. Can be any value larger than
          zero. Probabilities will be normalised to the sum
          of all relative probabilities.
    */
    public func addXCTestLongPressAction(weight: Double) {
        addAction(weight: weight) { [weak self] in
            let point = self!.randomPoint()
            let semaphore = DispatchSemaphore(value: 0)
            self!.sharedXCEventGenerator.pressAtPoint(point, forDuration: 0.5, orientation: orientationValue) {
                semaphore.signal()
            }
            let useStr="LongPress \(String(describing: point))"
            NSLog("XCTestMonkey:%@",useStr)
            semaphore.wait()
        }
    }

    /**
        Add an action that generates a drag event from one random
        screen position to another using the private XCTest API.

        - Parameter weight: The relative probability of this
          event being generated. Can be any value larger than
          zero. Probabilities will be normalised to the sum
          of all relative probabilities.
    */
    public func addXCTestDragAction(weight: Double) {
        addAction(weight: weight) { [weak self] in
            let start = self!.randomPointAvoidingPanelAreas()
            let end = self!.randomPoint()
            
            let semaphore = DispatchSemaphore(value: 0)
            self!.sharedXCEventGenerator.pressAtPoint(start, forDuration: 0, liftAtPoint: end, velocity: 1000, orientation: orientationValue, name: "Monkey drag" as NSString) {
                semaphore.signal()
            }
            let useStr="Drag from \(String(describing: start)) to \(String(describing:end))"
            NSLog("XCTestMonkey:%@",useStr)
            semaphore.wait()
        }
    }

    public func addXCTestSlipScreenAction(weight: Double) {
        addAction(weight: weight) { [weak self] in
            let points = self!.randomSlipPoints()
            let start = points[0]
            let end = points[1]

            let semaphore = DispatchSemaphore(value: 0)
            self!.sharedXCEventGenerator.pressAtPoint(start, forDuration: 0, liftAtPoint: end, velocity: 1000, orientation: orientationValue, name: "Monkey slip" as NSString) {
                semaphore.signal()
            }
            let useStr="Slip from \(String(describing: start)) to \(String(describing:end))"
            NSLog("XCTestMonkey:%@",useStr)
            semaphore.wait()
        }
    }
    
    /**
        Add an action that generates a pinch close gesture
        at a random screen position using the private XCTest API.

        - Parameter weight: The relative probability of this
          event being generated. Can be any value larger than
          zero. Probabilities will be normalised to the sum
          of all relative probabilities.
    */
    public func addXCTestPinchCloseAction(weight: Double) {
        addAction(weight: weight) { [weak self] in
            let rect = self!.randomRect(sizeFraction: 2)
            let scale = 1 / CGFloat(self!.r.randomDouble() * 4 + 1)
            
            let semaphore = DispatchSemaphore(value: 0)
            self!.sharedXCEventGenerator.pinchInRect(rect, withScale: scale, velocity: 1, orientation: orientationValue) {
                semaphore.signal()
            }
            let useStr="PinchClose rect \(String(describing: rect.debugDescription)) with scale \(String(describing:scale))"
            NSLog("XCTestMonkey:%@",useStr)
            semaphore.wait()
        }
    }

    /**
        Add an action that generates a pinch open gesture
        at a random screen position using the private XCTest API.

        - Parameter weight: The relative probability of this
          event being generated. Can be any value larger than
          zero. Probabilities will be normalised to the sum
          of all relative probabilities.
    */
    public func addXCTestPinchOpenAction(weight: Double) {
        addAction(weight: weight) { [weak self] in
            let rect = self!.randomRect(sizeFraction: 2)
            let scale = CGFloat(self!.r.randomDouble() * 4 + 1)
            
            let semaphore = DispatchSemaphore(value: 0)
            self!.sharedXCEventGenerator.pinchInRect(rect, withScale: scale, velocity: 3, orientation: orientationValue) {
                semaphore.signal()
            }
            let useStr="PinchOpen rect \(String(describing: rect.debugDescription)) with scale \(String(describing:scale))"
            NSLog("XCTestMonkey:%@",useStr)
            semaphore.wait()
        }
    }

    /**
        Add an action that generates a rotation gesture
        at a random screen position over a random angle
        using the private XCTest API.

        - Parameter weight: The relative probability of this
          event being generated. Can be any value larger than
          zero. Probabilities will be normalised to the sum
          of all relative probabilities.
    */
    public func addXCTestRotateAction(weight: Double) {
        addAction(weight: weight) { [weak self] in
            let rect = self!.randomRect(sizeFraction: 2)
            let angle = CGFloat(self!.r.randomDouble() * 2 * 3.141592)
            
            let semaphore = DispatchSemaphore(value: 0)
            self!.sharedXCEventGenerator.rotateInRect(rect, withRotation: angle, velocity: 5, orientation: orientationValue) {
                semaphore.signal()
            }
            let useStr="RotateAction rect \(String(describing: rect.debugDescription)) with angle \(String(describing:angle))"
            NSLog("XCTestMonkey:%@",useStr)
            semaphore.wait()
        }
    }

    /**
        Add an action that generates a device rotation event
        using the private XCTest API. Does not currently work!

        - Parameter weight: The relative probability of this
          event being generated. Can be any value larger than
          zero. Probabilities will be normalised to the sum
          of all relative probabilities.
    */
    public func addXCTestOrientationAction(weight: Double) {
        addAction(weight: weight) { [weak self] in
            
            let orientations: [UIDeviceOrientation] = [
                .portrait,
                .portraitUpsideDown,
                .landscapeLeft,
                .landscapeRight,
                .faceUp,
                .faceDown,
                ]
            
            let index = Int(self!.r.randomUInt32() % UInt32(orientations.count))
            orientationValue = orientations[index]
        }
    }
}

@objc public protocol XCEventGenerator {
    static func sharedGenerator() -> XCEventGenerator

    var generation: UInt64 { get set }
    //@property(readonly) NSObject<OS_dispatch_queue> *eventQueue; // @synthesize eventQueue=_eventQueue;

    @discardableResult func rotateInRect(_: CGRect, withRotation: CGFloat, velocity: CGFloat, orientation: UIDeviceOrientation, handler: @escaping () -> Void) -> CGFloat
    @discardableResult func pinchInRect(_: CGRect, withScale: CGFloat, velocity: CGFloat, orientation: UIDeviceOrientation, handler: @escaping () -> Void) -> CGFloat
    @discardableResult func pressAtPoint(_: CGPoint, forDuration: TimeInterval, liftAtPoint: CGPoint, velocity: CGFloat, orientation: UIDeviceOrientation, name: AnyObject, handler: @escaping () -> Void) -> CGFloat
    @discardableResult func pressAtPoint(_: CGPoint, forDuration: TimeInterval, orientation: UIDeviceOrientation, handler: @escaping () -> Void) -> CGFloat
    @discardableResult func tapAtTouchLocations(_: [CGPoint], numberOfTaps: UInt, orientation: UIDeviceOrientation, handler: @escaping () -> Void) -> CGFloat
    func _startEventSequenceWithSteppingCallback(_: () -> Void)
    func _scheduleCallback(_: () -> Void, afterInterval: TimeInterval)

    init()
}
