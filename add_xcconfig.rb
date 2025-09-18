#!/usr/bin/env ruby

begin
  # Try to use xcodeproj gem if available
  require 'xcodeproj'
  
  project_path = 'Growth.xcodeproj'
  project = Xcodeproj::Project.open(project_path)
  
  # Get the main target
  main_target = project.targets.find { |t| t.name == 'Growth' }
  
  if main_target
    # Add the xcconfig file to the project
    file_ref = project.new_file('Config/InfoPlist.xcconfig')
    
    # Set the xcconfig file for all configurations
    main_target.build_configurations.each do |config|
      config.base_configuration_reference = file_ref
    end
    
    # Set specific build settings 
    main_target.build_configurations.each do |config|
      config.build_settings['INFOPLIST_FILE'] = 'Growth/Resources/Plist/App/Info.plist'
      config.build_settings['SKIP_INSTALL'] = 'NO'
      
      # Remove any explicit resource copying
      if config.build_settings['COPY_PHASE_STRIP']
        config.build_settings.delete('COPY_PHASE_STRIP')
      end
      
      # Ensure we're using the processed version
      config.build_settings['INFOPLIST_PREPROCESS'] = 'YES'
    end
    
    # Save the project
    project.save
    puts "Successfully updated project with xcconfig file"
  else
    puts "Error: Couldn't find Growth target"
  end
rescue LoadError
  puts "Xcodeproj gem not available, using manual approach"
  
  # Fallback to manual approach
  # Update INFOPLIST_FILE setting in the project.pbxproj file
  system("sed -i '' 's|INFOPLIST_FILE = Growth/Info.plist;|INFOPLIST_FILE = Growth/Resources/Plist/App/Info.plist;|g' Growth.xcodeproj/project.pbxproj")
end
