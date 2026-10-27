---
description: >-
  The same report and code as qa-static-analysis-triage, asked for in plain words with no skill
  named. It measures whether the skill's description makes Claude Code load it on a triage request.
expected_outcome: >-
  A triage of six findings: the two rules on src/users.ts line 6 folded into one true positive (SQL
  injection, fix with a parameterized query); src/users.ts line 13 a false positive (limit is a
  clamped integer); tests/seed.ts not reachable in production; the eval in src/legacy/report.ts
  already in the baseline and kept out of the gate; the any in generated code handled by excluding
  generated files, not by editing them; and a CI gate on new findings only.
tags: [qa-static-analysis, triage, triggering]
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

Semgrep and ESLint ran on our checkout service for the first time; we want both in CI.
The SARIF report and the files it points at are below. Triage the findings: for each one,
say whether it is a real problem and what we should do about it, then say how CI should gate
on these tools from now on.

## report.sarif

```json
{
  "version": "2.1.0",
  "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "Semgrep OSS",
          "version": "1.97.0"
        }
      },
      "results": [
        {
          "ruleId": "javascript.express.security.injection.tainted-sql-string",
          "level": "error",
          "message": {
            "text": "User input from an Express request flows into a manually built SQL string."
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "src/users.ts"
                },
                "region": {
                  "startLine": 6,
                  "snippet": {
                    "text": "const rows = await db.query(`SELECT id, name, email FROM users WHERE name = '${name}'`);"
                  }
                }
              }
            }
          ],
          "baselineState": "new"
        },
        {
          "ruleId": "javascript.lang.security.audit.sqli.node-postgres-sqli",
          "level": "error",
          "message": {
            "text": "Detected string concatenation or interpolation in a node-postgres query."
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "src/users.ts"
                },
                "region": {
                  "startLine": 6,
                  "snippet": {
                    "text": "const rows = await db.query(`SELECT id, name, email FROM users WHERE name = '${name}'`);"
                  }
                }
              }
            }
          ],
          "baselineState": "new"
        },
        {
          "ruleId": "javascript.lang.security.audit.sqli.node-postgres-sqli",
          "level": "error",
          "message": {
            "text": "Detected string concatenation or interpolation in a node-postgres query."
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "src/users.ts"
                },
                "region": {
                  "startLine": 13,
                  "snippet": {
                    "text": "const rows = await db.query(\"SELECT id, total FROM orders ORDER BY id DESC LIMIT \" + limit);"
                  }
                }
              }
            }
          ],
          "baselineState": "new"
        },
        {
          "ruleId": "javascript.lang.security.detect-child-process",
          "level": "warning",
          "message": {
            "text": "Detected a child_process call with a non-literal argument."
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "tests/seed.ts"
                },
                "region": {
                  "startLine": 5,
                  "snippet": {
                    "text": "execSync(`psql \"$TEST_DATABASE_URL\" -f tests/fixtures/${fixture}.sql`);"
                  }
                }
              }
            }
          ],
          "baselineState": "new"
        },
        {
          "ruleId": "javascript.browser.security.eval-detected",
          "level": "error",
          "message": {
            "text": "Detected the use of eval() on a non-literal value."
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "src/legacy/report.ts"
                },
                "region": {
                  "startLine": 3,
                  "snippet": {
                    "text": "return eval(expression.replace(/[a-z_]+/g, (key) => String(row[key] ?? 0)));"
                  }
                }
              }
            }
          ],
          "baselineState": "unchanged"
        }
      ]
    },
    {
      "tool": {
        "driver": {
          "name": "ESLint",
          "version": "9.13.0"
        }
      },
      "results": [
        {
          "ruleId": "@typescript-eslint/no-explicit-any",
          "level": "warning",
          "message": {
            "text": "Unexpected any. Specify a different type."
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "src/generated/api-client.ts"
                },
                "region": {
                  "startLine": 2,
                  "snippet": {
                    "text": "export async function getOrders(params: any): Promise<any> {"
                  }
                }
              }
            }
          ],
          "baselineState": "new"
        }
      ]
    }
  ]
}
```

## src/users.ts

```ts
import type { Request, Response } from "express";
import { db } from "./db";

export async function findUser(req: Request, res: Response) {
  const name = String(req.query.name);
  const rows = await db.query(`SELECT id, name, email FROM users WHERE name = '${name}'`);
  res.json(rows);
}

export async function recentOrders(req: Request, res: Response) {
  const requested = Number.parseInt(String(req.query.limit), 10);
  const limit = Number.isInteger(requested) ? Math.min(Math.max(requested, 1), 100) : 20;
  const rows = await db.query("SELECT id, total FROM orders ORDER BY id DESC LIMIT " + limit);
  res.json(rows);
}
```

## tests/seed.ts

```ts
import { execSync } from "node:child_process";

// Test-only helper: loads a fixture SQL file into the local test database before the suite.
export function seed(fixture: string) {
  execSync(`psql "$TEST_DATABASE_URL" -f tests/fixtures/${fixture}.sql`);
}
```

## src/legacy/report.ts

```ts
// Kept for the monthly finance export; its replacement is tracked in CHK-412.
export function computeColumn(expression: string, row: Record<string, number>) {
  return eval(expression.replace(/[a-z_]+/g, (key) => String(row[key] ?? 0)));
}
```

## src/generated/api-client.ts

```ts
// Code generated by openapi-generator 7.9.0. DO NOT EDIT.
export async function getOrders(params: any): Promise<any> {
  return fetch(`/api/orders?${new URLSearchParams(params)}`).then((r) => r.json());
}
```
