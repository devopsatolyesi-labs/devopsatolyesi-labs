#!/usr/bin/env python3
"""
Generates modern, high-resolution SVG architecture and pipeline diagrams
for DevOps Atölyesi Student Portal labs and projects.
All technical concepts preserve standard English industry terminology (Pipeline, Stage, Job, Artifacts, etc.)
"""

import os
from pathlib import Path

PORTAL_DOCS = Path(__file__).resolve().parent.parent / "docs"


def create_svg(width, height, content):
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="100%" height="100%" style="background:#0f172a; border-radius:12px; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
  <defs>
    <linearGradient id="grad-blue" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#3b82f6"/>
      <stop offset="100%" stop-color="#1d4ed8"/>
    </linearGradient>
    <linearGradient id="grad-green" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#10b981"/>
      <stop offset="100%" stop-color="#047857"/>
    </linearGradient>
    <linearGradient id="grad-amber" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#f59e0b"/>
      <stop offset="100%" stop-color="#b45309"/>
    </linearGradient>
    <linearGradient id="grad-purple" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#8b5cf6"/>
      <stop offset="100%" stop-color="#6d28d9"/>
    </linearGradient>
    <linearGradient id="grad-rose" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#f43f5e"/>
      <stop offset="100%" stop-color="#be123c"/>
    </linearGradient>
    <linearGradient id="grad-cyan" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#06b6d4"/>
      <stop offset="100%" stop-color="#0e7490"/>
    </linearGradient>
    <filter id="shadow" x="-5%" y="-5%" width="110%" height="115%" filterUnits="userSpaceOnUse">
      <feDropShadow dx="0" dy="4" stdDeviation="6" flood-color="#000000" flood-opacity="0.4"/>
    </filter>
    <marker id="arrow" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#64748b"/>
    </marker>
    <marker id="arrow-green" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#10b981"/>
    </marker>
    <marker id="arrow-blue" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#3b82f6"/>
    </marker>
  </defs>
  {content}
</svg>"""


def stage_box(x, y, w, h, title, subtitle, grad, jobs):
    items_svg = []
    job_y = y + 52
    for job in jobs:
        badge = f"""<rect x="{x+w-75}" y="{job_y+10}" width="65" height="18" rx="9" fill="{job.get('badge_bg', '#334155')}"/>
        <text x="{x+w-42}" y="{job_y+22}" fill="{job.get('badge_fg', '#94a3b8')}" font-size="10" font-weight="600" text-anchor="middle">{job.get('badge', 'JOB')}</text>""" if 'badge' in job else ""

        desc_svg = f"""<text x="{x+16}" y="{job_y+36}" fill="#94a3b8" font-size="11">{job.get('desc', '')}</text>""" if 'desc' in job else ""
        detail_svg = f"""<text x="{x+16}" y="{job_y+50}" fill="#64748b" font-size="10" font-family="monospace">{job.get('detail', '')}</text>""" if 'detail' in job else ""

        card_h = job.get("height", 62)
        items_svg.append(f"""
      <rect x="{x+8}" y="{job_y}" width="{w-16}" height="{card_h}" rx="8" fill="#1e293b" stroke="#334155" stroke-width="1" filter="url(#shadow)"/>
      <text x="{x+16}" y="{job_y+22}" fill="#f8fafc" font-size="13" font-weight="600">{job['name']}</text>
      {badge}
      {desc_svg}
      {detail_svg}
        """)
        job_y += card_h + 10

    return f"""
    <!-- Stage: {title} -->
    <g>
      <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="10" fill="#1e293b" stroke="#334155" stroke-width="1.5"/>
      <rect x="{x}" y="{y}" width="{w}" height="42" rx="10" fill="url(#{grad})"/>
      <rect x="{x}" y="{y+32}" width="{w}" height="10" fill="url(#{grad})"/>
      <text x="{x+14}" y="{y+26}" fill="#ffffff" font-size="14" font-weight="700">{title}</text>
      <text x="{x+w-12}" y="{y+26}" fill="#e2e8f0" font-size="11" font-weight="500" text-anchor="end">{subtitle}</text>
      {''.join(items_svg)}
    </g>
    """


def write_diagram(rel_path, width, height, content):
    full_path = PORTAL_DOCS / rel_path
    full_path.parent.mkdir(parents=True, exist_ok=True)
    svg_str = create_svg(width, height, content)
    full_path.write_text(svg_str, encoding="utf-8")
    print(f"  -> Generated: {rel_path}")


def generate_all():
    print("Generating comprehensive visual architecture diagrams with standard technical terms...")

    # 1. LAB-GLB-01
    write_diagram("day3/images/lab-glb-01-pipeline.svg", 960, 280, f"""
  <text x="30" y="36" fill="#f8fafc" font-size="18" font-weight="700">LAB-GLB-01 — GitLab CI/CD Multi-Stage Pipeline Architecture</text>
  <text x="30" y="58" fill="#64748b" font-size="12">End-to-End Delivery on GitLab Runner Docker Executor</text>
  {stage_box(30, 80, 200, 170, "Stage 1: Test", "unit-tests", "grad-green", [{"name": "unit-tests", "desc": "npm install & test", "detail": "image: node:20-alpine", "badge": "PASS", "badge_bg": "#064e3b", "badge_fg": "#34d399"}])}
  <path d="M 230 165 L 260 165" stroke="#64748b" stroke-width="2.5" marker-end="url(#arrow)"/>
  {stage_box(260, 80, 200, 170, "Stage 2: Security", "Trivy Scan", "grad-amber", [{"name": "dependency-scan", "desc": "Trivy FS CVE Audit", "detail": "aquasec/trivy:0.74.0", "badge": "CVE: 0", "badge_bg": "#451a03", "badge_fg": "#fbbf24"}])}
  <path d="M 460 165 L 490 165" stroke="#64748b" stroke-width="2.5" marker-end="url(#arrow)"/>
  {stage_box(490, 80, 200, 170, "Stage 3: Build", "Containerize", "grad-blue", [{"name": "docker-build", "desc": "docker build -t api:tag", "detail": "docker:27.5.1-cli", "badge": "IMAGE", "badge_bg": "#1e3a8a", "badge_fg": "#60a5fa"}])}
  <path d="M 690 165 L 720 165" stroke="#64748b" stroke-width="2.5" marker-end="url(#arrow)"/>
  {stage_box(720, 80, 210, 170, "Stage 4: Deploy", "Smoke Test", "grad-purple", [{"name": "deploy-and-smoke", "desc": "run :3089 & /health test", "detail": "after_script: stop & rm", "badge": "LIVE", "badge_bg": "#3b0764", "badge_fg": "#c084fc"}])}
    """)

    # 2. LAB-GLB-02
    write_diagram("day3/images/lab-glb-02-variables-artifacts.svg", 940, 330, f"""
  <text x="30" y="36" fill="#f8fafc" font-size="18" font-weight="700">LAB-GLB-02 — GitLab CI Variables and Artifacts Lifecycle</text>
  <text x="30" y="58" fill="#64748b" font-size="12">Stage Data Transfer, Dependencies Filtering &amp; expire_in Lifecycle</text>
  {stage_box(30, 80, 260, 220, "Stage 1: Build", "Artifact Generation", "grad-blue", [{"name": "build-artifacts", "desc": "node index.js (build-info)", "detail": "artifacts: paths [build-info.txt]", "badge": "1 HOUR", "badge_bg": "#1e3a8a", "badge_fg": "#93c5fd", "height": 68}, {"name": "Variables", "desc": "$CI_COMMIT_SHORT_SHA", "detail": "$CI_PIPELINE_IID / $APP_VERSION", "height": 55}])}
  <path d="M 290 150 L 340 150" stroke="#3b82f6" stroke-width="2.5" marker-end="url(#arrow-blue)"/>
  <text x="315" y="140" fill="#94a3b8" font-size="10" text-anchor="middle">artifacts</text>
  {stage_box(340, 80, 260, 220, "Stage 2: Test", "Artifact Verification", "grad-green", [{"name": "verify-artifacts", "desc": "node test.js (assert file)", "detail": "dependencies: [build-artifacts]", "badge": "PASSED", "badge_bg": "#064e3b", "badge_fg": "#34d399", "height": 68}, {"name": "Dependencies Filter", "desc": "Only build-artifacts fetched", "detail": "Clean execution environment", "height": 55}])}
  <path d="M 600 150 L 650 150" stroke="#10b981" stroke-width="2.5" marker-end="url(#arrow-green)"/>
  <text x="625" y="140" fill="#94a3b8" font-size="10" text-anchor="middle">verified</text>
  {stage_box(650, 80, 260, 220, "Stage 3: Package", "Release Packaging", "grad-purple", [{"name": "package-release", "desc": "tar -czvf release.tar.gz", "detail": "artifacts: paths [*.tar.gz]", "badge": "RELEASE", "badge_bg": "#3b0764", "badge_fg": "#d8b4fe", "height": 68}, {"name": "Job Artifacts", "desc": "Downloadable from GitLab UI", "detail": "Deployable distribution package", "height": 55}])}
    """)

    # 3. LAB-GLB-03
    write_diagram("day3/images/lab-glb-03-dag-pipelines.svg", 940, 280, f"""
  <text x="30" y="36" fill="#f8fafc" font-size="18" font-weight="700">LAB-GLB-03 — GitLab CI Directed Acyclic Graph (DAG) Pipeline</text>
  <text x="30" y="58" fill="#64748b" font-size="12">Parallel Matrix Execution with needs: [] Direct Dependency Graph</text>
  <rect x="30" y="80" width="240" height="70" rx="8" fill="#1e293b" stroke="#3b82f6" stroke-width="1.5"/>
  <text x="45" y="105" fill="#60a5fa" font-size="14" font-weight="700">build-frontend</text>
  <text x="45" y="125" fill="#94a3b8" font-size="11">Frontend Bundle v2.0</text>
  <text x="45" y="140" fill="#64748b" font-size="10">Stage: build</text>
  <path d="M 270 115 L 340 115" stroke="#3b82f6" stroke-width="2.5" marker-end="url(#arrow-blue)"/>
  <text x="305" y="107" fill="#60a5fa" font-size="10" text-anchor="middle">needs</text>
  <rect x="340" y="80" width="240" height="70" rx="8" fill="#1e293b" stroke="#10b981" stroke-width="1.5"/>
  <text x="355" y="105" fill="#34d399" font-size="14" font-weight="700">test-frontend</text>
  <text x="355" y="125" fill="#94a3b8" font-size="11">needs: [build-frontend]</text>
  <text x="355" y="140" fill="#10b981" font-size="10">Starts immediately without waiting backend!</text>
  <rect x="30" y="180" width="240" height="70" rx="8" fill="#1e293b" stroke="#3b82f6" stroke-width="1.5"/>
  <text x="45" y="205" fill="#60a5fa" font-size="14" font-weight="700">build-backend</text>
  <text x="45" y="225" fill="#94a3b8" font-size="11">Backend Binary v2.0</text>
  <text x="45" y="240" fill="#64748b" font-size="10">Stage: build</text>
  <path d="M 270 215 L 340 215" stroke="#3b82f6" stroke-width="2.5" marker-end="url(#arrow-blue)"/>
  <text x="305" y="207" fill="#60a5fa" font-size="10" text-anchor="middle">needs</text>
  <rect x="340" y="180" width="240" height="70" rx="8" fill="#1e293b" stroke="#10b981" stroke-width="1.5"/>
  <text x="355" y="205" fill="#34d399" font-size="14" font-weight="700">test-backend</text>
  <text x="355" y="225" fill="#94a3b8" font-size="11">needs: [build-backend]</text>
  <text x="355" y="240" fill="#10b981" font-size="10">Runs independently in parallel!</text>
  <path d="M 580 115 Q 640 115 670 155" stroke="#64748b" stroke-width="2.5" fill="none"/>
  <path d="M 580 215 Q 640 215 670 175" stroke="#64748b" stroke-width="2.5" fill="none" marker-end="url(#arrow)"/>
  <rect x="670" y="130" width="240" height="75" rx="8" fill="#1e293b" stroke="#8b5cf6" stroke-width="2"/>
  <text x="685" y="155" fill="#c084fc" font-size="14" font-weight="700">fast-deploy-staging</text>
  <text x="685" y="175" fill="#94a3b8" font-size="11">needs: [test-frontend, test-backend]</text>
  <text x="685" y="192" fill="#c084fc" font-size="10">Converges only when dependencies pass</text>
    """)

    # 4. LAB-GLB-04
    write_diagram("day3/images/lab-glb-04-security-gates.svg", 940, 290, f"""
  <text x="30" y="36" fill="#f8fafc" font-size="18" font-weight="700">LAB-GLB-04 — GitLab CI DevSecOps Security Gate &amp; CVE Audit</text>
  <text x="30" y="58" fill="#64748b" font-size="12">Shift-Left Security: Syntax Linting, Static Dependency Scan &amp; Container Image Gate</text>
  {stage_box(30, 80, 260, 180, "Stage 1: Lint", "Static Analysis", "grad-cyan", [{"name": "code-lint", "desc": "node --check src/index.js", "detail": "Syntax &amp; Coding Standards", "badge": "LINT OK", "badge_bg": "#164e63", "badge_fg": "#22d3ee", "height": 65}])}
  <path d="M 290 160 L 340 160" stroke="#64748b" stroke-width="2.5" marker-end="url(#arrow)"/>
  {stage_box(340, 80, 260, 180, "Stage 2: Security Scan", "Filesystem CVE", "grad-amber", [{"name": "dependency-cve-scan", "desc": "trivy fs --severity HIGH,CRITICAL", "detail": "aquasec/trivy:0.74.0", "badge": "CVE: 0", "badge_bg": "#451a03", "badge_fg": "#fbbf24", "height": 65}])}
  <path d="M 600 160 L 650 160" stroke="#64748b" stroke-width="2.5" marker-end="url(#arrow)"/>
  {stage_box(650, 80, 260, 180, "Stage 3: Container Audit", "Image Quality Gate", "grad-rose", [{"name": "container-image-gate", "desc": "docker build &amp; trivy image", "detail": "after_script: docker rmi", "badge": "GATE PASS", "badge_bg": "#4c0519", "badge_fg": "#fb7185", "height": 65}])}
    """)

    # 5. LAB-JNK-CORE
    write_diagram("day3/images/lab-jnk-core-pipeline.svg", 900, 300, f"""
  <text x="30" y="36" fill="#f8fafc" font-size="18" font-weight="700">LAB-JNK-CORE — Jenkins Declarative Pipeline Fundamentals</text>
  <text x="30" y="58" fill="#64748b" font-size="12">Syntax Structure, Parameters, Conditions (when) and Downstream Triggering</text>
  <rect x="30" y="90" width="180" height="65" rx="8" fill="#1e293b" stroke="#3b82f6" stroke-width="1.5"/>
  <text x="45" y="115" fill="#60a5fa" font-size="13" font-weight="700">01-basics</text>
  <text x="45" y="135" fill="#94a3b8" font-size="11">Core Stages &amp; Echo</text>
  <rect x="245" y="90" width="180" height="65" rx="8" fill="#1e293b" stroke="#10b981" stroke-width="1.5"/>
  <text x="260" y="115" fill="#34d399" font-size="13" font-weight="700">02-parameters</text>
  <text x="260" y="135" fill="#94a3b8" font-size="11">Dynamic Input Validation</text>
  <rect x="460" y="90" width="180" height="65" rx="8" fill="#1e293b" stroke="#f59e0b" stroke-width="1.5"/>
  <text x="475" y="115" fill="#fbbf24" font-size="13" font-weight="700">03-when</text>
  <text x="475" y="135" fill="#94a3b8" font-size="11">Conditional Stage Execution</text>
  <rect x="675" y="90" width="195" height="65" rx="8" fill="#1e293b" stroke="#8b5cf6" stroke-width="1.5"/>
  <text x="690" y="115" fill="#c084fc" font-size="13" font-weight="700">04-downstream</text>
  <text x="690" y="135" fill="#94a3b8" font-size="11">Downstream Job Trigger</text>
  <path d="M 770 155 Q 770 230 335 230 L 335 160" stroke="#8b5cf6" stroke-width="2" fill="none" stroke-dasharray="5,5" marker-end="url(#arrow)"/>
  <text x="550" y="222" fill="#c084fc" font-size="11" text-anchor="middle">build job: '02-parameters' (Downstream)</text>
    """)

    # 6. LAB-JNK-DOC
    write_diagram("day3/images/lab-jnk-doc-pipeline.svg", 940, 260, f"""
  <text x="30" y="36" fill="#f8fafc" font-size="18" font-weight="700">LAB-JNK-DOC — Jenkins Docker Containerization Architecture</text>
  <text x="30" y="58" fill="#64748b" font-size="12">Jenkins Agent Docker Socket (/var/run/docker.sock) Multi-Stage Image Build</text>
  {stage_box(30, 80, 200, 150, "Stage 1: SCM", "Jenkinsfile", "grad-blue", [{"name": "Checkout", "desc": "Git Source Code", "badge": "SCM", "badge_bg": "#1e3a8a", "badge_fg": "#60a5fa"}])}
  <path d="M 230 155 L 260 155" stroke="#64748b" stroke-width="2.5" marker-end="url(#arrow)"/>
  {stage_box(260, 80, 200, 150, "Stage 2: Test", "target: test", "grad-green", [{"name": "pytest suite", "desc": "Isolated in Container", "badge": "PASS", "badge_bg": "#064e3b", "badge_fg": "#34d399"}])}
  <path d="M 460 155 L 490 155" stroke="#64748b" stroke-width="2.5" marker-end="url(#arrow)"/>
  {stage_box(490, 80, 200, 150, "Stage 3: Prod Build", "target: runtime", "grad-blue", [{"name": "Hardened Image", "desc": "Non-root UID 10001", "badge": "IMAGE", "badge_bg": "#1e3a8a", "badge_fg": "#60a5fa"}])}
  <path d="M 690 155 L 720 155" stroke="#64748b" stroke-width="2.5" marker-end="url(#arrow)"/>
  {stage_box(720, 80, 190, 150, "Stage 4: Tagging", "Version Tag", "grad-purple", [{"name": "docker tag", "desc": "python-lab:v1", "badge": "READY", "badge_bg": "#3b0764", "badge_fg": "#c084fc"}])}
    """)

    # 7. LAB-JNK-02: DevSecOps Sequence
    write_diagram("day3/images/lab-jnk-02-secure-pipeline.svg", 960, 360, f"""
  <text x="30" y="36" fill="#f8fafc" font-size="18" font-weight="700">LAB-JNK-02 — Jenkins Secure Pipeline &amp; DevSecOps Integration</text>
  <text x="30" y="58" fill="#64748b" font-size="12">SonarQube Quality Gate, Trivy Container CVE Audit &amp; Harbor OCI Push</text>
  <rect x="50" y="80" width="130" height="36" rx="6" fill="#3b82f6"/>
  <text x="115" y="103" fill="#ffffff" font-size="12" font-weight="700" text-anchor="middle">1. Git SCM</text>
  <rect x="230" y="80" width="130" height="36" rx="6" fill="#10b981"/>
  <text x="295" y="103" fill="#ffffff" font-size="12" font-weight="700" text-anchor="middle">2. Jenkins CI</text>
  <rect x="410" y="80" width="130" height="36" rx="6" fill="#06b6d4"/>
  <text x="475" y="103" fill="#ffffff" font-size="12" font-weight="700" text-anchor="middle">3. SonarQube</text>
  <rect x="590" y="80" width="130" height="36" rx="6" fill="#f59e0b"/>
  <text x="655" y="103" fill="#ffffff" font-size="12" font-weight="700" text-anchor="middle">4. Trivy CVE</text>
  <rect x="770" y="80" width="130" height="36" rx="6" fill="#8b5cf6"/>
  <text x="835" y="103" fill="#ffffff" font-size="12" font-weight="700" text-anchor="middle">5. Harbor Registry</text>
  <line x1="115" y1="120" x2="115" y2="330" stroke="#334155" stroke-dasharray="4,4"/>
  <line x1="295" y1="120" x2="295" y2="330" stroke="#334155" stroke-dasharray="4,4"/>
  <line x1="475" y1="120" x2="475" y2="330" stroke="#334155" stroke-dasharray="4,4"/>
  <line x1="655" y1="120" x2="655" y2="330" stroke="#334155" stroke-dasharray="4,4"/>
  <line x1="835" y1="120" x2="835" y2="330" stroke="#334155" stroke-dasharray="4,4"/>
  <line x1="115" y1="145" x2="295" y2="145" stroke="#3b82f6" stroke-width="2" marker-end="url(#arrow-blue)"/>
  <text x="205" y="137" fill="#93c5fd" font-size="11" text-anchor="middle">1. Webhook / SCM Push</text>
  <line x1="295" y1="185" x2="475" y2="185" stroke="#06b6d4" stroke-width="2" marker-end="url(#arrow)"/>
  <text x="385" y="177" fill="#67e8f9" font-size="11" text-anchor="middle">2. Sonar-Scanner Report</text>
  <line x1="475" y1="225" x2="295" y2="225" stroke="#10b981" stroke-width="2" marker-end="url(#arrow-green)"/>
  <text x="385" y="217" fill="#6ee7b7" font-size="11" text-anchor="middle">3. Quality Gate Status (OK)</text>
  <line x1="295" y1="265" x2="655" y2="265" stroke="#f59e0b" stroke-width="2" marker-end="url(#arrow)"/>
  <text x="475" y="257" fill="#fcd34d" font-size="11" text-anchor="middle">4. Trivy Image Scan (0 CRITICAL)</text>
  <line x1="295" y1="305" x2="835" y2="305" stroke="#8b5cf6" stroke-width="2" marker-end="url(#arrow)"/>
  <text x="565" y="297" fill="#d8b4fe" font-size="11" text-anchor="middle">5. Docker Push OCI Registry</text>
    """)

    # 8. Projects
    write_diagram("projects/images/gitlab-python-flask-pipeline.svg", 960, 290, f"""
  <text x="30" y="36" fill="#f8fafc" font-size="18" font-weight="700">Project — GitLab CI/CD Python Flask Microservice Delivery Pipeline</text>
  <text x="30" y="58" fill="#64748b" font-size="12">Multi-Stage Hardened Container, Trivy Security Gate, Staging Deployment &amp; Teardown</text>
  {stage_box(30, 80, 200, 180, "Stage 1: Test", "Pytest Suite", "grad-green", [{"name": "unit-tests", "desc": "docker build --target test", "detail": "pytest tests/ (in container)", "badge": "TEST OK", "badge_bg": "#064e3b", "badge_fg": "#34d399", "height": 65}])}
  <path d="M 230 160 L 260 160" stroke="#64748b" stroke-width="2.5" marker-end="url(#arrow)"/>
  {stage_box(260, 80, 200, 180, "Stage 2: Build", "Hardened Image", "grad-blue", [{"name": "docker-build", "desc": "Non-root UID: 10001", "detail": "target: runtime (gunicorn)", "badge": "PROD IMG", "badge_bg": "#1e3a8a", "badge_fg": "#60a5fa", "height": 65}])}
  <path d="M 460 160 L 490 160" stroke="#64748b" stroke-width="2.5" marker-end="url(#arrow)"/>
  {stage_box(490, 80, 200, 180, "Stage 3: Security", "Trivy Quality Gate", "grad-amber", [{"name": "trivy-cve-audit", "desc": "HIGH,CRITICAL CVE Gate", "detail": "aquasec/trivy:0.74.0", "badge": "SECURE", "badge_bg": "#451a03", "badge_fg": "#fbbf24", "height": 65}])}
  <path d="M 690 160 L 720 160" stroke="#64748b" stroke-width="2.5" marker-end="url(#arrow)"/>
  {stage_box(720, 80, 210, 180, "Stage 4: Deploy", "Smoke Test &amp; Clean", "grad-purple", [{"name": "deploy-and-smoke", "desc": "docker run :8089 & /health", "detail": "after_script: docker rm -f", "badge": "HEALTHY", "badge_bg": "#3b0764", "badge_fg": "#c084fc", "height": 65}])}
    """)

    write_diagram("projects/images/gitlab-devops-capstone-pipeline.svg", 975, 290, f"""
  <text x="30" y="36" fill="#f8fafc" font-size="18" font-weight="700">Project — GitLab CI/CD DevOps Capstone End-to-End Pipeline</text>
  <text x="30" y="58" fill="#64748b" font-size="12">End-to-End Enterprise Delivery: Lint, Test, Package, Security Gate &amp; Deploy</text>
  {stage_box(30, 80, 165, 180, "Stage 1: Lint", "py_compile", "grad-cyan", [{"name": "lint-and-validate", "desc": "Syntax Verification", "detail": "python:3.11-alpine", "badge": "VALID", "badge_bg": "#164e63", "badge_fg": "#22d3ee", "height": 65}])}
  <path d="M 195 160 L 215 160" stroke="#64748b" stroke-width="2" marker-end="url(#arrow)"/>
  {stage_box(215, 80, 165, 180, "Stage 2: Test", "Unit Tests", "grad-green", [{"name": "run-test-suite", "desc": "test_main.py", "detail": "python:3.11-alpine", "badge": "PASS", "badge_bg": "#064e3b", "badge_fg": "#34d399", "height": 65}])}
  <path d="M 380 160 L 400 160" stroke="#64748b" stroke-width="2" marker-end="url(#arrow)"/>
  {stage_box(400, 80, 165, 180, "Stage 3: Package", "Container", "grad-blue", [{"name": "build-container", "desc": "capstone:tag", "detail": "docker:27.5.1-cli", "badge": "IMAGE", "badge_bg": "#1e3a8a", "badge_fg": "#60a5fa", "height": 65}])}
  <path d="M 565 160 L 585 160" stroke="#64748b" stroke-width="2" marker-end="url(#arrow)"/>
  {stage_box(585, 80, 165, 180, "Stage 4: Security", "CVE Gate", "grad-amber", [{"name": "trivy-gate", "desc": "Image Vulnerability", "detail": "trivy:0.74.0", "badge": "AUDITED", "badge_bg": "#451a03", "badge_fg": "#fbbf24", "height": 65}])}
  <path d="M 750 160 L 770 160" stroke="#64748b" stroke-width="2" marker-end="url(#arrow)"/>
  {stage_box(770, 80, 175, 180, "Stage 5: Deploy", "Smoke &amp; Teardown", "grad-purple", [{"name": "deploy-smoke", "desc": "run :8090 & /health", "detail": "after_script: rm -f", "badge": "LIVE", "badge_bg": "#3b0764", "badge_fg": "#c084fc", "height": 65}])}
    """)

    write_diagram("projects/images/python-flask-pipeline.svg", 975, 290, f"""
  <text x="30" y="36" fill="#f8fafc" font-size="18" font-weight="700">Jenkins Declarative Pipeline — Python Flask CI/CD Architecture</text>
  <text x="30" y="58" fill="#64748b" font-size="12">Jenkins Controller / Agent Architecture with Automated Verification and Teardown</text>
  {stage_box(30, 80, 165, 180, "Stage 1: Checkout", "Git SCM", "grad-blue", [{"name": "Git Checkout", "desc": "devops-atolyesi repo", "detail": "branch: main", "badge": "SCM", "badge_bg": "#1e3a8a", "badge_fg": "#60a5fa", "height": 65}])}
  <path d="M 195 160 L 215 160" stroke="#64748b" stroke-width="2" marker-end="url(#arrow)"/>
  {stage_box(215, 80, 165, 180, "Stage 2: Test", "Pytest Unit", "grad-green", [{"name": "Pytest Suite", "desc": "Isolated Docker Test", "detail": "tests/test_app.py", "badge": "PASS", "badge_bg": "#064e3b", "badge_fg": "#34d399", "height": 65}])}
  <path d="M 380 160 L 400 160" stroke="#64748b" stroke-width="2" marker-end="url(#arrow)"/>
  {stage_box(400, 80, 165, 180, "Stage 3: Build", "Hardened Container", "grad-blue", [{"name": "Docker Build", "desc": "Non-root UID: 10001", "detail": "target: runtime", "badge": "BUILT", "badge_bg": "#1e3a8a", "badge_fg": "#60a5fa", "height": 65}])}
  <path d="M 565 160 L 585 160" stroke="#64748b" stroke-width="2" marker-end="url(#arrow)"/>
  {stage_box(585, 80, 165, 180, "Stage 4: Security", "Trivy Quality Gate", "grad-amber", [{"name": "Trivy CVE Audit", "desc": "HIGH,CRITICAL CVE", "detail": "Security Quality Gate", "badge": "GATE OK", "badge_bg": "#451a03", "badge_fg": "#fbbf24", "height": 65}])}
  <path d="M 750 160 L 770 160" stroke="#64748b" stroke-width="2" marker-end="url(#arrow)"/>
  {stage_box(770, 80, 175, 180, "Stage 5: Deploy", "Smoke &amp; Clean", "grad-purple", [{"name": "Deploy Staging", "desc": "docker run & /health", "detail": "post: docker rm -f", "badge": "HEALTHY", "badge_bg": "#3b0764", "badge_fg": "#c084fc", "height": 65}])}
    """)

    # Day 2: Docker diagrams
    write_diagram("day2/images/lab-doc-06-trivy-harbor.svg", 940, 280, f"""
  <text x="30" y="36" fill="#f8fafc" font-size="18" font-weight="700">LAB-DOC-06 — Trivy Security Gate and Harbor Registry Push</text>
  <text x="30" y="58" fill="#64748b" font-size="12">Automated Build Block on Critical CVEs &amp; Secure OCI Image Storage</text>
  {stage_box(30, 80, 200, 160, "Stage 1: Build", "Docker Build", "grad-blue", [{"name": "Application Image", "desc": "docker build -t app:tag", "badge": "BUILD", "badge_bg": "#1e3a8a", "badge_fg": "#60a5fa"}])}
  <path d="M 230 160 L 260 160" stroke="#64748b" stroke-width="2.5" marker-end="url(#arrow)"/>
  {stage_box(260, 80, 210, 160, "Stage 2: Scan", "CVE Audit", "grad-amber", [{"name": "Trivy Scanner", "desc": "--severity CRITICAL", "badge": "AUDIT", "badge_bg": "#451a03", "badge_fg": "#fbbf24"}])}
  <path d="M 470 160 L 500 160" stroke="#10b981" stroke-width="2.5" marker-end="url(#arrow-green)"/>
  {stage_box(500, 80, 210, 160, "Stage 3: Gate", "Decision Gate", "grad-green", [{"name": "0 CRITICAL", "desc": "Quality Gate Passed (Exit 0)", "badge": "PASS", "badge_bg": "#064e3b", "badge_fg": "#34d399"}])}
  <path d="M 710 160 L 740 160" stroke="#8b5cf6" stroke-width="2.5" marker-end="url(#arrow)"/>
  {stage_box(740, 80, 190, 160, "Stage 4: Push", "Registry", "grad-purple", [{"name": "Private Registry", "desc": "docker push :8082", "badge": "STORED", "badge_bg": "#3b0764", "badge_fg": "#c084fc"}])}
    """)

    # Day 5: Logging
    write_diagram("day5/images/lab-log-01-logging.svg", 940, 280, f"""
  <text x="30" y="36" fill="#f8fafc" font-size="18" font-weight="700">LAB-LOG-01 — Centralized Logging Pipeline: Docker ➔ Vector ➔ Elasticsearch</text>
  <text x="30" y="58" fill="#64748b" font-size="12">Structured JSON Log Aggregation, Transformation (Remap), Indexing and Querying</text>
  {stage_box(30, 80, 260, 160, "Stage 1: App &amp; Docker", "Log Source", "grad-blue", [{"name": "FastAPI App", "desc": "stdout / json-file", "badge": "STDOUT", "badge_bg": "#1e3a8a", "badge_fg": "#60a5fa"}, {"name": "Docker Daemon", "desc": "/var/run/docker.sock", "height": 45}])}
  <path d="M 290 160 L 340 160" stroke="#06b6d4" stroke-width="2.5" marker-end="url(#arrow)"/>
  <text x="315" y="150" fill="#06b6d4" font-size="10" text-anchor="middle">logs</text>
  {stage_box(340, 80, 260, 160, "Stage 2: Vector Shipper", "Transform (Remap)", "grad-cyan", [{"name": "Vector v0.40.2", "desc": "parse_json! + timestamp", "badge": "REMAP", "badge_bg": "#164e63", "badge_fg": "#22d3ee"}, {"name": "Lightweight", "desc": "Minimal Memory Footprint", "height": 45}])}
  <path d="M 600 160 L 650 160" stroke="#f59e0b" stroke-width="2.5" marker-end="url(#arrow)"/>
  <text x="625" y="150" fill="#f59e0b" font-size="10" text-anchor="middle">bulk sink</text>
  {stage_box(650, 80, 260, 160, "Stage 3: Elasticsearch", "Search &amp; Storage", "grad-amber", [{"name": "devops-logs-*", "desc": "Bulk Indexer :9200", "badge": "ES 8.17", "badge_bg": "#451a03", "badge_fg": "#fbbf24"}, {"name": "REST API", "desc": "Curl &amp; Kibana Queries", "height": 45}])}
    """)

    # Day 2: Docker diagrams
    write_diagram("day2/images/lab-doc-03-optimization.svg", 900, 260, f"""
  <text x="30" y="36" fill="#f8fafc" font-size="18" font-weight="700">LAB-DOC-03 — Dockerfile Layer Optimization &amp; Caching</text>
  <text x="30" y="58" fill="#64748b" font-size="12">Build Cache, .dockerignore and Layer Order Optimization Strategy</text>
  {stage_box(30, 80, 260, 150, "1. .dockerignore", "Context Reduction", "grad-amber", [{"name": "Reduce Context", "desc": "node_modules, .git excluded", "badge": "CLEAN", "badge_bg": "#451a03", "badge_fg": "#fbbf24"}])}
  <path d="M 290 155 L 340 155" stroke="#64748b" stroke-width="2.5" marker-end="url(#arrow)"/>
  {stage_box(340, 80, 260, 150, "2. Cache Layering", "Order Strategy", "grad-blue", [{"name": "COPY package*.json", "desc": "Dependencies copied first", "badge": "CACHED", "badge_bg": "#1e3a8a", "badge_fg": "#60a5fa"}])}
  <path d="M 600 155 L 650 155" stroke="#64748b" stroke-width="2.5" marker-end="url(#arrow)"/>
  {stage_box(650, 80, 260, 150, "3. Final Build", "Fast Build", "grad-green", [{"name": "COPY . .", "desc": "Code change skips RUN npm", "badge": "FAST", "badge_bg": "#064e3b", "badge_fg": "#34d399"}])}
    """)

    write_diagram("day2/images/lab-doc-04-multistage.svg", 900, 260, f"""
  <text x="30" y="36" fill="#f8fafc" font-size="18" font-weight="700">LAB-DOC-04 — Multi-Stage Build &amp; Container Hardening</text>
  <text x="30" y="58" fill="#64748b" font-size="12">Build Tool Separation, Minimal Alpine Base &amp; Non-Root Execution</text>
  {stage_box(30, 80, 260, 150, "AS builder", "Build Stage", "grad-blue", [{"name": "SDK &amp; Compilers", "desc": "Build tools discarded later", "badge": "BUILD", "badge_bg": "#1e3a8a", "badge_fg": "#60a5fa"}])}
  <path d="M 290 155 L 340 155" stroke="#10b981" stroke-width="2.5" marker-end="url(#arrow-green)"/>
  <text x="315" y="145" fill="#10b981" font-size="10" text-anchor="middle">COPY --from</text>
  {stage_box(340, 80, 260, 150, "AS runtime", "Minimal Alpine", "grad-green", [{"name": "Production Binary", "desc": "Zero build dependencies", "badge": "TINY", "badge_bg": "#064e3b", "badge_fg": "#34d399"}])}
  <path d="M 600 155 L 650 155" stroke="#64748b" stroke-width="2.5" marker-end="url(#arrow)"/>
  {stage_box(650, 80, 260, 150, "USER 10001", "Non-Root Security", "grad-purple", [{"name": "Restricted User", "desc": "Root access stripped", "badge": "HARDENED", "badge_bg": "#3b0764", "badge_fg": "#c084fc"}])}
    """)

    # Day 4: K8s / Argo
    write_diagram("day4/images/lab-k8s-01-deployments.svg", 900, 260, f"""
  <text x="30" y="36" fill="#f8fafc" font-size="18" font-weight="700">LAB-K8S-01 — Kubernetes Pods, ReplicaSet and Deployments Architecture</text>
  <text x="30" y="58" fill="#64748b" font-size="12">Declarative Workload Management &amp; Self-Healing Reconciliation Loop</text>
  {stage_box(30, 80, 260, 150, "Deployment", "Workload Controller", "grad-blue", [{"name": "spec.replicas: 3", "desc": "Desired State Declaration", "badge": "DESIRED", "badge_bg": "#1e3a8a", "badge_fg": "#60a5fa"}])}
  <path d="M 290 155 L 340 155" stroke="#64748b" stroke-width="2.5" marker-end="url(#arrow)"/>
  {stage_box(340, 80, 260, 150, "ReplicaSet", "Pod Controller", "grad-green", [{"name": "Reconciliation Loop", "desc": "Maintains Pod count", "badge": "MANAGED", "badge_bg": "#064e3b", "badge_fg": "#34d399"}])}
  <path d="M 600 155 L 650 155" stroke="#64748b" stroke-width="2.5" marker-end="url(#arrow)"/>
  {stage_box(650, 80, 260, 150, "Pods (x3)", "Workload Pods", "grad-purple", [{"name": "Container Runtimes", "desc": "Running microservice pods", "badge": "RUNNING", "badge_bg": "#3b0764", "badge_fg": "#c084fc"}])}
    """)

    write_diagram("day4/images/lab-arg-01-gitops.svg", 900, 260, f"""
  <text x="30" y="36" fill="#f8fafc" font-size="18" font-weight="700">LAB-ARG-01 — Argo CD Declarative GitOps Synchronization</text>
  <text x="30" y="58" fill="#64748b" font-size="12">Git Repository as the Single Source of Truth Architecture</text>
  {stage_box(30, 80, 260, 150, "1. Git Repository", "Single Source of Truth", "grad-blue", [{"name": "K8s Manifests", "desc": "Git commit &amp; push", "badge": "GIT", "badge_bg": "#1e3a8a", "badge_fg": "#60a5fa"}])}
  <path d="M 290 155 L 340 155" stroke="#10b981" stroke-width="2.5" marker-end="url(#arrow-green)"/>
  <text x="315" y="145" fill="#10b981" font-size="10" text-anchor="middle">polling/webhook</text>
  {stage_box(340, 80, 260, 150, "2. Argo CD Server", "Reconciliation Engine", "grad-amber", [{"name": "Diff Detection", "desc": "Desired vs Actual State", "badge": "SYNC", "badge_bg": "#451a03", "badge_fg": "#fbbf24"}])}
  <path d="M 600 155 L 650 155" stroke="#8b5cf6" stroke-width="2.5" marker-end="url(#arrow)"/>
  <text x="625" y="145" fill="#c084fc" font-size="10" text-anchor="middle">apply</text>
  {stage_box(650, 80, 260, 150, "3. K8s Cluster", "Runtime Environment", "grad-purple", [{"name": "Auto Sync &amp; Self-Heal", "desc": "Cluster conforms to Git", "badge": "HEALTHY", "badge_bg": "#3b0764", "badge_fg": "#c084fc"}])}
    """)

    # Day 5: Monitoring / Capstone
    write_diagram("day5/images/lab-mon-01-metrics.svg", 900, 260, f"""
  <text x="30" y="36" fill="#f8fafc" font-size="18" font-weight="700">LAB-MON-01 — Prometheus and Grafana Observability Pipeline</text>
  <text x="30" y="58" fill="#64748b" font-size="12">Metrics Scraping (Pull Model), Time-Series Database &amp; Dashboard Panels</text>
  {stage_box(30, 80, 260, 150, "1. Exporters / Pods", "Metrics Sources", "grad-blue", [{"name": "/metrics Endpoints", "desc": "Node Exporter, cAdvisor, App", "badge": "METRICS", "badge_bg": "#1e3a8a", "badge_fg": "#60a5fa"}])}
  <path d="M 290 155 L 340 155" stroke="#f59e0b" stroke-width="2.5" marker-end="url(#arrow)"/>
  <text x="315" y="145" fill="#fbbf24" font-size="10" text-anchor="middle">pull scrape</text>
  {stage_box(340, 80, 260, 150, "2. Prometheus", "Time-Series Database", "grad-amber", [{"name": "PromQL &amp; Storage", "desc": "Collects and queries metrics", "badge": "TSDB", "badge_bg": "#451a03", "badge_fg": "#fbbf24"}])}
  <path d="M 600 155 L 650 155" stroke="#10b981" stroke-width="2.5" marker-end="url(#arrow-green)"/>
  <text x="625" y="145" fill="#34d399" font-size="10" text-anchor="middle">query</text>
  {stage_box(650, 80, 260, 150, "3. Grafana", "Visual Dashboards", "grad-green", [{"name": "Dashboard Panels", "desc": "Real-time CPU, RAM, Latency", "badge": "VISUAL", "badge_bg": "#064e3b", "badge_fg": "#34d399"}])}
    """)

    write_diagram("day5/images/lab-cap-01-capstone.svg", 960, 290, f"""
  <text x="30" y="36" fill="#f8fafc" font-size="18" font-weight="700">LAB-CAP-01 — DevOps Capstone End-to-End Enterprise Architecture</text>
  <text x="30" y="58" fill="#64748b" font-size="12">GitLab/Jenkins CI/CD ➔ Harbor ➔ Argo CD GitOps ➔ K8s Cluster ➔ Prometheus</text>
  {stage_box(30, 80, 170, 180, "1. Code &amp; CI", "CI Pipeline", "grad-blue", [{"name": "Test &amp; Build", "desc": "Automated pipeline", "badge": "CI OK", "badge_bg": "#1e3a8a", "badge_fg": "#60a5fa", "height": 65}])}
  <path d="M 200 160 L 220 160" stroke="#64748b" stroke-width="2" marker-end="url(#arrow)"/>
  {stage_box(220, 80, 170, 180, "2. Security", "Harbor &amp; Trivy", "grad-amber", [{"name": "Vulnerability", "desc": "0 CVE Gate", "badge": "SECURE", "badge_bg": "#451a03", "badge_fg": "#fbbf24", "height": 65}])}
  <path d="M 390 160 L 410 160" stroke="#64748b" stroke-width="2" marker-end="url(#arrow)"/>
  {stage_box(410, 80, 170, 180, "3. GitOps", "Argo CD", "grad-green", [{"name": "Auto Sync", "desc": "Git repo sync", "badge": "SYNCED", "badge_bg": "#064e3b", "badge_fg": "#34d399", "height": 65}])}
  <path d="M 580 160 L 600 160" stroke="#64748b" stroke-width="2" marker-end="url(#arrow)"/>
  {stage_box(600, 80, 170, 180, "4. Production", "K8s Runtime", "grad-purple", [{"name": "Live Cluster", "desc": "Ingress &amp; Pods", "badge": "PROD", "badge_bg": "#3b0764", "badge_fg": "#c084fc", "height": 65}])}
  <path d="M 770 160 L 790 160" stroke="#64748b" stroke-width="2" marker-end="url(#arrow)"/>
  {stage_box(790, 80, 160, 180, "5. Observability", "Grafana", "grad-rose", [{"name": "Monitoring", "desc": "Alerts &amp; Logs", "badge": "ALERT", "badge_bg": "#4c0519", "badge_fg": "#fb7185", "height": 65}])}
    """)


if __name__ == "__main__":
    generate_all()
