package com.screenrecorder.screen_recorder

import android.app.Activity
import android.content.Context
import android.content.Context.*
import android.content.Intent
import android.media.MediaRecorder
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import com.hbisoft.hbrecorder.HBRecorder
import com.hbisoft.hbrecorder.HBRecorderListener
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/** ScreenRecorderPlugin */
class ScreenRecorderPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
  PluginRegistry.ActivityResultListener, HBRecorderListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var hbRecorder : HBRecorder
  private lateinit var channel : MethodChannel
  private var mDisplayWidth: Int = 1080
  private var mDisplayHeight: Int = 1920
  private var videoName: String? = ""
  private var recordAudio: Boolean = false
  private var path = ""
  private  var mMediaRecorder: MediaRecorder? = null
  private lateinit var mProjectionManager: MediaProjectionManager
  private lateinit var appContext :Context
  private lateinit var activity: Activity
  private val SCREEN_RECORD_REQUEST_CODE = 333

  private lateinit var _result: Result
  @RequiresApi(Build.VERSION_CODES.LOLLIPOP)

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if(requestCode == SCREEN_RECORD_REQUEST_CODE){
      if(resultCode == Activity.RESULT_OK){
        hbRecorder.startScreenRecording(data, resultCode)
        return true
      }
    }
    return false
  }
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
  }
  override fun onDetachedFromActivityForConfigChanges() {
    print("**** detachedChanges")

  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    print("**** retached")
  }

  override fun onDetachedFromActivity() {
    print("**** detached")

  }
  @RequiresApi(Build.VERSION_CODES.S)
  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "screen_recorder")
    channel.setMethodCallHandler(this)
    appContext = flutterPluginBinding.applicationContext
    hbRecorder = HBRecorder(appContext,this)
    mProjectionManager = appContext.getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
    mMediaRecorder = MediaRecorder(appContext)
  }

  @RequiresApi(Build.VERSION_CODES.Q)
  override fun onMethodCall( call: MethodCall, result: Result) {
    when(call.method){
      "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")
      "startRecording" ->{
        try{
          _result = result
          ForegroundService.startService(appContext, "Your screen is being recorded")
          mProjectionManager = (appContext.getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager?)!!
          videoName = call.argument<String?>("name")
          recordAudio = call.argument<Boolean>("audio") == true
          path = call.argument<String?>("dirPath").toString()
          if(path==""){
            path = appContext.externalCacheDir?.absolutePath.toString()
          }
          startRecordScreen()
          _result.success(true)
        }catch (e: Exception) {
          println("Error onMethodCall startRecordScreen")
          println(e.message)
          result.success(false)
        }
      }
      "stopRecording" ->{
        ForegroundService.stopService(appContext)
        stopRecordScreen()
        result.success(hbRecorder.filePath)
      }
      else -> _result.notImplemented()

    }
  }
  override fun onDetachedFromEngine( binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
  @RequiresApi(Build.VERSION_CODES.Q)
  private fun startRecordScreen() {
    hbRecorder.run { enableCustomSettings() }
    initReccording()
    val permissionIntent: Intent?
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      permissionIntent = mProjectionManager.createScreenCaptureIntent()
      ActivityCompat.startActivityForResult(
        activity,
        permissionIntent,
        SCREEN_RECORD_REQUEST_CODE,
        null
      )
    }
  }

  @RequiresApi(Build.VERSION_CODES.Q)
  private fun initReccording(){
    try {
      hbRecorder.fileName = videoName
      hbRecorder.setOutputPath(path)
      //hbRecorder.setOutputUri(Uri.parse(path))
      hbRecorder.isAudioEnabled(recordAudio)
      if(recordAudio){
        hbRecorder.setAudioSource("MIC")
      }
      hbRecorder.setVideoEncoder("DEFAULT")
      hbRecorder.setVideoFrameRate(30)
      hbRecorder.setOutputFormat("DEFAULT")
      hbRecorder.setVideoBitrate(3000000)
      hbRecorder.setScreenDimensions(mDisplayHeight, mDisplayWidth)
    } catch (e: java.lang.Exception) {
      Log.d("Init recorder", e.message!!)
    }
  }

  @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
  private fun stopRecordScreen() {
    try {
      hbRecorder.stopScreenRecording()
      println("stopRecordScreen success")
    } catch (e: Exception) {
      Log.d("--INIT-RECORDER", e.message +"")
      println("stopRecordScreen error")
      println(e.message)

    }
  }


  override fun HBRecorderOnStart() {
    println("Start")
  }

  override fun HBRecorderOnComplete() {
    println("Complete")
  }

  override fun HBRecorderOnError(errorCode: Int, reason: String?) {
      println(reason)
  }

  override fun HBRecorderOnPause() {
    TODO("Not yet implemented")
  }

  override fun HBRecorderOnResume() {
    TODO("Not yet implemented")
  }

}
