document.addEventListener("DOMContentLoaded", function() {
  var accessRole = null;
  var mermaidInitialized = false;

  function normalizePath(pathname) {
    if (!pathname) return "";
    var p = pathname.split("?")[0].split("#")[0];
    p = p.replace(/\/index\.html$/, "").replace(/\.html$/, "");
    if (p.length > 1 && p.charAt(p.length - 1) === "/") {
      p = p.slice(0, -1);
    }
    return p;
  }

  function canOpen(pathname) {
    if (!pathname) return true;
    if (accessRole === "admin") return true;

    var p = normalizePath(pathname);

    // Platform environment admin setup, raw lab guides, and master zip are strictly admin-only
    if (p.indexOf("/env") === 0 || p.indexOf("/labs") === 0 || p.indexOf("/lab-assets") === 0 || p === "/devops-labs.zip") {
      return false;
    }

    // Portal home, general search, and common static assets are available to all students
    if (p === "" || p === "/" || p.indexOf("/search") === 0) {
      return true;
    }

    // Reference matrices are accessible to all students
    if (p.indexOf("/reference") === 0) {
      return true;
    }

    // DevOps Practitioner Role (5-day comprehensive course):
    // Full access across Day 1 to Day 5, Projects, Troubleshooting, Curriculum, and Setup.
    if (accessRole === "devops") {
      if (p.indexOf("/curriculum") === 0) return true;
      if (p.indexOf("/setup") === 0) return true;
      if (p.indexOf("/projects") === 0) return true;
      if (p.indexOf("/troubleshooting") === 0) return true;

      // Matches ANY lab on Day 1 to Day 5 (all 64 active labs across Linux, Git, Docker, CI/CD, K8s, GitOps, Monitoring, Capstone)
      if (/^\/day[1-5]\/LAB-[A-Za-z0-9_-]+$/.test(p)) return true;

      // Downloads: any student lab package
      if (/^\/downloads\/LAB-[A-Za-z0-9_-]+\.zip$/.test(p)) return true;

      return false;
    }

    // Docker and Kubernetes Role (2-day focused course):
    // Strictly Docker (all 20 labs) and Kubernetes (all 12 labs), plus 2-day curriculum and Docker/K8s setup.
    if (accessRole === "kubernetes" || accessRole === "docker") {
      // 2-Day specific curriculum and shared indexes ONLY (blocks 5-day curriculum)
      if (p === "/curriculum/02_2_DAY_DOCKER_KUBERNETES" ||
          p === "/curriculum/02_LAB_CATALOG_INDEX" ||
          p === "/curriculum/06_DEMO_APPLICATION_MAPPING") {
        return true;
      }

      // Docker & Kubernetes relevant setup guides only
      if (p === "/setup" ||
          p === "/setup/docker-engine" ||
          p === "/setup/kind-cluster" ||
          p === "/setup/kubeadm-cluster" ||
          p === "/setup/kubeconfig-management" ||
          p === "/setup/nfs-storageclass" ||
          p === "/setup/docker-kubernetes") {
        return true;
      }

      // All 20 Docker labs (Day 1 & Day 2: LAB-DOC-01 to LAB-DOC-20)
      if (/^\/day[12]\/LAB-DOC-[A-Za-z0-9_-]+$/.test(p)) return true;

      // All 12 Kubernetes labs (Day 4: LAB-K8S-01 to LAB-K8S-12)
      if (/^\/day4\/LAB-K8S-[A-Za-z0-9_-]+$/.test(p)) return true;

      // Downloads: strictly Docker and Kubernetes starter packages
      if (/^\/downloads\/LAB-(?:DOC|K8S)-[A-Za-z0-9_-]+\.zip$/.test(p)) return true;

      return false;
    }

    return false;
  }

  function installLogoutButton() {
    if (document.getElementById("portal-logout")) return;

    var reauthenticate = window.location.origin + "/oauth2/start?rd=%2F&prompt=login";
    var logout = document.createElement("a");
    logout.id = "portal-logout";
    logout.className = "md-header__button";
    logout.href = "/oauth2/sign_out?rd=" + encodeURIComponent(reauthenticate);
    logout.textContent = "Çıkış";
    logout.setAttribute("title", "Portal ve kimlik oturumunu kapat");
    logout.style.color = "inherit";
    logout.style.fontWeight = "600";
    logout.style.whiteSpace = "nowrap";

    var header = document.querySelector(".md-header__inner");
    if (header) header.appendChild(logout);
  }

  function installAdminButton() {
    if (accessRole !== "admin" || document.getElementById("keycloak-admin")) return;

    var admin = document.createElement("a");
    admin.id = "keycloak-admin";
    admin.className = "md-header__button";
    admin.href = "https://auth.devopsatolyesi.com/admin/devops-atolyesi/console/";
    admin.target = "_blank";
    admin.rel = "noopener noreferrer";
    admin.textContent = "Kullanıcı Yönetimi";
    admin.setAttribute("title", "Keycloak kullanıcı ve grup yönetimi");
    admin.style.color = "inherit";
    admin.style.fontWeight = "600";
    admin.style.whiteSpace = "nowrap";

    var header = document.querySelector(".md-header__inner");
    if (header) header.appendChild(admin);
  }

  function filterSearchResults() {
    if (accessRole === "admin") return;
    var resultItems = document.querySelectorAll(".md-search-result__item");
    for (var i = 0; i < resultItems.length; i++) {
      var a = resultItems[i].querySelector("a.md-search-result__link");
      if (a) {
        var path = new URL(a.href, window.location.origin).pathname;
        if (!canOpen(path)) {
          resultItems[i].style.display = "none";
        } else {
          resultItems[i].style.display = "";
        }
      }
    }
  }

  function attachSearchFilter() {
    var searchOutput = document.querySelector(".md-search__output");
    if (searchOutput && !searchOutput.hasAttribute("data-filter-attached")) {
      searchOutput.setAttribute("data-filter-attached", "true");
      var observer = new MutationObserver(function() {
        filterSearchResults();
      });
      observer.observe(searchOutput, { childList: true, subtree: true });
    }
  }

  function applyCourseNavigation() {
    if (!accessRole) return;
    installAdminButton();
    installLogoutButton();
    attachSearchFilter();
    if (accessRole === "admin") return;

    // Redirect to home if current page is unauthorized for this role
    if (!canOpen(window.location.pathname)) {
      window.location.replace("/");
      return;
    }

    // For 2-day role, adapt the top curriculum tab and navigation links so they point to 2-day curriculum
    if (accessRole === "kubernetes" || accessRole === "docker") {
      var curLinks = document.querySelectorAll("a.md-tabs__link[href*='01_5_DAY_CURRICULUM'], a.md-nav__link[href*='01_5_DAY_CURRICULUM']");
      for (var c = 0; c < curLinks.length; c++) {
        var link = curLinks[c];
        var parentItem = link.closest("li.md-tabs__item, li.md-nav__item--nested");
        if (parentItem && (link.classList.contains("md-tabs__link") || link.parentElement === parentItem)) {
          link.setAttribute("href", "/curriculum/02_2_DAY_DOCKER_KUBERNETES/");
        }
      }
    }

    // 1. Filter desktop tabs
    var tabs = document.querySelectorAll("li.md-tabs__item");
    for (var t = 0; t < tabs.length; t++) {
      var tabLink = tabs[t].querySelector("a.md-tabs__link[href]");
      if (tabLink) {
        var tabPath = new URL(tabLink.href, window.location.origin).pathname;
        if (!canOpen(tabPath)) {
          tabs[t].remove();
        }
      }
    }

    // 2. Filter sidebar leaf navigation links
    var navLinks = document.querySelectorAll(".md-sidebar a.md-nav__link[href], .md-nav--primary a.md-nav__link[href]");
    for (var i = 0; i < navLinks.length; i++) {
      var path = new URL(navLinks[i].href, window.location.origin).pathname;
      if (!canOpen(path)) {
        var item = navLinks[i].closest("li.md-nav__item");
        if (item && !item.classList.contains("md-nav__item--nested")) {
          item.remove();
        }
      }
    }

    // 3. Clean up any empty nested section containers (bottom-up)
    var sections = document.querySelectorAll("li.md-nav__item--nested");
    for (var j = sections.length - 1; j >= 0; j--) {
      if (!sections[j].querySelector("a.md-nav__link[href]")) {
        sections[j].remove();
      }
    }
  }

  function loadIdentity() {
    fetch("/_auth/me", {credentials: "same-origin", cache: "no-store"})
      .then(function(response) {
        if (!response.ok) throw new Error("identity request failed");
        return response.json();
      })
      .then(function(identity) {
        accessRole = identity.course;
        applyCourseNavigation();
      })
      .catch(function() {
        accessRole = "unauthorized";
        applyCourseNavigation();
      });
  }

  function makeExternalLinksOpenInNewTab() {
    var links = document.querySelectorAll("a[href^='http://'], a[href^='https://']");
    for (var i = 0; i < links.length; i++) {
      var link = links[i];
      if (link.hostname !== window.location.hostname) {
        link.setAttribute("target", "_blank");
        link.setAttribute("rel", "noopener noreferrer");
      }
    }
  }

  function renderMermaidDiagrams() {
    if (!window.mermaid) {
      setTimeout(renderMermaidDiagrams, 100);
      return;
    }
    if (!mermaidInitialized) {
      window.mermaid.initialize({startOnLoad: false, securityLevel: "strict"});
      mermaidInitialized = true;
    }
    var diagrams = document.querySelectorAll(".mermaid:not([data-processed])");
    if (diagrams.length > 0) {
      window.mermaid.run({nodes: diagrams}).catch(function(error) {
        console.error("Mermaid render failed", error);
      });
    }
  }

  makeExternalLinksOpenInNewTab();
  renderMermaidDiagrams();
  loadIdentity();

  if (typeof document$ !== "undefined") {
    document$.subscribe(function() {
      setTimeout(makeExternalLinksOpenInNewTab, 100);
      setTimeout(applyCourseNavigation, 100);
      setTimeout(renderMermaidDiagrams, 100);
    });
  }
});
