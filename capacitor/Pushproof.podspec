require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'Pushproof'
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  s.homepage = package['homepage']
  s.author = { 'Pushproof' => 'hello@pushproof.dev' }
  s.source = { git: package['repository']['url'], tag: s.version.to_s }
  s.source_files = 'ios/Plugin/**/*.{swift,h,m}'
  s.ios.deployment_target = '14.0'
  s.dependency 'Capacitor'
  s.swift_version = '5.9'

  # Le pont importe le module `PushproofCore` du Swift Package "Pushproof".
  # L'app consommatrice doit ajouter ce Swift Package (cf. README + INSTALL-iOS-NSE.md) :
  #   https://github.com/csurbier/pushproofsdk (Package.swift à la racine)
end
