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
        # Get raw body and parse manually (Azure Functions req.get_json() has issues)
        try:
            raw_body = req.get_body().decode('utf-8')
            logger.info(f"✅ Got raw body successfully, length: {len(raw_body)}")
            logger.info(f"Raw request body (first 200 chars): {raw_body[:200]}")
        except Exception as body_error:
            logger.error(f"❌ Error getting request body: {str(body_error)}")
            return create_error_response(
                "Body Read Error",
                400,
                f"Could not read request body: {str(body_error)}"
            )

        # Parse JSON manually instead of using req.get_json()
        try:
            req_body = json.loads(raw_body)
            logger.info("JSON parsed successfully")
        except (json.JSONDecodeError, ValueError) as json_error:
            logger.error(f"JSON parsing error: {str(json_error)}")
            logger.error(f"Error type: {type(json_error).__name__}")
            logger.error(f"Raw request body (first 500): {raw_body[:500]}")
            logger.error(f"Raw request body (full length): {len(raw_body)}")
            # Return raw body preview in error for debugging
            return create_error_response(
                "JSON Parse Error",
                400,
                f"{str(json_error)} | Body (first 200 chars): {raw_body[:200]}"
            )

        if not req_body:
            return create_error_response(
                "Empty request body",
                400,
                "Request body is required"
            )

        document_id = req_body.get('document_id', '').strip()
        improvement_type = req_body.get('improvement_type', '').strip()
        feedback = req_body.get('feedback', '').strip()

        logger.info(f"Request received - Document: {document_id}, Type: {improvement_type}, Feedback length: {len(feedback)}")

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

CRITICAL: You MUST return valid JSON. Properly escape all special characters including quotes, newlines, and backslashes.

When suggesting improvements, you should:
1. Improve CONTENT based on the user's feedback
2. Suggest METADATA improvements to enhance searchability:
   - search_keywords: Natural language phrases users might search for
   - glossary_terms: Technical terms that should link to the glossary
   - related_documents: IDs of related documents users should read
   - prerequisites: What knowledge/documents are needed first
   - learning_outcomes: What users will learn (specific, measurable)
   - tags/topics: Categorization for better discovery

IMPORTANT: In the modified_content field, do NOT include the entire document. Just provide a SUMMARY of changes in plain text.

Format your response as a JSON object with this structure:
{
  "explanation": "Brief explanation of the improvements",
  "content_changes": {
    "summary": "Description of what content changes to make",
    "suggested_additions": "List key points or sections to add",
    "suggested_edits": "List specific edits to make"
  },
  "metadata_changes": {
    "summary": "What metadata changes are proposed",
    "search_keywords": ["keyword1", "keyword2", "keyword3"],
    "glossary_terms": ["term1", "term2"],
    "related_documents": ["doc-id-1", "doc-id-2"],
    "prerequisites": ["prerequisite1", "prerequisite2"],
    "learning_outcomes": ["outcome1", "outcome2"]
  }
}

Keep all text values SHORT and simple. Do NOT include full document content in the JSON.
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
        logger.info(f"OpenAI response length: {len(suggestions_json)}")
        logger.info(f"OpenAI response (first 300 chars): {suggestions_json[:300]}")

        try:
            suggestions = json.loads(suggestions_json)
        except json.JSONDecodeError as parse_error:
            logger.error(f"Failed to parse OpenAI response as JSON: {str(parse_error)}")
            logger.error(f"OpenAI response (first 1000 chars): {suggestions_json[:1000]}")
            raise ValueError(f"OpenAI returned invalid JSON: {str(parse_error)}")

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
