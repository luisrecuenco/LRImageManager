Pod::Spec.new do |s|
  s.name     = 'LRImageManager'
  s.version  = '1.1'
  s.license  = 'MIT'
  s.summary  = 'Objective-C simple image manager with memory and disk cache support.'
  s.homepage = 'https://github.com/luisrecuenco/LRImageManager'
  s.author   = { "Luis Recuenco" => "luis.recuenco@gmail.com" }
  s.source   = { :git => 'https://github.com/xhzengAIB/LRImageManager.git'}
  s.platform     = :ios, '6.0'
  s.source_files = 'LRImageManager'
  s.requires_arc = true
  s.dependency 'Reachability'
  s.frameworks = 'Security'
end
