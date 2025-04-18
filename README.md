# Redmine Issue Template Plugin

This plugin allows defining templates for Redmine issues.

(It achieves this by using simple template files, because frankly, Redmine database migrations give me nightmares! 👻)

## Features

*   Define default issue templates.
*   Define project-specific issue templates.
*   Define project- and tracker-specific issue templates (using tracker ID).

## Installation

1.  Navigate to your Redmine `plugins` directory (e.g., `/path/to/redmine/plugins`).
2.  Clone this repository:
    ```bash
    git clone https://github.com/minchik/redmine_issue_template.git
    ```
3.  Restart Redmine.

## Compatibility

This plugin is tested and compatible with Redmine versions:

*   5.x

## Usage / Configuration

Templates are loaded from the `assets/templates/` directory within the plugin folder. Follow the naming conventions described in the Examples section below.

## Examples

### Default Template

To set a default template for all projects, create a file named `default_issue_template.md` in the `assets/templates/` directory.

Example `assets/templates/default_issue_template.md`:

```markdown
**Steps to Reproduce:**

1.  [Step 1]
2.  [Step 2]
3.  [Step 3]

**Expected Result:**

[Describe the expected outcome]

**Actual Result:**

[Describe the actual outcome]
```

### Project-Specific Template

To set a template for a specific project, create a file named `issue_template_<project_identifier>.md` in the `assets/templates/` directory. Replace `<project_identifier>` with the actual identifier of your project (e.g., `myproject`).

Example `assets/templates/issue_template_myproject.md`:

```markdown
**Feature Request:**

**Goal:**

[Describe the goal of the feature]

**User Story:**

As a [type of user], I want [some goal] so that [some reason].

**Acceptance Criteria:**

*   [Criterion 1]
*   [Criterion 2]
```

### Project- and Tracker-Specific Template

You can also define templates specific to both a project and a tracker type (e.g., Bug, Feature Request).

Create a file named `issue_template_<project_identifier>_<tracker_id>.md` in the `assets/templates/` directory.
*   Replace `<project_identifier>` with the project identifier (e.g., `myproject`).
*   Replace `<tracker_id>` with the numerical ID of the tracker (e.g., `1` for Bug, `2` for Feature Request, depending on your Redmine configuration).

Example `assets/templates/issue_template_myproject_1.md` (assuming tracker ID 1 corresponds to 'Bug'):

```markdown
**Bug Report:**

**Environment:**

*   Redmine version: [...]
*   Browser: [...]
*   OS: [...]

**Steps to Reproduce:**

1.  [...]

**Expected Result:**

[...]

**Actual Result:**

[...]
```