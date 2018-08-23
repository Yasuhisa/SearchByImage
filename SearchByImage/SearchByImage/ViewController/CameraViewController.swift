//
//  CameraViewController.swift
//  SearchByImage
//
//  Created by arakawa.yasuhisa on 2018/08/19.
//  Copyright © 2018年 yasuhisa.arakawa. All rights reserved.
//

import UIKit
import AVKit
import Vision

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var detectedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCaptureSession()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /// Setup Video Capture Session
    func setupCaptureSession() {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            return
        }
        
        captureSession.addInput(input)
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraView.layer.addSublayer(previewLayer)
        previewLayer.frame.size = cameraView.frame.size
        previewLayer.frame.origin = CGPoint(x: 0, y: 0)
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "Video Queue"))
        captureSession.addOutput(dataOutput)
    }
    
    
    /// Capture Output Delegate method
    ///
    /// - Parameters:
    ///   - output: output
    ///   - didOutput sampleBuffer: sampleBuffer
    ///   - from connection: connection
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {
            return
        }
        
        let coreMLRequest = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                return
            }
            guard let firstResult = results.first else {
                return
            }
            
            DispatchQueue.main.async {
                // You can change UI on main thread.
                print(firstResult)
                self.detectedLabel.text = firstResult.identifier
            }
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([coreMLRequest])
    }
    
}
