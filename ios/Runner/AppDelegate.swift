import Flutter
import UIKit
import AVKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    
    // Register the custom Native AirPlay Button PlatformView
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NativeAirPlayPlugin") {
        let factory = NativeAirPlayButtonFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "native_airplay_button")
    }
  }
}

class NativeAirPlayButtonFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return NativeAirPlayButton(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }
}

class NativeAirPlayButton: NSObject, FlutterPlatformView {
    private var _view: UIView

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = UIView(frame: frame)
        super.init()

        // Create the AVRoutePickerView natively
        let airplayButton = AVRoutePickerView(frame: _view.bounds)
        airplayButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Match Mara FM styling
        airplayButton.backgroundColor = .clear
        airplayButton.activeTintColor = UIColor(red: 1.0, green: 0.35, blue: 0.13, alpha: 1.0) // AppTheme.accentOrange Hex #FF5922
        airplayButton.tintColor = .white

        _view.addSubview(airplayButton)
    }

    func view() -> UIView {
        return _view
    }
}
