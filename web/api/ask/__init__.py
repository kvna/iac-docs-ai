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

        # Generate embedding for the question
        logger.info("Generating embedding for question...")
        embedding_response = openai_client.embeddings.create(
            input=question,
            model=EMBEDDING_DEPLOYMENT
        )
        question_embedding = embedding_response.data[0].embedding

        # Search for relevant documents
        logger.info("Searching for relevant documents...")
        vector_query = VectorizedQuery(
            vector=question_embedding,
            k_nearest_neighbors=3,
            fields="content_vector"
        )

        search_results = search_client.search(
            search_text=question,
            vector_queries=[vector_query],
            select=["document_id", "title", "content", "document_type", "file_path", "topics", "technologies"],
            top=3
        )

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
Answer questions based ONLY on the provided documentation context.
If the answer isn't in the context, say so.
Format your answer in clear markdown with proper headings, lists, and code blocks.
Be specific and provide examples when available in the documentation."""

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
                    "file_path": doc["file_path"]
                }
                for doc in documents
            ],
            "question": question
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
