"""Undo Cloudflare email obfuscation in a live body so it can be compared with the origin build."""
import re, sys

def decode(hex_text):
    data = bytes.fromhex(hex_text)
    return bytes(b ^ data[0] for b in data[1:]).decode()

text = open(sys.argv[1], encoding="utf-8").read()
text = re.sub(r'<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="([0-9a-f]+)">\[email&#160;protected\]</a>',
              lambda m: decode(m.group(1)), text)
text = re.sub(r'href="/cdn-cgi/l/email-protection#([0-9a-f]+)"', lambda m: 'href="mailto:' + decode(m.group(1)) + '"', text)
text = re.sub(r'<script data-cfasync="false" src="/cdn-cgi/scripts/[^"]+/cloudflare-static/email-decode.min.js"></script>', "", text)
sys.stdout.write(text)
