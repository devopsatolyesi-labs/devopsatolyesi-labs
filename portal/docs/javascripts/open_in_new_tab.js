document.addEventListener("DOMContentLoaded", function() {
  var accessRole = null;
  var mermaidInitialized = false;

  function isLabPage(pathname, expression) {
    return expression.test(pathname);
  }

  function canOpen(pathname) {
    if (!pathname) return true;
    if (accessRole === "admin") return true;

    // Platform environment admin setup and raw master archives are strictly admin-only
    if (pathname.indexOf("/env/") === 0 || pathname.indexOf("/lab-assets/") === 0 || pathname === "/devops-labs.zip") {
      return false;
    }

    // Portal home, general setup, curriculum syllabi, reference, troubleshooting, and search are available to students
    if (pathname === "/" || pathname === "/index.html" || pathname === "") return true;
    if (pathname.indexOf("/setup") === 0) return true;
    if (pathname.indexOf("/curriculum") === 0) return true;
    if (pathname.indexOf("/troubleshooting") === 0) return true;
    if (pathname.indexOf("/reference") === 0) return true;
    if (pathname.indexOf("/search") === 0) return true;

    if (accessRole === "devops") {
      if (pathname.indexOf("/projects") === 0) return true;
      return isLabPage(pathname, /^\/day1\/LAB-(LNX-(01-linux-preflight|02-nginx-letsencrypt-ssl|03-ssh-tunnel-mysql)|GIT-01-git-workflow|DOC-(01-docker-first-container|02-docker-volumes-env))(\/|\.html)?$/) ||
        isLabPage(pathname, /^\/day2\/LAB-DOC-(03-dockerfile-optimization|04-docker-multistage-hardening|05-docker-compose-multitier|06-trivy-harbor-integration|07-docker-java-spring-boot|08-docker-react-nginx|09-docker-networks-dns|10-docker-backup-restore|13-docker-compose-production-patterns)(\/|\.html)?$/) ||
        isLabPage(pathname, /^\/day3\/LAB-(JNK-(01-jenkins-declarative-pipeline|02-jenkins-secure-pipeline)|GLB-01-gitlab-ci-pipeline|GHA-01-github-actions-ci|TF-(01-terraform-docker-provider|04-terraform-helm-centralized-monitoring|08-terraform-aws-vpc-architecture))(\/|\.html)?$/) ||
        isLabPage(pathname, /^\/day4\/LAB-(K8S-(01-kind-pods-deployments|02-services-config-secrets|03-production-workloads)|HLM-01-helm-chart-deployment|ARG-01-argocd-gitops-sync)(\/|\.html)?$/) ||
        isLabPage(pathname, /^\/day5\/LAB-(MON-(01-prometheus-grafana-metrics|02-alertmanager-rules)|LOG-(01-centralized-logging|02-elk-centralized-logging)|INC-01-k8s-crashloop-postmortem|CAP-01-end-to-end-devops)(\/|\.html)?$/);
    }
    if (accessRole === "docker" || accessRole === "kubernetes") {
      return isLabPage(pathname, /^\/day1\/LAB-DOC-(01-docker-first-container|02-docker-volumes-env)(\/|\.html)?$/) ||
        isLabPage(pathname, /^\/day2\/LAB-DOC-(03-dockerfile-optimization|04-docker-multistage-hardening|05-docker-compose-multitier|06-trivy-harbor-integration|07-docker-java-spring-boot|08-docker-react-nginx|09-docker-networks-dns|10-docker-backup-restore|13-docker-compose-production-patterns)(\/|\.html)?$/) ||
        isLabPage(pathname, /^\/day4\/LAB-K8S-(01-kind-pods-deployments|02-services-config-secrets|03-production-workloads)(\/|\.html)?$/);
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

    // Filter sidebar navigation links and top desktop tabs
    var links = document.querySelectorAll("a.md-nav__link[href], a.md-tabs__link[href]");
    for (var i = 0; i < links.length; i++) {
      var path = new URL(links[i].href, window.location.origin).pathname;
      if (!canOpen(path)) {
        var item = links[i].closest("li.md-nav__item, li.md-tabs__item");
        if (item) item.remove();
      }
    }

    // Do not leave empty nested section containers
    var sections = document.querySelectorAll("li.md-nav__item--nested");
    for (var j = sections.length - 1; j >= 0; j--) {
      if (!sections[j].querySelector("a.md-nav__link[href]")) sections[j].remove();
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
