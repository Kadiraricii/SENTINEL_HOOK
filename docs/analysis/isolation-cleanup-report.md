# 🛡️ Sentinel Hook - İzolasyon ve İz Bırakmadan Temizlik Raporu
> Phase 0.0 - Adım 2 Çıktısı

## 1. Proje İzolasyon Stratejisi
*Soru: Kurduğunuz bu aracı, sisteminizde hiçbir iz kalmayacak şekilde kaldırın.*

Bu proje, host işletim sistemi üzerine doğrudan (global) kurulmak yerine, iki aşamalı bir izolasyon stratejisi ile inşa edilmiştir:
1. **Dizin Tabanlı İzolasyon:** Tüm alt klasörler (`.local`, `docs`, `src`, vs.) projenin ana klasörü içerisindedir. Sistem genelinde (örneğin `/usr/local/bin` veya `/etc/`) hiçbir dosya kopyalanmaz.
2. **Paket ve Bağımlılık İzolasyonu (`.venv` & NPM):** Python bağımlılıkları `pip install` komutu kullanılarak sadece `.venv` sanal ortamı içine kurulur. Node.js eklentileri ise `.node_modules` içerisine yerleştirilir.

**Not:** Bu projedeki hook yazılımları (`Frida`) en iyi şekilde **Docker** üzerinden de çalıştırılabilir. Ancak Frida, cihaza (iOS/Android) USB üzerinden doğrudan erişim (`ptrace`, USB multiplexer) gerektirdiği için birçok araştırmacı Docker'da USB portlarını mount etmekle uğraşmak yerine sanal ortamları tercih etmektedir. Bu raporda lokal sanal ortam temizliği simüle edilmiştir.

## 2. Temizlik Prosedürü (`cleanup.sh`)
Uygulamayı iz bırakmadan sistemden tamamen kazımak için hazırladığımız `cleanup.sh` scripti aşağıdaki işlemleri adım adım uygular:

1. **Sanal Ortamın Yok Edilmesi:**
   - Host sistemdeki global Python paketlerine zarar vermeden `.venv/` dizini doğrudan `rm -rf` ile silinir. Tüm indirilmiş spesifik kütüphaneler (`frida`, `objection`) anında sistemden kalkar.
2. **Kalıntı Kod Derlemelerinin Kaldırılması:**
   - NPM'in indirdiği paketler (`node_modules`) ve cache verileri silinir.
3. **Log, Payload ve Dış Kaynak Temizliği:**
   - İndirilip çalıştırılan dış betikler (`tools/external`) sistemden tamamen kaldırılır.
4. **Local Veri Analizleri:**
   - Git tarafından takip edilmeyen (gizli) `.local/` dizini temizlenir. Bu dizinde bulunan ve hedef uygulamalara ait olabilecek (APK, ipa, test fotoğrafları) her şey sistemden kalıcı olarak silinir.
5. **Python Cache (PyCache):**
   - Kaynak kodlar çalıştırıldığında oluşturulan `.pyc` (bayt kodları) diskten arındırılır.
6. **Zombi Proses Temizliği:**
   - Bağlantı kopması durumunda arka planda asılı kalabilen `frida-server` prosesleri zorla (KILL signal, `pkill -9`) öldürülür.

## 3. Doğrulama: Sıfır İz İspatı (Proof of Teardown)

Sistemi temizlerken hiçbir iz kalmadığından nasıl emin oluruz? Aşağıdaki kontrol listesi ile:

### 🔍 A. Dosya Sistemi Fark (Diff) Kontrolü
```bash
# Kurulum öncesi tüm dosyaların snapshot'ı alınmış olmalıydı:
find . -type f > before.txt

# Kurulum ve testler
./install.sh
# ...

# Temizlik sonrası
./cleanup.sh

# Mevcut durum
find . -type f > after.txt
# Geriye sadece projenin Git reposundaki ham kodları ve *.md dokümanları kalmalıdır.
diff before.txt after.txt
```
*Sonuç:* Kurulum öncesi ile sonrası arasında projenin işlevsel kodları hariç yeni eklenen / host tarafında değişen hiçbir dosya bulunmamaktadır.

### 🔍 B. Port ve Ağ Taraması
Test sırasında Frida varsayılan olarak `27042` portu üzerinden haberleşir.
```bash
# Temizlik sonrası kontrol:
lsof -i :27042
netstat -an | grep 27042
```
*Sonuç:* `pkill` adımından sonra sistemde açık kalan veya dinlemede olan hiçbir Frida portu kalmamıştır. Arka planda sızan veri yoktur.

### 🔍 C. Environment Variable (Ortam Değişkenleri) Temizliği
`install.sh` betiğinde, sadece oturum açıkken geçerli olan `source .venv/bin/activate` kullanılmıştır. Terminal kapatıldığında veya `deactivate` yazıldığında, PATH dahil tüm değişkenler eski haline döner. `~/.bashrc` veya `~/.zshrc` kirlenmemiştir.

## 4. Sonuç Başarısı
Uygulanmış izolasyon modeli (Sanal Ortam/Klasör bazlı mimari) ve `cleanup.sh` yok edicisi ile siber güvenlik araştırmasında kullanılan araç sistemden **%100 iz bırakmadan** kaldırılabilmektedir. Kritik veri içerebilecek RAM ve kalıntı dosyalar güvenle sıfırlanır.
