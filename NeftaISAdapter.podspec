Pod::Spec.new do |s|
  s.name         = 'NeftaISAdapter'
  s.version      = '4.4.0'
  s.summary      = 'Nefta Ad Network SDK for LevelPlay Mediation.'
  s.homepage     = 'https://docs.nefta.io/update/docs/ironsource-ios'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Tomaz Treven' => 'treven@nefta.io' }
  s.source       = { :git => 'https://github.com/Nefta-io/NeftaISAdapter.git', :tag => 'REL_4.4.0' }

  s.ios.deployment_target = '12.0'

  s.swift_version = '5.0'
  s.static_framework = true

  s.source_files     = 'NeftaISAdapter/**/IS*.{h,m}'

  s.dependency 'NeftaSDK', '= 4.4.0'
  s.dependency 'IronSourceSDK/Ads', '>= 7.0.0'
end
