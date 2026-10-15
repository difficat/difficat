#!/usr/bin/env sh
# Adds DiffiCat to Claude Code as a remote MCP server.
claude mcp add --transport http difficat https://app.difficat.com/mcp

# Paying from a prepaid or Pro key instead of the daily allowance? Add the key
# once as a header; every keyed call is billed.
#
#   claude mcp add --transport http --header "Authorization: Bearer $DIFFICAT_KEY" difficat https://app.difficat.com/mcp
