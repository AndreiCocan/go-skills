---
name: tdd
description: >
  Test-driven development. Language-agnostic. Use when the user wants to build features or fix bugs
  test-first, mentions "red-green-refactor" or "test driven development" or "tdd".
---

# Test-Driven Development

TDD is the red → green → refactor loop. This skill is the reference that makes that loop produce tests worth keeping: what a good test is, where tests go, the anti-patterns that quietly ruin a suite, and the rules of the loop itself. Every section applies on every cycle — consult them before and during the loop, not after.

When exploring the codebase first, read any project context file (`CONTEXT.md`, `CLAUDE.md`, ADRs) so your test names and interface vocabulary match the project's domain language, and respect existing decisions in the area you're touching.

## What a good test is

A good test verifies **behavior through a public interface**, not implementation details. The internals can change entirely; the test should not. It reads like a specification — the name alone ("user can checkout with a valid cart") tells you what capability exists — and it survives refactors because it never reaches inside the thing it tests.

Characteristics of a test worth keeping:

- Asserts on behavior a caller or user actually cares about.
- Exercises the public contract only — the same surface a real consumer would use.
- Survives internal refactors that don't change behavior.
- Describes **what**, not **how**.
- Fails for one reason — it pins down a single behavior.

## Seams — where tests go

A **seam** is a public boundary you test at: an interface where you can observe behavior without reaching inside. Seams exist at every level — a function signature, a module's exported API, an HTTP endpoint — and tests live at seams, never against internals.

**Choose the seams deliberately, and say which ones and why.** You can't test everything; naming the seams up front is how testing effort lands on the critical paths and the complex logic instead of being spread evenly over every trivial edge case. State the seam you're testing at as you go; confirm it with the user when it's ambiguous or expensive to get wrong, rather than treating every test as a negotiation.

Ask, when it isn't obvious: *"What's the public contract here, and which seams are worth pinning?"*

## The anti-patterns

Three failure modes account for most bad suites. Name them out loud when you spot them.

**Implementation-coupled.** The test asserts on *how* the code works instead of *what* it does — it mocks an internal collaborator, reaches a private method, checks that some function was called N times, or verifies through a side channel (reading a database row instead of reading the value back through the interface). Mocking your own types is the most common form: it turns the test into a mirror of the implementation, so it breaks on refactor while behavior is unchanged. The fix: assert on what the public contract returns or does, and verify state by reading it back through that same contract.

**Tautological.** The assertion recomputes the expected value the same way the code does, so it passes by construction and can never disagree with the code. Asserting that a sum equals `items.reduce(sum)`, comparing a constant to itself, or hand-deriving a snapshot with the code's own logic are all tautologies. The expected value must come from an **independent source of truth** — a known-good literal `15`, a worked example, or the spec — never "whatever the code happens to produce."

**Horizontal slicing — writing tests for behavior you haven't designed yet.** The anti-pattern is *design by bulk test*: when the shape of the code doesn't exist yet, writing all the tests first specifies *imagined* behavior, kills the feedback loop (each cycle should teach you the next test), and locks in a test structure before you understand the implementation. Work in **vertical slices** instead — one test → one implementation → repeat, each test a **tracer bullet** that responds to what the last cycle taught you.

This is about *discovery, not batch size.* When the behavior is already pinned down by an external source — a spec, a grammar, a standard, or existing legacy behavior you're characterizing — writing a batch of tests up front is *capture*, not guessing, and it's correct. See the next section.

## Be exhaustive where the behavior is specified

Vertical slicing keeps you honest while the design is still forming — it is **not** a licence to under-test well-defined logic. When a component has a fixed, knowable contract — a parser, a tokenizer, a validator, a state machine, a pricing rule — cover the space that actually defines its behavior:

- every branch of the grammar / rule set, valid **and** invalid inputs,
- boundary values and off-by-one edges,
- combinations that *interact*, not just each option once in isolation,
- the empty, malformed, and adversarial inputs a real caller will eventually send.

This is capture, not horizontal slicing: you're pinning behavior that's already specified, so enumerate it deliberately. A **table-driven** test (one row per case) or a **property-based** test (assert an invariant across generated inputs) is the right tool — both let you pile on cases without repeating structure. You can still grow the table one row per red → green cycle *or* batch the rows when characterizing a known spec; both are fine because the behavior isn't being guessed. For anything parser-like, a "happy path only" suite is a bug waiting to ship — coverage there should be thorough on purpose.

## Listen to the test

The difficulty of writing a test is design feedback, not an obstacle to push through. If a behavior is awkward to test — you need to mock five things, reach into internals, or stand up the whole world to check one rule — the design is usually telling you the boundary is in the wrong place. Prefer fixing the seam (inject the dependency, split the responsibility, extract the pure logic) over contorting the test to fit an awkward shape. Testability and good design are the same signal read from two directions.

## When to mock

Mock at **system boundaries only** — the places you don't own and can't run cheaply or deterministically:

- External services (payment, email, third-party APIs).
- Databases (and even here, prefer a real test database when practical).
- Time and randomness.
- The filesystem (sometimes).

Anything you own — your own types, internal collaborators — is not a boundary; mocking it is the implementation-coupled anti-pattern above. Design the real boundaries to be easy to fake: inject external dependencies rather than constructing them inside the code under test, and prefer small, specific interfaces (one operation per method) over one generic do-everything call — a specific interface fakes to a single fixed shape with no conditional logic in the test setup.

## Rules of the loop

- **Red before green.** Write the failing test first and *watch it fail for the right reason* — a real assertion failure, not a compile error or a test that passes on the first run (either means the test proves nothing). Then write only enough code to pass it; don't anticipate future tests or add speculative features.
- **One slice at a time.** One seam, one test, one minimal implementation per cycle.
- **Refactor — after green only.** With the test passing: remove duplication, improve names, extract helpers. Keep tests green. Don't add behavior — new behavior needs a new red test. Larger structural rework is a separate pass, not this beat.
