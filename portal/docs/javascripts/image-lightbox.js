(() => {
  const overlayId = "portal-image-lightbox";

  function closeLightbox() {
    const overlay = document.getElementById(overlayId);
    if (!overlay) return;
    overlay.hidden = true;
    document.body.style.removeProperty("overflow");
  }

  function openLightbox(image) {
    let overlay = document.getElementById(overlayId);
    if (!overlay) {
      overlay = document.createElement("div");
      overlay.id = overlayId;
      overlay.className = "image-lightbox";
      overlay.hidden = true;
      overlay.setAttribute("role", "dialog");
      overlay.setAttribute("aria-modal", "true");
      overlay.innerHTML = `
        <button class="image-lightbox__close" type="button" aria-label="Görseli kapat">×</button>
        <img class="image-lightbox__image" alt="">
        <div class="image-lightbox__caption"></div>`;
      overlay.addEventListener("click", (event) => {
        if (event.target === overlay || event.target.classList.contains("image-lightbox__image")) closeLightbox();
      });
      overlay.querySelector(".image-lightbox__close").addEventListener("click", closeLightbox);
      document.body.appendChild(overlay);
    }

    const fullImage = overlay.querySelector(".image-lightbox__image");
    fullImage.src = image.currentSrc || image.src;
    fullImage.alt = image.alt || "Büyütülmüş lab diyagramı";
    overlay.querySelector(".image-lightbox__caption").textContent = image.alt || "";
    overlay.hidden = false;
    document.body.style.overflow = "hidden";
    overlay.querySelector(".image-lightbox__close").focus();
  }

  function attachLightbox() {
    document.querySelectorAll(".md-content img:not(.image-lightbox-trigger)").forEach((image) => {
      image.classList.add("image-lightbox-trigger");
      image.title = image.alt ? `${image.alt} — büyütmek için tıklayın` : "Büyütmek için tıklayın";
      image.tabIndex = 0;
      image.setAttribute("role", "button");
      image.addEventListener("click", () => openLightbox(image));
      image.addEventListener("keydown", (event) => {
        if (event.key === "Enter" || event.key === " ") {
          event.preventDefault();
          openLightbox(image);
        }
      });
    });
  }

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") closeLightbox();
  });

  if (typeof document$ !== "undefined") {
    document$.subscribe(() => setTimeout(attachLightbox, 50));
  } else {
    document.addEventListener("DOMContentLoaded", attachLightbox, { once: true });
  }
})();
