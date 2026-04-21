#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_ble_devices.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_ble_devices'
  s.version          = '1.0.0'
  s.summary          = 'Flutter plugin for Viatom/Lepu BLE medical devices.'
  s.description      = <<-DESC
Flutter plugin wrapping the official Viatom VTProductLib iOS SDK (and lepu-blepro
on Android) to expose device scanning, connection, and real-time data streaming
for ECG, Oximeter, Blood Pressure and Scale products.
                       DESC
  s.homepage         = 'https://github.com/wecodelife/flutter_ble_devices'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'WeCodeLife' => 'dev@wecodelife.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  # Viatom VTProductLib (Obj-C xcframework).
  s.dependency 'VTMProductLib', '~> 1.5'

  # iComon scale SDK (vendored xcframeworks — see ios/Frameworks/).
  s.vendored_frameworks = [
    'Frameworks/ICDeviceManager.xcframework',
    'Frameworks/ICBleProtocol.xcframework',
    'Frameworks/ICBodyFatAlgorithms.xcframework',
    'Frameworks/ICLogger.xcframework',
  ]

  s.platform         = :ios, '11.0'
  s.ios.deployment_target = '11.0'

  # Vendored xcframeworks are device-only arm64; exclude the simulator arm64
  # slice so Apple-Silicon macs build cleanly for physical devices.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 arm64',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
    'OTHER_LDFLAGS' => '$(inherited) -ObjC',
  }
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
  }
  s.swift_version = '5.0'
  s.libraries = 'c++', 'stdc++'
  s.frameworks  = 'CoreBluetooth'
end
