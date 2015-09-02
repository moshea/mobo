ruby_files = Dir.glob('*.rb') + Dir.glob('lib/**/*.rb') + Dir.glob('bin/**/*.rb')

bin_files = ['bin/mobo']

Gem::Specification.new do |s|
  s.name        = 'mobo'
  s.version     = '0.0.4'
  s.date        = '2015-09-02'
  s.summary     = 'Mobo - android emulator abstraction'
  s.description = 'Abstract android emaulators with a simple yaml file'
  s.authors     = ["Mark O'Shea"]
  s.licenses    = ['MIT']
  s.email       = 'mark@osheatech.com'
  s.executables = ['mobo']
  s.files       = ruby_files + bin_files
  s.homepage    = 'https://github.com/moshea/mobo'
end
