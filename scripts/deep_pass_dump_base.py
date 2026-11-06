#!/usr/bin/env python3
"""Dump TutoTOONS.Base.dll + per-title Assembly-CSharp from one metadata file."""
import json, os, subprocess, zipfile, re, sys
from collections import Counter

REA="/Users/danielvm/.nvm/versions/node/v24.22.2/bin/rea"
ROOT="/Users/danielvm/Developer/big-quiqui-v2"
ENV={**os.environ,"PATH":f"/opt/homebrew/bin:{REA.rsplit('/',1)[0]}:{os.environ['PATH']}"}

def dump(pkg, out):
    base=f"{ROOT}/.rea/acq/{pkg}/base.apk"
    meta="/tmp/base-meta.dat"
    with zipfile.ZipFile(base) as z:
        cand=[n for n in z.namelist() if n.endswith('Metadata/global-metadata.dat')]
        open(meta,'wb').write(z.read(cand[0]))
    r=subprocess.run([REA,'inspect-il2cpp-metadata',meta,'--json'],capture_output=True,text=True,env=ENV)
    d=json.loads(r.stdout)['normalized_result']
    types,methods=d['types'],d['methods']
    out['counts']={k:len(d[k]) for k in ('images','types','methods','fields','string_literals')}
    for img in d['images']:
        name=img['name']
        if name in ('TutoTOONS.Base.dll','Assembly-CSharp.dll','Fluvsies.dll'):
            s,c=img['type_start'],img['type_count']
            ts=types[s:s+c]
            out[name]={'types':c,'methods':sum(t['method_count'] for t in ts)}
            # namespaces
            ns=Counter(t['namespace'] for t in ts if t['namespace'])
            out[name]['namespaces']=dict(ns.most_common())
            # full type names
            out[name]['type_names']=[(t['namespace']+'.' if t['namespace'] else '')+t['name'] for t in ts]
            # methods per selected type
            sel={}
            for t in ts:
                if not t['namespace'] and t['method_count']>=8:
                    ms=methods[t['method_start']:t['method_start']+t['method_count']]
                    sel[t['name']]=sorted(m['name'] for m in ms)
            out[name]['big_types']=sel
    os.remove(meta)
    return d

if __name__=='__main__':
    pkg=sys.argv[1]
    o={}
    dump(pkg,o)
    json.dump(o,open(f'/tmp/{pkg}-base.json','w'),indent=1)
    print(f"wrote /tmp/{pkg}-base.json: {json.dumps(o['counts'])}")
    for k in ('TutoTOONS.Base.dll','Assembly-CSharp.dll','Fluvsies.dll'):
        if k in o:
            print(f"{k}: {o[k]['types']} types / {o[k]['methods']} methods; namespaces={list(o[k]['namespaces'])[:12]}")
