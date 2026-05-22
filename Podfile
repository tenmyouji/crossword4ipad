platform :ios, '17.0'

target 'crosswordapp' do
  use_frameworks!

  pod 'GoogleMLKit/DigitalInkRecognition', '8.0.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    end
  end
end
