---
name: audit
description: Run all iOS quality audits in parallel
---

# The Craft Audit

## Process
Launch these Axiom auditors in parallel:

1. **axiom:concurrency-validator** - Swift 6 concurrency safety
2. **axiom:swiftui-performance-analyzer** - Performance anti-patterns
3. **axiom:accessibility-auditor** - A11y compliance
4. **axiom:memory-audit-runner** - Memory leak detection

## After Audits Complete
1. Prioritize findings by severity
2. Create TodoWrite items for each fix
3. Address critical issues before shipping

## Quick Commands
```
/axiom:audit-concurrency
/axiom:audit-swiftui-performance
/axiom:audit-accessibility
/axiom:audit-memory
```
