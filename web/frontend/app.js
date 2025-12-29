// Configuration
const CONFIG = {
    // Temporarily force production API (local Function App not running)
    // To use local API: Start Function App with 'cd web/api && func start'
    // Then change apiEndpoint to: 'http://localhost:7071/api/ask'
    apiEndpoint: 'https://func-iac-docs-poc-northeu.azurewebsites.net/api/ask'
};

// DOM Elements
const queryInput = document.getElementById('queryInput');
const searchBtn = document.getElementById('searchBtn');
const results = document.getElementById('results');
const answerContent = document.getElementById('answerContent');
const sourcesContent = document.getElementById('sourcesContent');
const errorContainer = document.getElementById('error');
const errorContent = document.getElementById('errorContent');

// Quick question buttons
const quickQuestions = document.querySelectorAll('.quick-q');
quickQuestions.forEach(btn => {
    btn.addEventListener('click', () => {
        const question = btn.dataset.question;
        queryInput.value = question;
        handleSearch();
    });
});

// Example question clicks
const exampleQuestions = document.querySelectorAll('.example-card li');
exampleQuestions.forEach(li => {
    li.addEventListener('click', () => {
        queryInput.value = li.textContent;
        handleSearch();
        // Scroll to search box
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });
});

// Search button click
searchBtn.addEventListener('click', handleSearch);

// Enter key in input
queryInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        handleSearch();
    }
});

// Handle search
async function handleSearch() {
    const query = queryInput.value.trim();

    if (!query) {
        showError('Please enter a question');
        return;
    }

    // Hide previous results/errors
    results.style.display = 'none';
    errorContainer.style.display = 'none';

    // Show loading state
    setLoading(true);

    try {
        // Log which endpoint we're using
        console.log('🔍 Searching with endpoint:', CONFIG.apiEndpoint);
        console.log('📝 Question:', query);

        const response = await fetch(CONFIG.apiEndpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ question: query })
        });

        console.log('📡 Response status:', response.status);

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({ error: 'Unknown error' }));
            throw new Error(errorData.error || `HTTP ${response.status}: ${response.statusText}`);
        }

        const data = await response.json();
        console.log('✅ Response data:', data);
        displayResults(data);

    } catch (error) {
        console.error('❌ Search error:', error);
        console.error('Error details:', {
            message: error.message,
            name: error.name,
            stack: error.stack
        });

        // More specific error message
        let errorMessage = error.message || 'Failed to search documentation.';
        if (error.message === 'Failed to fetch') {
            errorMessage = `Cannot connect to API endpoint: ${CONFIG.apiEndpoint}\n\n`;
            errorMessage += 'Possible issues:\n';
            errorMessage += '• Function App is not running locally (run: cd web/api && func start)\n';
            errorMessage += '• Production endpoint is down or not deployed\n';
            errorMessage += '• CORS or network issue';
        }

        showError(errorMessage);
    } finally {
        setLoading(false);
    }
}

// Display results
function displayResults(data) {
    // Render answer (markdown to HTML)
    answerContent.innerHTML = markdownToHtml(data.answer);

    // Add copy buttons to code blocks
    addCopyButtonsToCodeBlocks();

    // Render sources
    sourcesContent.innerHTML = '';
    if (data.sources && data.sources.length > 0) {
        data.sources.forEach(source => {
            const card = createSourceCard(source);
            sourcesContent.appendChild(card);
        });
    } else {
        sourcesContent.innerHTML = '<p style="color: var(--text-secondary);">No sources available</p>';
    }

    // Show results
    results.style.display = 'flex';

    // Scroll to results
    results.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

// Create source card
function createSourceCard(source) {
    const card = document.createElement('div');
    card.className = 'source-card';

    const title = document.createElement('h4');
    title.textContent = source.title || source.document_id || 'Untitled';

    const meta = document.createElement('div');
    meta.className = 'source-meta';

    if (source.document_type) {
        const type = document.createElement('span');
        type.className = 'source-type';
        type.textContent = source.document_type;
        meta.appendChild(type);
    }

    if (source.file_path) {
        const path = document.createElement('span');
        path.textContent = source.file_path;
        meta.appendChild(path);
    }

    card.appendChild(title);
    card.appendChild(meta);

    // Add clickable link to view source
    if (source.file_path) {
        const viewLink = document.createElement('a');
        viewLink.className = 'view-source-link';
        viewLink.href = '#';
        viewLink.innerHTML = `
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
            View Source
        `;

        viewLink.addEventListener('click', (e) => {
            e.preventDefault();
            openSourceFile(source);
        });

        card.appendChild(viewLink);
    }

    return card;
}

// Open source file
async function openSourceFile(source) {
    // GitHub raw content URL
    const githubRawBaseUrl = 'https://raw.githubusercontent.com/kvna/iac-docs-ai/main/docs/';

    console.log('Opening source:', source);

    // Try to reconstruct the full path from document_id
    let docId = source.document_id || '';
    const docType = source.document_type || '';

    // Remove .md extension if it exists (we'll add it back consistently)
    if (docId.endsWith('.md')) {
        docId = docId.slice(0, -3);
    }

    let fullPath = '';

    // Map document types to their folders
    if (docType === 'learning-path' || docId.startsWith('learning-path')) {
        fullPath = `learning-paths/${docId}.md`;
    } else if (docType === 'troubleshooting' || docId.startsWith('troubleshooting')) {
        fullPath = `troubleshooting/${docId}.md`;
    } else if (docType === 'reference' || docId.startsWith('reference')) {
        fullPath = `reference/${docId}.md`;
    } else {
        // Try to determine skill level from document_id prefix
        const skillLevelPrefixes = {
            'day1': 'day1',
            'week': 'week1-4',
            'month1': 'month1-2',
            'month3': 'month3-6',
            'month6': 'month6-12'
        };

        let skillLevel = 'day1'; // default
        for (const [prefix, folder] of Object.entries(skillLevelPrefixes)) {
            if (docId.includes(prefix)) {
                skillLevel = folder;
                break;
            }
        }

        fullPath = `${skillLevel}/${docId}.md`;
    }

    // Construct the full GitHub raw URL
    const githubRawUrl = githubRawBaseUrl + fullPath;

    console.log('Fetching from:', githubRawUrl);

    // Show loading modal
    showLoadingModal('Loading source document...');

    try {
        // Fetch the markdown content
        console.log('Fetching markdown from:', githubRawUrl);
        const response = await fetch(githubRawUrl, {
            mode: 'cors',
            cache: 'no-cache'
        });

        console.log('Fetch response status:', response.status);

        if (!response.ok) {
            throw new Error(`Failed to fetch document (HTTP ${response.status})`);
        }

        const markdownContent = await response.text();
        console.log('Fetched markdown length:', markdownContent.length);

        // Remove YAML frontmatter if present
        const contentWithoutFrontmatter = markdownContent.replace(/^---[\s\S]*?---\n\n?/m, '');

        console.log('Content after removing frontmatter length:', contentWithoutFrontmatter.length);

        // Close loading modal
        document.querySelector('.source-modal')?.remove();

        // Display in modal
        showSourceDocumentModal(source, contentWithoutFrontmatter);

    } catch (error) {
        console.error('❌ Error fetching source document:', error);
        console.error('Attempted URL:', githubRawUrl);

        // Close loading modal
        document.querySelector('.source-modal')?.remove();

        // Show error modal with better message
        showFetchErrorModal(source, error.message, githubRawUrl);
    }
}

// Show loading modal
function showLoadingModal(message) {
    const modal = document.createElement('div');
    modal.className = 'source-modal';
    modal.innerHTML = `
        <div class="source-modal-content">
            <div class="source-modal-body" style="text-align: center; padding: 3rem;">
                <svg class="spinner" width="40" height="40" viewBox="0 0 24 24" style="margin-bottom: 1rem;">
                    <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" opacity="0.25"/>
                    <path d="M12 2 A10 10 0 0 1 22 12" stroke="var(--primary)" stroke-width="2" fill="none" stroke-linecap="round"/>
                </svg>
                <p style="color: var(--text-secondary);">${message}</p>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
}

// Show source document in modal
function showSourceDocumentModal(source, markdownContent) {
    // Remove any existing modals
    document.querySelectorAll('.source-modal').forEach(m => m.remove());

    const modal = document.createElement('div');
    modal.className = 'source-modal';

    // Convert markdown to HTML
    const htmlContent = markdownToHtml(markdownContent);

    modal.innerHTML = `
        <div class="source-modal-content source-document-modal">
            <div class="source-modal-header">
                <div>
                    <h3>📄 ${source.title || source.document_id}</h3>
                    <div class="source-meta" style="margin-top: 0.5rem;">
                        <span class="source-type">${source.document_type || 'document'}</span>
                        ${source.file_path ? `<span style="color: var(--text-secondary); font-size: 0.875rem;">${source.file_path}</span>` : ''}
                    </div>
                </div>
                <button class="close-modal" onclick="this.closest('.source-modal').remove()">×</button>
            </div>
            <div class="source-modal-body source-document-content">
                ${htmlContent}
            </div>
            <div class="source-modal-footer">
                <button class="suggest-improvement-btn" onclick="showImprovementDialog('${source.document_id}', '${(source.title || '').replace(/'/g, "\\'")}')">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                    </svg>
                    💡 Suggest Improvement
                </button>
                <a href="https://github.com/kvna/iac-docs-ai/blob/main/docs/${getDocumentPath(source)}"
                   target="_blank"
                   rel="noopener"
                   class="view-on-github-btn">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                    </svg>
                    View on GitHub
                </a>
            </div>
        </div>
    `;

    document.body.appendChild(modal);

    // Add copy buttons to code blocks in the modal
    addCopyButtonsToModalCodeBlocks(modal);

    // Close on background click
    modal.addEventListener('click', (e) => {
        if (e.target === modal) {
            modal.remove();
        }
    });
}

// Helper function to get document path
function getDocumentPath(source) {
    const docId = source.document_id || '';
    const docType = source.document_type || '';

    if (docType === 'learning-path' || docId.startsWith('learning-path')) {
        return `learning-paths/${docId}.md`;
    } else if (docType === 'troubleshooting' || docId.startsWith('troubleshooting')) {
        return `troubleshooting/${docId}.md`;
    } else if (docType === 'reference' || docId.startsWith('reference')) {
        return `reference/${docId}.md`;
    } else {
        const skillLevelPrefixes = {
            'day1': 'day1',
            'week': 'week1-4',
            'month1': 'month1-2',
            'month3': 'month3-6',
            'month6': 'month6-12'
        };

        let skillLevel = 'day1';
        for (const [prefix, folder] of Object.entries(skillLevelPrefixes)) {
            if (docId.includes(prefix)) {
                skillLevel = folder;
                break;
            }
        }

        return `${skillLevel}/${docId}.md`;
    }
}

// Add copy buttons to code blocks in modal
function addCopyButtonsToModalCodeBlocks(modal) {
    const codeBlocks = modal.querySelectorAll('pre');

    codeBlocks.forEach((pre) => {
        // Skip if already has copy button
        if (pre.querySelector('.copy-btn')) return;

        // Create wrapper
        const wrapper = document.createElement('div');
        wrapper.className = 'code-block-wrapper';

        // Wrap the pre element
        pre.parentNode.insertBefore(wrapper, pre);
        wrapper.appendChild(pre);

        // Create copy button
        const copyBtn = document.createElement('button');
        copyBtn.className = 'copy-btn';
        copyBtn.innerHTML = `
            <svg class="copy-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <rect x="9" y="9" width="13" height="13" rx="2" stroke="currentColor" stroke-width="2"/>
                <path d="M5 15H4C2.89543 15 2 14.1046 2 13V4C2 2.89543 2.89543 2 4 2H13C14.1046 2 15 2.89543 15 4V5" stroke="currentColor" stroke-width="2"/>
            </svg>
            <span class="copy-text">Copy</span>
            <span class="copied-text" style="display: none;">Copied!</span>
        `;

        copyBtn.addEventListener('click', () => {
            const code = pre.querySelector('code');
            const text = code.textContent;

            navigator.clipboard.writeText(text).then(() => {
                copyBtn.querySelector('.copy-text').style.display = 'none';
                copyBtn.querySelector('.copied-text').style.display = 'inline';
                copyBtn.classList.add('copied');

                setTimeout(() => {
                    copyBtn.querySelector('.copy-text').style.display = 'inline';
                    copyBtn.querySelector('.copied-text').style.display = 'none';
                    copyBtn.classList.remove('copied');
                }, 2000);
            }).catch(err => {
                console.error('Failed to copy:', err);
            });
        });

        wrapper.appendChild(copyBtn);
    });
}

// Show fetch error modal
function showFetchErrorModal(source, errorMessage, attemptedUrl) {
    const modal = document.createElement('div');
    modal.className = 'source-modal';

    const githubUrl = `https://github.com/kvna/iac-docs-ai/blob/main/docs/${getDocumentPath(source)}`;

    modal.innerHTML = `
        <div class="source-modal-content">
            <div class="source-modal-header">
                <h3>⚠️ Failed to Load Document</h3>
                <button class="close-modal" onclick="this.closest('.source-modal').remove()">×</button>
            </div>
            <div class="source-modal-body">
                <p><strong>Document:</strong> ${source.title || source.document_id}</p>
                <p><strong>Error:</strong> ${errorMessage}</p>
                <p style="margin-top: 1.5rem; padding: 1rem; background: var(--bg); border-radius: 6px; font-size: 0.875rem;">
                    <strong>Debug Info:</strong><br>
                    Document ID: <code>${source.document_id}</code><br>
                    Document Type: <code>${source.document_type}</code><br>
                    Attempted URL: <code style="word-break: break-all;">${attemptedUrl}</code>
                </p>
                <p style="margin-top: 1rem;">
                    <a href="${githubUrl}" target="_blank" rel="noopener" class="view-on-github-btn">
                        View on GitHub instead →
                    </a>
                </p>
            </div>
        </div>
    `;
    document.body.appendChild(modal);

    // Close on background click
    modal.addEventListener('click', (e) => {
        if (e.target === modal) {
            modal.remove();
        }
    });
}

// Show source information modal (legacy - for reference)
function showSourceInfo(source) {
    const modal = document.createElement('div');
    modal.className = 'source-modal';

    const repoUrl = 'https://github.com/kvna/iac-docs-ai';
    const searchUrl = `${repoUrl}/find/main?q=${encodeURIComponent(source.document_id || source.title)}`;

    modal.innerHTML = `
        <div class="source-modal-content">
            <div class="source-modal-header">
                <h3>📄 Source Document</h3>
                <button class="close-modal" onclick="this.closest('.source-modal').remove()">×</button>
            </div>
            <div class="source-modal-body">
                <p><strong>Title:</strong> ${source.title || 'Untitled'}</p>
                <p><strong>Document ID:</strong> <code>${source.document_id || 'N/A'}</code></p>
                <p><strong>Type:</strong> ${source.document_type || 'N/A'}</p>
                <p><strong>File Path:</strong> <code>${source.file_path || 'N/A'}</code></p>
                <p class="info-note">💡 <a href="${searchUrl}" target="_blank" rel="noopener">Search for this file on GitHub</a></p>
                <p style="margin-top: 1rem;"><a href="${repoUrl}/tree/main/docs" target="_blank" rel="noopener" style="color: var(--primary);">Browse all documentation →</a></p>
            </div>
        </div>
    `;
    document.body.appendChild(modal);

    // Close on background click
    modal.addEventListener('click', (e) => {
        if (e.target === modal) {
            modal.remove();
        }
    });
}

// Show error
function showError(message) {
    errorContent.textContent = message;
    errorContainer.style.display = 'flex';
    results.style.display = 'none';

    // Scroll to error
    errorContainer.scrollIntoView({ behavior: 'smooth', block: 'center' });
}

// Set loading state
function setLoading(isLoading) {
    const btnText = searchBtn.querySelector('.btn-text');
    const btnLoading = searchBtn.querySelector('.btn-loading');

    if (isLoading) {
        btnText.style.display = 'none';
        btnLoading.style.display = 'flex';
        searchBtn.disabled = true;
        queryInput.disabled = true;
    } else {
        btnText.style.display = 'block';
        btnLoading.style.display = 'none';
        searchBtn.disabled = false;
        queryInput.disabled = false;
    }
}

// Simple Markdown to HTML converter
function markdownToHtml(markdown) {
    if (!markdown) return '';

    let html = markdown;

    // Code blocks (```...```)
    html = html.replace(/```(\w+)?\n([\s\S]*?)```/g, (match, lang, code) => {
        return `<pre><code>${escapeHtml(code.trim())}</code></pre>`;
    });

    // Inline code (`...`)
    html = html.replace(/`([^`]+)`/g, '<code>$1</code>');

    // Headers
    html = html.replace(/^### (.*$)/gim, '<h3>$1</h3>');
    html = html.replace(/^## (.*$)/gim, '<h2>$1</h2>');
    html = html.replace(/^# (.*$)/gim, '<h1>$1</h1>');

    // Bold
    html = html.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');

    // Italic
    html = html.replace(/\*([^*]+)\*/g, '<em>$1</em>');

    // Links
    html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank" rel="noopener">$1</a>');

    // Lists (unordered)
    html = html.replace(/^\s*[-*]\s+(.*)$/gim, '<li>$1</li>');
    html = html.replace(/(<li>.*<\/li>)/s, '<ul>$1</ul>');

    // Lists (ordered)
    html = html.replace(/^\s*\d+\.\s+(.*)$/gim, '<li>$1</li>');

    // Line breaks
    html = html.replace(/\n\n/g, '</p><p>');
    html = html.replace(/\n/g, '<br>');

    // Wrap in paragraph if not already wrapped
    if (!html.startsWith('<')) {
        html = `<p>${html}</p>`;
    }

    return html;
}

// Escape HTML
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Add copy buttons to code blocks
function addCopyButtonsToCodeBlocks() {
    const codeBlocks = answerContent.querySelectorAll('pre');

    codeBlocks.forEach((pre) => {
        // Skip if already has copy button
        if (pre.querySelector('.copy-btn')) return;

        // Create wrapper
        const wrapper = document.createElement('div');
        wrapper.className = 'code-block-wrapper';

        // Wrap the pre element
        pre.parentNode.insertBefore(wrapper, pre);
        wrapper.appendChild(pre);

        // Create copy button
        const copyBtn = document.createElement('button');
        copyBtn.className = 'copy-btn';
        copyBtn.innerHTML = `
            <svg class="copy-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <rect x="9" y="9" width="13" height="13" rx="2" stroke="currentColor" stroke-width="2"/>
                <path d="M5 15H4C2.89543 15 2 14.1046 2 13V4C2 2.89543 2.89543 2 4 2H13C14.1046 2 15 2.89543 15 4V5" stroke="currentColor" stroke-width="2"/>
            </svg>
            <span class="copy-text">Copy</span>
            <span class="copied-text" style="display: none;">Copied!</span>
        `;

        copyBtn.addEventListener('click', () => {
            const code = pre.querySelector('code');
            const text = code.textContent;

            navigator.clipboard.writeText(text).then(() => {
                // Show "Copied!" feedback
                copyBtn.querySelector('.copy-text').style.display = 'none';
                copyBtn.querySelector('.copied-text').style.display = 'inline';
                copyBtn.classList.add('copied');

                // Reset after 2 seconds
                setTimeout(() => {
                    copyBtn.querySelector('.copy-text').style.display = 'inline';
                    copyBtn.querySelector('.copied-text').style.display = 'none';
                    copyBtn.classList.remove('copied');
                }, 2000);
            }).catch(err => {
                console.error('Failed to copy:', err);
            });
        });

        wrapper.appendChild(copyBtn);
    });
}

// Show improvement suggestion dialog
function showImprovementDialog(documentId, documentTitle) {
    // Store current document for later use
    window.currentDocumentForImprovement = { documentId, documentTitle };

    const dialog = document.createElement('div');
    dialog.className = 'source-modal';
    dialog.innerHTML = `
        <div class="source-modal-content improvement-dialog">
            <div class="source-modal-header">
                <div>
                    <h3>💡 Suggest Improvement</h3>
                    <p style="margin: 0.5rem 0 0 0; color: var(--text-secondary); font-size: 0.875rem;">
                        Document: ${documentTitle}
                    </p>
                </div>
                <button class="close-modal" onclick="this.closest('.source-modal').remove()">×</button>
            </div>
            <div class="source-modal-body">
                <p style="margin-bottom: 1rem;">
                    Describe what you'd like to improve, add, or clarify in this document.
                    Our AI will analyze it and suggest specific changes.
                </p>

                <label for="improvementType" style="display: block; margin-bottom: 0.5rem; font-weight: 600;">
                    Type of improvement:
                </label>
                <select id="improvementType" style="width: 100%; padding: 0.75rem; margin-bottom: 1rem; border: 2px solid var(--border); border-radius: 6px; font-size: 1rem;">
                    <option value="add-content">Add missing content</option>
                    <option value="clarify">Clarify existing content</option>
                    <option value="fix-error">Fix technical error</option>
                    <option value="update">Update outdated information</option>
                    <option value="example">Add code example</option>
                    <option value="other">Other improvement</option>
                </select>

                <label for="improvementFeedback" style="display: block; margin-bottom: 0.5rem; font-weight: 600;">
                    What would you like to improve?
                </label>
                <textarea
                    id="improvementFeedback"
                    placeholder="Example: Add a section explaining how to backup Terraform state files to Azure Storage..."
                    style="width: 100%; min-height: 120px; padding: 0.75rem; border: 2px solid var(--border); border-radius: 6px; font-size: 1rem; font-family: inherit; resize: vertical;"
                ></textarea>

                <div style="margin-top: 1rem; padding: 1rem; background: #E8F4FD; border-left: 4px solid var(--primary); border-radius: 6px;">
                    <strong>💡 Tip:</strong> Be specific! The more detail you provide, the better the AI suggestions will be.
                </div>
            </div>
            <div class="source-modal-footer" style="display: flex; gap: 1rem; justify-content: flex-end;">
                <button class="btn-secondary" onclick="this.closest('.source-modal').remove()">
                    Cancel
                </button>
                <button class="btn-primary" onclick="requestAIImprovement()">
                    <svg class="btn-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M13 10V3L4 14h7v7l9-11h-7z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
                    </svg>
                    Get AI Suggestions
                </button>
            </div>
        </div>
    `;

    document.body.appendChild(dialog);

    // Focus textarea
    setTimeout(() => {
        document.getElementById('improvementFeedback').focus();
    }, 100);

    // Close on background click
    dialog.addEventListener('click', (e) => {
        if (e.target === dialog) {
            dialog.remove();
        }
    });
}

// Request AI improvement suggestions
async function requestAIImprovement() {
    const feedback = document.getElementById('improvementFeedback').value.trim();
    const improvementType = document.getElementById('improvementType').value;

    if (!feedback) {
        alert('Please describe what you\'d like to improve.');
        return;
    }

    // Safety check
    if (!window.currentDocumentForImprovement) {
        console.error('currentDocumentForImprovement is not set');
        alert('Error: Document information not found. Please try again.');
        return;
    }

    const { documentId, documentTitle } = window.currentDocumentForImprovement;

    // Validate we have the required data
    if (!documentId || !improvementType || !feedback) {
        console.error('Missing required data:', { documentId, improvementType, feedback });
        alert('Error: Missing required information. Please try again.');
        return;
    }

    // Close dialog and show loading
    document.querySelectorAll('.source-modal').forEach(m => m.remove());
    showLoadingModal('🤖 AI is analyzing the document and generating suggestions...');

    try {
        const endpoint = `${CONFIG.apiEndpoint.replace('/ask', '/suggest-improvement')}`;

        // Strip .md extension if present (backend expects document_id without extension)
        let cleanDocumentId = documentId;
        if (cleanDocumentId.endsWith('.md')) {
            cleanDocumentId = cleanDocumentId.slice(0, -3);
        }

        const requestBody = {
            document_id: cleanDocumentId,
            improvement_type: improvementType,
            feedback: feedback
        };

        console.log('🔍 Requesting AI suggestions');
        console.log('  Endpoint:', endpoint);
        console.log('  Document ID:', documentId);
        console.log('  Improvement Type:', improvementType);
        console.log('  Feedback:', feedback.substring(0, 50) + '...');

        // Call Azure Function endpoint
        const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(requestBody)
        });

        console.log('📡 Response status:', response.status);

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({ error: 'Unknown error' }));
            console.error('❌ API Error:', errorData);
            throw new Error(errorData.detail || errorData.error || `HTTP ${response.status}: ${response.statusText}`);
        }

        const data = await response.json();
        console.log('✅ AI suggestions received successfully');
        console.log('  Explanation:', data.explanation?.substring(0, 100) + '...');
        console.log('  Has content changes:', !!data.content_changes);
        console.log('  Has metadata changes:', !!data.metadata_changes);

        // Close loading modal
        document.querySelector('.source-modal')?.remove();

        // Show suggestions
        showAISuggestions(documentId, documentTitle, data);

    } catch (error) {
        console.error('❌ Error getting AI suggestions:', error);
        console.error('Error stack:', error.stack);
        document.querySelector('.source-modal')?.remove();

        let errorMessage = `Failed to get AI suggestions: ${error.message}`;
        if (error.message.includes('Failed to fetch')) {
            errorMessage += '\n\nPossible causes:\n- Network connection issue\n- CORS not configured\n- Function App not responding';
        } else if (error.message.includes('Missing required fields')) {
            errorMessage += '\n\nThe request is missing required information. Please try again.';
        }

        // Show error
        showError(errorMessage);
    }
}

// Show AI suggestions with diff
function showAISuggestions(documentId, documentTitle, data) {
    // Store suggestions for PR creation
    window.currentSuggestions = data;

    const modal = document.createElement('div');
    modal.className = 'source-modal';

    const {
        explanation,
        content_changes = {},
        metadata_changes = {},
        modified_frontmatter,
        modified_content
    } = data;

    // Render metadata improvements
    const metadataHtml = renderMetadataChanges(metadata_changes);

    modal.innerHTML = `
        <div class="source-modal-content ai-suggestions-modal" style="max-width: 1000px;">
            <div class="source-modal-header">
                <div>
                    <h3>🤖 AI Suggestions</h3>
                    <p style="margin: 0.5rem 0 0 0; color: var(--text-secondary); font-size: 0.875rem;">
                        ${escapeHtml(documentTitle)}
                    </p>
                </div>
                <button class="close-modal" onclick="this.closest('.source-modal').remove()">×</button>
            </div>
            <div class="source-modal-body" style="max-height: 70vh; overflow-y: auto; padding: 1.5rem;">
                <!-- AI Analysis -->
                <div style="padding: 1rem; background: #E8F4FD; border-left: 4px solid var(--primary); border-radius: 6px; margin-bottom: 1.5rem;">
                    <strong>💡 AI Analysis:</strong>
                    <p style="margin: 0.5rem 0 0 0;">${escapeHtml(explanation || 'The AI has suggested improvements to enhance this document.')}</p>
                </div>

                <!-- Metadata Improvements Section -->
                <div style="margin-bottom: 2rem;">
                    <h4 style="margin-bottom: 0.5rem; display: flex; align-items: center; gap: 0.5rem;">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/>
                        </svg>
                        Metadata Improvements (Searchability)
                    </h4>
                    <p style="color: var(--text-secondary); font-size: 0.875rem; margin-bottom: 1rem;">
                        ${escapeHtml(metadata_changes.summary || 'These improvements help users find this document more easily')}
                    </p>
                    ${metadataHtml}
                </div>

                <!-- Content Changes Section -->
                <div style="margin-bottom: 2rem;">
                    <h4 style="margin-bottom: 0.5rem; display: flex; align-items: center; gap: 0.5rem;">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M14 2H6c-1.1 0-1.99.9-1.99 2L4 20c0 1.1.89 2 1.99 2H18c1.1 0 2-.9 2-2V8l-6-6zm2 16H8v-2h8v2zm0-4H8v-2h8v2zm-3-5V3.5L18.5 9H13z"/>
                        </svg>
                        Content Changes
                    </h4>
                    <p style="color: var(--text-secondary); font-size: 0.875rem; margin-bottom: 1rem;">
                        ${escapeHtml(content_changes.summary || 'Improvements to document content')}
                    </p>
                    <div class="diff-preview" style="background: var(--bg); padding: 1rem; border-radius: 6px; border: 1px solid var(--border); max-height: 400px; overflow-y: auto;">
                        ${content_changes.suggested_additions ? `
                            <div style="margin-bottom: 1rem;">
                                <strong style="color: #2E7D32; display: block; margin-bottom: 0.5rem;">✚ Suggested Additions:</strong>
                                <div style="padding-left: 1rem; line-height: 1.6;">${markdownToHtml(Array.isArray(content_changes.suggested_additions) ? content_changes.suggested_additions.join('\n\n') : content_changes.suggested_additions)}</div>
                            </div>
                        ` : ''}
                        ${content_changes.suggested_edits ? `
                            <div>
                                <strong style="color: #1976D2; display: block; margin-bottom: 0.5rem;">✎ Suggested Edits:</strong>
                                <div style="padding-left: 1rem; line-height: 1.6;">${markdownToHtml(Array.isArray(content_changes.suggested_edits) ? content_changes.suggested_edits.join('\n\n') : content_changes.suggested_edits)}</div>
                            </div>
                        ` : ''}
                        ${!content_changes.suggested_additions && !content_changes.suggested_edits ? '<p style="color: var(--text-secondary);">No specific changes suggested</p>' : ''}
                    </div>
                </div>

                <!-- Review Warning -->
                <div style="margin-top: 1.5rem; padding: 1rem; background: #FFF4E5; border-left: 4px solid #FF9800; border-radius: 6px;">
                    <strong>⚠️ Review Required:</strong>
                    <p style="margin: 0.5rem 0 0 0; color: var(--text-secondary); font-size: 0.875rem;">
                        Please review the suggestions carefully. You can create a Pull Request with these changes,
                        which will require approval before merging.
                    </p>
                </div>
            </div>
            <div class="source-modal-footer" style="display: flex; gap: 1rem; justify-content: flex-end;">
                <button class="btn-secondary" onclick="this.closest('.source-modal').remove()">
                    Discard
                </button>
                <button class="btn-primary" onclick="createPullRequest('${escapeHtml(documentId)}', '${escapeHtml(documentTitle)}')">
                    <svg class="btn-icon" width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                    </svg>
                    Create Pull Request
                </button>
            </div>
        </div>
    `;

    document.body.appendChild(modal);

    // Close on background click
    modal.addEventListener('click', (e) => {
        if (e.target === modal) {
            modal.remove();
        }
    });
}

// Render metadata changes as structured list
function renderMetadataChanges(metadata) {
    if (!metadata || Object.keys(metadata).length === 0) {
        return '<p style="color: var(--text-secondary); font-size: 0.875rem;">No metadata changes suggested.</p>';
    }

    let html = '<div style="background: white; border: 1px solid var(--border); border-radius: 6px; padding: 1rem;">';

    // Search Keywords
    if (metadata.search_keywords && metadata.search_keywords.length > 0) {
        html += `
            <div style="margin-bottom: 1rem;">
                <strong style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.5rem;">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11 16 9.5 16 5.91 13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z"/>
                    </svg>
                    Search Keywords
                </strong>
                <div style="display: flex; flex-wrap: wrap; gap: 0.5rem;">
                    ${metadata.search_keywords.map(kw => `<span style="background: #E3F2FD; color: #1976D2; padding: 0.25rem 0.75rem; border-radius: 12px; font-size: 0.875rem;">${escapeHtml(kw)}</span>`).join('')}
                </div>
            </div>
        `;
    }

    // Glossary Terms
    if (metadata.glossary_terms && metadata.glossary_terms.length > 0) {
        html += `
            <div style="margin-bottom: 1rem;">
                <strong style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.5rem;">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M21 5c-1.11-.35-2.33-.5-3.5-.5-1.95 0-4.05.4-5.5 1.5-1.45-1.1-3.55-1.5-5.5-1.5S2.45 4.9 1 6v14.65c0 .25.25.5.5.5.1 0 .15-.05.25-.05C3.1 20.45 5.05 20 6.5 20c1.95 0 4.05.4 5.5 1.5 1.35-.85 3.8-1.5 5.5-1.5 1.65 0 3.35.3 4.75 1.05.1.05.15.05.25.05.25 0 .5-.25.5-.5V6c-.6-.45-1.25-.75-2-1zm0 13.5c-1.1-.35-2.3-.5-3.5-.5-1.7 0-4.15.65-5.5 1.5V8c1.35-.85 3.8-1.5 5.5-1.5 1.2 0 2.4.15 3.5.5v11.5z"/>
                    </svg>
                    Glossary Terms
                </strong>
                <div style="display: flex; flex-wrap: wrap; gap: 0.5rem;">
                    ${metadata.glossary_terms.map(term => `<span style="background: #F3E5F5; color: #7B1FA2; padding: 0.25rem 0.75rem; border-radius: 12px; font-size: 0.875rem;">${escapeHtml(term)}</span>`).join('')}
                </div>
            </div>
        `;
    }

    // Related Documents
    if (metadata.related_documents && metadata.related_documents.length > 0) {
        html += `
            <div style="margin-bottom: 1rem;">
                <strong style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.5rem;">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M3 13h2v-2H3v2zm0 4h2v-2H3v2zm0-8h2V7H3v2zm4 4h14v-2H7v2zm0 4h14v-2H7v2zM7 7v2h14V7H7z"/>
                    </svg>
                    Related Documents
                </strong>
                <div style="display: flex; flex-wrap: wrap; gap: 0.5rem;">
                    ${metadata.related_documents.map(doc => `<span style="background: #E8F5E9; color: #388E3C; padding: 0.25rem 0.75rem; border-radius: 12px; font-size: 0.875rem; font-family: monospace;">${escapeHtml(doc)}</span>`).join('')}
                </div>
            </div>
        `;
    }

    // Prerequisites
    if (metadata.prerequisites && metadata.prerequisites.length > 0) {
        html += `
            <div style="margin-bottom: 1rem;">
                <strong style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.5rem;">
                    Prerequisites
                </strong>
                <ul style="margin: 0; padding-left: 1.5rem; color: var(--text-secondary); font-size: 0.875rem;">
                    ${metadata.prerequisites.map(prereq => `<li>${escapeHtml(prereq)}</li>`).join('')}
                </ul>
            </div>
        `;
    }

    // Learning Outcomes
    if (metadata.learning_outcomes && metadata.learning_outcomes.length > 0) {
        html += `
            <div style="margin-bottom: 1rem;">
                <strong style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.5rem;">
                    Learning Outcomes
                </strong>
                <ul style="margin: 0; padding-left: 1.5rem; color: var(--text-secondary); font-size: 0.875rem;">
                    ${metadata.learning_outcomes.map(outcome => `<li>${escapeHtml(outcome)}</li>`).join('')}
                </ul>
            </div>
        `;
    }

    // Other metadata
    if (metadata.other_metadata && Object.keys(metadata.other_metadata).length > 0) {
        html += `
            <div>
                <strong style="margin-bottom: 0.5rem; display: block;">Other Improvements</strong>
                <ul style="margin: 0; padding-left: 1.5rem; color: var(--text-secondary); font-size: 0.875rem;">
                    ${Object.entries(metadata.other_metadata).map(([key, value]) =>
                        `<li><strong>${escapeHtml(key)}:</strong> ${escapeHtml(String(value))}</li>`
                    ).join('')}
                </ul>
            </div>
        `;
    }

    html += '</div>';
    return html;
}

// HTML escape helper
function escapeHtml(text) {
    if (typeof text !== 'string') return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Render diff view
function renderDiff(changes) {
    if (!changes || typeof changes !== 'string') {
        return '<p style="color: var(--text-secondary);">No specific changes provided.</p>';
    }

    // Convert markdown changes to HTML
    const html = markdownToHtml(changes);

    return `<div class="diff-view">${html}</div>`;
}

// Create Pull Request
async function createPullRequest(documentId, documentTitle) {
    showLoadingModal('Creating Pull Request on GitHub...');

    try {
        const response = await fetch(`${CONFIG.apiEndpoint.replace('/ask', '/create-pr')}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                document_id: documentId,
                suggestions: window.currentSuggestions
            })
        });

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({ error: 'Unknown error' }));
            throw new Error(errorData.error || `HTTP ${response.status}`);
        }

        const data = await response.json();

        // Close loading modal
        document.querySelector('.source-modal')?.remove();

        // Show success with PR link
        showPRSuccess(data.pr_url, documentTitle);

    } catch (error) {
        console.error('Error creating PR:', error);
        document.querySelector('.source-modal')?.remove();

        showError(`Failed to create Pull Request: ${error.message}\n\nNote: This feature requires GitHub API integration to be configured.`);
    }
}

// Show PR success
function showPRSuccess(prUrl, documentTitle) {
    const modal = document.createElement('div');
    modal.className = 'source-modal';

    modal.innerHTML = `
        <div class="source-modal-content">
            <div class="source-modal-header">
                <h3>✅ Pull Request Created!</h3>
                <button class="close-modal" onclick="this.closest('.source-modal').remove()">×</button>
            </div>
            <div class="source-modal-body" style="text-align: center; padding: 2rem;">
                <svg width="80" height="80" viewBox="0 0 24 24" fill="none" style="margin-bottom: 1.5rem;">
                    <circle cx="12" cy="12" r="10" stroke="var(--success)" stroke-width="2" fill="none"/>
                    <path d="M8 12l2 2 4-4" stroke="var(--success)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>

                <p style="font-size: 1.125rem; margin-bottom: 1.5rem;">
                    Your suggested improvements for <strong>${documentTitle}</strong> have been submitted as a Pull Request!
                </p>

                <p style="color: var(--text-secondary); margin-bottom: 2rem;">
                    A team member will review your suggestions and merge them if approved.
                </p>

                <a href="${prUrl}" target="_blank" rel="noopener" class="btn-primary" style="display: inline-flex; align-items: center; gap: 0.5rem; text-decoration: none;">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                    </svg>
                    View Pull Request
                </a>
            </div>
        </div>
    `;

    document.body.appendChild(modal);

    modal.addEventListener('click', (e) => {
        if (e.target === modal) {
            modal.remove();
        }
    });
}

// Focus on input when page loads
window.addEventListener('load', () => {
    queryInput.focus();
});
