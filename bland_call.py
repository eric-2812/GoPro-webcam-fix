#!/usr/bin/env python3
"""Place an outbound AI phone call through Bland.

Usage:
    export BLAND_API_KEY=...            # never hard-code the key
    python3 bland_call.py +34662941624 "Remind me to check the GoPro build" \
        --first-sentence "Hi, this is Claude." --language es

Optional: export BLAND_FROM=+1... to use a Bland-provisioned caller ID.
"""
import argparse
import json
import os
import sys
import urllib.request

API_URL = "https://api.bland.ai/v1/calls"


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    p.add_argument("phone_number", help="Destination in E.164 format, e.g. +34662941624")
    p.add_argument("task", help="Instructions for the AI agent on the call")
    p.add_argument("--first-sentence", help="Exact opening line")
    p.add_argument("--language", default="en", help="Language code, e.g. es, en")
    p.add_argument("--voice", default=None, help="Bland voice name or id")
    p.add_argument("--max-duration", type=int, default=5, help="Minutes (default 5)")
    args = p.parse_args()

    key = os.environ.get("BLAND_API_KEY")
    if not key:
        sys.exit("Set BLAND_API_KEY in the environment first.")
    if not args.phone_number.startswith("+"):
        sys.exit("Phone number must be E.164 (start with +country code).")

    body = {
        "phone_number": args.phone_number,
        "task": args.task,
        "language": args.language,
        "max_duration": args.max_duration,
        "wait_for_greeting": True,
    }
    if args.first_sentence:
        body["first_sentence"] = args.first_sentence
    if args.voice:
        body["voice"] = args.voice
    if os.environ.get("BLAND_FROM"):
        body["from"] = os.environ["BLAND_FROM"]

    req = urllib.request.Request(
        API_URL,
        data=json.dumps(body).encode(),
        headers={"authorization": key, "content-type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req) as r:
            print(json.dumps(json.load(r), indent=2))
    except urllib.error.HTTPError as e:
        sys.exit(f"HTTP {e.code}: {e.read().decode()}")


if __name__ == "__main__":
    main()
