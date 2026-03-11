# 🛡️ Sentinel Hook - İzole Test Ortamı
# Multi-stage yapı kullanılarak güvenliği artırılmış Dockerfile ve non-root user

FROM python:3.10-slim-bullseye AS builder

# 1. Aşama: Bağımlılıkların derlenmesi ve ortamın hazırlanması
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN mkdir -p /install
WORKDIR /install

# Sadece gereksinimleri kopyalayarak docker cache mantığını koruyalım
# Security: Bu projedeki requirements'da --require-hashes kuralı uygulanmalıdır.
COPY requirements.txt ./
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ----------------------------------------------------------------------------
FROM python:3.10-slim-bullseye AS runner
# 2. Aşama: Çalıştırma ortamı (Çok daha küçük ve güvenli bir imaj)

# Node.js ve ADB gibi sistem çapı bağımlılıklarını kur
RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs \
    npm \
    android-tools-adb \
    usbutils \
    && rm -rf /var/lib/apt/lists/*

# Özel yetkisiz (non-root) kullanıcı oluştur (Security Best Practice)
RUN addgroup --system sentinel && adduser --system --group sentinel
# ADB usb cihazları görebilsin diye kullanıcımızı plugdev grubuna ekliyoruz
RUN usermod -aG plugdev sentinel

WORKDIR /app

# Builder katmanında kurduğumuz saf Python paketlerini kopyala
COPY --from=builder /install /usr/local

# Kaynak kodları kopyala
COPY --chown=sentinel:sentinel . .

# Sentinel kullanıcısına geç (Bundan sonraki komutlar root DEĞİL)
USER sentinel

# Frida-compile için node paketlerini yükle
RUN npm install

# USB üzerinden emülatöre veya iPhone'a bağlanılacağı için portları (frida varsayılan 27042) sabitleyelim
EXPOSE 27042 27043

# Start shell
CMD ["/bin/bash"]
