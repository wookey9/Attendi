// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDJzwCxkiFBaeIIaEV8HrXxZ2RF3uvNy2c',
    appId: '1:517667457970:web:abfc7ea3e78a34302132ab',
    messagingSenderId: '517667457970',
    projectId: 'work-inout',
    authDomain: 'work-inout.firebaseapp.com',
    storageBucket: 'work-inout.appspot.com',
    measurementId: 'G-9600WYELT5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBve1lLJ9RBMadYRpgCW-5LDVm3t7IuabY',
    appId: '1:517667457970:android:cb17ebeb3f836ca12132ab',
    messagingSenderId: '517667457970',
    projectId: 'work-inout',
    storageBucket: 'work-inout.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAaLEAa11vgnP-rzbbFDg6981K5U_75XGQ',
    appId: '1:517667457970:ios:74f84e01c0c0a7222132ab',
    messagingSenderId: '517667457970',
    projectId: 'work-inout',
    storageBucket: 'work-inout.appspot.com',
    iosClientId: '517667457970-e82n3t0j3dbfo5jl2csbhgactdblqm9j.apps.googleusercontent.com',
    iosBundleId: 'com.example.workInout',
  );
}
