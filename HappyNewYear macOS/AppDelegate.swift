//
//  AppDelegate.swift
//  HappyNewYear macOS
//
//  Created by Siarhei Yakushevich on 27/12/2024.
//

import Cocoa
import AVFoundation

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    /*var captureSession: AVCaptureSession!
    var screenInput: AVCaptureScreenInput!
    var movieOutput: AVCaptureMovieFileOutput!
    
    // File path for the recorded video
    let outputURL = URL(fileURLWithPath: "/Users/user_name/Desktop/ScreenRecording.mov")
    
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        startScreenRecording()
    }
    

    func startScreenRecording() {
        // Create a capture session
        captureSession = AVCaptureSession()

        // Get the main screen for capture
        guard let mainScreen = NSScreen.main else { return }

        // Set up the screen input for the capture session
        screenInput = AVCaptureScreenInput(displayID: mainScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as! CGDirectDisplayID)
        
        // Check if screen input is available
        if captureSession.canAddInput(screenInput) {
            captureSession.addInput(screenInput)
        } else {
            print("Cannot add screen input to session")
            return
        }

        // Set up the output for the video
        movieOutput = AVCaptureMovieFileOutput()

        // Check if we can add the output to the session
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        } else {
            print("Cannot add output to session")
            return
        }

        // Start capturing
        captureSession.startRunning()

        // Start recording to the file
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        
        print("Screen recording started.")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        stopScreenRecording()
    }

    func stopScreenRecording() {
        movieOutput.stopRecording()
        captureSession.stopRunning()
        print("Screen recording stopped.")
    } */
}


/*extension AppDelegate: AVCaptureFileOutputRecordingDelegate {

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        if let error = error {
            print("Error during recording: \(error)")
        } else {
            print("Recording saved to: \(outputFileURL)")
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput,
                    didStartRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection]) {
        print("Started recording.")
    }
} */
