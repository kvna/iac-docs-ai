import azure.functions as func
import json
import logging
import os
import re
from typing import Dict, Any
import urllib.request
import urllib.error
from openai import AzureOpenAI

# Initialize logging
logger = logging.getLogger(__name__)

# Environment variables
OPENAI_ENDPOINT = os.environ.get("OPENAI_ENDPOINT")
OPENAI_KEY = os.environ.get("OPENAI_KEY")
OPENAI_DEPLOYMENT = os.environ.get("OPENAI_DEPLOYMENT", "gpt-4")
GITHUB_REPO_URL = "https://raw.githubusercontent.com/kvna/iac-docs-ai/main/docs/"


def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    HTTP trigger function that generates AI-powered documentation improvement suggestions.
    Analyzes both content and metadata to improve searchability.
    """
    logger.info('Suggest improvement function triggered')

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
    if not all([OPENAI_ENDPOINT, OPENAI_KEY]):
        logger.error("Missing required environment variables")
        return create_error_response(
            "Server configuration error",
            500,
            "Missing required environment variables"
        )

    try:
        # Parse request body
        req_body = req.get_json()
        document_id = req_body.get('document_id', '').strip()
        improvement_type = req_body.get('improvement_type', '').strip()
        feedback = req_body.get('feedback', '').strip()

        if not all([document_id, improvement_type, feedback]):
            return create_error_response(
                "Missing required fields",
                400,
                "document_id, improvement_type, and feedback are required"
            )

        logger.info(f"Processing improvement request for: {document_id}")

        # Fetch original document from GitHub
        document_content = fetch_document_from_github(document_id)
        if not document_content:
            return create_error_response(
                "Document not found",
                404,
                f"Could not fetch document: {document_id}"
            )

        # Parse frontmatter and content
        frontmatter, content = parse_markdown_document(document_content)

        # Initialize OpenAI client
        openai_client = AzureOpenAI(
            api_key=OPENAI_KEY,
            api_version="2024-02-01",
            azure_endpoint=OPENAI_ENDPOINT,
            timeout=120.0,
            max_retries=2
        )

        # Generate AI suggestions
        logger.info("Generating AI suggestions...")
        suggestions = generate_suggestions(
            openai_client,
            document_id,
            frontmatter,
            content,
            improvement_type,
            feedback
        )

        logger.info("Successfully generated suggestions")

        return func.HttpResponse(
            body=json.dumps(suggestions),
            status_code=200,
            headers={
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            }
        )

    except ValueError as e:
        logger.error(f"Invalid request: {str(e)}")
        return create_error_response("Invalid request format", 400, str(e))

    except Exception as e:
        logger.error(f"Error processing request: {str(e)}", exc_info=True)
        return create_error_response(
            "An error occurred while generating suggestions",
            500,
            str(e)
        )


def fetch_document_from_github(document_id: str) -> str:
    """Fetch document content from GitHub repository."""
    # Determine file path based on document_id pattern
    doc_type = document_id.split('-')[0] if '-' in document_id else ''

    # Map document types to directories
    type_to_dir = {
        'concept': 'day1',
        'howto': 'week1-4',
        'reference': 'reference',
        'troubleshooting': 'troubleshooting',
        'lpath': 'learning-paths'
    }

    # Try to determine directory from document type
    directory = type_to_dir.get(doc_type, 'day1')

    # Construct possible file paths
    possible_paths = [
        f"{directory}/{document_id}.md",
        f"day1/{document_id}.md",
        f"week1-4/{document_id}.md",
        f"month1-2/{document_id}.md",
        f"learning-paths/{document_id}.md",
        f"reference/{document_id}.md",
        f"troubleshooting/{document_id}.md"
    ]

    # Try each path
    for path in possible_paths:
        url = f"{GITHUB_REPO_URL}{path}"
        try:
            logger.info(f"Attempting to fetch: {url}")
            with urllib.request.urlopen(url) as response:
                content = response.read().decode('utf-8')
                logger.info(f"Successfully fetched document from: {path}")
                return content
        except urllib.error.HTTPError:
            continue

    logger.error(f"Document not found in any location: {document_id}")
    return None


def parse_markdown_document(content: str) -> tuple:
    """Parse markdown document into frontmatter and content."""
    # Match YAML frontmatter
    frontmatter_match = re.match(r'^---\s*\n(.*?)\n---\s*\n(.*)$', content, re.DOTALL)

    if frontmatter_match:
        frontmatter = frontmatter_match.group(1)
        main_content = frontmatter_match.group(2)
        return frontmatter, main_content
    else:
        return "", content


def generate_suggestions(
    client: AzureOpenAI,
    document_id: str,
    frontmatter: str,
    content: str,
    improvement_type: str,
    feedback: str
) -> Dict[str, Any]:
    """Generate AI-powered suggestions for document improvement."""

    improvement_type_descriptions = {
        'add-content': 'Add missing content or expand existing sections',
        'clarify': 'Clarify confusing or ambiguous content',
        'fix-error': 'Fix technical errors or inaccuracies',
        'update': 'Update outdated information or examples',
        'example': 'Add or improve code examples',
        'other': 'General improvement'
    }

    system_prompt = """You are an expert technical documentation editor specializing in Infrastructure as Code documentation.
Your goal is to improve documentation quality and searchability.

When suggesting improvements, you should:
1. Improve CONTENT based on the user's feedback
2. Suggest METADATA improvements to enhance searchability:
   - search_keywords: Natural language phrases users might search for
   - glossary_terms: Technical terms that should link to the glossary
   - related_documents: IDs of related documents users should read
   - prerequisites: What knowledge/documents are needed first
   - learning_outcomes: What users will learn (specific, measurable)
   - tags/topics: Categorization for better discovery

Format your response as a JSON object with this structure:
{
  "explanation": "Brief explanation of the improvements (2-3 sentences)",
  "content_changes": {
    "summary": "What content changes are proposed",
    "modified_content": "The full improved content (markdown format, without frontmatter)"
  },
  "metadata_changes": {
    "summary": "What metadata changes are proposed",
    "search_keywords": ["list", "of", "improved", "keywords"],
    "glossary_terms": ["list", "of", "terms"],
    "related_documents": ["doc-id-1", "doc-id-2"],
    "prerequisites": ["updated prerequisites"],
    "learning_outcomes": ["specific learning outcome 1", "specific learning outcome 2"],
    "other_metadata": {
      "field_name": "value"
    }
  },
  "modified_frontmatter": "The complete improved YAML frontmatter (without --- markers)"
}

Be specific and actionable in your suggestions."""

    user_prompt = f"""Document ID: {document_id}
Improvement Type: {improvement_type_descriptions.get(improvement_type, improvement_type)}
User Feedback: {feedback}

CURRENT FRONTMATTER:
---
{frontmatter}
---

CURRENT CONTENT:
{content}

Please analyze this document and suggest improvements to both the content and metadata.
Focus on making the document more searchable and valuable for users learning Infrastructure as Code.

Return your suggestions in the JSON format specified."""

    try:
        chat_response = client.chat.completions.create(
            model=OPENAI_DEPLOYMENT,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.4,
            max_tokens=4000,
            response_format={"type": "json_object"}
        )

        suggestions_json = chat_response.choices[0].message.content
        suggestions = json.loads(suggestions_json)

        # Add original content for comparison
        suggestions['original_content'] = content
        suggestions['original_frontmatter'] = frontmatter
        suggestions['document_id'] = document_id

        return suggestions

    except Exception as e:
        logger.error(f"Error generating suggestions: {str(e)}")
        raise


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
