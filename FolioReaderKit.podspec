Pod::Spec.new do |s|
  s.name             = "FolioReaderKit"
  s.version          = "1.9.0"
  s.summary          = "A Swift ePub reader and parser framework for iOS."
  s.description  = <<-DESC
                   Written in Swift.
                   The Best Open Source ePub Reader.
                   DESC
  s.homepage         = "https://github.com/drearycold/FolioReaderKit"
  s.screenshots     = "https://raw.githubusercontent.com/FolioReader/FolioReaderKit/assets/custom-fonts.gif", "https://raw.githubusercontent.com/FolioReader/FolioReaderKit/assets/highlight.gif"
  s.license          = 'BSD'
  s.author           = { "Heberti Almeida" => "hebertialmeida@gmail.com" }
  s.source           = { :git => "https://github.com/drearycold/FolioReaderKit.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/hebertialmeida'

  s.swift_version = '4.2'
  s.platform      = :ios, '10.0'
  s.requires_arc  = true

  s.source_files = [
    'Sources/*.{h,swift}',
    'Sources/**/*.swift',
    'Vendor/**/*.swift',
  ]
  s.resources = [
    'Sources/**/*.{js,css}',
    'Sources/Resources/*.xcassets'
  ]
  s.public_header_files = 'Source/*.h'

  s.libraries  = "z"
  s.dependency 'SSZipArchive', '2.1.1'
  s.dependency 'MenuItemKit', '3.1.3'
  s.dependency 'ZFDragableModalTransition', '0.6'
  s.dependency 'AEXML', '4.3.3'
  s.dependency 'FontBlaster', '4.1.0'
  s.dependency 'RealmSwift', '~> 5.0'

end
