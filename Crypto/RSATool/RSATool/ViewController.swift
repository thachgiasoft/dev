//
//  ViewController.swift
//  RSATool
//
//  Created by Matthew Homer on 10/19/17.
//  Copyright © 2017 Matthew Homer. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSControlTextEditingDelegate {

    let defaultPrimeP: String = "257"
    let defaultPrimeQ = "251"
    let defaultPublicKey = "36083"
    let defaultCharacterSet = "-ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+*/"

    @IBOutlet var plaintextFilePathTextField: NSTextField!
    @IBOutlet var ciphertextFilePathTextField: NSTextField!
    @IBOutlet var deCiphertextFilePathTextField: NSTextField!
    
    @IBOutlet var primePTextField: NSTextField!
    @IBOutlet var primeQTextField: NSTextField!
    @IBOutlet var publicKeyTextField: NSTextField!
    @IBOutlet var privateKeyTextField: NSTextField!
    @IBOutlet var nTextField: NSTextField!
    @IBOutlet var gammaTextField: NSTextField!
    @IBOutlet var characterSetTextField: NSTextField!
    @IBOutlet var characterSetSizeTextField: NSTextField!
    @IBOutlet var chunkSizeTextField: NSTextField!

    @IBOutlet var encodeButton: NSButton!
    @IBOutlet var decodeButton: NSButton!

    var rsa: HLRSA!
    let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
    var plainTextURL: URL?
    var cipherTextURL: URL?
    var deCipherTextURL: URL?

    let HLDefaultCharacterSetKey        = "CharacterSetKey"
    let HLDefaultPrimePKey              = "PrimePKey"
    let HLDefaultPrimeQKey              = "PrimeQKey"
    let HLDefaultPublicKey              = "HLPublicKey"
    
    let HLPlaintextBookmarkKey          = "PlaintextBookmarkKey"
    let HLCiphertextBookmarkKey         = "CiphertextBookmarkKey"
    let HLDeCiphertextBookmarkKey       = "DeCiphertextBookmarkKey"
   
    @IBAction func setPlaintextPathAction(sender: NSButton) {
        plainTextURL = HLPlaintextBookmarkKey.getOpenFilePath(title: "Open Plaintext file")
        guard let url = plainTextURL else { return }

        plaintextFilePathTextField.stringValue = url.path
        UserDefaults.standard.set(url, forKey: HLPlaintextBookmarkKey)
    }

    @IBAction func setCiphertextPathAction(sender: NSButton) {
        let filename = "Ciphertext"
        cipherTextURL = filename.getSaveFilePath(title: "HLCrypto Save Panel", message: "Set Ciphertext file path")
        guard let url = cipherTextURL else { return }

        ciphertextFilePathTextField.stringValue = url.path
        UserDefaults.standard.set(url, forKey: HLCiphertextBookmarkKey)
    }

    @IBAction func setDeCiphertextPathAction(sender: NSButton) {
        let filename = "DeCiphertext"
        deCipherTextURL = filename.getSaveFilePath(title: "HLCrypto Save Panel", message: "Set DeCiphertext file path")
        guard let url = deCipherTextURL else { return }

        deCiphertextFilePathTextField.stringValue = url.path
        UserDefaults.standard.set(url, forKey: HLDeCiphertextBookmarkKey)
    }
    
    
    @IBAction func encodeAction(sender: NSButton) {
        guard rsa.keyPrivate != -1 else {
            displayAlert(title: "Calculated Key cannot be equal to -1", message: "Please enter valid Chosen Key value.")
            return
        }

        if plainTextURL == nil   {
            print( "plainTextURL is nil" )
            setPlaintextPathAction(sender: sender) //  wrong button but any button will do
        }
        
        if cipherTextURL == nil   {
            print( "cipherTextURL is nil" )
            setCiphertextPathAction(sender: sender) //  wrong button but any button will do
        }
        
        rsa.encodeFile(inputFilepath: plaintextFilePathTextField.stringValue, outputFilepath: ciphertextFilePathTextField.stringValue)
        print( "rsa.encodeFile completed." )
    }


    @IBAction func decodeAction(sender: NSButton) {
         guard rsa.keyPrivate != -1 else {
            displayAlert(title: "Calculated Key cannot be equal to -1", message: "Please enter valid Chosen Key value.")
            return
        }

       if cipherTextURL == nil   {
            print( "cipherTextURL is nil" )
            cipherTextURL = HLCiphertextBookmarkKey.getOpenFilePath(title: "Open Ciphertext file")
            ciphertextFilePathTextField.stringValue = cipherTextURL!.path
        }
        
        if deCipherTextURL == nil   {
            print( "deCipherTextURL is nil" )
            setDeCiphertextPathAction(sender: sender) //  wrong button but any button will do
        }
        
        rsa.decodeFile(inputFilepath: ciphertextFilePathTextField.stringValue, outputFilepath: deCiphertextFilePathTextField.stringValue)
        print( "rsa.decodeFile completed." )
    }


     func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool    {
        print( "ViewController-  textShouldEndEditing-  control: \(control.stringValue)" )
        
        if control == primePTextField    {
            guard let value = HLPrimeType(primePTextField.stringValue), value > 1 else {
                displayAlert(title: "Prime P must be an integer > 1", message: "Please enter valid Prime P value.")
                return false
            }
            setupRSA()
            UserDefaults.standard.set(primePTextField.stringValue, forKey:HLDefaultPrimePKey)
        }

        else if control == primeQTextField    {
            guard let value = HLPrimeType(primeQTextField.stringValue), value > 1 else {
                displayAlert(title: "Prime Q must be an integer > 1", message: "Please enter valid Prime Q value.")
                return false
            }
            setupRSA()
            UserDefaults.standard.set(primeQTextField.stringValue, forKey:HLDefaultPrimeQKey)
        }

        else if control == publicKeyTextField    {
            //  allow the public key == 1 to see what happens (calculated key will equal 1 also)
            guard let value = HLPrimeType(publicKeyTextField.stringValue), value > 0 else {
                displayAlert(title: "Public Key must be an integer > 0", message: "Please enter valid Public Key value.")
                return false
            }
            setupKeys()
            UserDefaults.standard.set(publicKeyTextField.stringValue, forKey:HLDefaultPublicKey)
        }

        else if control == characterSetTextField    {
            UserDefaults.standard.set(characterSetTextField.stringValue, forKey:HLDefaultCharacterSetKey)
            characterSetSizeTextField.integerValue = characterSetTextField.stringValue.count
            setupRSA()
        }

        else    {   assert( false )     }
        
        UserDefaults.standard.synchronize()
        return true
    }
    
    func setupKeys()    {
        let publicKey = HLPrimeType(publicKeyTextField.stringValue)!
        let privateKey = rsa.calculateKey(publicKey: publicKey)
        privateKeyTextField.stringValue = String(privateKey)
        rsa.keyPublic = publicKey
        rsa.keyPrivate = privateKey
    }
    
    
    func setupRSA() {
        let charSet = characterSetTextField.stringValue
        let p = HLPrimeType(primePTextField.stringValue)!
        let q = HLPrimeType(primeQTextField.stringValue)!
        let n = p * q
        let gamma = (p-1) * (q-1)
        nTextField.stringValue = String(n)
        gammaTextField.stringValue = String(gamma)
        rsa = HLRSA(p: p, q: q, characterSet: charSet)
        setupKeys()
        
        chunkSizeTextField.stringValue = String.init(format:" %0.1f", arguments: [rsa.chuckSizeDouble])
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
//        print( "ViewController-  viewDidDisappear" )
        
        plainTextURL?.stopAccessingSecurityScopedResource()
        cipherTextURL?.stopAccessingSecurityScopedResource()
        deCipherTextURL?.stopAccessingSecurityScopedResource()
        
        exit(0) //  if main window closes then quit app
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let primeP = UserDefaults.standard.string(forKey: HLDefaultPrimePKey)  {
            primePTextField.stringValue = primeP
        }
        else    {
            primePTextField.stringValue = defaultPrimeP
        }

        if let primeQ = UserDefaults.standard.string(forKey: HLDefaultPrimeQKey)  {
            primeQTextField.stringValue = primeQ
        }
        else    {
            primeQTextField.stringValue = defaultPrimeQ
        }

        if let publicKey = UserDefaults.standard.string(forKey: HLDefaultPublicKey)  {
  //          NSSound(named: NSSound.Name(rawValue: "Ping"))?.play()
            publicKeyTextField.stringValue = publicKey
        }
        else    {
   //         NSSound(named: NSSound.Name(rawValue: "Purr"))?.play()
            publicKeyTextField.stringValue = defaultPublicKey
        }

        if let characterSet = UserDefaults.standard.string(forKey: HLDefaultCharacterSetKey)  {
            characterSetTextField.stringValue = characterSet
        }
        else    {
            characterSetTextField.stringValue = defaultCharacterSet
            characterSetSizeTextField.integerValue = characterSetTextField.stringValue.count
        }

        plainTextURL = HLPlaintextBookmarkKey.getBookmark()
        if plainTextURL != nil  {
            plaintextFilePathTextField.stringValue = plainTextURL!.path
        }

        cipherTextURL = HLCiphertextBookmarkKey.getBookmark()
        if cipherTextURL != nil  {
            ciphertextFilePathTextField.stringValue = cipherTextURL!.path
        }

        deCipherTextURL = HLDeCiphertextBookmarkKey.getBookmark()
        if deCipherTextURL != nil  {
            deCiphertextFilePathTextField.stringValue = deCipherTextURL!.path
        }

        setupRSA()
   }
}
