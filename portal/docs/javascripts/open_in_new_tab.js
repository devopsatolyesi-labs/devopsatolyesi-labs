document.addEventListener("DOMContentLoaded", function() {
  var accessRole = null;

  function isLabPage(pathname, expression) {
    return expression.test(pathname);
  }

  function canOpen(pathname) {
    if (accessRole === "admin") return true;
    if (pathname.indexOf("/curriculum/") === 0 || pathname.indexOf("/env/") === 0 || pathname.indexOf("/lab-assets/") === 0 || pathname === "/devops-labs.zip") return false;
    if (accessRole === "devops") {
      return isLabPage(pathname, /^\/day1\/LAB-(LNX-01-linux-preflight|GIT-01-git-workflow|DOC-01-docker-first-container|DOC-02-docker-volumes-env)(\/|\.html)?$/) ||
        isLabPage(pathname, /^\/day2\/LAB-DOC-(03-dockerfile-optimization|04-docker-multistage-hardening|05-docker-compose-multitier|06-trivy-harbor-integration|13-docker-compose-production-patterns)(\/|\.html)?$/) ||
        isLabPage(pathname, /^\/day3\/LAB-(JNK-01-jenkins-declarative-pipeline|JNK-02-jenkins-secure-pipeline|GLB-01-gitlab-ci-pipeline|TF-01-terraform-docker-provider|TF-04-terraform-helm-centralized-monitoring|TF-08-terraform-aws-vpc-architecture)(\/|\.html)?$/) ||
        isLabPage(pathname, /^\/day4\/LAB-(K8S-01-kind-pods-deployments|K8S-02-services-config-secrets|K8S-03-production-workloads|HLM-01-helm-chart-deployment|ARG-01-argocd-gitops-sync)(\/|\.html)?$/) ||
        isLabPage(pathname, /^\/day5\/LAB-(MON-01-prometheus-grafana-metrics|MON-02-alertmanager-rules|LOG-01-centralized-logging|LOG-02-elk-centralized-logging|INC-01-k8s-crashloop-postmortem|CAP-01-end-to-end-devops)(\/|\.html)?$/);
    }
    if (accessRole === "docker" || accessRole === "kubernetes") {
      return isLabPage(pathname, /^\/day1\/LAB-DOC-(01-docker-first-container|02-docker-volumes-env)(\/|\.html)?$/) ||
        isLabPage(pathname, /^\/day2\/LAB-DOC-(03-dockerfile-optimization|05-docker-compose-multitier)(\/|\.html)?$/) ||
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

  function applyCourseNavigation() {
    if (!accessRole) return;
    installAdminButton();
    installLogoutButton();
    if (accessRole === "admin") return;
    // Material renders the drawer/sidebar and desktop tabs as separate menus.
    // Filter both so a student never sees a link that the edge would reject.
    var links = document.querySelectorAll("a.md-nav__link[href], a.md-tabs__link[href]");
    for (var i = 0; i < links.length; i++) {
      var path = new URL(links[i].href, window.location.origin).pathname;
      if (!canOpen(path)) {
        var item = links[i].closest("li.md-nav__item, li.md-tabs__item");
        if (item) item.remove();
      }
    }

    // Do not leave an empty topic heading behind after its forbidden labs have
    // been removed from the student navigation.
    var sections = document.querySelectorAll("li.md-nav__item--nested");
    for (var j = sections.length - 1; j >= 0; j--) {
      if (!sections[j].querySelector("a.md-nav__link[href]")) sections[j].remove();
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

  makeExternalLinksOpenInNewTab();
  loadIdentity();

  if (typeof location$ !== "undefined") {
    location$.subscribe(function() {
      setTimeout(makeExternalLinksOpenInNewTab, 100);
      setTimeout(applyCourseNavigation, 100);
    });
  }
});
