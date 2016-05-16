Gem::Specification.new do |s|
  s.name           = 'wielder_of_anor'
  s.version        = '0.1.0'
  s.authors        = ['Chris Sellek']
  s.email          = ['iamsellek@gmail.com']
  s.description    = 'See GitHub page for longer description.'
  s.summary        = 'Checks a user\'s staged files for \'forbidden\' words (as determined by the user) '\
                     'and, if any are found, alerts the user to the locations of said words.'
  s.homepage       = 'https://github.com/iamsellek/wielder_of_anor'
  s.license        = 'MIT'
  s.files          = `git ls-files`.split($/)
  s.executables    = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files     = []
  s.require_paths  = ['lib']

  s.add_dependency 'rainbow'

  s.add_development_dependency 'bundler'
end