"""Collapse build/BuildAssetShowcase.lua to one line (comments stripped) for single-line command bars."""
import pathlib, sys
src = pathlib.Path(sys.argv[1]).read_text()
out, i, n = [], 0, len(src)
def long_bracket(s, j):
    # s[j] == '[' ; returns level or -1
    k = j + 1
    while k < len(s) and s[k] == '=':
        k += 1
    return (k - j - 1) if k < len(s) and s[k] == '[' else -1
while i < n:
    c = src[i]
    if src.startswith('--', i):
        j = i + 2
        if j < n and src[j] == '[' and long_bracket(src, j) >= 0:
            lvl = long_bracket(src, j); end = ']' + '=' * lvl + ']'
            i = src.index(end, j) + len(end)
        else:
            while i < n and src[i] != '\n':
                i += 1
        if not out or not out[-1].endswith(' '):
            out.append(' ')
        continue
    if c in '"\'':
        j = i + 1
        while src[j] != c:
            j += 2 if src[j] == '\\' else 1
        out.append(src[i:j + 1]); i = j + 1; continue
    if c == '`':
        j = src.index('`', i + 1); out.append(src[i:j + 1]); i = j + 1; continue
    if c == '[' and long_bracket(src, i) >= 0:
        lvl = long_bracket(src, i); end = ']' + '=' * lvl + ']'
        j = src.index(end, i)
        body = src[i + lvl + 2:j]
        if body.startswith('\n'):
            body = body[1:]
        # long strings become one-line quoted strings so nothing in the output has a newline
        esc = body.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\t', '\\t').replace('\r', '')
        out.append('"' + esc + '"'); i = j + len(end); continue
    if c in ' \n\t\r':
        if not out or not out[-1].endswith(' '):
            out.append(' ')
    else:
        out.append(c)
    i += 1
s = ''.join(out)
import re
s = s.strip()  # runs of spaces are left alone: they may sit inside strings
pathlib.Path(sys.argv[2]).write_text(s)
print(len(s))
