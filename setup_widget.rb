require 'xcodeproj'

project_path = 'WorldCup2026.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# 1. Identify main app target
app_target = project.targets.find { |t| t.name == 'WorldCup2026' }
raise "Main target WorldCup2026 not found" unless app_target

# Identify or create Widget target
target_name = 'WorldCupWidgetExtension'
widget_target = project.targets.find { |t| t.name == target_name }

if widget_target
  puts "Target #{target_name} already exists. Re-configuring."
else
  puts "Creating new Widget Extension target."
  widget_target = project.new_target(:app_extension, target_name, :ios, '17.6')
end

# 2. Remove any old build files referencing these files from compile sources
[app_target, widget_target].each do |target|
  target.source_build_phase.files.dup.each do |bf|
    if bf.file_ref && (bf.file_ref.path.include?('WidgetDataModels.swift') || bf.file_ref.path.include?('WorldCupWidget.swift'))
      target.source_build_phase.remove_build_file(bf)
    end
  end
end

# Remove old WorldCupWidget group to start clean
old_group = project.main_group.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXGroup) && c.name == 'WorldCupWidget' }
if old_group
  puts "Removing old WorldCupWidget group references."
  old_group.remove_from_project
end

# 3. Create clean WorldCupWidget group with proper path
widget_group = project.main_group.new_group('WorldCupWidget', 'WorldCupWidget')
widget_group.source_tree = '<group>'

# Create file references
models_ref = widget_group.new_reference('WidgetDataModels.swift')
widget_swift_ref = widget_group.new_reference('WorldCupWidget.swift')
info_plist_ref = widget_group.new_reference('Info.plist')
entitlements_ref = widget_group.new_reference('WorldCupWidgetExtension.entitlements')

# 4. Add files to widget target compile sources
widget_target.add_file_references([widget_swift_ref, models_ref])

# 5. Add WidgetDataModels.swift to the main app compile sources
app_sources_phase = app_target.source_build_phase
unless app_sources_phase.files.any? { |f| f.file_ref == models_ref }
  app_sources_phase.add_file_reference(models_ref, true)
end

# 6. Configure Build Settings for Widget Extension
widget_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_NAME'] = 'WorldCupWidgetExtension'
  config.build_settings['INFOPLIST_FILE'] = 'WorldCupWidget/Info.plist'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.mm.WorldCup2026.WorldCupWidgetExtension'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'WorldCupWidget/WorldCupWidgetExtension.entitlements'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.6'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '7'
  config.build_settings['MARKETING_VERSION'] = '1.0.5'
  config.build_settings['SKIP_INSTALL'] = 'YES'
end

# 7. Configure Build Settings for Main Application (App Group entitlements)
app_target.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'WorldCup2026/WorldCup2026.entitlements'
end

# 8. Add target dependency (Main app depends on Widget)
unless app_target.dependencies.any? { |d| d.target == widget_target }
  app_target.add_dependency(widget_target)
end

# 9. Create Copy Files Build Phase to embed the widget (.appex)
embed_phase = app_target.copy_files_build_phases.find { |p| p.dst_subfolder_spec == '13' }
unless embed_phase
  embed_phase = app_target.new_copy_files_build_phase('Embed App Extensions')
  embed_phase.dst_subfolder_spec = '13' # PlugIns
end

# Add product reference to the copy phase if not already present
product_ref = widget_target.product_reference
unless embed_phase.files.any? { |f| f.file_ref == product_ref }
  build_file = embed_phase.add_file_reference(product_ref, true)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy', 'CodeSignOnCopy'] }
end

# Save the project file
project.save
puts "Successfully configured Xcode project for Widget Extension!"
