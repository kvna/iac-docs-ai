"""
Azure Function: List Documents
Returns the complete document tree structure with metadata for the documentation browser.
"""

import azure.functions as func
import logging
import json
import os
from pathlib import Path
import yaml
import re

logger = logging.getLogger(__name__)


def extract_frontmatter(file_path):
    """Extract YAML frontmatter from markdown file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Match YAML frontmatter (---...---)
        match = re.match(r'^---\s*\n(.*?)\n---\s*\n', content, re.DOTALL)
        if match:
            frontmatter_text = match.group(1)
            metadata = yaml.safe_load(frontmatter_text)
            return metadata
        return {}
    except Exception as e:
        logger.warning(f"Failed to extract frontmatter from {file_path}: {e}")
        return {}


def get_document_tree(docs_dir):
    """
    Build a tree structure of all documents with their metadata.

    Returns structure like:
    {
        "folders": [
            {
                "name": "day1",
                "display_name": "Day 1 - First Day",
                "documents": [...]
            },
            ...
        ],
        "total_count": 42
    }
    """
    docs_path = Path(docs_dir)

    if not docs_path.exists():
        logger.error(f"Docs directory not found: {docs_dir}")
        return {"folders": [], "total_count": 0}

    # Define folder structure with display names
    folder_config = {
        "day1": {"display_name": "Day 1 - First Day", "order": 1},
        "week1-4": {"display_name": "Week 1-4 - Foundation", "order": 2},
        "month1-2": {"display_name": "Month 1-2 - Intermediate", "order": 3},
        "month3-6": {"display_name": "Month 3-6 - Advanced", "order": 4},
        "month6-12": {"display_name": "Month 6-12 - Expert", "order": 5},
        "reference": {"display_name": "Reference - Lookups", "order": 6},
        "troubleshooting": {"display_name": "Troubleshooting - Solutions", "order": 7},
        "learning-paths": {"display_name": "Learning Paths - Guided", "order": 8},
    }

    folders = []
    total_count = 0

    # Scan each folder
    for folder_name, config in sorted(folder_config.items(), key=lambda x: x[1]["order"]):
        folder_path = docs_path / folder_name

        if not folder_path.exists() or not folder_path.is_dir():
            continue

        documents = []

        # Find all .md files in folder
        for md_file in sorted(folder_path.glob("*.md")):
            try:
                # Extract metadata
                metadata = extract_frontmatter(md_file)

                # Get title from metadata or filename
                title = metadata.get('title', '')
                if not title:
                    # Try to extract title from first heading in content
                    with open(md_file, 'r', encoding='utf-8') as f:
                        content = f.read()
                        # Remove frontmatter
                        content = re.sub(r'^---\s*\n.*?\n---\s*\n', '', content, flags=re.DOTALL)
                        # Find first heading
                        heading_match = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
                        if heading_match:
                            title = heading_match.group(1)
                        else:
                            # Use filename as fallback
                            title = md_file.stem.replace('-', ' ').title()

                doc_info = {
                    "file_name": md_file.name,
                    "document_id": metadata.get('document_id', md_file.stem),
                    "title": title,
                    "document_type": metadata.get('document_type', 'unknown'),
                    "skill_level": metadata.get('skill_level', folder_name),
                    "topics": metadata.get('topics', []),
                    "technologies": metadata.get('technologies', []),
                    "estimated_time": metadata.get('estimated_time', 0),
                    "last_reviewed": metadata.get('last_reviewed', ''),
                    "review_status": metadata.get('review_status', ''),
                    "file_path": f"{folder_name}/{md_file.name}",
                    "search_keywords": metadata.get('search_keywords', []),
                }

                documents.append(doc_info)
                total_count += 1

            except Exception as e:
                logger.error(f"Error processing {md_file}: {e}")
                continue

        if documents:
            folders.append({
                "name": folder_name,
                "display_name": config["display_name"],
                "order": config["order"],
                "document_count": len(documents),
                "documents": documents
            })

    return {
        "folders": folders,
        "total_count": total_count
    }


def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    HTTP trigger function to list all documents.

    Optional query parameters:
    - folder: Filter by specific folder (e.g., "day1", "week1-4")
    - document_type: Filter by document type (e.g., "concept", "howto")
    - format: Response format ("tree" or "flat"), default "tree"
    """
    logger.info('Processing list_documents request')

    try:
        # Get query parameters
        folder_filter = req.params.get('folder')
        doc_type_filter = req.params.get('document_type')
        format_type = req.params.get('format', 'tree')

        # Determine docs directory - try multiple locations
        possible_paths = [
            os.path.join(os.path.dirname(__file__), '..', '..', '..', 'docs'),
            os.path.join(os.getcwd(), 'docs'),
            '/home/site/wwwroot/docs',  # Azure Function App path
        ]

        docs_dir = None
        for path in possible_paths:
            if os.path.exists(path):
                docs_dir = path
                logger.info(f"Found docs directory at: {docs_dir}")
                break

        if not docs_dir:
            logger.error("Docs directory not found in any expected location")
            return func.HttpResponse(
                json.dumps({"error": "Documentation directory not found"}),
                status_code=500,
                mimetype="application/json"
            )

        # Get document tree
        tree = get_document_tree(docs_dir)

        # Apply filters if specified
        if folder_filter:
            tree["folders"] = [f for f in tree["folders"] if f["name"] == folder_filter]
            tree["total_count"] = sum(f["document_count"] for f in tree["folders"])

        if doc_type_filter:
            for folder in tree["folders"]:
                folder["documents"] = [d for d in folder["documents"] if d["document_type"] == doc_type_filter]
                folder["document_count"] = len(folder["documents"])
            tree["total_count"] = sum(f["document_count"] for f in tree["folders"])

        # Format response
        if format_type == "flat":
            # Flatten to single list of documents
            all_docs = []
            for folder in tree["folders"]:
                all_docs.extend(folder["documents"])
            response_data = {
                "documents": all_docs,
                "total_count": len(all_docs)
            }
        else:
            # Return tree structure
            response_data = tree

        logger.info(f"Returning {response_data['total_count']} documents")

        return func.HttpResponse(
            json.dumps(response_data, indent=2),
            status_code=200,
            mimetype="application/json",
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type"
            }
        )

    except Exception as e:
        logger.error(f"Error in list_documents: {str(e)}", exc_info=True)
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            status_code=500,
            mimetype="application/json"
        )
