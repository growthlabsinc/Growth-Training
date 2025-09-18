
require 'xcodeproj'

project_path = '/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth.xcodeproj'
project = Xcodeproj::Project.open(project_path)

file_name_to_remove = "GoogleService-Info.plist"

project.targets.each do |target|
  # Find the build file reference in the resources build phase
  build_file = target.resources_build_phase.files.find do |file|
    file.file_ref && file.file_ref.path == file_name_to_remove
  end

  if build_file
    # Remove the file from the build phase
    target.resources_build_phase.remove_file_reference(build_file.file_ref)

    # Remove the file reference from the project
    build_file.file_ref.remove_from_project
  end
end

project.save
