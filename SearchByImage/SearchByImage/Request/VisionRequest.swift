//
//  VisionRequest.swift
//  SearchByImage
//
//  Created by arakawa.yasuhisa on 2018/09/04.
//  Copyright © 2018年 yasuhisa.arakawa. All rights reserved.
//

import AVKit
import Vision

/// request completion handler
typealias CompletionHandler = (([VNClassificationObservation], Error?) -> ())?

/// VisionRequest Class
class VisionRequest: NSObject {
    
    private lazy var model = VNCoreMLModel(for: Inceptionv3().model)
    
    /// Observe CoreMLRequest results from CMSampleBuffer.
    ///
    /// - Parameters:
    ///   - sampleBuffer: captured buffer
    ///   - completionHandler: use observation results this closure
    func observeFromSampleBuffer(sampleBuffer: CMSampleBuffer, completionHandler: CompletionHandler) -> Void {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let coreMLRequest = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else { return }
            
            completionHandler?(results, error)
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([coreMLRequest])
    }
    
    /// Observe CoreMLRequest results from UIImage.
    ///
    /// - Parameters:
    ///   - image: UIImage
    ///   - completionHandler: use observation results this closure
    func observeFromImage(image: UIImage, completionHandler: CompletionHandler) {
        guard let pixelBuffer = image.pixelBuffer() else { return }
        
        let coreMLRequest = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else { return }
            
            completionHandler?(results, error)
        }
        
        try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([coreMLRequest])
    }
    
}
