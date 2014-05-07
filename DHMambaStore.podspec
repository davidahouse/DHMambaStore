Pod::Spec.new do |s|
  s.name         = 'DHMambaStore'
  s.version      = '0.2.1'
  s.summary      = 'An object store that uses FMDB to facilitate persisting your objects.'
  s.source  = { :git => "https://github.com/davidahouse/DHMambaStore.git", :tag => s.version.to_s }
  s.homepage = "https://github.com/davidahouse/DHMambaStore"
  s.author       = {
    'David House' => 'davidahouse@gmail.com'
  }
  s.source_files = 'MambaStore'
  s.license		   = {
    :type => 'MIT',
    :file => 'LICENSE'
  }
  s.requires_arc = true
  s.ios.deployment_target = '6.1'
  s.dependency 'FMDB'
end
