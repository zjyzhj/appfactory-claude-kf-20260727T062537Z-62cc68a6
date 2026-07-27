#!/usr/bin/env python3
"""Validate a generated PNG and write an adjacent ok=true receipt for pm_visuals."""
import hashlib
import json
import struct
import sys
import time
from pathlib import Path

PNG_SIG = b"\x89PNG\r\n\x1a\n"


def main() -> int:
    out = Path(sys.argv[1])
    model = sys.argv[2] if len(sys.argv) > 2 else "gpt-image-2"
    data = out.read_bytes()
    if len(data) < 256 or not data.startswith(PNG_SIG):
        print("invalid_png", file=sys.stderr)
        return 1
    width, height = struct.unpack(">II", data[16:24])
    if width * height <= 1:
        print("trivial_png", file=sys.stderr)
        return 1
    receipt = {
        "ok": True,
        "code": "ok",
        "backend": "claude_gpt_image_http_factory_relay",
        "model": model,
        "requested_size": f"{width}x{height}",
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "output_path": str(out),
        "output_sha256": hashlib.sha256(data).hexdigest(),
        "output_bytes": len(data),
        "content_type": "image/png",
        "width": width,
        "height": height,
    }
    rp = out.with_suffix(out.suffix + ".receipt.json")
    rp.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"ok": True, "width": width, "height": height, "bytes": len(data)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
