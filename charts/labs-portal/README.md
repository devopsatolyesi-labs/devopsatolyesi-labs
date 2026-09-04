# Labs portal Kubernetes sözleşmesi

Portal image'ı CI'da build edilip registry'ye gönderilir; Kind ortamında
gerekirse `kind load docker-image` ile cluster'a alınır. Chart stateless'tir:
öğrenci içerikleri image içinde, kullanıcı/rol yönetimi Keycloak'ta tutulur.
Bu nedenle portal pod'u yeniden yaratıldığında içerik kaybolmaz.
