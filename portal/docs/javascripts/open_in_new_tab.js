document.addEventListener("DOMContentLoaded", function() {
  var username = null;

  function isLabPage(pathname, expression) {
    return expression.test(pathname);
  }

  function canOpen(pathname) {
    if (username === "admin") return true;
    if (pathname.indexOf("/curriculum/") === 0 || pathname.indexOf("/env/") === 0 || pathname.indexOf("/lab-assets/") === 0 || pathname === "/devops-labs.zip") return false;
    if (username === "devops") {
      return isLabPage(pathname, /^\/day1\/LAB-(LNX-01-linux-preflight|GIT-01-git-workflow|DOC-01-docker-first-container|DOC-02-docker-volumes-env)(\/|\.html)?$/) ||
        isLabPage(pathname, /^\/day2\/LAB-DOC-(03-dockerfile-optimization|04-docker-multistage-hardening|05-docker-compose-multitier|06-trivy-harbor-integration|13-docker-compose-production-patterns)(\/|\.html)?$/) ||
        isLabPage(pathname, /^\/day3\/LAB-(JNK-01-jenkins-declarative-pipeline|JNK-02-jenkins-secure-pipeline|GLB-01-gitlab-ci-pipeline|TF-01-terraform-docker-provider|TF-04-terraform-helm-centralized-monitoring|TF-08-terraform-aws-vpc-architecture)(\/|\.html)?$/) ||
        isLabPage(pathname, /^\/day4\/LAB-(K8S-01-kind-pods-deployments|K8S-02-services-config-secrets|K8S-03-production-workloads|HLM-01-helm-chart-deployment|ARG-01-argocd-gitops-sync)(\/|\.html)?$/) ||
        isLabPage(pathname, /^\/day5\/LAB-(MON-01-prometheus-grafana-metrics|MON-02-alertmanager-rules|LOG-01-centralized-logging|LOG-02-elk-centralized-logging|INC-01-k8s-crashloop-postmortem|CAP-01-end-to-end-devops)(\/|\.html)?$/);
    }
    if (username === "docker" || username === "kubernetes") {
      return isLabPage(pathname, /^\/day1\/LAB-DOC-(01-docker-first-container|02-docker-volumes-env)(\/|\.html)?$/) ||
        isLabPage(pathname, /^\/day2\/LAB-DOC-(03-dockerfile-optimization|05-docker-compose-multitier)(\/|\.html)?$/) ||
        isLabPage(pathname, /^\/day4\/LAB-K8S-(01-kind-pods-deployments|02-services-config-secrets|03-production-workloads)(\/|\.html)?$/);
    }
    return false;
  }

  function applyCourseNavigation() {
    if (!username) return;
    var logout = document.querySelector(".md-header__source");
    if (!logout) {
      logout = document.createElement("a");
      logout.className = "md-header__source";
      logout.href = "/logout";
      logout.textContent = "Çıkış";
      logout.setAttribute("title", "Portal çıkışı");
      var header = document.querySelector(".md-header__inner");
      if (header) header.appendChild(logout);
    }
    if (username === "admin") return;
    var links = document.querySelectorAll("a.md-nav__link[href]");
    for (var i = 0; i < links.length; i++) {
      var path = new URL(links[i].href, window.location.origin).pathname;
      if (!canOpen(path)) {
        var item = links[i].closest("li.md-nav__item");
        if (item) item.remove();
      }
    }
    var search = document.querySelector('[data-md-component="search"]');
    if (search) search.remove();
  }

  function loadIdentity() {
    fetch("/_auth/me", {credentials: "same-origin", cache: "no-store"})
      .then(function(response) {
        if (!response.ok) throw new Error("identity request failed");
        return response.json();
      })
      .then(function(identity) {
        username = identity.username;
        applyCourseNavigation();
      })
      .catch(function() {
        username = "unauthorized";
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

  makeExternalLinksOpenInNewTab();
  loadIdentity();

  if (typeof location$ !== "undefined") {
    location$.subscribe(function() {
      setTimeout(makeExternalLinksOpenInNewTab, 100);
      setTimeout(applyCourseNavigation, 100);
    });
  }
});
