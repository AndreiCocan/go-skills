---
name: aip
description: >
  Expert skill for designing and implementing APIs that follow Google's API Improvement Proposals
  (AIPs, aip.dev) — both the API definition (proto/IDL) and the service behind it (validation, resource-name
  parsing, pagination, field masks, defaults, error mapping). Enforces an index-first research loop and makes
  MUST rules silent while every SHOULD/MAY rule is raised with the user. Use when designing, implementing,
  reviewing, or refactoring any resource-oriented / gRPC / REST API or its service.
---

# Google AIP-Conformant API Design & Implementation

Design and implement **against the live spec** at https://google.aip.dev — never from memory — and let the
**user own every non-mandatory rule**. Applies to both the API definition and the service that implements it;
many AIP rules are runtime behavior (invalid page tokens must fail, page size must be capped not rejected,
unknown update-mask fields ignored) that only the service can enforce.

## When to Activate

- Designing resources, methods, fields, or messages under AIP conventions
- Implementing service logic AIPs govern: request validation, resource-name parse/validate, page-token and
  page-size handling, field masks (`update_mask`), etag/idempotency, filtering, and error/status mapping
- Reviewing or refactoring either the definition or the service for AIP conformance

## Research Loop — run EVERY time you face a decision

Never answer, write a proto, write service code, or recommend until you finish this loop for *that* question.
Re-run it per question; don't assume last question's reading still applies.

1. **Search the index first.** Read it live — the contents and grouping change, so don't trust remembered AIP
   numbers. Index: **https://google.aip.dev/general**. Individual AIP: **`https://google.aip.dev/{number}`**.
   Collect every AIP that could plausibly apply.
2. **List the candidate AIPs to the user** before going deep, so they can steer or add context.
3. **Read deeply, following EVERY link.** AIPs are a hypertext web; a rule usually depends on definitions on a
   linked page. Keep following links until they stop changing your understanding — the key constraint is often
   one link away.
4. **Extract each relevant rule and tag it** by RFC 2119 keyword — including behavioral rules the service must
   enforce: MUST/MUST NOT, SHOULD/SHOULD NOT, MAY.

## Applying rules: MUST is silent, SHOULD and MAY are the user's call

- **MUST / MUST NOT →** apply automatically (in the definition and in the service that enforces it). No need to
  ask; just note the AIP citation so it's traceable.
- **SHOULD / SHOULD NOT / MAY →** ask the user, **every single time**, before adopting or skipping. Use
  `AskUserQuestion`, one rule per question (or a tight batch). For each: quote the exact rule + AIP number, say
  whether it's SHOULD or MAY, what adopting it means concretely, the trade-off, and "do you want this in your
  API/service?". You may recommend a default, but the choice is theirs. Never silently apply a recommendation.

## Keep AIP references OUT of shipped code

Citations are for the conversation, not the artifact. **Proto and service comments describe behavior in domain
terms**, never `// Per AIP-158…`. Write `// Max books to return. Defaults to 50; values above 1000 are capped.`
Put the AIP number and MUST/SHOULD/MAY classification only in your message to the user and any design notes.

For each decision, tell the user: the **AIP number**, whether it was a **MUST** (applied) or **SHOULD/MAY**
(user-approved), whether it lands in the **definition** or the **service**, and a one-line rationale.

## Anti-Patterns

- Working from memory, or reusing last question's research for a new one.
- Treating this as proto-only — enforce the runtime rules in the service too.
- Skipping the index search, or trusting a remembered AIP-number map.
- Reading one page and stopping instead of following links to closure.
- Silently applying a SHOULD or MAY — always ask.
- Putting AIP numbers in shipped proto/service comments.
- Citing an AIP without quoting the rule (means you didn't read it closely).
