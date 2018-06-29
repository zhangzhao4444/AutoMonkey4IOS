//
//  XCTestWDMonkeyController.swift
//  FastMonkey
//
//  fixed by zhangzhao on 2017/7/17.
//

import Foundation
import XCTest

/**
    Extension using the public XCTest API to generate
    events.
*/
@available(iOS 9.0, *)
extension Monkey {

    /**
        Add an action that checks, at a fixed interval,
        if an alert is being displayed, and if so, selects
        a random button on it.

        - parameter interval: How often to generate this
          event. One of these events will be generated after
          this many randomised events have been generated.
        - parameter application: The `XCUIApplication` object
          for the current application.
    */
    public func addXCTestTapAlertAction(interval: Int, application: XCUIApplication) {
        addAction(interval: interval) { [weak self] in
            // The test for alerts on screen and dismiss them if there are any.
            //            for i in 0 ..< application.alerts.count {
            //                let alert = application.alerts.element(boundBy: i)
            //                let buttons = alert.descendants(matching: .button)
            //                XCTAssertNotEqual(buttons.count, 0, "No buttons in alert")
            //                let index = UInt(self!.r.randomUInt32() % UInt32(buttons.count))
            //                let button = buttons.element(boundBy: index)
            //                button.tap()
            //            }
            usleep(2000000)
            //let isRunning = application.running
            //let current = Int(XCTestWDFindElementUtils.getAppPid())
            //if current == 0 {
            //    return
            //}
            if application.state == XCUIApplication.State.runningForeground {
                for i in 0 ..< application.alerts.count {
                    let alert = application.alerts.element(boundBy: i)
                    let buttons = alert.descendants(matching: .button)
                    let index = UInt(self!.r.randomUInt32() % UInt32(buttons.count))
                    let button = buttons.element(boundBy: index)
                    button.tap()
                    let useStr="Button tap \(String(describing: button))"
                    NSLog("XCTestMonkey:%@",useStr)
                    return
                }
            }else{
                application.activate()
                self!.sleep(5)
                self?.pid = Int(XCTestWDFindElementUtils.getAppPid())
                let useStr="app kack to foreground)"
                NSLog("XCTestMonkey:%@",useStr)
                return
            }
        }
    }
    
    /**
     Add an action that checks current app, at a fixed interval,
     if app is not running , so launch app
     */
    
    public func addXCTestCheckCurrentApp(interval:Int, application:XCUIApplication) {
        addCheck(interval:interval){ [weak self] in
            //let work = DispatchWorkItem(qos:.userInteractive){
                /** too slow **/
                //application._waitForQuiescence()
            //    let isRunning = application.running
            //    let current = Int(XCTestWDFindElementUtils.getAppPid())
            //    if current != self?.pid || !isRunning{
            //        application.launch()
            //        self?.sleep(5)
            //        self?.pid = Int(XCTestWDFindElementUtils.getAppPid())
            //    }
            //}
            //DispatchQueue.main.async(execute:work)
            let work = DispatchWorkItem(qos:.userInteractive){
                if (application.state != XCUIApplication.State.runningForeground){
                    application.activate()
                    self?.sleep(5)
                    self?.pid = Int(XCTestWDFindElementUtils.getAppPid())
                    let useStr="app back to foreground)"
                    NSLog("XCTestMonkey:%@",useStr)
                }
            }
            DispatchQueue.main.async(execute:work)
        }
    }
    
    /**
     display current page to assist resolve problem
    */
    
    public func addXCTestCurrentPage(interval:Int, application:XCUIApplication){
        addAction(interval: interval){
            do{
                let session = try XCTestWDSessionManager.singleton.checkDefaultSessionthrow()
                let root = session.application
                if root != nil{
                    let usage = "class name"
                    let tag = "XCUIElementTypeNavigationBar"
                    let element = try? XCTestWDFindElementUtils.filterElement(usingText: usage, withvalue: tag, underElement: root!)
                    if let element = element {
                        if element != nil {
                            NSLog("XCTestMonkey:current page is \(String(describing: element?.rootName()))")
                        }
                    }
                }
            }catch{
                return
            }
        }
    }
    
    /**
     Add an action that check ui , at a fixed interval,
     if find the same ui then back to main ui
     */
    
    public func addXCTestAppMain(interval:Int, application:XCUIApplication) {
        addAction(interval:interval){ [weak self] in
            do{
                let session = try XCTestWDSessionManager.singleton.checkDefaultSessionthrow()
                let root = session.application
                if root != nil{
                    let usage = "class name"
                    let tag = "XCUIElementTypeNavigationBar"
                    let element = try? XCTestWDFindElementUtils.filterElement(usingText: usage, withvalue: tag, underElement: root!)
                    if let element = element {
                        if element != nil {
                            NSLog("XCTestMonkey:ui at \(String(describing: element?.rootName()))")
                            if self?.preElement == nil{
                                NSLog("XCTestMonkey:ui at first time \(String(describing: element?.rootName()))")
                                self?.preElement=(String(describing: element?.rootName()))
                                return
                            }else if self?.preElement == (String(describing:element?.rootName())){
                                NSLog("XCTestMonkey:ui at second time\(String(describing: element?.rootName()))")
                                let back = element?.children(matching:.button)
                                let rect = back?.firstMatch.wdFrame()
                                if let rect = rect {
                                    NSLog("XCTestMonkey:ui at 3333 \(String(describing: element?.rootName()))")
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
                                return
                            }else{
                                NSLog("XCTestMonkey:ui at nothing \(String(describing: element?.rootName()))<-XCTestWDSetup")
                                self?.preElement=(String(describing: element?.rootName()))
                                return
                            }
                        }else{
                            return
                        }
                    }
                }
            }catch{
                return
            }
        }
    }
    
    public func addXCTestPasswordAction(interval:Int, application:XCUIApplication){
        addAction(interval:interval){ [weak self] in
            do{
                let session = try XCTestWDSessionManager.singleton.checkDefaultSessionthrow()
                let root = session.application
                if root != nil{
                    let usage = "xpath"
                    let tag = "//XCUIElementTypeImage[@name='eg_password']"
                    let element = try? XCTestWDFindElementUtils.filterElement(usingText: usage, withvalue: tag, underElement: root!)
                    if let element = element {
                        if element != nil {
                            self?.addXCTestPasswordAction(application: application)
                        }else{
                            return
                        }
                    }
                }
            }catch{
                return
            }
        }
    }
    
    /**
     Add an action that check login keypoint, at a fixed interval,
     if find key point, take login event
     */

    public func addXCTestAppLogin(interval:Int, application:XCUIApplication,username:String,password:String) {
        addAction(interval:interval){ [weak self] in
            do{
                let session = try XCTestWDSessionManager.singleton.checkDefaultSessionthrow()
                let root = session.application
                if root != nil{
                    let usage = "xpath"
                    let tag = "//XCUIElementTypeStaticText[@name='记住用户名']"
                    let element = try? XCTestWDFindElementUtils.filterElement(usingText: usage, withvalue: tag, underElement: root!)
                    if let element = element {
                        if element != nil {
                            self?.addXCTestLoginAction(application: application,username:username,password:password)
                        }
                        else{
                            return
                        }
                    }
                }
            }catch{
                return
            }
        }
    }
}

