Pod::Spec.new do |s|
  s.name             = 'gomarketme'
  s.version          = '5.0.4'
  s.summary          = 'GoMarketMe Flutter SDK.'
  s.description      = 'GoMarketMe Flutter SDK for affiliate attribution through the native GoMarketMe cores.'
  s.homepage         = 'https://gomarketme.co'
  s.license          = { :type => 'MIT' }
  s.author           = { 'GoMarketMe' => 'support@gomarketme.co' }
  s.source           = { :path => '.' }

  s.source_files     = 'Classes/**/*.{swift,h,m}'
  s.vendored_frameworks = 'Frameworks/GoMarketMeAppleCoreKit.xcframework'
  s.preserve_paths   = 'Frameworks/GoMarketMeAppleCoreKit.xcframework'

  s.dependency 'Flutter'

  s.platform         = :ios, '15.0'
  s.swift_version    = '5.9'
  s.static_framework = true

  framework_search_paths = [
    '$(inherited)',
    '"$(PODS_TARGET_SRCROOT)/Frameworks"',
    '"$(PODS_TARGET_SRCROOT)/Frameworks/GoMarketMeAppleCoreKit.xcframework/ios-arm64"',
    '"$(PODS_TARGET_SRCROOT)/Frameworks/GoMarketMeAppleCoreKit.xcframework/ios-arm64_x86_64-simulator"',
    '"$(PODS_CONFIGURATION_BUILD_DIR)/XCFrameworkIntermediates/gomarketme"'
  ].join(' ')

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'FRAMEWORK_SEARCH_PATHS' => framework_search_paths,
    'OTHER_LDFLAGS' => '$(inherited) -framework "GoMarketMeAppleCoreKit"'
  }

  s.user_target_xcconfig = {
    'FRAMEWORK_SEARCH_PATHS' => framework_search_paths
  }
end
