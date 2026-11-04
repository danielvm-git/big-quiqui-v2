# Security & Privacy Architecture (`SECURITY_PLAN_LATEST.md`)

<!-- story: e01s01 -->

## 1. Threat Context & Regulatory Compliance
- **Audience:** Children ages 4–7 on iPadOS.
- **Regulations:** LGPD Art. 14 (protection of children's personal data) and Apple App Store Kids Category guidelines.

## 2. Five Hard Security Controls
1. **Air-Gapped Runtime (Zero Network Calls):**
   - CI enforces a grep ban across `game/` on `HTTPRequest`, `HTTPClient`, `WebSocketPeer`, `TCPServer`, `StreamPeerTCP`, `UDPServer`, `PacketPeerUDP`, `ENetMultiplayerPeer`, `OS.shell_open`, and `OS.execute`.
2. **Closed-Schema Local Logging with PII Redaction (`Log`):**
   - `Log.event(name, payload)` rejects unknown event names or keys not listed in `Log.SCHEMA`.
   - String values pass through `redact_pii()` which scrubs filesystem home paths (`/Users/<name>`), emails, IPv4/IPv6 addresses, UUIDs, and long digit sequences (`7+` digits).
3. **Resource Identifier Allowlist (`\A[a-z0-9_]{1,64}\z`):**
   - Every character, item, outfit, or furniture ID loaded from `user://progress.json` is validated against `RegEx` `\A[a-z0-9_]{1,64}\z` before constructing any `res://` path. Path traversal (`..`, `/`, `\`) is rejected immediately.
4. **Tamper-Resilient Save Deserialization (`ProgressManager`):**
   - `user://progress.json` is parsed via `JSON.parse_string` (never `ResourceLoader.load` on `user://`, preventing Godot `.tres` object injection).
   - Numeric fields (`coins`, `tickets`) are clamped to `[0, 9999]`; array lengths are capped at `128`.
5. **Atomic File Writes:**
   - Saves write to `user://progress.json.tmp`, flush, and atomically rename to `user://progress.json`.
