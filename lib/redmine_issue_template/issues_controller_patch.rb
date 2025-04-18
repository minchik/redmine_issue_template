require_dependency 'issues_controller'

module RedmineIssueTemplate
  module IssuesControllerPatch
    # Apply default template content when building a new issue
    def build_new_issue_from_params
      super
      if @issue&.new_record? && params[:issue].blank?
        plugin = Redmine::Plugin.find(:redmine_issue_template)
        project_template_path = File.join(plugin.assets_directory, 'templates', "issue_template_#{@issue.project.identifier}.md")
        default_template_path = File.join(plugin.assets_directory, 'templates', 'default_issue_template.md')
        template_path = if File.exist?(project_template_path)
                          project_template_path
                        else
                          default_template_path
                        end
        if File.exist?(template_path)
          content = File.read(template_path)
          @issue.description = content
          if template_path == project_template_path
            Rails.logger.info("RedmineIssueTemplate: Applied project template for project '#{@issue.project.identifier}'.")
          else
            Rails.logger.info("RedmineIssueTemplate: Applied default template in build_new_issue_from_params.")
          end
        else
          Rails.logger.warn("RedmineIssueTemplate: No template file found at #{project_template_path} or #{default_template_path}")
        end
      end
    rescue => e
      Rails.logger.error("RedmineIssueTemplate: Error applying template - #{e.message}\n#{e.backtrace.join("\n")}")
    end
  end
end