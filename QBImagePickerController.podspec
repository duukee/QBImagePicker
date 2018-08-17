Pod::Spec.new do |s|
  s.name             = "QBImagePickerController"
  s.version          = "3.5.3"
  s.summary          = "A clone of questbeat/QBImagePicker with multiple selection support.\n This version order photos by most recently first and fix photoLibraryDidChange: crash"
  s.homepage         = "https://github.com/duukee/QBImagePicker"
  s.license          = "MIT"
  s.author           = { "Duukee" => "duukee@me.com" }
  s.source           = { :git => "https://github.com/duukee/QBImagePicker.git", :tag => s.version.to_s }
  s.social_media_url = "https://twitter.com/duukee87"
  s.source_files     = "QBImagePicker/*.{h,m}"
  s.exclude_files    = "QBImagePicker/QBImagePicker.h"
  s.resource_bundles = { "QBImagePicker" => "QBImagePicker/*.{lproj,storyboard}" }
  s.platform         = :ios, "8.0"
  s.requires_arc     = true
  s.frameworks       = "Photos"
end
