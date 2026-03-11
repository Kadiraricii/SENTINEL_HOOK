#!/usr/bin/env bash

# ==============================================================================
# Sentinel Hook - Automated Teardown and Cleanup Script
# ==============================================================================
# Destroys all traces of the project from the system.
# Phase 0.0 - Step 2 (İzolasyon ve İz Bırakmadan Temizlik)
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR=$(pwd)
echo -e "${YELLOW}[*] Sentinel Hook tam sistem temizliği başlatılıyor: ${PROJECT_DIR}${NC}"

echo -e "${YELLOW}[*] 1. Sanal ortam (.venv) kaldırılıyor...${NC}"
if [ -d ".venv" ]; then
    rm -rf .venv
    echo -e "${GREEN}[+] .venv silindi.${NC}"
fi

echo -e "${YELLOW}[*] 2. NPM ve derleme kalıntıları kaldırılıyor...${NC}"
if [ -d "node_modules" ]; then
    rm -rf node_modules package-lock.json package.json
    echo -e "${GREEN}[+] NPM paketleri ve yapılandırmaları silindi.${NC}"
fi

echo -e "${YELLOW}[*] 3. İndirilen dış kaynaklar temizleniyor...${NC}"
if [ -d "tools/external" ]; then
    rm -rf tools/external
    echo -e "${GREEN}[+] Dış kaynaklar (external tools) silindi.${NC}"
fi

echo -e "${YELLOW}[*] 4. Bireysel / Yerel proje klasörleri (.local vb.) yok ediliyor...${NC}"
if [ -d ".local" ]; then
    rm -rf .local
    echo -e "${GREEN}[+] .local klasörü silindi.${NC}"
fi

echo -e "${YELLOW}[*] 5. Python Cache (__pycache__) dosyaları temizleniyor...${NC}"
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
echo -e "${GREEN}[+] PyCache temizlendi.${NC}"

echo -e "${YELLOW}[*] Sistemin kalıntı port ve prosesleri kontrol ediliyor...${NC}"
if pgrep frida-server > /dev/null; then
    echo -e "${RED}[!] Çalışan frida-server tespit edildi. Zorla sonlandırılıyor...${NC}"
    pkill -9 frida-server || true
fi

echo -e "${GREEN}[*] Tüm Sentinel Hook kalıntıları başarıyla temizlendi! İz bırakılmadı.${NC}"
