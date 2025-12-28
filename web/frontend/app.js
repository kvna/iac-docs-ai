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
function openSourceFile(source) {
    // GitHub repository URL
    const githubBaseUrl = 'https://github.com/kvna/iac-docs-ai/blob/main/docs/';

    console.log('Opening source:', source);

    // Try to reconstruct the full path from document_id
    const docId = source.document_id || '';
    const docType = source.document_type || '';

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

    // Construct the full GitHub URL
    const githubUrl = githubBaseUrl + fullPath;

    console.log('GitHub URL:', githubUrl);

    // Open GitHub link in new tab
    window.open(githubUrl, '_blank', 'noopener,noreferrer');
}

// Show source information modal
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

// Focus on input when page loads
window.addEventListener('load', () => {
    queryInput.focus();
});
