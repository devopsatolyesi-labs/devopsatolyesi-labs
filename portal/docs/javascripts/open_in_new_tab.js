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

    // Platform sources and raw assets are admin-only.
    if (p.indexOf("/env") === 0 || p.indexOf("/labs") === 0 || p.indexOf("/lab-assets") === 0 || p === "/devops-labs.zip") {
      return false;
    }

    // Portal shell is common; all course content is an exact generated allow-list.
    if (p === "" || p === "/" || p.indexOf("/search") === 0) {
      return true;
    }
    var policies = window.PORTAL_ACCESS_POLICY && window.PORTAL_ACCESS_POLICY.roles;
    var policy = policies && policies[accessRole];
    return Boolean(policy && policy.paths && policy.paths.indexOf(p) !== -1);
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

    // The tab uses its first child as target; point it to the enrolled course.
    if (accessRole === "kubernetes" || accessRole === "docker") {
      var curLinks = document.querySelectorAll("a.md-tabs__link[href*='devops-practitioner-5-day']");
      for (var c = 0; c < curLinks.length; c++) {
        var link = curLinks[c];
        link.setAttribute("href", "/courses/docker-kubernetes-2-day/");
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
