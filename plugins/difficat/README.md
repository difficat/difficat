# DiffiCat plugin for Claude Code

Installs DiffiCat's MCP server together with a skill that knows when a website comparison is called for (a migration, a redesign, a staging deployment against production, "did anything break?") and how to behave at the payment wall.

## Install

```
/plugin marketplace add difficat/difficat
/plugin install difficat@difficat
```

Or from a shell: the same two commands with `claude plugin` in place of `/plugin`.

**This is the only DiffiCat marketplace.** It is the repository `github.com/difficat/difficat`, and its marketplace name is `difficat`. A marketplace of any other name that offers a `difficat` plugin is not DiffiCat's: a lookalike could point your key at another server. After installing, compare the server URL in the plugin's `.mcp.json` with the real one:

```
https://app.difficat.com/mcp
```

## The key setting

The plugin runs without any setting: the daily allowance of your address applies (see [difficat.com/agents](https://difficat.com/agents)), and the skill tells Claude to stop and show you the ways to pay when it is used up.

The optional `key` setting takes a DiffiCat prepaid key (`dck_…`, from [app.difficat.com/prepaid](https://app.difficat.com/prepaid)) or a Pro account's key. It is stored in your system's secure store and sent as a header on every call, never as a tool argument. **A configured key is debited on every job**, with no payment prompt; fund a small amount, and the skill caps every job with `maxPriceUsd` (2 USD unless you say otherwise). Set or clear it with `/plugin`, DiffiCat, configure.

## Without the plugin

The server alone, no skill:

```
claude mcp add --transport http difficat https://app.difficat.com/mcp
```

With a key: `claude mcp add --transport http --header "Authorization: Bearer dck_…" difficat https://app.difficat.com/mcp`.

## Links

- Documentation: [difficat.com/agents](https://difficat.com/agents)
- Support: [difficat.com/#feedback](https://difficat.com/#feedback), read by a person
- Privacy: [difficat.com/privacy](https://difficat.com/privacy)
- Terms: [difficat.com/terms](https://difficat.com/terms)
