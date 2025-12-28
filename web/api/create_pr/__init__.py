import azure.functions as func
import json
import logging
import os
from typing import Dict, Any
from datetime import datetime
from github import Github, GithubException

# Initialize logging
logger = logging.getLogger(__name__)

# Environment variables
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
GITHUB_REPO = os.environ.get("GITHUB_REPO", "kvna/iac-docs-ai")


def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    HTTP trigger function that creates a GitHub Pull Request with AI-suggested improvements.
    """
    logger.info('Create PR function triggered')

    # Handle CORS preflight
    if req.method == "OPTIONS":
        return func.HttpResponse(
            status_code=204,
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type",
            }
        )

    # Validate environment variables
    if not GITHUB_TOKEN:
        logger.error("Missing GITHUB_TOKEN environment variable")
        return create_error_response(
            "Server configuration error",
            500,
            "GitHub authentication not configured"
        )

    try:
        # Parse request body
        req_body = req.get_json()
        document_id = req_body.get('document_id', '').strip()
        suggestions = req_body.get('suggestions', {})

        if not all([document_id, suggestions]):
            return create_error_response(
                "Missing required fields",
                400,
                "document_id and suggestions are required"
            )

        logger.info(f"Creating PR for document: {document_id}")

        # Extract suggestion data
        explanation = suggestions.get('explanation', '')
        content_changes = suggestions.get('content_changes', {})
        metadata_changes = suggestions.get('metadata_changes', {})

        content_summary = content_changes.get('summary', '')
        suggested_additions = content_changes.get('suggested_additions', '')
        suggested_edits = content_changes.get('suggested_edits', '')
        metadata_summary = metadata_changes.get('summary', '')

        if not explanation:
            return create_error_response(
                "Invalid suggestions format",
                400,
                "AI suggestions are required"
            )

        # Initialize GitHub client
        g = Github(GITHUB_TOKEN)
        repo = g.get_repo(GITHUB_REPO)

        # Create suggestions document
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        suggestions_content = f"""# AI Suggestions for {document_id}

**Generated**: {datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")}

## Overview
{explanation}

## Content Changes

### Summary
{content_summary}

### Suggested Additions
{suggested_additions if suggested_additions else '_No additions suggested_'}

### Suggested Edits
{suggested_edits if suggested_edits else '_No edits suggested_'}

## Metadata Improvements

### Summary
{metadata_summary}

### Search Keywords
{', '.join(metadata_changes.get('search_keywords', []))}

### Glossary Terms
{', '.join(metadata_changes.get('glossary_terms', []))}

### Related Documents
{', '.join(metadata_changes.get('related_documents', []))}

### Prerequisites
{chr(10).join(f"- {p}" for p in metadata_changes.get('prerequisites', []))}

### Learning Outcomes
{chr(10).join(f"- {o}" for o in metadata_changes.get('learning_outcomes', []))}

---

**Next Steps**: Review these suggestions and manually apply them to `docs/{document_id}.md`
"""

        # Create branch name
        branch_name = f"ai-suggestions-{document_id}-{timestamp}"

        # Get default branch
        default_branch = repo.default_branch
        base_branch = repo.get_branch(default_branch)

        # Create new branch
        logger.info(f"Creating branch: {branch_name}")
        repo.create_git_ref(
            ref=f"refs/heads/{branch_name}",
            sha=base_branch.commit.sha
        )

        # Create suggestions file in new branch
        suggestions_file_path = f"suggestions/{document_id}-{timestamp}.md"
        logger.info(f"Creating suggestions file: {suggestions_file_path}")

        commit_message = f"AI suggestions for {document_id}\n\n{explanation}"

        repo.create_file(
            path=suggestions_file_path,
            message=commit_message,
            content=suggestions_content,
            branch=branch_name
        )

        # Create Pull Request
        logger.info("Creating pull request")

        pr_title = f"🤖 AI Suggestions for {document_id}"

        pr_body = f"""## AI-Suggested Documentation Improvements

### Document
**{document_id}**

### Summary
{explanation}

### 📄 Suggestions File
This PR adds a suggestions file: `{suggestions_file_path}`

The file contains:
- **Content additions**: {content_summary}
- **Metadata improvements**: {metadata_summary}

### 📋 How to Apply
1. Review the suggestions in `{suggestions_file_path}`
2. Manually apply the relevant changes to `docs/{document_id}.md`
3. Update the document's frontmatter metadata as suggested
4. Delete the suggestions file after applying changes
5. Commit the updates

---

### Review Checklist
- [ ] Reviewed all AI suggestions for accuracy
- [ ] Applied relevant content changes to the document
- [ ] Updated metadata (search keywords, glossary terms, etc.)
- [ ] Verified code examples are correct (if applicable)
- [ ] Deleted suggestions file after applying changes

---

*This pull request was automatically generated by AI based on user feedback.*
*Review carefully and manually apply suggestions before merging.*

**Generated**: {datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")}
"""

        pull_request = repo.create_pull(
            title=pr_title,
            body=pr_body,
            head=branch_name,
            base=default_branch
        )

        # Add labels
        try:
            pull_request.add_to_labels("ai-suggested", "documentation")
        except GithubException as e:
            logger.warning(f"Could not add labels (they may not exist): {str(e)}")

        logger.info(f"Successfully created PR: {pull_request.html_url}")

        # Prepare response
        response_data = {
            "success": True,
            "pr_url": pull_request.html_url,
            "pr_number": pull_request.number,
            "branch_name": branch_name
        }

        return func.HttpResponse(
            body=json.dumps(response_data),
            status_code=200,
            headers={
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            }
        )

    except GithubException as e:
        logger.error(f"GitHub API error: {str(e)}")
        return create_error_response(
            "GitHub API error",
            500,
            str(e)
        )

    except ValueError as e:
        logger.error(f"Invalid request: {str(e)}")
        return create_error_response("Invalid request format", 400, str(e))

    except Exception as e:
        logger.error(f"Error creating PR: {str(e)}", exc_info=True)
        return create_error_response(
            "An error occurred while creating the pull request",
            500,
            str(e)
        )


def determine_file_path(repo, document_id: str) -> str:
    """Determine the file path for a document in the repository."""
    # Extract document type from ID
    doc_type = document_id.split('-')[0] if '-' in document_id else ''

    # Map document types to directories
    type_to_dir = {
        'concept': 'day1',
        'howto': 'week1-4',
        'reference': 'reference',
        'troubleshooting': 'troubleshooting',
        'lpath': 'learning-paths'
    }

    # Get likely directory
    directory = type_to_dir.get(doc_type, 'day1')

    # Possible paths to check
    possible_paths = [
        f"docs/{directory}/{document_id}.md",
        f"docs/day1/{document_id}.md",
        f"docs/week1-4/{document_id}.md",
        f"docs/month1-2/{document_id}.md",
        f"docs/learning-paths/{document_id}.md",
        f"docs/reference/{document_id}.md",
        f"docs/troubleshooting/{document_id}.md"
    ]

    # Try to find the file
    for path in possible_paths:
        try:
            repo.get_contents(path)
            logger.info(f"Found file at: {path}")
            return path
        except GithubException:
            continue

    logger.error(f"File not found for document: {document_id}")
    return None


def create_error_response(message: str, status_code: int, detail: str = None) -> func.HttpResponse:
    """Create a standardized error response."""
    error_data = {
        "error": message
    }
    if detail:
        error_data["detail"] = detail

    return func.HttpResponse(
        body=json.dumps(error_data),
        status_code=status_code,
        headers={
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        }
    )
