//
//  ViewController.swift
//  HLPrimes
//
//  Created by Matthew Homer on 5/28/17.
//  Copyright © 2017 HomerLabs. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSControlTextEditingDelegate, HLPrimesProtocol {

    @IBOutlet var primeFilePathTextField: NSTextField!
    @IBOutlet var nicePrimeFilePathTextField: NSTextField!
//    @IBOutlet var lastLinePrimeTextField: NSTextField!
    @IBOutlet var terminalPrimeTextField: NSTextField!
    @IBOutlet var modCountTextField: NSTextField!
    @IBOutlet var progressTextField: NSTextField!

    @IBOutlet var primeButton: NSButton!
    @IBOutlet var nicePrimesButton: NSButton!

    var primeFinder: HLPrime!
    let HLDefaultPrimeFilePathKey       = "PrimeFilePathKey"
    let HLDefaultNicePrimeFilePathKey   = "NicePrimeFilePathKey"
    let HLDefaultTerminalPrimeKey       = "TerminalPrimeKey"
    let HLDefaultModCountKey            = "ModCountKey"
    
    let defaultTerminalPrime = "1000000"
    let defaultModSize = "100000"
    
    var findPrimesInProgress = false
    var findNicePrimesInProgress = false
    var factorPrimesInProgress = false
    var errorCode = 0

    var primesURL: URL? = nil
    var nicePrimesURL: URL? = nil
    let HLPrimesBookmarkKey         = "HLPrimesBookmarkKey"
    let HLNicePrimesBookmarkKey     = "HLNicePrimesBookmarkKey"


    @IBAction func setPrimesPathAction(sender: NSButton) {
        let path = getSaveFilePath(title: "Set Primes file path", fileName: "Primes", bookmarkName: HLPrimesBookmarkKey)
        primeFilePathTextField.stringValue = path
        UserDefaults.standard.set(path, forKey:HLDefaultPrimeFilePathKey)
        primesURL = path.getBookmarkFor(key: HLPrimesBookmarkKey)
    }

    @IBAction func setNicePrimesPathAction(sender: NSButton) {
        let path = getSaveFilePath(title: "Set NicePrimes file path", fileName: "NicePrimes", bookmarkName: HLNicePrimesBookmarkKey)
        nicePrimeFilePathTextField.stringValue = path
        UserDefaults.standard.set(path, forKey:HLDefaultNicePrimeFilePathKey)
        primesURL = path.getBookmarkFor(key: HLNicePrimesBookmarkKey)
    }

   func getSaveFilePath(title: String, fileName: String, bookmarkName: String) -> String     {
    
        var path = ""
        let savePanel = NSSavePanel();
        savePanel.canCreateDirectories = true;
        savePanel.title = "PrimeFinder Save Panel";
        savePanel.nameFieldStringValue = fileName;
        savePanel.showsTagField = false;
        savePanel.prompt = "Create";
        savePanel.message = title;
        savePanel.nameFieldLabel = "Save As:";
        savePanel.allowedFileTypes = ["txt"];

        let i = savePanel.runModal();
        if(i == NSApplication.ModalResponse.OK){
            path = savePanel.url!.path
            savePanel.url!.setBookmarkFor(key: bookmarkName)
        }
        return path
    }


    @IBAction func checkProgressAction(sender: NSButton) {
            progressTextField.stringValue = String(primeFinder.lastP)
    }
    
    @IBAction func filterAction(sender: NSButton) {
        if nicePrimesButton.state == .on {
            nicePrimesButton.title = "Running"
            primeFinder.makeNicePrimesFile2(largestPrime: Int64(terminalPrimeTextField.stringValue)!)
            findNicePrimesInProgress = true
        }
        else    {
            nicePrimesButton.title = "Stopped"
            nicePrimesButton.isEnabled = false
            primeFinder.active = false
        }
    }
    
    @IBAction func primesStartAction(sender: NSButton) {
        
        if primeButton.state == .on {
            primeButton.title = "Running"
            primeFinder.findPrimes(largestPrime: Int64(terminalPrimeTextField.stringValue)!)
            findPrimesInProgress = true
        }
        else    {
            primeButton.title = "Stopped"
            primeButton.isEnabled = false
            primeFinder.active = false
        }
    }
    

    //*************   HLPrimeProtocol     *********************************************************
/*    func hlPrimeInitCompleted()  {
        let elaspsedTime = primeFinder.actionTimeInSeconds.formatTime()
        print( "    *********   HLPrime init completed in \(elaspsedTime)    *********\n" )
        findPrimesInProgress = false
        
        if primeFinder.primeFileLastLine != nil {
            lastLinePrimeTextField.stringValue = primeFinder.primeFileLastLine!
            nicePrimesButton.isEnabled = true
            nicePrimesButton.isEnabled = true
        }
        
        primeButton.isEnabled = true
        primeButton.title = "Prime Start"
    }   */
    
    func findPrimesCompleted()  {
        let elaspsedTime = primeFinder.actionTimeInSeconds.formatTime()
        print( "    *********   findPrimes completed in \(elaspsedTime)    *********\n" )
        findPrimesInProgress = false
 //       lastLinePrimeTextField.stringValue = primeFinder.primeFileLastLine!
        primeButton.title = "Completed"
        primeButton.isEnabled = false
    }
    
    func findNicePrimesCompleted()  {
        let elaspsedTime = primeFinder.actionTimeInSeconds.formatTime()
        print( "    *********   findNicePrimes completed in \(elaspsedTime)    *********\n" )
        findNicePrimesInProgress = false
//        lastLinePrimeTextField.stringValue = primeFinder.primeFileLastLine!
        nicePrimesButton.title = "Completed"
        nicePrimesButton.isEnabled = false
    }
    
/*    func factorPrimesCompleted()    {
        let elaspsedTime = primeFinder.actionTimeInSeconds.formatTime()
        print( "    *********   makePrimes completed  in \(elaspsedTime)    *********\n" )
        factorPrimesInProgress = false
        lastLineFactorTextField.stringValue = primeFinder.factorFileLastLine!
        factorStartButton.title = "Completed"
        factorStartButton.isEnabled = false
    }   */
    //*************   HLPrimeProtocol     *********************************************************


    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool    {
        print( "ViewController-  textShouldEndEditing-  control: \(control.stringValue)" )
        
/*        if control == primeFilePathTextField    {
            var newValue = control.stringValue
            if !newValue.hasPrefix("/")  {
                newValue = "/Users/" + NSUserName() + "/" + newValue
            }
            
            primeFinder.setupFilePaths(basePath: newValue)
        
            if let lastLine = primeFinder.lastLineFor(path: newValue) {
                lastLinePrimeTextField.stringValue = lastLine
            }
            else    {
                lastLinePrimeTextField.stringValue = "FILE NOT FOUND"
            }
            
            UserDefaults.standard.set(newValue, forKey:HLDefaultPrimeFilePathKey)
        }   */

        if control == terminalPrimeTextField    {
            terminalPrimeTextField.stringValue = control.stringValue
            UserDefaults.standard.set(control.stringValue, forKey:HLDefaultTerminalPrimeKey)
        }

        else if control == modCountTextField    {
            primeFinder.fileManager.setModSize(control.intValue)
            modCountTextField.stringValue = control.stringValue
            UserDefaults.standard.set(control.stringValue, forKey:HLDefaultModCountKey)
        }

        else    {   assert( false )     }
        
        UserDefaults.standard.synchronize()
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
 //       lastLinePrimeTextField.stringValue = "?"
        progressTextField.stringValue = "?"

        if let primeFilePath = UserDefaults.standard.string(forKey: HLDefaultPrimeFilePathKey)  {
            primesURL = primeFilePath.getBookmarkFor(key: HLNicePrimesBookmarkKey)
            if primesURL != nil {
                primeFilePathTextField.stringValue = primeFilePath
            }
        }

        if let nicePrimeFilePath = UserDefaults.standard.string(forKey: HLDefaultNicePrimeFilePathKey)  {
            nicePrimesURL = nicePrimeFilePath.getBookmarkFor(key: HLNicePrimesBookmarkKey)
            if nicePrimesURL != nil {
                nicePrimeFilePathTextField.stringValue = nicePrimeFilePath
            }
        }

        if let terminalPrime = UserDefaults.standard.string(forKey: HLDefaultTerminalPrimeKey)  {
            terminalPrimeTextField.stringValue = terminalPrime
        }
        else    {
            terminalPrimeTextField.stringValue = defaultTerminalPrime
        }

        if let modCount = UserDefaults.standard.string(forKey: HLDefaultModCountKey)  {
            modCountTextField.stringValue = modCount
        }
        else    {
            modCountTextField.stringValue = defaultModSize
        }

 //       if
 //       primeFinder = HLPrime(primeFilePath: primeFilePathTextField.stringValue, modCount: modCountTextField.intValue, delegate: self)
        
 //       if let primeLastLine = primeFinder.primeFileLastLine    {
 //           lastLinePrimeTextField.stringValue = primeLastLine
  //      }
    }
}

