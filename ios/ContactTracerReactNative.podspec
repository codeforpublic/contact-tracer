
Pod::Spec.new do |s|
  s.name         = "ContactTracerReactNative"
  s.version      = "1.1.0"
  s.summary      = "ContactTracerReactNative"
  s.description  = <<-DESC
                  ContactTracerReactNative
                   DESC
  s.homepage     = "https://github.com/codeforpublic/contact-tracer"
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "sittiphol@gmail.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/codeforpublic/contact-tracer", :tag => "master" }
  s.source_files = "*.{m,h}"
  s.requires_arc = true


  s.dependency "React"
  #s.dependency "others"

end

  
