# Free from @barakahraaz on Instagram. Not for sale.
# usage: python3 -I get-sounds.py <engine-folder> <reel-folder | kit-id>...
# Chat ships no SFX Kit sounds and desktop ships 12 of the 28 categories. This fetches each one the reel uses
# from the kit's own GitHub, one file at a time, and checks it against the sha256 in sounds.json.
# A reel folder means every 'kit:<id>' named in its index.html, sfx.json and script.md.
# Files land in <engine-folder>/assets/sfx-kit/<file from sounds.json>, where mix.py reads them.
import hashlib, json, os, re, sys, urllib.request

BASE = 'https://raw.githubusercontent.com/wyzowl/sfx-kit/main/'
if len(sys.argv) < 3:
    sys.exit('usage: python3 -I get-sounds.py <engine-folder> <reel-folder | kit-id>...')
kit = os.path.join(sys.argv[1], 'assets', 'sfx-kit')
sounds = {s['id']: s for s in json.load(open(os.path.join(kit, 'sounds.json'), encoding='utf-8'))['sounds']}

ids = []
for a in sys.argv[2:]:
    if os.path.isdir(a):
        for f in ('index.html', 'sfx.json', 'script.md'):
            p = os.path.join(a, f)
            if os.path.isfile(p):
                ids += re.findall(r'kit:([a-z0-9][a-z0-9-]*)', open(p, encoding='utf-8').read())
    else:
        ids.append(a[4:] if a.startswith('kit:') else a)
ids = sorted(set(ids))
bad = [i for i in ids if i not in sounds]
if bad:
    sys.exit('unknown kit sound: ' + ', '.join(bad) + ' (see assets/sfx-kit/catalogue.md)')


def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for b in iter(lambda: f.read(1 << 16), b''):
            h.update(b)
    return h.hexdigest()


got = have = 0
for i in ids:
    s = sounds[i]
    dst = os.path.join(kit, s['file'])
    if os.path.isfile(dst) and sha(dst) == s['sha256']:
        have += 1
        continue
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    tmp = dst + '.part'
    with urllib.request.urlopen(BASE + s['file'], timeout=60) as r, open(tmp, 'wb') as f:
        f.write(r.read())
    if sha(tmp) != s['sha256']:
        os.remove(tmp)
        sys.exit(f'{i}: the download does not match its sha256, so it was not kept. Try again, or pick another sound.')
    os.replace(tmp, dst)
    got += 1
print(f'kit sounds: {got} fetched, {have} already here, {len(ids)} in all')
