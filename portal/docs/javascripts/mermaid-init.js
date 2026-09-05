(() => {
  const renderDiagrams = () => {
    if (!window.mermaid) return;
    window.mermaid.initialize({ startOnLoad: false, securityLevel: "strict" });
    window.mermaid.run({ querySelector: ".mermaid:not([data-processed])" });
  };

  if (window.document$) {
    window.document$.subscribe(renderDiagrams);
  } else {
    document.addEventListener("DOMContentLoaded", renderDiagrams, { once: true });
  }
})();
