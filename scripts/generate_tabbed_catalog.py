#!/usr/bin/env python3
import json
import glob
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]

with open(REPOSITORY / 'training-content/catalog.json', encoding='utf-8') as f:
    cat = json.load(f)

for lab in cat['labs']:
    guide_name = Path(lab['guide']).name
    matches = list((REPOSITORY / 'portal/docs').glob(f'day*/{guide_name}')) + list((REPOSITORY / 'portal/docs').glob(f'env/{guide_name}'))
    if matches:
        rel = matches[0].relative_to(REPOSITORY / 'portal/docs').as_posix().replace('.md', '/')
        lab['url'] = f'../{rel}'
    else:
        lab['url'] = f"../day1/{guide_name.replace('.md', '/')}"

diff_map = {100: '🟢 CORE', 200: '🟡 PRACTITIONER', 300: '🔴 ADVANCED'}

def make_rows(labs, include_level=False):
    lines = []
    if include_level:
        lines.append('| Lab ID | Seviye | Lab Başlığı | Konu | Süre | Portlar | İncele |')
        lines.append('| :--- | :--- | :--- | :--- | :--- | :--- | :--- |')
    else:
        lines.append('| Lab ID | Lab Başlığı | Konu | Süre | Portlar | İncele |')
        lines.append('| :--- | :--- | :--- | :--- | :--- | :--- |')
    for l in labs:
        p = ', '.join(str(x) for x in l.get('ports', [])) or '-'
        mins = f"{l.get('estimated_minutes', 45)} dk"
        topic = l.get('topic', 'DevOps').upper()
        lvl = diff_map.get(l.get('difficulty', 200), '🟡 PRACTITIONER')
        if include_level:
            lines.append(f"| `{l['id']}` | {lvl} | {l['title']} | {topic} | {mins} | `{p}` | [Labı Aç →]({l['url']}) |")
        else:
            lines.append(f"| `{l['id']}` | {l['title']} | {topic} | {mins} | `{p}` | [Labı Aç →]({l['url']}) |")
    return '\n    '.join(lines)

all_labs = cat['labs']
core_labs = [l for l in all_labs if l.get('difficulty', 200) <= 100]
prac_labs = [l for l in all_labs if l.get('difficulty', 200) == 200]
adv_labs = [l for l in all_labs if l.get('difficulty', 200) >= 300]

content = f"""# 02 — DevOps Lab Kataloğu ve Zorluk Seviyeleri

DevOps Atölyesi laboratuvar kütüphanesi, katılımcıların bilgi seviyelerine ve hedeflerine göre **3 ana zorluk düzeyinde** yapılandırılmıştır.

Aşağıdaki sekmeleri kullanarak dilediğiniz seviyedeki labları listeleyebilir ve doğrudan çalışmaya başlayabilirsiniz:

=== "Tüm Lablar ({len(all_labs)} Lab)"

    {make_rows(all_labs, include_level=True)}

=== "🟢 CORE — Temel Seviye ({len(core_labs)} Lab)"

    DevOps kültürüne giriş, Linux yönetimi, Git sürüm kontrolü ve ilk Docker konteyneri gibi temel yetkinlikleri kazandırır.

    {make_rows(core_labs)}

=== "🟡 PRACTITIONER — Üretim Standartları ({len(prac_labs)} Lab)"

    Kurumsal ortamlarda kullanılan ileri düzey Docker multi-stage hardening, Java Spring Boot JVM optimizasyonu, Docker Compose, Jenkins, Terraform, Kubernetes, Helm ve Argo CD GitOps uygulamalarını kapsar.

    {make_rows(prac_labs)}

=== "🔴 ADVANCED — İleri Seviye & Capstone ({len(adv_labs)} Lab)"

    Gerçek dünya felaket senaryoları (Incident Response / War Room), merkezi ELK log analitiği, Alertmanager kuralları ve uçtan uca DevOps Capstone projesini içerir.

    {make_rows(adv_labs)}
"""

(REPOSITORY / 'portal/docs/curriculum/02_LAB_CATALOG_INDEX.md').write_text(content.strip() + '\n', encoding='utf-8')
(REPOSITORY / 'training-content/curriculum/02_LAB_CATALOG_INDEX.md').write_text(content.strip() + '\n', encoding='utf-8')
print('Generated 02_LAB_CATALOG_INDEX.md successfully!')
