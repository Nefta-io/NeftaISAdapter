Pod::Spec.new do |s|
  s.name         = 'NeftaISAdapter'
  s.version      = '1.1.0'
  s.summary      = 'Custom mediation adapter for IronSource SDK.'
  s.homepage     = 'https://github.com/Nefta-io/NeftaISAdapter'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Tomaz Treven' => 'treven@nefta.io' }
  s.source       = { :git => 'https://github.com/Nefta-io/NeftaISAdapter.git', :tag => '1.1.0' }

  s.ios.deployment_target = '11.0'

  s.vendored_frameworks = 'NeftaSDK.xcframework'
  s.source_files = 'NeftaISAdapter/*.{h,m}'
end
