# Changelog

## Unreleased

- **Fix**: Patch tool call id validation to ensure strict 9-char alphanumeric format when using function calls.
  - **Workaround**: Middleware `~/openclaw/middleware/toolcall-id-sanitizing.js` ensures tool call IDs match OpenAI’s a-z,A-Z,0-9[9] requirements to prevent 400 errors in strict providers.
  - **Details**: Squashed transient `id was but must be a-z, A-Z, 0-9, with a length of 9` failures by sanitizing every outbound tool call ID before invoking `ctx.tools.invoke`.
