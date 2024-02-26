Pod::Spec.new do |s|
  s.name         = 'NeftaISAdapter'
  s.version      = '1.2.1'
  s.summary      = 'Custom mediation adapter for IronSource SDK.'
  s.homepage     = 'https://docs-adnetwork.nefta.io/docs/ironsource-ios'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Tomaz Treven' => 'treven@nefta.io' }
  s.source       = { :git => 'https://github.com/Nefta-io/NeftaISAdapter.git', :tag => '1.2.1' }

  s.ios.deployment_target = '11.0'

  s.dependency 'NeftaSDK', '~> 3.2.1'
  s.source_files = 'NeftaISAdapter/NeftaISAdapter/*.{h,m}'
end
