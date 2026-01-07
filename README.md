# CV Repository

This repository contains my CV in both Portuguese and English, built with [RenderCV](https://rendercv.com) and automatically deployed to GitHub Pages.

## Overview

The CVs are automatically built and deployed through specialized GitHub Actions workflows:
- **Build**: Compiles CVs from YAML sources
- **Deploy**: Publishes to GitHub Pages with a language selection interface
- **Release**: Creates versioned releases with CV PDFs as downloadable assets

## Structure

```
cv-repo/
├── languages/
│   ├── en.yaml                       # English CV configuration
│   └── pt.yaml                       # Portuguese CV configuration
├── .github/workflows/
│   ├── build.yaml                    # Reusable CV build workflow
│   ├── deploy-pages.yaml             # Reusable Pages deployment
│   ├── release.yaml                  # Reusable GitHub Release
│   └── deploy-and-release.yaml       # Deploy + Release on tags
├── build.sh                          # Local build script
├── .gitignore
└── README.md
```

## Workflows

### Workflow Architecture

All workflows are composable and reusable. The build workflow is the foundation, called by all others:

```
                    ┌─────────────────────┐
                    │   build.yaml        │◄──────────┐
                    │   (Foundation)      │           │
                    └──────────┬──────────┘           │
                               │                      │
                ┌──────────────┼──────────────┐      │
                │              │              │      │
                ▼              ▼              ▼      │
     ┌──────────────┐  ┌──────────────┐  ┌──────────┴──────┐
     │ deploy-pages │  │   release    │  │ deploy-and-     │
     │   .yaml      │  │    .yaml     │  │ release.yaml    │
     │  (Reusable)  │  │  (Reusable)  │  │  (Orchestrator) │
     └──────┬───────┘  └──────────────┘  └─────────────────┘
            │                                      │
            │              ┌───────────────────────┤
            │              │                       │
            │         ┌────▼────┐            ┌────▼────┐
            │         │ deploy- │            │ create- │
            │         │  pages  │───────────►│ release │
            │         └─────────┘  (passes   └─────────┘
            │                       pages_url)
            │
     GitHub Pages Deployment
     (on push to main)
```

**Trigger Summary**:
- **Push to `main`** → `deploy-pages.yaml` runs
- **Push tag `v*.*.*`** → `deploy-and-release.yaml` runs (calls both deploy + release)
- **Manual dispatch** → Any workflow can be triggered manually

### 🔨 Build Workflow (`build.yaml`)

**Purpose**: Compiles CV PDFs from YAML source files using custom output paths.

**Triggers**:
- Push to `main` branch (when `languages/` changes)
- Pull requests (when `languages/` changes)
- Called by other workflows

**Features**:
- ✅ Uses RenderCV's `--pdf-path` for direct output to artifacts
- ✅ No file copying needed - outputs directly to destination
- ✅ Skips unnecessary HTML/Markdown/PNG generation
- ✅ Includes verification step to ensure PDFs exist
- ✅ Generates comprehensive build metadata
- ✅ Shows file sizes in build summary

**Outputs**:
- `cv_en.pdf` - English CV
- `cv_pt.pdf` - Portuguese CV
- `metadata.json` - Build information (commit, timestamp, actor, etc.)
- Artifacts retained for 90 days

**Usage as reusable workflow**:
```yaml
jobs:
  build:
    uses: ./.github/workflows/build.yaml
```

The workflow outputs `artifact-name`, `en-pdf-name`, and `pt-pdf-name` for downstream workflows.

### 🚀 Deploy Pages Workflow (`deploy-pages.yaml`)

**Purpose**: Deploys CVs to GitHub Pages with a language selection interface.

**Triggers**:
- Push to `main` branch (when `languages/` or workflows change)
- Manual dispatch (`workflow_dispatch`)
- Called by other workflows (`workflow_call`)

**Features**:
- ✅ Reusable workflow via `workflow_call`
- ✅ Calls the build workflow
- ✅ Creates beautiful landing page with language selection
- ✅ Deploys to GitHub Pages
- ✅ Outputs `pages_url` for downstream workflows

**Deployment URLs**:
- Landing page: `https://[username].github.io/[repo]/`
- English CV: `https://[username].github.io/[repo]/en.pdf`
- Portuguese CV: `https://[username].github.io/[repo]/pt.pdf`

**Usage as reusable workflow**:
```yaml
jobs:
  deploy:
    uses: ./.github/workflows/deploy-pages.yaml
    permissions:
      contents: read
      pages: write
      id-token: write
```

### 📦 Release Workflow (`release.yaml`)

**Purpose**: Creates GitHub releases with CV PDFs as downloadable assets.

**Triggers**:
- Manual dispatch with custom tag name (`workflow_dispatch`)
- Called by other workflows (`workflow_call`)

**Features**:
- ✅ Reusable workflow via `workflow_call`
- ✅ Calls the build workflow
- ✅ Generates comprehensive release notes with GitHub Pages links
- ✅ Attaches CV PDFs as release assets
- ✅ Includes README with build information
- ✅ Accepts `pages_url` input to link to online viewing

**Release notes include**:
- 🌐 View online links (GitHub Pages)
- 📥 Download links (Release assets)
- 📦 Build metadata and commit information
- 📝 Recent changes (for tag-based releases)

**Usage as reusable workflow**:
```yaml
jobs:
  release:
    uses: ./.github/workflows/release.yaml
    with:
      tag_name: v1.0.0
      prerelease: false
      pages_url: https://user.github.io/repo/
    permissions:
      contents: write
```

### 🎯 Deploy and Release Workflow (`deploy-and-release.yaml`)

**Purpose**: Automated deployment and release creation when pushing version tags.

**Triggers**:
- Push tags matching `v*.*.*` (e.g., `v1.0.0`, `v2.1.3`)

**Features**:
- ✅ Calls deploy-pages workflow first
- ✅ Passes Pages URL to release workflow
- ✅ Creates release with direct links to online viewing
- ✅ Atomic operation for tags - deploys and releases together

**Workflow**:
```yaml
1. Deploy to GitHub Pages
   ↓
2. Get Pages URL
   ↓
3. Create Release with Pages links
```

**Creating a versioned release**:

```bash
# Create and push a tag
git tag -a v1.0.0 -m "Initial CV release"
git push origin v1.0.0

# The workflow automatically:
# 1. Builds CVs
# 2. Deploys to GitHub Pages
# 3. Creates GitHub Release with:
#    - Links to view online (Pages)
#    - PDF downloads (Assets)
```

## Local Development

### Prerequisites

- Python 3.12+
- Virtual environment (recommended)

### Setup

1. Create and activate a virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install RenderCV with full dependencies:
```bash
pip install "rendercv[full]"
```

### Building CVs

**Option 1: Using the build script (recommended)**

```bash
./build.sh                  # Build to artifacts/
./build.sh output/          # Build to custom directory
```

The build script:
- ✅ Builds both English and Portuguese CVs
- ✅ Uses custom output paths to avoid copying
- ✅ Generates build metadata
- ✅ Shows summary with file sizes

**Option 2: Manual build with RenderCV**

Build both CVs with custom output locations:
```bash
mkdir -p artifacts

# English CV
rendercv render languages/en.yaml \
  --pdf-path artifacts/cv_en.pdf \
  --dont-generate-html \
  --dont-generate-markdown \
  --dont-generate-png

# Portuguese CV
rendercv render languages/pt.yaml \
  --pdf-path artifacts/cv_pt.pdf \
  --dont-generate-html \
  --dont-generate-markdown \
  --dont-generate-png
```

**Option 3: Simple build (default output)**

```bash
rendercv render languages/en.yaml
rendercv render languages/pt.yaml
```

The generated PDFs will be in `languages/rendercv_output/`.

### Custom Output Paths

RenderCV supports custom output paths for generated files:

```bash
# Output to specific location
rendercv render languages/en.yaml --pdf-path ~/Desktop/MyCV.pdf

# Output to current directory
rendercv render languages/en.yaml --pdf-path ./cv_en.pdf

# Skip unwanted outputs
rendercv render languages/en.yaml \
  --pdf-path ./cv.pdf \
  --dont-generate-html \
  --dont-generate-markdown \
  --dont-generate-png
```

### Local Testing

To test the complete GitHub Pages setup locally:

```bash
# Build CVs using the build script
./build.sh artifacts

# Create public directory for Pages simulation
mkdir -p public
cp artifacts/cv_en.pdf public/en.pdf
cp artifacts/cv_pt.pdf public/pt.pdf

# Serve locally
cd public
python -m http.server 8000
```

Then visit `http://localhost:8000` to test the language selection page.

## GitHub Setup

### Enable GitHub Pages

1. Go to your repository **Settings** → **Pages**
2. Under "Build and deployment", select:
   - **Source**: GitHub Actions
3. The workflow will automatically deploy on the next push to `main`

### Required Permissions

The workflows require the following permissions (configured in workflow files):
- `contents: read` - Read repository content
- `contents: write` - Create releases (release workflow only)
- `pages: write` - Deploy to GitHub Pages
- `id-token: write` - OIDC token for Pages deployment

## Language Routing

The deployed site includes intelligent language routing:

### Direct Links
- `https://[username].github.io/[repo]/` - Language selection page
- `https://[username].github.io/[repo]/en.pdf` - English CV
- `https://[username].github.io/[repo]/pt.pdf` - Portuguese CV

### Query Parameters
- `?lang=en` - Auto-redirects to English CV
- `?lang=pt` - Auto-redirects to Portuguese CV

### Optional: Automatic Browser Language Detection

The landing page includes commented-out code for automatic language detection. To enable it:

1. Edit `.github/workflows/deploy-pages.yaml`
2. Find the "Create index.html" step
3. Uncomment this section in the JavaScript:

```javascript
const userLang = navigator.language || navigator.userLanguage;
if (userLang.startsWith('pt')) {
    window.location.href = 'pt.pdf';
} else {
    window.location.href = 'en.pdf';
}
```

## Workflow Scenarios

### Updating Your CV

1. Edit `languages/en.yaml` and/or `languages/pt.yaml`
2. Commit and push:
   ```bash
   git add languages/
   git commit -m "Update professional experience"
   git push
   ```
3. Workflows automatically trigger:
   - ✅ Build workflow compiles PDFs
   - ✅ Deploy workflow publishes to GitHub Pages

### Creating a Versioned Release

**Option 1: Via Git Tag**
```bash
git tag -a v1.2.0 -m "Q4 2024 update"
git push origin v1.2.0
```

**Option 2: Via GitHub UI**
1. Go to **Actions** → **Create Release**
2. Click **Run workflow**
3. Enter tag name (e.g., `v1.2.0`)
4. Optionally mark as pre-release
5. Click **Run workflow**

**Result**: Creates a GitHub Release with:
- CV PDFs as downloadable assets
- Automatic release notes
- Build metadata
- Direct download links

### Testing Changes in Pull Requests

1. Create a feature branch:
   ```bash
   git checkout -b update-skills
   ```
2. Make changes to `languages/*.yaml`
3. Push and create a PR:
   ```bash
   git push origin update-skills
   ```
4. Build workflow runs automatically on PR
5. Download artifacts from workflow run to preview
6. Merge when ready

## Customization

### Changing the Theme

Edit the `design` section in `languages/en.yaml` or `languages/pt.yaml`:

```yaml
design:
  theme: classic  # Options: classic, sb2nov, moderncv, engineeringresumes
  colors:
    name: rgb(0, 79, 144)
    connections: rgb(0, 79, 144)
    section_titles: rgb(0, 79, 144)
    links: rgb(0, 79, 144)
```

### Customizing the Landing Page

The landing page is generated in the deploy workflow:

1. Edit `.github/workflows/deploy-pages.yaml`
2. Find the "Create index.html" step
3. Modify the HTML/CSS/JavaScript as needed
4. Commit and push to apply changes

### Adding More Languages

To add another language (e.g., Spanish):

1. **Create** `languages/es.yaml` with Spanish content
2. **Update** `.github/workflows/build.yaml`:
   ```yaml
   - name: Build Spanish CV
     run: rendercv render languages/es.yaml

   - name: Prepare artifacts
     run: |
       cp languages/rendercv_output/[Name]_CV.pdf artifacts/cv_es.pdf
   ```
3. **Update** `.github/workflows/deploy-pages.yaml`:
   ```yaml
   - name: Prepare deployment directory
     run: |
       cp artifacts/cv_es.pdf public/es.pdf
   ```
4. **Add button** to the landing page HTML
5. **Update** release workflow similarly

### Workflow Concurrency

The deploy workflow uses concurrency control to prevent simultaneous deployments:

```yaml
concurrency:
  group: "pages"
  cancel-in-progress: false
```

Modify `cancel-in-progress: true` if you want newer deployments to cancel older ones.

## Troubleshooting

### Workflow Failures

**Build fails**: Check that YAML files are valid
```bash
rendercv render languages/en.yaml --validate-only
```

**Deploy fails**: Ensure GitHub Pages is enabled and set to "GitHub Actions" source

**Release fails**: Check that you have write permissions and the tag doesn't already exist

### Viewing Workflow Logs

1. Go to **Actions** tab in GitHub
2. Click on a workflow run
3. Click on a job to see detailed logs
4. Download artifacts from the workflow summary

### Local Build Issues

**RenderCV not found**:
```bash
pip install "rendercv[full]"
```

**Font issues**: RenderCV uses Typst which bundles fonts, but you can add custom fonts if needed

## RenderCV Documentation

For more information about RenderCV configuration and customization:
- [RenderCV Documentation](https://docs.rendercv.com)
- [RenderCV User Guide](https://docs.rendercv.com/user_guide/)
- [RenderCV GitHub](https://github.com/rendercv/rendercv)

## License

This repository structure is free to use. Please ensure you customize the CV content with your own information.
