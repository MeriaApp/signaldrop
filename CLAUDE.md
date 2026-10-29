# SignalDrop (dropout): macOS Wi-Fi monitor

Repo `MeriaApp/dropout`; App Store record "SignalDrop - WiFi Monitor" (`com.meria.signaldrop`). Current state: `CONTEXT_STATE.md`. Mac App Store steps: `MAC_APP_STORE_CHECKLIST.md`.

## App Store conduct gate: every submission, never skipped

All our apps share one Apple developer account, and a DPLA 3.2(f) termination removes every one of them (Jesse,
2026-10-28). Before any App Store review submission of SignalDrop (ASC app ID `6761185430`), on the exact build being
submitted and after the review notes are filled in:

```bash
python3 ~/.claude/scripts/asc-conduct-preflight.py 6761185430 --repo <this repo> --binary <archived .app|.ipa|.xcarchive> --version <x.y.z>
```

It must print PASS. A hook (`~/.claude/hooks/block-unchecked-app-store-submission.py`) blocks any submission script
or call without a PASS for this app from the last 24 hours. Rules: `~/.claude/playbooks/app-store-conduct-rules.md`.
Legitimate binary hits go in `AppStore/conduct-allowlist.json`; any owner screen marked `disclose` is named in the
review notes. Never ship a hidden screen or gesture (gate it with `#if DEBUG`), a custom review prompt, or a price
that isn't live, and never let family, staff or affiliates rate the app.

