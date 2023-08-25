#
# Be sure to run `pod lib lint LYMainThreadGuard.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LYMainThreadGuard'
  s.version          = '0.1.0'
  s.summary          = 'LYMainThreadGuardian is used to detect UI operations which are not performed on the main thread.'

  s.description      = 'LYMainThreadGuardian is used to detect UI operations which are not performed on the main thread.'

  s.homepage         = 'https://github.com/pigmeetsomebody/LYMainThreadGuard'
  s.license          = 'NONE'
  s.author           = { 'zhuyanyu' => 'zhuyanyu@fintopia.tech' }
  s.source           = { :git => 'https://github.com/zhuyanyu/LYMainThreadGuard.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'LYMainThreadGuard/Classes/**/*'
  
  # s.resource_bundles = {
  #   'LYMainThreadGuard' => ['LYMainThreadGuard/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
