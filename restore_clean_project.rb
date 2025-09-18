#!/usr/bin/env ruby

require 'fileutils'

project_file = "/Users/tradeflowj/Desktop/Dev/growth-backup-22aug2025/Growth.xcodeproj/project.pbxproj"

# Let's check if we have an older working backup
backups = Dir.glob("#{project_file}.backup.*").sort

puts "Available backups:"
backups.each_with_index do |backup, idx|
  size = File.size(backup)
  mtime = File.mtime(backup)
  version = File.read(backup)[/objectVersion = (\d+);/, 1]
  puts "#{idx}: #{File.basename(backup)} - Size: #{size} bytes, Modified: #{mtime}, Version: #{version}"
end

# Try to find a working backup from before our changes
original_backup = backups.find do |backup|
  content = File.read(backup)
  # Look for a backup that doesn't have our problematic sections
  !content.include?("setExplicitFileTypeIfNil") && 
  !content.include?("buildPhase") &&
  content.include?("objectVersion = 77")
end

if original_backup
  puts "\nFound potentially working backup: #{File.basename(original_backup)}"
  
  # Create a new backup of current corrupted file
  corrupted_backup = "#{project_file}.corrupted.#{Time.now.strftime('%Y%m%d_%H%M%S')}"
  FileUtils.cp(project_file, corrupted_backup)
  puts "Backed up corrupted file to: #{corrupted_backup}"
  
  # Restore the original
  FileUtils.cp(original_backup, project_file)
  puts "Restored from: #{original_backup}"
  
  # Now let's properly clean it up
  content = File.read(project_file)
  
  # Remove any PBXFileSystemSynchronized sections completely
  # We'll let Xcode regenerate them properly
  content.gsub!(/\/\* Begin PBXFileSystemSynchronizedRootGroup section \*\/.*?\/\* End PBXFileSystemSynchronizedRootGroup section \*\//m, '')
  content.gsub!(/\/\* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section \*\/.*?\/\* End PBXFileSystemSynchronizedBuildFileExceptionSet section \*\//m, '')
  
  # Remove any references to synchronized groups from the main group
  content.gsub!(/\s*[A-F0-9]{24} \/\* PBXFileSystemSynchronizedRootGroup \*\/,/, '')
  
  # Change to Xcode 14 format temporarily
  content.gsub!(/objectVersion = 77;/, 'objectVersion = 56;')
  
  # Write the cleaned file
  File.write(project_file, content)
  
  puts "\n✅ Project file cleaned!"
  puts "The project has been converted to Xcode 14 format (objectVersion = 56)"
  puts "This should allow you to open it in Xcode."
  puts "\nOnce opened, Xcode will offer to upgrade it to the newer format if needed."
else
  puts "\n⚠️  No suitable backup found. Creating a minimal working project file..."
  
  # Create a minimal but valid project file
  minimal_project = <<-'EOF'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		7F45FC482DCD768A00B4BEC9 /* Growth.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Growth.app; sourceTree = BUILT_PRODUCTS_DIR; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		7F45FC452DCD768A00B4BEC9 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		7F45FC3F2DCD768A00B4BEC9 = {
			isa = PBXGroup;
			children = (
				7F45FC462DCD768A00B4BEC9 /* Products */,
			);
			sourceTree = "<group>";
		};
		7F45FC462DCD768A00B4BEC9 /* Products */ = {
			isa = PBXGroup;
			children = (
				7F45FC482DCD768A00B4BEC9 /* Growth.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		7F45FC472DCD768A00B4BEC9 /* Growth */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 7F45FC6C2DCD768B00B4BEC9 /* Build configuration list for PBXNativeTarget "Growth" */;
			buildPhases = (
				7F45FC442DCD768A00B4BEC9 /* Sources */,
				7F45FC452DCD768A00B4BEC9 /* Frameworks */,
				7F45FC462DCD768A00B4BEC9 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = Growth;
			packageProductDependencies = (
			);
			productName = Growth;
			productReference = 7F45FC482DCD768A00B4BEC9 /* Growth.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		7F45FC3D2DCD768A00B4BEC9 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1540;
				LastUpgradeCheck = 1540;
				TargetAttributes = {
					7F45FC472DCD768A00B4BEC9 = {
						CreatedOnToolsVersion = 15.4;
					};
				};
			};
			buildConfigurationList = 7F45FC402DCD768A00B4BEC9 /* Build configuration list for PBXProject "Growth" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = 7F45FC3F2DCD768A00B4BEC9;
			packageReferences = (
			);
			productRefGroup = 7F45FC462DCD768A00B4BEC9 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				7F45FC472DCD768A00B4BEC9 /* Growth */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		7F45FC462DCD768A00B4BEC9 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		7F45FC442DCD768A00B4BEC9 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		7F45FC6A2DCD768B00B4BEC9 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		7F45FC6B2DCD768B00B4BEC9 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		7F45FC6D2DCD768B00B4BEC9 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchStoryboardName = LaunchScreen;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.growthlabs.growthmethod;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
		7F45FC6E2DCD768B00B4BEC9 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchStoryboardName = LaunchScreen;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.growthlabs.growthmethod;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		7F45FC402DCD768A00B4BEC9 /* Build configuration list for PBXProject "Growth" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				7F45FC6A2DCD768B00B4BEC9 /* Debug */,
				7F45FC6B2DCD768B00B4BEC9 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		7F45FC6C2DCD768B00B4BEC9 /* Build configuration list for PBXNativeTarget "Growth" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				7F45FC6D2DCD768B00B4BEC9 /* Debug */,
				7F45FC6E2DCD768B00B4BEC9 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = 7F45FC3D2DCD768A00B4BEC9 /* Project object */;
}
EOF
  
  # Backup current corrupted file
  corrupted_backup = "#{project_file}.corrupted.#{Time.now.strftime('%Y%m%d_%H%M%S')}"
  FileUtils.cp(project_file, corrupted_backup)
  
  # Write minimal project
  File.write(project_file, minimal_project)
  
  puts "\n✅ Created minimal valid project file!"
  puts "The project should now open in Xcode."
  puts "\nOnce opened:"
  puts "1. Right-click on the project in the navigator"
  puts "2. Select 'Add Files to Growth...'"
  puts "3. Navigate to and select the Growth folder"
  puts "4. Make sure 'Create groups' is selected"
  puts "5. Click Add"
  puts "6. Repeat for GrowthTimerWidget folder"
end