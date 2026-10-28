## Contract mismatches

All three recorded responses violate the contract. Seven distinct findings are listed below, in order of severity.

| # | Recording | Field / aspect | Contract says | Observed | Severity |
|---|-----------|----------------|---------------|----------|----------|
| 1 | 3 | HTTP status | Only 201 and 400 are defined for POST /orders | 500 | High |
| 2 | 3 | Error body shape | `Error` requires `code` and `message` | `{"error": ...}` with neither field | High |
| 3 | 3 | Error content | Not specified, but the message leaks a Postgres type and column width | `value too long for type character varying(500)` | High (information disclosure) |
| 4 | 3 | `NewOrder.note` length | `type: string`, no `maxLength`, so 5,000 characters is a valid request | Rejected at the database layer | High (contract and implementation disagree) |
| 5 | 1 | `Order.total` | `type: number` | `"42.50"`, a JSON string | Medium |
| 6 | 1 | `Order.note` | `type: string`, not `nullable`, not required | `null` | Medium |
| 7 | 2 | `Error.code` | Required | Absent | Medium |

Details on each:

- **Finding 1 and 2.** A contract-valid request produced an undocumented 5xx with an undocumented body. Either a real crash path or an unhandled database constraint error. Clients that branch on the `Error` schema will fail to parse it.
- **Finding 3.** The raw database error is passed through to the client. This should be masked regardless of how finding 4 is resolved.
- **Finding 4.** The server enforces a 500-character limit that the contract does not declare. One of two fixes is needed. Either add `maxLength: 500` to `note` in both `NewOrder` and `Order` and return 400 with a proper `Error` body, or widen the column. The owning team must decide. I assume the 500-character limit is intentional and the contract is what needs updating.
- **Finding 5.** A string total breaks numeric clients and any downstream arithmetic. Note that `type: number` for money is itself fragile because of floating-point rounding. Consider `multipleOf: 0.01` or integer minor units in a future version. That is a separate contract change, not a staging bug.
- **Finding 6.** OpenAPI 3.0.3 does not allow `null` for a non-nullable string. The server should omit the property when there is no note, or the contract should add `nullable: true`.
- **Finding 7.** The 404 body is missing the required `code` field. Consumers cannot distinguish error kinds programmatically.

Things the recordings do not tell me, with my assumptions:

- Response `Content-Type` headers were not recorded. I assume `application/json` was sent correctly.
- Order 999999 is assumed to simply not exist, rather than being rejected for some other reason.
- The 5,000-character note is assumed to be plain ASCII. If it contained multi-byte characters, the character versus byte counting question becomes a separate test case, covered below.
- The deployed build is assumed to be the one the 2.1.0 contract describes, so these are implementation defects rather than version drift.

## Contract gaps worth closing

These are not mismatches, but the contract is silent on cases the server will certainly see:

- No response is defined for an invalid path parameter such as `/orders/0`, `/orders/-1`, or `/orders/abc`. The `minimum: 1` constraint has no documented failure mode.
- No response is defined for a malformed JSON body or a wrong `Content-Type` on POST.
- No 5xx is documented anywhere. That is acceptable only if the tests prove a 5xx is unreachable with contract-valid input, which recording 3 already disproves.
- `NewOrder` does not set `additionalProperties: false`, so it is undefined whether unknown fields are ignored or rejected.
- `Order.status` after creation is unspecified. I assume `placed`.

## Test design

The suite has four layers. Every test asserts three things on every response: status code is one the contract lists for that operation, `Content-Type` is `application/json`, and the body validates against the referenced schema. Schema validation should be done with a real OpenAPI validator against the spec file, not with hand-written assertions, so the contract stays the single source of truth.

### Layer 1: Schema conformance (regression for the findings above)

GET /orders/{id}:

1. Existing order returns 200 and the body validates against `Order`. Explicitly assert `total` is a JSON number, not a string. Covers finding 5.
2. Existing order with no note omits the `note` key entirely, or the contract is amended first. Covers finding 6.
3. Existing order with a note returns it as a string.
4. Each enum value of `status` round-trips. Requires fixture orders in `placed`, `paid`, and `shipped` states.
5. Nonexistent id returns 404 with a body that validates against `Error`, including `code`. Covers finding 7.

POST /orders:

6. Minimal valid body with one item returns 201, body validates against `Order`, `status` is `placed`.
7. Valid body with a note returns 201 and the note is echoed unchanged.
8. Valid body without a note returns 201 and the response omits `note`.

### Layer 2: Input validation boundaries

Path parameter:

9. `id` of `0` and `-1` are rejected with the status the contract will define. Today the expected value is unknown, so the test should assert "not 200 and not 5xx" until the contract is fixed.
10. Non-integer ids such as `abc`, `1.5`, and `1e3` are rejected the same way.
11. An id above the 64-bit signed range, such as `99999999999999999999`, returns a 4xx rather than a 500 from an integer overflow.
12. Leading zeros and signs such as `0042` and `+42` are handled consistently. Document whichever behaviour is chosen.

Request body, `items`:

13. Missing `items` returns 400 with `Error`.
14. Empty array returns 400, enforcing `minItems: 1`.
15. Non-array `items` such as a string or object returns 400.
16. Array containing a non-string such as a number or `null` returns 400.
17. Very large array, for example 10,000 items, returns either 201 or 400, never 500. This probes an undeclared upper bound the same way recording 3 did.

Request body, `note`:

18. Note of exactly 500 characters returns 201. Boundary just inside the limit.
19. Note of 501 characters returns 400 with `Error`, never 500. Direct regression for findings 1 through 4.
20. Note of 5,000 characters returns 400 with `Error`. Reproduces the recording exactly.
21. Note of 500 multi-byte characters, for example 500 emoji or CJK characters, returns 201. Verifies the limit counts characters, not bytes, matching Postgres `varchar(n)` semantics. If any proxy or ORM counts bytes, this is where it surfaces.
22. Empty string note returns 201 and is distinguishable from an absent note.
23. Note set to `null` in the request returns 400, or 201 with the note omitted. The contract must pick one.
24. Non-string note such as a number returns 400.

Request envelope:

25. Malformed JSON returns 400, not 500.
26. Empty body returns 400.
27. `Content-Type: text/plain` with a JSON body returns 400 or 415, not 500.
28. Unknown top-level fields are either ignored or rejected. Assert whichever the contract chooses once `additionalProperties` is specified.

### Layer 3: Error response hygiene

29. For every 4xx and 5xx produced by the suite, the body validates against `Error`. Covers findings 2 and 7 in one sweep.
30. No error body contains any of: `character varying`, `relation`, `syntax error`, `constraint`, `Traceback`, `at line`, or a stack frame pattern. Covers finding 3 and guards against future leaks.
31. No contract-valid request anywhere in the suite ever produces a 5xx.

### Layer 4: Property-based and generative tests

32. Run Schemathesis or an equivalent tool against the spec. It generates requests from the schema and checks every response against the declared status codes and bodies. This would have caught all seven findings automatically.
33. Add a Hypothesis-style property for POST: any body that validates against `NewOrder` yields a 201 whose body validates against `Order`, and a subsequent GET of the returned id yields an equal `Order`. This is the round-trip invariant.
34. Add the inverse property: any body that fails `NewOrder` validation yields exactly 400 with a valid `Error`.

### Fixtures and environment

- Seed at least one order per `status` value, one with a note, one without, and one with a note of exactly 500 characters.
- Use a known-absent id for 404 tests rather than a large guess. Either query the max id and add one, or reserve a sentinel.
- Run the suite against a fresh database per run so POST tests do not accumulate state.
- Pin the contract file to the deployed version and fail the suite if `info.version` in the served spec does not match the version under test.

### Suggested order of work

1. Fix findings 1 through 4 together, since they share one code path. Add `maxLength: 500` to the contract, validate before the database write, return 400 with `Error`.
2. Fix findings 5 and 6 in the serializer. These are one-line changes.
3. Fix finding 7 in the not-found handler.
4. Land the Layer 1 and Layer 3 tests with the fixes so each finding has a regression test.
5. Add Layers 2 and 4 once the contract gaps above are decided, because several of those tests cannot assert a specific status until the contract defines one.
