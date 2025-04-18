require_dependency 'issues_controller'

module RedmineIssueTemplate
  module IssuesControllerPatch
    PLUGIN_NAME = :redmine_issue_template
    TEMPLATES_DIR_NAME = 'templates'.freeze
    DEFAULT_TEMPLATE_FILENAME = 'default_issue_template.md'.freeze
    PROJECT_TEMPLATE_PREFIX = 'issue_template_'.freeze
    AJAX_TRACKER_CHANGE_TRIGGER = 'issue_tracker_id'.freeze

    # Apply default template content when building a new issue
    # or updating the form via AJAX when the tracker changes.
    def build_new_issue_from_params
      super # Let Redmine core build the issue first

      # Only proceed if we have a valid issue object
      return unless @issue

      # Case 1: Initial form load (new issue, no params submitted yet)
      if @issue.new_record? && params[:issue].blank? && request.format.html?
        handle_initial_load
      # Case 2: AJAX form update triggered by tracker change
      elsif request.format.js? && params[:form_update_triggered_by] == AJAX_TRACKER_CHANGE_TRIGGER
        handle_ajax_tracker_change
      end

    rescue => e
      Rails.logger.error { "[#{PLUGIN_NAME}] Error in build_new_issue_from_params - #{e.message}\n#{e.backtrace.join("\n")}" }
    end

    private # Ensure subsequent methods are private

    # --- Template Finding Helpers ---

    def issue_template_plugin
      @issue_template_plugin ||= Redmine::Plugin.find(PLUGIN_NAME)
    end

    def templates_directory
      File.join(issue_template_plugin.assets_directory, TEMPLATES_DIR_NAME)
    end

    def project_template_path(project_id)
      File.join(templates_directory, "#{PROJECT_TEMPLATE_PREFIX}#{project_id}.md")
    end

    def tracker_template_path(project_id, tracker_id)
      File.join(templates_directory, "#{PROJECT_TEMPLATE_PREFIX}#{project_id}_#{tracker_id}.md")
    end

    def default_template_path
      File.join(templates_directory, DEFAULT_TEMPLATE_FILENAME)
    end

    # Finds the most specific template path that exists for a given project and tracker.
    # Order: Tracker-specific -> Project-specific -> Default
    def find_template_path_for(project, tracker)
      # Use safe navigation (&.) in case project or tracker is nil
      project_id = project&.identifier
      tracker_id = tracker&.id
      return nil unless project_id && tracker_id # Need both to find specific templates

      paths_to_check = [
        tracker_template_path(project_id, tracker_id),
        project_template_path(project_id),
        default_template_path
      ]

      paths_to_check.find { |path| File.exist?(path) }
    end

    # --- Main Logic Handlers ---

    # Handles applying the template on the initial 'new issue' form load.
    def handle_initial_load
      template_path = find_template_path_for(@issue.project, @issue.tracker)
      if template_path # find_template_path_for already checks File.exist?
        apply_template(template_path, "initial load")
      else
        Rails.logger.debug { "[#{PLUGIN_NAME}] No template found for initial load. Project: '#{@issue.project&.identifier}', Tracker: '#{@issue.tracker&.id}'." }
      end
    end

    # Handles applying the template when the tracker is changed via AJAX.
    def handle_ajax_tracker_change
      submitted_desc = params[:issue][:description]
      project_id = @issue.project&.identifier

      if description_unmodified_or_blank?(project_id, submitted_desc)
        Rails.logger.debug { "[#{PLUGIN_NAME}] Description is blank or matches an existing template for project '#{project_id}', attempting to apply new tracker template." }
        apply_template_for_new_tracker(submitted_desc)
      else
        Rails.logger.debug { "[#{PLUGIN_NAME}] User modified description (does not match any project templates for '#{project_id}'), not applying new template." }
        # Do nothing, keep the user's submitted description (@issue.description is already set by `super`)
      end
    end

    # --- AJAX Update Helpers ---

    # Checks if the submitted description is blank or matches any existing template
    # for the given project (project-specific, tracker-specific, or default).
    def description_unmodified_or_blank?(project_id, submitted_desc)
      normalized_submitted_desc = normalize_text(submitted_desc)
      return true if normalized_submitted_desc.blank?

      # Find *all* potential templates for this project
      potential_template_paths = [
        project_template_path(project_id),
        default_template_path
      ] + Dir.glob(File.join(templates_directory, "#{PROJECT_TEMPLATE_PREFIX}#{project_id}_*.md"))

      # Read and normalize content of all existing potential templates
      normalized_existing_template_contents = potential_template_paths.uniq.filter_map do |path|
        normalize_text(File.read(path)) if File.exist?(path)
      end

      # Check if submitted description matches any of the potential templates
      normalized_existing_template_contents.include?(normalized_submitted_desc)
    end

    # Finds and applies the appropriate template for the *new* tracker,
    # but only if it's different from the submitted description.
    # If no template is found for the new tracker, it clears the description.
    def apply_template_for_new_tracker(submitted_desc)
      new_best_template_path = find_template_path_for(@issue.project, @issue.tracker)

      if new_best_template_path # find_template_path_for checks File.exist?
        new_template_content_normalized = normalize_text(File.read(new_best_template_path))
        normalized_submitted_desc = normalize_text(submitted_desc)

        # Apply only if the new template is different from the submitted description
        if normalized_submitted_desc != new_template_content_normalized
          apply_template(new_best_template_path, "tracker change")
        else
          Rails.logger.debug { "[#{PLUGIN_NAME}] New template content is identical to current description for tracker '#{@issue.tracker&.id}', skipping apply." }
          # Keep the current description (@issue.description already holds it from `super`)
        end
      else
        # No template found for the new tracker. Since the old description matched a template, clear it.
        Rails.logger.debug { "[#{PLUGIN_NAME}] No specific template found for new tracker '#{@issue.tracker&.id}'. Clearing description as it matched a previous template." }
        @issue.description = ""
      end
    end

    # --- Template Application Logic ---

    # Reads a template file and applies its content to the issue description.
    def apply_template(template_path, context)
      content = File.read(template_path)
      @issue.description = content
      # Use block format for logger for potential performance benefit (lazy evaluation)
      Rails.logger.debug { "[#{PLUGIN_NAME}] Applied template '#{File.basename(template_path)}' during #{context} for project '#{@issue.project&.identifier}', tracker '#{@issue.tracker&.id}'." }
    rescue => e
      Rails.logger.error { "[#{PLUGIN_NAME}] Error reading/applying template '#{template_path}' - #{e.message}" }
      # Optionally re-raise or handle the error further if needed
    end

    # --- Text Normalization ---

    # Normalize text for comparison (handle newlines and whitespace)
    def normalize_text(text)
      return "" if text.blank?
      text.to_s.gsub(/\r\n?/, "\n").strip
    end
  end
end

unless IssuesController.included_modules.include?(RedmineIssueTemplate::IssuesControllerPatch)
  IssuesController.send(:prepend, RedmineIssueTemplate::IssuesControllerPatch)
end