Ten CI runs of the e2e suite (120 tests) on the same commit, c0ffee1, on main. Playwright, 4 workers, retries 0. P = passed, F = failed.

| Test | R1 | R2 | R3 | R4 | R5 | R6 | R7 | R8 | R9 | R10 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| cart > updates the total when the quantity changes | P | F | P | P | F | P | P | P | F | P |
| profile > saves a new avatar | F | F | F | F | F | F | F | F | F | F |
| search > filters results by tag | P | F | P | F | P | P | F | P | P | F |
| orders > shows the latest order first | P | P | F | P | P | P | P | F | P | P |
| login > signs in with valid credentials | P | P | P | P | P | P | P | P | P | P |

Failure messages (the same message in every failed run of that test):

- cart > updates the total when the quantity changes: expect(received).toBe(expected). Expected: "€58.00". Received: "€29.00". The test clicks "+", waits with page.waitForTimeout(300), then reads the total once with textContent() and compares it.
- profile > saves a new avatar: expect(received).toBe(expected). Expected: "avatar.png". Received: undefined.
- search > filters results by tag: expected 3 results, received 5. Run alone (npx playwright test search.spec.ts --workers=1 --repeat-each=20) it passed 20 of 20. It uses the seeded tag "summer", which tags.spec.ts renames during its own run.
- orders > shows the latest order first: Expected "Order #1043", Received "Order #1042". A --repeat-each=50 run of this spec alone, with web-first assertions and a new user for every run, failed 3 of 50; in those runs GET /orders returned the list without the new order for up to 2 seconds after the order was created.
