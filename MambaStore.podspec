Pod::Spec.new do |s|
  s.name         = 'MambaStore'
  s.version      = '0.2.0'
  s.summary      = 'An object store that uses FMDB to facilitate persisting your objects.'
  s.source  = { :git => "https://github.com/davidahouse/MambaStore.git", :tag => s.version.to_s }
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
