#!/usr/bin/env bash

# ==============================================================================
# Sentinel Hook - Frida Server Setup Automation (iOS / Android)
# ==============================================================================
# Bu script, bağlı hedef cihaza frida-server paketini gönderir ve çalıştırır.
#
# iOS için: Cihazın jailbroken olması ve Cydia/Sileo üzerinden 'Frida' 
# kurulmuş olması önerilir. SSH kapalıysa bu script ile port flow açılır.
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FRIDA_VERSION="16.2.1"

echo -e "${YELLOW}[*] Sentinel Hook - Frida Cihaz Hazırlayıcı${NC}"

if [ "$1" == "ios" ]; then
    echo -e "${YELLOW}[*] iOS modu seçildi.${NC}"
    echo -e "${YELLOW}[*] (Not: iOS cihazlarda Frida genel olarak Cydia üzerinden kurulmalıdır.)${NC}"
    echo -e "[+] USB yönlendirme denetimi yapılıyor..."
    
    if ! command -v iproxy &> /dev/null; then
        echo -e "${RED}[!] 'iproxy' bulunamadı. Lütfen 'brew install libimobiledevice' çalıştırın.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}[+] iproxy ile 22 (SSH) ve 27042 (Frida) portları hosta mapleniyor...${NC}"
    # Arka planda iproxy başlat
    iproxy 2222:22 > /dev/null 2>&1 &
    iproxy 27042:27042 > /dev/null 2>&1 &
    echo -e "${GREEN}[+] iOS bağlantı hazırlığı tamam. (localhost:27042)${NC}"
    
elif [ "$1" == "android" ]; then
    echo -e "${YELLOW}[*] Android modu seçildi.${NC}"
    if ! command -v adb &> /dev/null; then
         echo -e "${RED}[!] ADB bulunamadı!${NC}"
         exit 1
    fi

    ARCH=$(adb shell getprop ro.product.cpu.abi)
    echo -e "${GREEN}[+] Cihaz Mimarisi: ${ARCH}${NC}"
    
    SERVER_NAME="frida-server-${FRIDA_VERSION}-android-${ARCH}"
    
    if [ ! -f "/tmp/$SERVER_NAME" ]; then
        echo -e "${YELLOW}[*] Frida Server indiriliyor ($SERVER_NAME)...${NC}"
        curl -sL "https://github.com/frida/frida/releases/download/${FRIDA_VERSION}/${SERVER_NAME}.xz" -o "/tmp/${SERVER_NAME}.xz"
        xz -d "/tmp/${SERVER_NAME}.xz"
    fi

    echo -e "${YELLOW}[*] Sunucu cihaza push ediliyor...${NC}"
    adb push "/tmp/$SERVER_NAME" /data/local/tmp/frida-server
    adb shell "chmod 755 /data/local/tmp/frida-server"
    
    echo -e "${YELLOW}[*] Root yetkisiyle başlatılıyor...${NC}"
    # Not: ADB root gerektirir
    adb shell "su -c '/data/local/tmp/frida-server -D'" &
    
    # Port Forwarding
    adb forward tcp:27042 tcp:27042
    adb forward tcp:27043 tcp:27043
    
    echo -e "${GREEN}[+] Android Frida-Server Başarılıyla çalışıyor! (localhost:27042)${NC}"

else
    echo -e "${RED}Kullanım: ./setup_frida_server.sh [ios|android]${NC}"
    exit 1
fi
