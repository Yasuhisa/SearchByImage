//
//  CameraViewController.swift
//  SearchByImage
//
//  Created by arakawa.yasuhisa on 2018/08/19.
//  Copyright © 2018年 yasuhisa.arakawa. All rights reserved.
//

import UIKit
import SafariServices
import Photos

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let visionRequest = VisionRequest()
    
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
        showPhotoLibrary()
    }
    
    // MARK: - Video Capture Session
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
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        visionRequest.observeFromSampleBuffer(sampleBuffer: sampleBuffer) { (results, error) in
            // firstResult
            guard let firstResult = results.first else { return }

            DispatchQueue.main.async {
                // Update UI in this block
                self.detectedLabel.text = firstResult.identifier
                // TODO: firstResult.confidence を使って精度が低い場合は処理しない
            }
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
        
        visionRequest.observeFromImage(image: originalImage) { (results, error) in
            // firstResult
            guard let firstResult = results.first else { return }
            
            DispatchQueue.main.async {
                // Update UI in this block
                self.detectedLabel.text = firstResult.identifier
                // TODO: firstResult.confidence を使って精度が低い場合は処理しない
                picker.dismiss(animated: true, completion: nil)
            }
        }
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
    
    func showPhotoLibrary() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            if status == PHAuthorizationStatus.denied {
                // Unauthorized
                self?.showUnAuthorizedAlert()
            }
            
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .photoLibrary
            imagePickerController.delegate = self
            
            self?.present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    func showUnAuthorizedAlert() {
        guard let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") else { return }
        
        let alertController = UIAlertController(
            title: "アクセスできません",
            message: "設定アプリで「\(appName)」の写真の使用を許可してください。", // Application name
            preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK",
                                     style: .cancel,
                                     handler: nil)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
}
