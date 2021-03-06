//
//  HLRSA.swift
//  RSATool
//
//  Created by Matthew Homer on 10/30/17.
//  Copyright © 2017 Matthew Homer. All rights reserved.
//

//************************************************************************
//        Z(N) = { 1, 2, ... N-1 } but I don't use '1' so it becomes
//        Z(N) = { 2, 3, ... N-1 }
//        N = RSA_P * RSA_Q
//        Gamma = lcm( RSA_P-1, RSA_Q-1 )
//        RSA_KeyPublic * RSA_KeyPrivate is congruant to 1 mod( Gamma )
//        C = M**RSA_KeyPublic  % N
//        M = C**RSA_KeyPrivate % N
//************************************************************************
import Cocoa

public typealias HLPrimeType = Int64

public struct HLRSA {

    let N: HLPrimeType
    let Phi: HLPrimeType
    var keyPrivate: HLPrimeType = 0
    var keyPublic: HLPrimeType = 0
    let chuckSize: Int
    let chunkSizeDouble: Double

    let charSetSize: HLPrimeType
    let charSetSizePlusOne: HLPrimeType
    var charSet: [Character]
    
    
    func chunker(workingString: inout String) -> String   {
        var chunk = ""
//        print( "chunker-  workingString: \(workingString)" )
        
        if workingString.count > chuckSize  {
            chunk = String( workingString.prefix(chuckSize+1) )
            let chunkInt = stringToInt(text: chunk)
            if chunkInt < N     {
                //  done
   //             print( "chunker-  chunkPlusOne: \(chunk)    chunkInt: \(chunkInt)" )
                workingString.removeFirst(chunk.count)
            }
            
            else    {
                chunk = String( workingString.prefix(chuckSize) )
  //              print( "chunker-  chunk: \(chunk)    chunkInt: \(stringToInt(text: chunk))" )
                workingString.removeFirst(chunk.count)
            }
        }
        else    {
            chunk = String( workingString.prefix(chuckSize) )
   //         print( "chunker-  chunk: \(chunk)    chunkInt: \(stringToInt(text: chunk))" )
            workingString.removeFirst(chunk.count)
        }
        
        return chunk
    }

    func fastExp2Of(a: HLPrimeType, exp: HLPrimeType, mod: HLPrimeType) -> HLPrimeType   {
        let arraySize = 100
        var value: [Float80] = Array(repeatElement(0, count: arraySize))
        var weight: [HLPrimeType] = Array(repeatElement(0, count: arraySize))
        var i = 0
        var partialResult = Float80(a)
        value[0] = Float80(a)
        weight[0] = 1
        let bigMod = Float80(mod)
        
        while weight[i] < exp   {
            i += 1
            let temp = partialResult * partialResult
            partialResult = temp.truncatingRemainder(dividingBy: bigMod)
            value[i] = partialResult
            weight[i] = weight[i-1] * 2
  //      print( "i: \(i)   weight[i]: \(weight[i])   partialResult: \(partialResult)" )
       }
       
 //       print( "fastExp2Of: \(a)   exp: \(exp)   mod: \(mod)   i: \(i)" )
       partialResult = 1
       var count = exp
       
        while count > 0  {
            var j = 0
            while weight[j+1] < count   {
                j += 1
            }
            
            let temp = partialResult * value[j]
            partialResult = temp.truncatingRemainder(dividingBy: bigMod)
   //         print( "count: \(count)   j: \(j)" )
            count -= weight[j]
        }

        return HLPrimeType(partialResult)
    }
    
    
    func fastExpOf(a: HLPrimeType, exp: HLPrimeType, mod: HLPrimeType) -> HLPrimeType   {

        var weight: HLPrimeType = 0
        var d: Float80 = 1
        var i: Int = 60
        var bitIndex = Int64(pow(2.0, Double(i)))
        let bigMod = Float80(mod)
        let bigA = Float80(a)

//        print( "fastExpOf: \(a)   exp: \(exp)   mod: \(mod)" )

        while i >= 0 {
        
            weight = weight << 1
            var bigD = d
            bigD *= bigD
            d = bigD.truncatingRemainder(dividingBy: bigMod)
            d = Float80(Int64(d))

            let testB = exp & bitIndex > 0
 //           print( "i: \(i)   bitIndex: \(bitIndex)    weight: \(weight)    testB: \(testB)   d: \(d)   temp: \(temp.debugDescription)" )

           if testB   {
                weight += 1
                let temp = d * bigA
                d = temp.truncatingRemainder(dividingBy: bigMod)
       //         d = Int64(temp2)
       //      print( "i: \(i)   bitIndex: \(bitIndex)    weight: \(weight)   d: \(d)   temp: \(temp.debugDescription)" )
           }
            
 //          print( "i: \(i)   testB: \(testB)    weight: \(weight)   d: \(d)   " )
            bitIndex = bitIndex >> 1
            i -= 1
        }
        
        return Int64(d)
    }

    func slowExpOf(a: HLPrimeType, exp: HLPrimeType, mod: HLPrimeType) -> HLPrimeType   {
        
        let bigMod = Float80(mod)
        let bigA = Float80(a)
        var bigC = bigA

        for _ in 2...exp    {
            bigC *= bigA
            bigC = bigC.truncatingRemainder(dividingBy: bigMod)
        }

       return Int64(bigC)
    }

    func encode( m: HLPrimeType, key: HLPrimeType) -> HLPrimeType {
        let result = fastExpOf(a: m, exp: key, mod: N)
//        let result2 = fastExp2Of(a: m, exp: key, mod: N)
//        let result3 = slowExpOf(a: m, exp: key, mod: N)
  //      assert(result == result2 )
//        print( "encode-  result: \(result)  result2: \(result2)  result3: \(result3)" )
        return result
    }
    
    
    //  have to add one to the index to avoid zero
    func stringToInt(text: String) -> HLPrimeType {
        var result: HLPrimeType = 0
        
        for char in text    {
            result *= charSetSizePlusOne
            let n = Int64(indexForChar(c: char)+1)
     //       print( "stringToInt-  char: \(char)  result: \(result)    n: \(n)" )
            result += n
       }
        
        return result
    }
    
    //  have to subtract one to make up for the add one in stringToInt()
    func intToString( n: HLPrimeType ) -> String {
        var result = ""
        var workingN = n
        var power = charSetSizePlusOne
        while power < n {   power *= charSetSizePlusOne}
        
        while power > 1 {
            power /= charSetSizePlusOne
            if workingN >= power {
                let index = Int(workingN / power)
                
     //           print( "intToString-  workingN: \(workingN)  power: \(power)" )
                result.append(charSet[index-1])
           }
            workingN %= power
  //          print( "intToString-  result: \(result)" )
        }
        
        return result
    }
    
    
    //  check each character in the input string and replace any invalid character with a default character
    //  use the first character in the characterSet as the default character
    func validateCharactersInSet( data: String ) -> String   {
        var inputString = data
        var outputString = ""

        while inputString.count > 0    {
            var char = inputString.removeFirst()
            if !charSet.contains(char)   {
                print( "Warning:  Invalid character: '\(char)' in string!" )
                char = charSet[0]   //  use the first char as the default
            }

            outputString.append(char)
        }
        
        return outputString
    }
    
    
    func decodeFile(inputFilepath: String, outputFilepath: String)  {
//        print( "HLRSA-  decode: \(path)" )
        do {
            let dataIn = try String(contentsOfFile: inputFilepath, encoding: .utf8)
            var workingString = validateCharactersInSet( data: dataIn )
            var dataOut = ""
//            print( "HLRSA-  decodeFile-  text: \(dataIn)" )
            
            var chunk = chunker(workingString: &workingString)
 //           print( "HLRSA1-  decodeFile-  chunk: \(chunk)  workingString: \(workingString)" )

            while chunk.count > 0 {

                let cipherInt = stringToInt(text: chunk)
     //           let deCipherInt = encode(m: ciphertextInt, key: keyPublic)
                let deCipherInt = encode(m: cipherInt, key: keyPrivate)
                let deCipherChunk = intToString(n: deCipherInt)
                
                dataOut.append(deCipherChunk)
                
    //            let reCypherInt = encode(m: cypher, key: keyPrivate)
                let reCipherInt = encode(m: deCipherInt, key: keyPublic)
                let reCipherChunk = intToString(n: reCipherInt)
print( "cipherChunk: \(chunk)    cipherInt: \(cipherInt)    deCipherInt: \(deCipherInt)    deCipherChunk: \(deCipherChunk)    reCipherChunk: \(reCipherChunk)" )

                chunk = chunker(workingString: &workingString)
            }
            
            try dataOut.write(toFile: outputFilepath, atomically: false, encoding: .utf8)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    func encodeFile(inputFilepath: String, outputFilepath: String)  {
//        print( "HLRSA-  encode: \(path)" )
        do {
            let dataIn = try String(contentsOfFile: inputFilepath, encoding: .utf8)
            var workingString = validateCharactersInSet( data: dataIn )
            var dataOut = ""
//            print( "HLRSA-  encodeFile-  text: \(dataIn)" )
            
            var chunk = chunker(workingString: &workingString)
 //           print( "HLRSA1-  encodeFile-  chunk: \(chunk)  workingString: \(workingString)" )

            while chunk.count > 0 {
                let plaintextInt = stringToInt(text: chunk)
                let cipher = encode(m: plaintextInt, key: keyPublic)
      //           let cipher = encode(m: plaintextInt, key: keyPrivate)
               let cipherChunk = intToString(n: cipher)

                dataOut.append(cipherChunk)
                
                let deCipherInt = encode(m: cipher, key: keyPrivate)
    //            let deCipherInt = encode(m: cypher, key: keyPublic)
                let deCipherString = intToString(n: deCipherInt)
print( "plaintextChunk: \(chunk)    plaintextInt: \(plaintextInt)    cyipherInt: \(cipher)    cipherChunk: \(cipherChunk)    deCipherChunk: \(deCipherString)" )
                
                chunk = chunker(workingString: &workingString)
            }
            
            try dataOut.write(toFile: outputFilepath, atomically: false, encoding: .utf8)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    //  for a give char, return it's index in the charSet
    //  return 1 not 0 for the first index
    func indexForChar( c: Character) -> Int {
        var index = Int(charSetSize - 1)
        while index >= 0  {
            let d = charSet[index]
            if c == d   {
                break
            }
            
            index -= 1
        }
        
        return index
    }
    
    
    func calculateKey(publicKey: HLPrimeType) -> HLPrimeType  {
        let arraySize = 50
        let bigGamma = Float80(exactly: Phi)!
        var s: [Float80] = Array(repeating: 0, count: arraySize)
        var t: [Float80] = Array(repeating: 0, count: arraySize)
        var r: [Float80] = Array(repeating: 0, count: arraySize)
        s[0] = 1
        s[1] = 0
        t[0] = 0
        t[1] = 1
        r[0] = bigGamma
        r[1] = Float80(exactly: publicKey)!
        var i = 1
        
        while r[i].rounded() != 1 && r[i].rounded() != 0    {
            i += 1
            let bigQ = r[i-2] / r[i-1]
            let bigInt = Int64(bigQ)
            let q = Float80(exactly: bigInt)!
            s[i] = s[i-2] - q * s[i-1]
            t[i] = t[i-2] - q * t[i-1]
            r[i] = r[i-2] - q * r[i-1]
  //          print( "i: \(i)    r[i]: \(r[i])" )
        }

        if r[i].rounded() == 1        {
            var privateKey = t[i]
            if privateKey <= 0     {   privateKey += bigGamma       }
            
            let product = Float80(exactly: publicKey)! * Float80(exactly: privateKey)!
            let keyVerify = product.truncatingRemainder(dividingBy: bigGamma)
            assert( keyVerify.rounded() == 1 )
            return Int64(exactly: privateKey)!
        }
        
        else                {   return -1            }
    }

    func calculateKey2(publicKey: HLPrimeType) -> HLPrimeType  {
        let arraySize = 50
        var s: [HLPrimeType] = Array(repeating: 0, count: arraySize)
        var t: [HLPrimeType] = Array(repeating: 0, count: arraySize)
        var r: [HLPrimeType] = Array(repeating: 0, count: arraySize)
        s[0] = 1
        s[1] = 0
        t[0] = 0
        t[1] = 1
        r[0] = Phi
        r[1] = publicKey
        var i = 1
        
        while r[i] != 1 && r[i] != 0    {
            i += 1
            let q = r[i-2] / r[i-1]
            s[i] = s[i-2] - q * s[i-1]
            t[i] = t[i-2] - q * t[i-1]
            r[i] = r[i-2] - q * r[i-1]
  //          print( "i: \(i)    r[i]: \(r[i])" )
        }

        if r[i] == 1        {
            var privateKey = t[i]
            if privateKey <= 0     {   privateKey += Phi       }
            
            let product = Float80(exactly: publicKey)! * Float80(exactly: privateKey)!
            let keyVerify = product.truncatingRemainder(dividingBy: Float80(exactly: Phi)!)
            assert( keyVerify == 1 )
            return privateKey
        }
        
        else                {   return -1            }
    }
    
    init(p: HLPrimeType, q: HLPrimeType, characterSet: String) {
    
        charSet = Array(characterSet)
        charSetSize = Int64(charSet.count)
        charSetSizePlusOne = charSetSize + 1

        N = p * q
        Phi = (p-1) * (q-1)

        chunkSizeDouble = log(Double(N)) / log(Double(charSetSizePlusOne))
        chuckSize = Int(chunkSizeDouble)
        
        print( "HLRSA-  init-  p: \(p)    q: \(q)    N: \(N)    Phi: \(Phi)    charSetSize: \(charSetSize)    chuckSize: \(String.init(format:" %0.2f", arguments: [chunkSizeDouble]))" )
    }
}
