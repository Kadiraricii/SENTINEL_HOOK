# 🛡️ Sentinel Hook - Docker Mimarisi ve Konteyner Güvenliği 🐳
> Phase 0.0 - Adım 4 Çıktısı

Bu dokümanda Sentinel Hook test arayüzünün (sandbox) Docker üzerindeki tasarımı, katman mimarisi ve güvenlik konseptleri ele alınmaktadır.

## 1. Docker İmaj / Katman (Layer) Analizi

`Dockerfile` iki aşamalı (Multi-stage build) bir formda kurgulanmıştır ve şu temel güvenlik/optimizasyon kurallarına uyar:

1. **Katman 1 (builder):** `python:3.10-slim-bullseye` baz alınarak sadece Python derleme bağımlılıkları barındırır. `pip install` komutları burada çalışır ve yalnızca saf Python kütüphanelerini tutar.
2. **Katman 2 (runner):** İşletim ortamıdır. Node.js ve ADB gibi doğrudan çalıştırılabilir araçları içerir.
3. **Güvenlik Mimarisi:**
   - **Gereksiz Yükün Atılması (Attack Surface Yüzeyi):** İlk katmanda derlenen cache dosyaları (apt cache, gcc vb.) ikinci katmana alınmaz, bu sayede konteyner hem MB boyutunda ufalır (az alan) hem de olası bir RCE saldırısında hacker'in elinde derleyici (compiler) araçlar bulunmaz.
   - **Rootless (Non-root) Çalışma:** `adduser --system sentinel` ile yetkili bir kullanıcı yaratılarak, imaj varsayılan olarak root yetkilerini *düşürmüştür* (Privilege Drop). Bu sayede hacker konteyner kodunu kırsa bile `root` olamadığı için host cihaza sızamaz (Container Escape).

## 2. Erişim Limitsizliği ve Konteyner İzolasyonu 

`docker-compose.yml` özel yapılandırılmıştır:
- Hata: Çoğu pentester `Frida` kullanırken `--privileged` verir. Bu güvenli değildir.
- Bizim Tasarımımız: `privileged: false` ayarlandık ve Frida'nın donanımları görmesi için sadece `/dev/bus/usb` cihaz konumunu konteynera doğrudan map ettik. Bu **Least Privilege (En Az Yetki)** felsefesinin kalbidir.
- **Volume Mounts:**
  - `./docs:/app/docs:ro` (RO = Read Only). Hosttan veriyi sadece okumak amaçlı alır. Konteyner içinde yazma yapılsa da host'daki veriyi silemez. Host bütünlüğünü korur.

## 3. KRİTİK SORU: Docker imajı nedir ve Katmanlar nasıl çalışır?

**Docker İmajı:** Üst üste binen (stacked) salt okunur (read-only) işletim sistemi dosyalarının sanallaştırılmış bir yığınıdır. Katmanlar, `Dockerfile` içindeki her `RUN`, `COPY`, `ADD` işlemiyle sırayla oluşturulur.
- Çekirdeği (Kernel) Docker Engine ile Host üzerinden paylaşır, fakat kendisine ait izole bir Cgroup (donanım limiti) ve Namespace (Ağ/PID ayrımı) vardır.
- "Gemi taşınırken konteynerın ne taşıdığına gemi bakmaz".
 
## 4. Karşılaştırma Analizi: Docker vs Kubernetes (K8s) vs Sanal Makine (VM)

| Karşılaştırma Noktası | Docker (Konteyner) | Kubernetes (Orkestrasyon) | Sanal Makine (VM) |
| --- | --- | --- | --- |
| **Mimari** | Kendi başına konteyner koşturur. İşletim sistemi Kernel'i paylaşımlıdır. | Binlerce Docker'ı / Konteyneri yüzlerce fiziksel makinede kümeleyen (cluster) bir yönetim ahtapotudur. | CPU donanımı Hypervisor ile tamamen bölünür, kendi Kernel'ine, kendi Windows/Linux çekirdeğine sahiptir. |
| **Güvenlik Düzeyi** | Çok Yüksek değil (Kernel paylaşıldığı için kernel bypass/escape ihtimali vardır). | Container seviyesi güvenlik + RBA, Pod Security Policies. Güvenliği policy düzeyinde zordur. | **En Üstün Güvenlik.** VMWare/VirtualBox donanımı ayırdığı için kaçış imkansıza yakındır. |
| **Açılış/Tepki Süresi** | Milisaniye (Çok Hızlı) | Saniyeler (Scale olurken) | Dakikalar (Ağır İşler) |
| **Hangi durumda hangisi:** | Geliştirici veya bizim gibi testçi (Frida sandbox'ı) doğrudan PC'de hızlı test ortamı isterse kullanılır. | Sentinel Bypass projesini arka planda binlerce bulut sunucusunda analiz yapmak için Scale etseydik (Mass-Scanner) K8s kullanırdık. | Güvenemediğimiz, sıfır-gün (zero-day) trojan analizleri yapacaksak (Zararlı Yazılım Analizi) kesinlikle izole bir **VM** içinde yapmalıyız. |
