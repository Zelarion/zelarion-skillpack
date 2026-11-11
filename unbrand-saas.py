import re
def rw(p, fn):
    s = open(p, encoding="utf-8", newline="").read()
    t = fn(s)
    open(p, "w", encoding="utf-8", newline="").write(t)

def skill(s):
    s = re.sub(r'Reference implementation: the Drezivo product pack \("Drezivo - Product and Architecture\s+Pack"; its\s+source is not part of this bundle\)\. The code shapes',
               'Reference implementation: a production greenfield API (its source is not part of this\nbundle). The code shapes', s)
    s = s.replace("using the Drezivo approach", "using the Clerk-plus-central-gate approach")
    s = s.replace("(Drezivo approach)", "(Clerk + central gate)")
    s = s.replace("**Greenfield** (Drezivo)", "**Greenfield**")
    return s

def patterns(s):
    s = s.replace("the Drezivo API (greenfield)", "a greenfield API")
    s = s.replace("X-Drezivo-Branch-Id", "X-Branch-Id")
    s = re.sub(r"\(Drezivo `", "(greenfield `", s)
    return s

rw("SKILL.md", skill); rw("references/patterns.md", patterns)
