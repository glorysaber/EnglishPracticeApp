# AGENT WORKFLOW GUIDELINES

- **Approval Required:**
  - Every code change
  - Before builds/tests/commits
  - Present changes one at a time

- **Integration Points:**
  - Shared/ directory modifications
  - Model changes
  - Service layer updates
  - Require pre-approval

- **One Type Per File:**
  - One primary type (class/struct/enum/protocol) per file
  - Extensions in separate files
  - New types approved individually

- **Change Presentation:**
  - Explain: Purpose + Architecture fit
  - List: Side effects + Testing
  - Provide: Before/after code snippets

- **Additional Rules:**
  - Security: Approve user data/auth changes
  - Error handling: Add patterns for all new code
  - Performance: Benchmark UI/algorithm changes
  - Tests: Generate unit tests automatically
  - Accessibility: Check VoiceOver/Dynamic Type
  - Documentation: Update for API changes
  - Dependencies: No circular references
  - Git: Feature branches + descriptive commits
