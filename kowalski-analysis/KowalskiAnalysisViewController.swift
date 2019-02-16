//
//  ViewController.swift
//  kowalski-analysis
//
//  Created by William Huang on 2/16/19.
//  Copyright © 2019 William Huang. All rights reserved.
//

import UIKit
import Speech
import Firebase

class KowalskiAnalysisViewController: UIViewController, SFSpeechRecognizerDelegate {

    private var speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    private let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()
    private var kowalskiCurrentlyAnalyzing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestSpeechAccess()
        configureMicrophone()
        recognizeSpeech()
    }
    
    private func configureMicrophone() {
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Microphone not avaible right now. Please make sure microphone is avaible and try again.")
        }
        
        let inputNode = audioEngine.inputNode
        
        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine failed to start.")
        }
    }
    
    private func recognizeSpeech() {
        speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            guard let result = result else {
                return
            }

            if self.kowalskiCurrentlyAnalyzing {
                return
            }
            
            let lastWord = result.bestTranscription.segments.last?.substring ?? "subscribe2pewdiepie"
            print(lastWord)
            if self.isKowalskiAnalysis(word: lastWord) {
                self.kowalskiCurrentlyAnalyzing = true
                self.presentCamera()
            }

            if error != nil || result.isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
            }
        })
    }
    
    private func isKowalskiAnalysis(word: String) -> Bool {
        // TODO: make this method smarter lmao
        return word == "analysis"
    }
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            print("speech recognition available")
        } else {
            print("speech recognition NOT available")
        }
    }
    
    private func requestSpeechAccess() {
        // Make the authorization request
        SFSpeechRecognizer.requestAuthorization { authStatus in
            
            // The authorization status results in changes to the
            // app’s interface, so process the results on the app’s
            // main queue.
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    print("Speech recognition is enabled 🎤")
                    
                case .denied:
                    print("Speech recognition is denied 🎤")
                    
                case .restricted:
                    print("Speech recognition is restricted 🎤")
                    
                case .notDetermined:
                    print("Speech recognition is not determined 🎤")
                }
            }
        }
    }
}

extension KowalskiAnalysisViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private func setupCamera() -> UIImagePickerController {
        let imagePickerController = UIImagePickerController()
    
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            print("Camera is available 📸")
            imagePickerController.sourceType = .camera
        }
        
        // Gets rid of all camera buttoms
        imagePickerController.showsCameraControls = false
        return imagePickerController
    }
    
    private func presentCamera() {
        let imagePickerController = setupCamera()
        imagePickerController.delegate = self
        self.present(imagePickerController, animated: false) {
            // Wait 2 seconds to take the photo so the camera can take in some light
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
                imagePickerController.takePicture()
            })
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Get the image captured by the UIImagePickerController
        var image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
        // Do something with the images (based on your use case)
        print("Received an image! 📸")
        self.kowalskiCurrentlyAnalyzing = false
        
        if image.imageOrientation != .up {
            image = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .up)
        }
        
        // Create VisionImage from UIImage
        let visionImage = VisionImage(image: image)
        
        // Create image labeler with min confience threshold of 0.7
        let options = VisionOnDeviceImageLabelerOptions()
        options.confidenceThreshold = 0.7
        let labeler = Vision.vision().onDeviceImageLabeler(options: options)
        
        // Label the image!!
        labeler.process(visionImage) { labels, error in
            guard error == nil, let labels = labels else { return }
            
            print("Image successfully labeled! 📷🏷")
            
            for label in labels {
                let labelText = label.text
                let entityId = label.entityID
                let confidence = label.confidence
                print("\n\nlabelText: \(labelText)\nentityId: \(String(describing: entityId))\nconfidence: \(String(describing: confidence))\n")
            }
        }
        
        // Dismiss UIImagePickerController to go back to your original view controller
        dismiss(animated: true, completion: nil)
    }
}

