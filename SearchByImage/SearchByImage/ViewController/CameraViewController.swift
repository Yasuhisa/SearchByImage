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
import SafariServices

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var detectedLabel: UILabel!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cameraView.frame = view.frame
        setupCaptureSession()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IBAction
    @IBAction func infoButtonPressed(_ sender: Any) {
        showWalkthroughViewController()
    }
    
    @IBAction func searchButtonPressed(_ sender: Any) {
        showSafariViewController()
    }
    
    @IBAction func photoButtonPressed(_ sender: Any) {
        // TODO
    }
    
    // MARK: - Video Capture Session
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
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = self.cameraView.frame
        self.cameraView.layer.addSublayer(previewLayer)
        
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
    
    // MARK: - Private
    func showWalkthroughViewController() {
        let storybord = UIStoryboard(name: Constants.STORYBOARD_WALKTHROUGH, bundle: nil)
        if let walkthroughViewController = storybord.instantiateInitialViewController() as? WalkthroughViewController {
            walkthroughViewController.fromCameraView = true
            present(walkthroughViewController, animated: true, completion: nil)
        }
    }
    
    func showSafariViewController() {
        if self.detectedLabel.text?.count == 0 {
            return
        }
        
        var urlString = "https://www.google.co.jp/search?q=\(self.detectedLabel.text ?? "food")&tbm=isch"
        
        // If multiple results, replace url parameter with Google Image Search format url.
        if urlString.contains(",") {
            // delete [,], replace whitespace with [+]
            urlString = urlString.replacingOccurrences(of: ",", with: "")
                .replacingOccurrences(of: " ", with: "+")
        }
        
        if let url = URL(string: urlString) {
            let safariViewController = SFSafariViewController(url: url)
            safariViewController.modalPresentationStyle = .popover
            safariViewController.preferredBarTintColor = UIColor.orange
            safariViewController.preferredControlTintColor = UIColor.white
            
            present(safariViewController, animated: true, completion: nil)
        }
    }
    
}
