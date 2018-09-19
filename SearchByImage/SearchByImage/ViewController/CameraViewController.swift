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

enum SearchMode: Int {
    case movie
    case picture
}

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let visionRequest = VisionRequest()
    private var targetRect: CGRect?
    private var barStyleDefault: Bool = true
    
    private lazy var defaultAnalysisAreaTopConstraint = self.analysisAreaTopConstraint.constant
    private lazy var defaultAnalysisAreaLeftConstraint = self.analysisAreaLeftConstraint.constant
    private lazy var defaultAnalysisAreaRightConstraint = self.analysisAreaRightConstraint.constant
    private lazy var defaultAnalysisAreaBottomConstraint = self.analysisAreaBottomConstraint.constant
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var analysisAreaView: UIView!
    @IBOutlet weak var detectedLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var confidenceSlider: UISlider!
    @IBOutlet weak var describeLabel: UILabel!
    @IBOutlet weak var confidenceAccuracyLabel: UILabel!
    
    @IBOutlet weak var analysisAreaTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var analysisAreaLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var analysisAreaRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var analysisAreaBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cameraView.frame = self.view.frame
        self.targetRect = self.analysisAreaView.frame

        setupCaptureSession()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(animateAnalysisArea),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.animateAnalysisArea()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return self.barStyleDefault ? .lightContent : .default
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
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
    
    @IBAction func segmentedControlValueChanged(_ sender: Any) {
        if self.segmentedControl.selectedSegmentIndex == SearchMode.picture.rawValue {
            self.detectedLabel.text = ""
            showPhotoLibrary()
        }
    }
    
    @IBAction func confidenceSliderValueChanged(_ sender: Any) {
        let confidenceAccuracy = Int(self.confidenceSlider.value * 100.0)
        self.confidenceAccuracyLabel.text = "\(confidenceAccuracy)%"
    }
    
    @IBAction func cameraViewPinched(_ sender: UIPinchGestureRecognizer) {
        if sender.state != .changed {
            return
        }
        
        zoomCameraView(pinchGestureRecognizer: sender)
    }
    
    // MARK: - Video Capture Session
    func setupCaptureSession() {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
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
        self.visionRequest.observeFromSampleBuffer(sampleBuffer: sampleBuffer, targetRect: self.targetRect ?? UIScreen.main.bounds) { (results, error) in
            // firstResult
            guard let firstResult = results.first else { return }
            
            DispatchQueue.main.async {
                // Update UI in this block
                if self.segmentedControl.selectedSegmentIndex == SearchMode.movie.rawValue &&
                    firstResult.confidence > self.confidenceSlider.value {
                    // firstResult.confidence value is higher than slider value
                    self.detectedLabel.text = firstResult.identifier
                }
            }
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        
        self.segmentedControl.selectedSegmentIndex = SearchMode.picture.rawValue
        
        self.visionRequest.observeFromImage(image: originalImage) { (results, error) in
            // firstResult
            guard let firstResult = results.first else { return }
            
            DispatchQueue.main.async {
                // Update UI in this block
                self.detectedLabel.text = firstResult.identifier
                picker.dismiss(animated: true) {
                    self.barStyleDefault = false
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            self.barStyleDefault = false
        }
    }
    
    // MARK: - Private
    @objc func animateAnalysisArea() {
        self.view.layoutIfNeeded()
        
        if (self.analysisAreaTopConstraint.constant == self.defaultAnalysisAreaTopConstraint) {
            self.analysisAreaTopConstraint.constant = self.defaultAnalysisAreaTopConstraint + 16.0
            self.analysisAreaLeftConstraint.constant = self.defaultAnalysisAreaLeftConstraint + 16.0
            self.analysisAreaRightConstraint.constant = self.defaultAnalysisAreaRightConstraint + 16.0
            self.analysisAreaBottomConstraint.constant = self.defaultAnalysisAreaBottomConstraint + 16.0
        } else {
            self.analysisAreaTopConstraint.constant = self.defaultAnalysisAreaTopConstraint
            self.analysisAreaLeftConstraint.constant = self.defaultAnalysisAreaLeftConstraint
            self.analysisAreaRightConstraint.constant = self.defaultAnalysisAreaRightConstraint
            self.analysisAreaBottomConstraint.constant = self.defaultAnalysisAreaBottomConstraint
        }
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0.0,
            options: [.repeat, .autoreverse],
            animations: {
                self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
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
            imagePickerController.sourceType = .savedPhotosAlbum
            imagePickerController.delegate = self
            
            self?.present(imagePickerController, animated: true, completion: {
                self?.barStyleDefault = true
            })
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
    
    func zoomCameraView(pinchGestureRecognizer: UIPinchGestureRecognizer) {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        let maxZoomFactor: CGFloat = captureDevice.activeFormat.videoMaxZoomFactor
        let pinchVelocityDividerFactor: CGFloat = 5.0
        let delay: CGFloat = 5.0
        
        do {
            try captureDevice.lockForConfiguration()
            
            defer {
                captureDevice.unlockForConfiguration()
            }
            
            let desiredZoomFactor = captureDevice.videoZoomFactor + atan2(pinchGestureRecognizer.velocity, pinchVelocityDividerFactor) / delay
            captureDevice.videoZoomFactor = max(1.0, min(desiredZoomFactor, maxZoomFactor))
        } catch {
            print(error)
        }
    }
    
}
