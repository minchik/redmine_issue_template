require_dependency 'issues_controller'

module RedmineIssueTemplate
  module IssuesControllerPatch
    # Apply default template content when building a new issue
    def build_new_issue_from_params
      super
      if @issue&.new_record? && params[:issue].blank?
        plugin = Redmine::Plugin.find(:redmine_issue_template)
        template_path = File.join(plugin.assets_directory, 'templates', 'default_issue_template.md')
        if File.exist?(template_path)
          content = File.read(template_path)
          @issue.description = content
          Rails.logger.info("RedmineIssueTemplate: Applied default template in build_new_issue_from_params.")
        else
          Rails.logger.warn("RedmineIssueTemplate: Template file not found at #{template_path}")
        end
      end
    rescue => e
      Rails.logger.error("RedmineIssueTemplate: Error applying template - #{e.message}\n#{e.backtrace.join("\n")}")
    end
  end
end