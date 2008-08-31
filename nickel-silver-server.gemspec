SPEC = Gem::Specification.new do |s|
  s.name = 'nickel-silver-server'
  s.version = '0.0.5'
  s.summary = 'LocoNet over TCP server.'
  s.description = 'LocoNet over TCP server written in ruby.'
  s.author = 'Tobin Richard'
  s.email = 'tobin.richard@gmail.com'
  s.homepage = 'http://github.com/toholio/nickel-silver-server/'
  s.files = [ 'History.txt',
              'License.txt',
              'Manifest.txt',
              'README.txt',
              'nickel-silver-server.gemspec',
              'lib/LocoBufferUSB.rb',
              'lib/LocoNetServer.rb',
              'lib/nickel-silver-server.rb']
  
  s.test_files = [ 'test/test_helper.rb',
                   'test/test_nickel-silver-server.rb' ]
  
  s.require_path = 'lib'
  s.autorequire = 'nickel-silver-server'

  s.has_rdoc = true
  s.extra_rdoc_files = ['History.txt', 'Manifest.txt', 'README.txt']
end
