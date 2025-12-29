import azure.functions as func
import json
import logging
import os
from typing import List, Dict, Any
from azure.core.credentials import AzureKeyCredential
from azure.search.documents import SearchClient
from azure.search.documents.models import VectorizedQuery
from openai import AzureOpenAI

# Initialize logging
logger = logging.getLogger(__name__)

# Environment variables
SEARCH_ENDPOINT = os.environ.get("SEARCH_ENDPOINT")
SEARCH_KEY = os.environ.get("SEARCH_KEY")
SEARCH_INDEX = os.environ.get("SEARCH_INDEX", "docs-index")
OPENAI_ENDPOINT = os.environ.get("OPENAI_ENDPOINT")
OPENAI_KEY = os.environ.get("OPENAI_KEY")
OPENAI_DEPLOYMENT = os.environ.get("OPENAI_DEPLOYMENT", "gpt-4")
EMBEDDING_DEPLOYMENT = os.environ.get("EMBEDDING_DEPLOYMENT", "text-embedding-ada-002")

def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    HTTP trigger function that answers documentation questions using AI search.
    """
    logger.info('Documentation ask function triggered')

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
    if not all([SEARCH_ENDPOINT, SEARCH_KEY, OPENAI_ENDPOINT, OPENAI_KEY]):
        logger.error("Missing required environment variables")
        return create_error_response(
            "Server configuration error",
            500,
            "Missing required environment variables"
        )

    try:
        # Parse request body
        req_body = req.get_json()
        question = req_body.get('question', '').strip()

        if not question:
            return create_error_response("Question is required", 400)

        logger.info(f"Processing question: {question[:100]}...")

        # Initialize clients
        search_client = SearchClient(
            endpoint=SEARCH_ENDPOINT,
            index_name=SEARCH_INDEX,
            credential=AzureKeyCredential(SEARCH_KEY)
        )

        openai_client = AzureOpenAI(
            api_key=OPENAI_KEY,
            api_version="2024-02-01",
            azure_endpoint=OPENAI_ENDPOINT,
            timeout=60.0,
            max_retries=2
        )

        # Try to generate embedding for vector search, but fallback to keyword search if it fails
        vector_query = None
        try:
            logger.info("Generating embedding for question...")
            embedding_response = openai_client.embeddings.create(
                input=question,
                model=EMBEDDING_DEPLOYMENT
            )
            question_embedding = embedding_response.data[0].embedding

            vector_query = VectorizedQuery(
                vector=question_embedding,
                k_nearest_neighbors=3,
                fields="content_vector"
            )
            logger.info("Using hybrid search (vector + keyword)")
        except Exception as e:
            logger.warning(f"Could not generate embedding, using keyword search only: {e}")
            vector_query = None

        # Search for relevant documents (hybrid or keyword-only)
        logger.info("Searching for relevant documents...")

        search_params = {
            "search_text": question,
            "select": ["document_id", "title", "content", "document_type", "file_path", "topics", "technologies"],
            "top": 3,
            "query_type": "full",  # Use full text search
            "search_mode": "any"    # Match any of the keywords
        }

        if vector_query:
            search_params["vector_queries"] = [vector_query]

        search_results = search_client.search(**search_params)

        # Collect relevant documents
        documents = []
        context_parts = []

        for result in search_results:
            doc = {
                "document_id": result.get("document_id", ""),
                "title": result.get("title", "Untitled"),
                "document_type": result.get("document_type", ""),
                "file_path": result.get("file_path", ""),
                "content": result.get("content", "")
            }
            documents.append(doc)

            # Build context for GPT
            context_parts.append(f"# {doc['title']}\n\n{doc['content']}")

        if not documents:
            return create_error_response(
                "No relevant documentation found",
                404,
                "Try rephrasing your question or check if the documentation exists"
            )

        logger.info(f"Found {len(documents)} relevant documents")

        # Generate answer using GPT-4
        logger.info("Generating answer with GPT-4...")
        context = "\n\n---\n\n".join(context_parts)

        system_prompt = """You are a helpful assistant for Infrastructure as Code documentation.

CRITICAL RULES:
1. Answer questions STRICTLY using ONLY the provided documentation context below
2. DO NOT add information from your training data or general knowledge
3. If specific details aren't in the context, explicitly say "The documentation doesn't provide details about X"
4. Quote or paraphrase ONLY what's explicitly written in the context
5. If the context is insufficient to answer fully, say so

Format your answer in clear markdown with proper headings, lists, and code blocks.
Only provide examples that appear in the documentation context."""

        user_prompt = f"""Context from documentation:

{context}

---

Question: {question}

Please provide a detailed answer based on the documentation above."""

        chat_response = openai_client.chat.completions.create(
            model=OPENAI_DEPLOYMENT,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.3,
            max_tokens=2000
        )

        answer = chat_response.choices[0].message.content

        # Prepare response
        response_data = {
            "answer": answer,
            "sources": [
                {
                    "document_id": doc["document_id"],
                    "title": doc["title"],
                    "document_type": doc["document_type"],
                    "file_path": doc["file_path"],
                    "content_preview": doc["content"][:500] + "..." if len(doc["content"]) > 500 else doc["content"]  # Show what context was used
                }
                for doc in documents
            ],
            "question": question,
            "context_used": context  # Include full context for debugging
        }

        logger.info("Successfully generated answer")

        return func.HttpResponse(
            body=json.dumps(response_data),
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
            "An error occurred while processing your question",
            500,
            str(e)
        )


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
