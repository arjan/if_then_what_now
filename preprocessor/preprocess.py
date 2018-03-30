import re
import sys
import spacy
import json
from spacy.lang.nl import Dutch


def make_timestamp(string):
    parts = string.split(":")
    if len(parts) == 1:
        return float(string)
    return int(parts[0]) * 60 + float(parts[1])

nlp = spacy.load('nl')
contents = open(sys.argv[1], "r").read()
parts = re.split("#(.*)", contents)

grouped = list(zip(*[iter(parts)] * 2))

current_ts = 0
all = []
for (text, ts) in grouped:
    ts = make_timestamp(ts)
    tokens = [t for t in nlp(text) if not t.is_space]
    word_tokens = [t.text for t in tokens if not t.is_punct]
    total_chars = len("".join(word_tokens))
    n = 0
    total_time = ts - current_ts
    for t in tokens:
        all.append( (t.text, current_ts) )
        if t.text in word_tokens:
            current_ts += (len(t) / float(total_chars)) * total_time

print(json.dumps(all))

# #print(lines)
# for tok in (nlp(lines)):
#     if tok.text == "#":
#         print("-----")
#         print(list(tok.rights))
#         continue
#     if tok.is_punct or tok.is_space:
#         continue
#     print("-", tok.text)
