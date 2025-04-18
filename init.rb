require 'redmine'

require_dependency File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'redmine_issue_template', 'issues_controller_patch'))

patch_module = RedmineIssueTemplate::IssuesControllerPatch
target_controller = IssuesController

unless target_controller.ancestors.include?(patch_module)
  target_controller.send(:prepend, patch_module)
end

Redmine::Plugin.register :redmine_issue_template do
  name 'Redmine Issue Template plugin'
  author 'minchik'
  description 'Applies a default Markdown template to new issues via IssuesController patch.'
  version '0.1.0'
  url 'https://github.com/minchik/redmine_issue_template'
  author_url 'https://github.com/minchik'
end