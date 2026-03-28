import frida
import sys
import time

def on_message(message, data):
    if message['type'] == 'send':
        print(f"[*] SIGNAL: {message['payload']}")
    elif message['type'] == 'error':
        print(f"[!] ERROR: {message['stack']}")

def run_test(target_process):
    print(f"[INIT] Başlatılıyor: {target_process}")
    try:
        device = frida.get_usb_device()
    except:
        device = frida.get_local_device()

    print(f"[*] Cihaz Bağlandı: {device.name}")
    
    try:
        session = device.attach(target_process)
        print(f"[✓] Süreç Yakalandı: {target_process}")
        
        with open("src/hooks/ios/local_auth_bypass.js", "r") as f:
            js_code = f.read()
        
        script = session.create_script(js_code)
        script.on('message', on_message)
        script.load()
        
        print("[🌟] TEST BAŞLADI: Lütfen uygulamada biyometrik doğrulamayı tetikleyin.")
        print("[!] 30 saniye bekleniyor... (Timeout)")
        
        time.sleep(30)
        session.detach()
        print("[✓] Test Tamamlandı.")
        
    except Exception as e:
        print(f"[!] Test Başarısız: {str(e)}")

if __name__ == "__main__":
    target = "DummyBank" # Veya hedef uygulama ismin
    run_test(target)
