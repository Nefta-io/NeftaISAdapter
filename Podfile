source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'

workspace 'NeftaISAdapter.xcodeworkspace.xcworkspace'

target 'IronSourceSwiftDemoApp' do
  project 'IronSourceSwiftDemoApp/IronSourceSwiftDemoApp.xcodeproj'

  pod 'IronSourceSDK'
  pod 'NeftaISAdapter', :path => '.'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.name == 'NeftaISAdapter'
      framework_ref = installer.pods_project.reference_for_path(File.dirname(__FILE__) + '/Pods/IronSourceSDK/IronSource/IronSource.xcframework')
      target.frameworks_build_phase.add_file_reference(framework_ref, true)
    end
  end
end
