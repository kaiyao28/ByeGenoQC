# Contributing to ByeGenoQC

Thank you for considering contributing to ByeGenoQC! Whether you've found a bug, want to suggest an enhancement, or propose a new feature, we welcome your feedback and contributions.

## How to Report a Bug

If you encounter an issue:

1. **Check existing issues** — search [GitHub Issues](https://github.com/kaiyao28/ByeGenoQC/issues) to see if it's already been reported
2. **Create a new issue** using the [bug report template](https://github.com/kaiyao28/ByeGenoQC/issues/new?template=bug_report.md)
3. **Include details:**
   - Your operating system and version
   - Nextflow and Java versions (`nextflow -version`, `java -version`)
   - Docker or container engine version
   - The exact command you ran
   - Error message and `.nextflow.log` file (if available)
   - Input data summary (number of samples, variants, file size)

## How to Suggest an Enhancement

If you have an idea for improvement:

1. **Check existing issues** — your idea may already be under discussion
2. **Create a new issue** using the [feature request template](https://github.com/kaiyao28/ByeGenoQC/issues/new?template=feature_request.md)
3. **Describe:**
   - The problem you're trying to solve
   - Your proposed solution
   - Why this enhancement would be useful
   - Any relevant examples or use cases

## How to Contribute Code

We appreciate code contributions! Here's the workflow:

### 1. Fork and clone the repository

```bash
git clone https://github.com/your-username/ByeGenoQC.git
cd ByeGenoQC
```

### 2. Create a feature branch

```bash
git checkout -b feature/your-feature-name
```

### 3. Make your changes

- Keep commits atomic and well-described
- Test your changes with the smoke tests:
  ```bash
  bash test_data/run_smoke_tests.sh
  ```
- Update documentation if your changes affect user-facing behavior

### 4. Push and create a pull request

```bash
git push origin feature/your-feature-name
```

Then [open a pull request](https://github.com/kaiyao28/ByeGenoQC/compare) with:
- A clear title and description
- Reference to any related issues
- A summary of what changed and why

### 5. Code review

Maintainers will review your PR, request changes if needed, and merge once approved.

## Development Setup

To develop locally:

```bash
# Clone the repository
git clone https://github.com/kaiyao28/ByeGenoQC.git
cd ByeGenoQC

# Install Nextflow (if not already installed)
curl -s https://get.nextflow.io | bash
mkdir -p ~/bin && mv nextflow ~/bin/
export PATH=$HOME/bin:$PATH

# Install Docker or use your container engine of choice
# See docs/setup.md for platform-specific instructions

# Run smoke tests
bash test_data/run_smoke_tests.sh
```

## Code Style and Conventions

- **Nextflow:** Follow nf-core style guidelines where applicable
- **Bash scripts:** Use shellcheck-compatible syntax
- **Comments:** Add comments to explain WHY, not WHAT (code should be self-explanatory)
- **Naming:** Use descriptive, kebab-case names for processes and variables

## Testing Your Changes

Before submitting a PR:

1. Run the smoke test suite:
   ```bash
   bash test_data/run_smoke_tests.sh
   ```

2. Test with your own data if possible

3. Verify the reports are generated and look sensible

## Documentation

If your changes affect:
- **User workflows** — update the relevant manual (SNP array or WGS/WES)
- **Setup or installation** — update `docs/setup.md`
- **Parameters** — update the manual's parameter reference section
- **New features** — add a note to CHANGELOG.md under Unreleased

## Licensing

By contributing to ByeGenoQC, you agree that your contributions will be licensed under the MIT License.

## Questions?

Feel free to open an issue or discussion on [GitHub](https://github.com/kaiyao28/ByeGenoQC/issues) with any questions about contributing.

Thank you for helping make ByeGenoQC better! 🎉
