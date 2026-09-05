# PROJECT-DK-01 — Container’dan Kubernetes’e Uygulama Teslimi

## Amaç

Bir web uygulamasını imaj haline getirip Kubernetes üzerinde çalıştırın; ağ erişimi, kaynak sınırları ve veri kalıcılığını gerçek çalışma zamanı kanıtlarıyla gösterin.

## Beklenen Teslimler

- Uygulama için tekrar üretilebilir bir `Dockerfile`
- Sürümlenmiş bir container image
- Deployment ve Service manifestleri
- Resource request/limit değerleri
- Kalıcı veri için uygun PVC seçimi
- `docker image inspect`, `kubectl get`, `kubectl describe`, `kubectl logs` ve `curl` çıktılarından oluşan kısa doğrulama notu

## Uygulama Koşulları

1. Uygulamayı container içinde root olmayan kullanıcıyla çalıştırın.
2. Image için değişmez bir sürüm etiketi kullanın; `latest` kullanmayın.
3. Deployment en az iki replica çalıştırsın.
4. Service yalnız gerekli uygulama portunu açsın.
5. Liveness ve readiness probe tanımlayın.
6. Namespace için ResourceQuota ve LimitRange kurallarına uyun.
7. Birden fazla Pod’un yazması gereken veri için NFS tabanlı `ReadWriteMany` PVC kullanın.
8. Pod silinip yeniden oluşturulduktan sonra verinin kaldığını gösterin.

## Başlangıç Dosyaları

Paket içindeki `starter/` dizininde Dockerfile ile Kubernetes manifest taslakları bulunur. `TODO` alanlarını kendi image adınız ve kaynak değerlerinizle tamamlayın.

## Doğal Doğrulama ve Beklenen Sonuç

```bash
docker image inspect YOUR_IMAGE:YOUR_TAG
kubectl get deploy,pod,svc,pvc -n dk-project
kubectl describe deployment web -n dk-project
kubectl logs -n dk-project deployment/web --tail=50
kubectl port-forward -n dk-project service/web 8080:80
curl -fsS http://127.0.0.1:8080
```

Teslim, yalnız manifestlerin bulunmasıyla değil; çalışan iki Pod, sağlıklı probe sonuçları, HTTP yanıtı ve kalıcı veri kanıtıyla tamamlanır.
