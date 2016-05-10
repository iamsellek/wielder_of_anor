Gem::Specification.new do |s|
  s.name           = 'wielder_of_anor'
  s.version        = '0.9.0'
  s.date           = '2016-05-10'
  s.summary        = "Checks a user's staged files for 'forbidden' words (as determined by the user) "\
                     'and, if any are found, alerts the user to the locations of said words.'
  s.description    = 'See GitHub page for longer description.'
  s.files          = Dir['lib/*.rb'] + Dir['[A-Z]*']
  s.platform       = 'Unix and Windows with some Windows-tweaking.'
  s.require_paths  = ['lib']
  s.authors        = ["Chris Sellek"]
  s.email          = 'iamsellek@gmail.com'
  s.homepage       = 'https://github.com/iamsellek/wielder_of_anor'
  s.license        = 'MIT'
end