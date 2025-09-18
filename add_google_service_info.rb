
require 'xcodeproj'

# Path to your .xcodeproj file
project_path = '/Users/tradeflowj/Desktop/Dev/growth-fresh/Growth.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Path to your GoogleService-Info.plist
plist_path = 'Growth/Resources/Plist/GoogleService-Info.plist'

# Get the main target
target = project.targets.first

# Add the file to the project
file_ref = project.new_file(plist_path)

# Add the file to the "Copy Bundle Resources" build phase
target.resources_build_phase.add_file_reference(file_ref)

# Save the project
project.save
