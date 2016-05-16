# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wielder_of_anor/version'

Gem::Specification.new do |spec|
  spec.name           = 'wielder_of_anor'
  spec.version        = WielderOfAnor::VERSION
  spec.authors        = ['Chris Sellek']
  spec.email          = ['iamsellek@gmail.com']

  spec.summary        = 'Checks a user\'s staged files for \'forbidden\' words (as determined by the user) '\
                     'and, if any are found, alerts the user to the locations of said words.'
  spec.description    = 'See GitHub page for longer description.'
  spec.homepage       = 'https://github.com/iamsellek/wielder_of_anor'
  spec.license        = 'MIT'

  spec.files          = `git ls-files`.split($/)
  spec.executables    = ['wielder_of_anor']
  spec.test_files     = []
  spec.require_paths  = ['lib']

  spec.add_dependency 'rainbow'

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
end