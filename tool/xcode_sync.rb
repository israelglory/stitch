# Keeps the Xcode project in step with the files on disk:
# - every Swift file and resource in ios/Runner/Engine is in the Runner target;
# - every Swift file in ios/RunnerTests is in the RunnerTests target, with
#   test_media/ copied into the test bundle;
# - the privacy manifest is a Runner resource.
# Idempotent. Run from the repo root: ruby tool/xcode_sync.rb
require 'xcodeproj'

project = Xcodeproj::Project.open('ios/Runner.xcodeproj')
runner = project.targets.find { |t| t.name == 'Runner' }
tests = project.targets.find { |t| t.name == 'RunnerTests' }

def group_for(project, path)
  project.main_group.find_subpath(path, true).tap { |g| g.set_source_tree('<group>') }
end

def sync(project, target, dir, group_path, resources: [])
  group = group_for(project, group_path)
  group.set_path(File.basename(dir)) if group.path.nil?
  Dir.glob("#{dir}/*").sort.each do |file|
    name = File.basename(file)
    ref = group.files.find { |f| f.path == name } || group.new_reference(name)
    if name.end_with?('.swift')
      next if target.source_build_phase.files_references.include?(ref)
      target.source_build_phase.add_file_reference(ref, true)
    elsif resources.include?(File.extname(name))
      next if target.resources_build_phase.files_references.include?(ref)
      target.resources_build_phase.add_file_reference(ref, true)
    end
  end
end

sync(project, runner, 'ios/Runner/Engine', 'Runner/Engine', resources: ['.mp4'])
sync(project, tests, 'ios/RunnerTests', 'RunnerTests')

# Test media: one folder reference, copied as-is into the test bundle.
media_ref = project.main_group.files.find { |f| f.path == '../test_media' } ||
  project.main_group.new_reference('../test_media').tap { |r| r.last_known_file_type = 'folder' }
unless tests.resources_build_phase.files_references.include?(media_ref)
  tests.resources_build_phase.add_file_reference(media_ref, true)
end

# The privacy manifest, copied into the app.
runner_group = project.main_group.find_subpath('Runner', false)
privacy = runner_group.files.find { |f| f.path == 'PrivacyInfo.xcprivacy' } ||
  runner_group.new_reference('PrivacyInfo.xcprivacy')
unless runner.resources_build_phase.files_references.include?(privacy)
  runner.resources_build_phase.add_file_reference(privacy, true)
end

project.save
puts 'Xcode project in sync.'
