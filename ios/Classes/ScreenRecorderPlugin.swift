import Flutter
import UIKit
import ReplayKit
import Photos

public class ScreenRecorderPlugin: NSObject, FlutterPlugin {
    
  let recorder = RPScreenRecorder.shared()
  var videoURL: URL!
  var assetWriter: AVAssetWriter!
  var videoInput: AVAssetWriterInput!
  var audioMicInput: AVAssetWriterInput!
  var videoPath: NSString=""
  var nameVideo: String = ""
  var recordAudio: Bool = false;
  let screenSize = UIScreen.main.nativeBounds

  var myResult: FlutterResult?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "screen_recorder", binaryMessenger: registrar.messenger())
    let instance = ScreenRecorderPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      if(call.method == "startRecording"){
               myResult = result
               let args = call.arguments as? Dictionary<String, Any>

               self.recordAudio = (args?["audio"] as? Bool)!
               self.nameVideo = (args?["name"] as? String)!+".mp4"
               startRecording()

        }else if(call.method == "stopRecording"){
              if(assetWriter != nil){
                    stopRecording()
                    print("done stopped")
                    result(String(self.videoPath.appendingPathComponent(nameVideo)))
                }
               result("")
          }
  }
  @objc func startRecording() {

        //Use ReplayKit to record the screen
        //Create the file path to write to
        
        self.videoPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        videoURL = URL(fileURLWithPath: videoPath.appendingPathComponent(nameVideo))

        //Check the file does not already exist by deleting it if it does
        do {
            try FileManager.default.removeItem(at: videoURL)
        } catch {}

        do {
            try assetWriter = AVAssetWriter(outputURL: videoURL, fileType: AVFileType.mp4) // AVAssetWriter(url: videoURL, fileType: .mp4) didn't make a difference
        } catch {}

        //Create the video settings
        if #available(iOS 11.0, *) {
                            
            let videoSettings: [String : Any] = [
                AVVideoCodecKey  : AVVideoCodecType.h264,
                AVVideoWidthKey  : screenSize.width,
                AVVideoHeightKey : screenSize.height,
                AVVideoCompressionPropertiesKey: [
                        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                        AVVideoAverageBitRateKey: 30
                    ]
            ]
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoInput.expectsMediaDataInRealTime = true
            if assetWriter.canAdd(videoInput) {
                assetWriter.add(videoInput)
            }           
            if(recordAudio){
                let audioOutputSettings: [String : Any] = [
                    AVNumberOfChannelsKey : 2,
                    AVFormatIDKey : kAudioFormatMPEG4AAC,
                    AVSampleRateKey: 44100,
                ]
                audioMicInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioOutputSettings)
                audioMicInput.expectsMediaDataInRealTime = true
                if assetWriter.canAdd(audioMicInput) {
                    assetWriter.add(audioMicInput)
                }       
            }   
        }
        //Tell the screen recorder to start capturing and to call the handler
        guard recorder.isAvailable else { return }
            
        if(recordAudio){
            recorder.isMicrophoneEnabled=true;
        }else{
            recorder.isMicrophoneEnabled=false;
        }
        recorder.startCapture(handler: { (cmSampleBuffer, rpSampleType, error) in
            guard error == nil else {
                //Handle error
                print("Error starting capture");
                self.myResult!(false)
                return;
            }
            DispatchQueue.main.async {
                switch rpSampleType {
                    case .video:
                        print("writing sample....")
                        
                        if self.assetWriter?.status == AVAssetWriter.Status.unknown {
                            print("Started writing")
                            self.assetWriter?.startWriting()
                            self.assetWriter?.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(cmSampleBuffer))        
                        }

                        if self.assetWriter?.status == AVAssetWriter.Status.failed {
                            return
                        }

                        if self.assetWriter.status == AVAssetWriter.Status.writing {
                            if self.videoInput.isReadyForMoreMediaData {
                                print("Writing a sample")
                                if self.videoInput.append(cmSampleBuffer) == false {
                                    print("problem writing video")
                                }
                            }
                        }
                    case .audioMic:
                        if self.audioMicInput.isReadyForMoreMediaData {
                             print("audioMic data added")
                            self.audioMicInput.append(cmSampleBuffer)
                        }
                    default:
                        print("not a video sample")
                }
            }
        } ){(error) in
            guard error == nil else {
                //Handle error
                print("Screen record not allowed");
                self.myResult!(false)
                return;
            }
        }
 
    }

    @objc func stopRecording() {
    
        //Stop Recording the screen
        if #available(iOS 11.0, *) {
            recorder.stopCapture( handler: { (error) in
                print("stopping recording");
            })
        } else {
          //  Fallback on earlier versions
        }        
        self.videoInput.markAsFinished()
        if(recordAudio){
            self.audioMicInput.markAsFinished()
        }
        self.assetWriter.finishWriting(completionHandler: {
        PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.videoURL)
                }) { (saved, error) in
                    if saved {
                        print("saved")
                        let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertController.addAction(defaultAction)
                        //self.present(alertController, animated: true, completion: nil)
                    }else{
                        print("not saved")
                    }
                    if let error = error {
                        print("PHAssetChangeRequest Video Error: \(error.localizedDescription)")
                        return
                    }
                }
        })
    
    }
 
}
