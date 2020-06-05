//
//  ViewController.swift
//  NFCReaderWriterDemo
//
//  Created by janlionly on 2020/6/4.
//  Copyright © 2020 janlionly. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    let readerWriter = NFCReaderWriter.sharedInstance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: Actions
    // iOS 11
    @IBAction func readButtonTapped(_ sender: Any) {
        readerWriter.newReaderSession(with: self, invalidateAfterFirstRead: true, alertMessage: "Nearby NFC Card for read")
        readerWriter.begin()
    }
    
    // iOS 13
    @IBAction func writeButtonTapped(_ sender: Any) {
        readerWriter.newWriterSession(with: self, isLegacy: true, invalidateAfterFirstRead: true, alertMessage: "Nearby NFC Card for write")
        readerWriter.begin()
    }
}

extension ViewController: NFCReaderDelegate {
    
    func readerDidBecomeActive(_ session: NFCReader) {
        print("Reader did become")
    }
    
    func reader(_ session: NFCReader, didInvalidateWithError error: Error) {
            print("ERROR:\(error)")
            readerWriter.end()
        }
        
        func reader(_ session: NFCReader, didDetectNDEFs messages: [NFCNDEFMessage]) {
            var recordInfos = ""
            
            for message in messages {
                for (i, record) in message.records.enumerated() {
                    recordInfos += "Record(\(i + 1)):\n"
                    recordInfos += "Type name format: \(record.typeNameFormat.rawValue)\n"
                    recordInfos += "Type: \(record.type as NSData)\n"
                    recordInfos += "Identifier: \(record.identifier)\n"
                    recordInfos += "Length: \(message.length)\n"
                    
                    if let string = String(data: record.payload, encoding: .ascii) {
                        recordInfos += "Payload content:\(string)\n"
                    }
                    recordInfos += "Payload raw data: \(record.payload as NSData)\n\n"
                }
            }
            DispatchQueue.main.async {
                self.textView.text = recordInfos
            }
            
            readerWriter.end()
        }
        
        func reader(_ session: NFCReader, didDetect tags: [NFCNDEFTag]) {
            print("did detect tags")
            
            var payloadData = Data([0x02])
            let urls = ["apple.com", "google.com", "facebook.com"]
            payloadData.append(urls[Int.random(in: 0..<urls.count)].data(using: .utf8)!)

            let payload = NFCNDEFPayload.init(
                format: NFCTypeNameFormat.nfcWellKnown,
                type: "U".data(using: .utf8)!,
                identifier: Data.init(count: 0),
                payload: payloadData,
                chunkSize: 0)

            let message = NFCNDEFMessage(records: [payload])

            readerWriter.write(message, to: tags.first!) { (error) in
                if let err = error {
                    print("ERR:\(err)")
                } else {
                    print("write success")
                }
                self.readerWriter.end()
            }
        }
}

