---
name: simplify
description: "Only when there is no choice will he work with complexity"
---

# The Way of Simplification

## Philosophy
Every line of code is debt. Every component is friction.
The best code is code that was never written.

## Process

### Step 1: Observe Without Judgment
Launch Explore agent to understand the current state:
- Map component dependencies
- Identify similar/duplicate patterns
- Find code that exists "just in case"

### Step 2: Question Necessity
For each component found, ask:
- Is this solving a real problem or an imagined one?
- Could an existing component do this with minor modification?
- What would break if this didn't exist?

### Step 3: Propose Consolidation
- Group similar components
- Identify the "essence" - the core that must remain
- Suggest removals with safety validation

### Step 4: Execute with Care
- Make changes one component at a time
- Build after each change
- Commit frequently with clear messages

## Mantra
"Source does nothing, yet through it all things are done."
