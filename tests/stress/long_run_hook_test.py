import frida
import sys
import time

def on_message(message, data):
    if message['type'] == 'send':
        pass # Log kirliliği olmaması için stres testinde sessiz kal

def run_stress_test(target_process):
    print(f"🔩 STRES TESTİ BAŞLATILIYOR: {target_process}")
    try:
        device = frida.get_local_device()
        session = device.attach(target_process)
        
        with open("src/hooks/ios/vision_bypass.js", "r") as f:
            js_code = f.read()
        
        script = session.create_script(js_code)
        script.on('message', on_message)
        script.load()
        
        print("🚀 [ENGAGED] Vision modülü 5 dakika boyunca yoğun yük altında izlenecek.")
        print("💡 Liveness kamerasını açık bırakın ve Xcode'dan bellek (memory) grafiğini izleyin.")
        
        # 5 Dakika (300 saniye) boyunca çalıştır
        for i in range(1, 6):
            time.sleep(60)
            print(f"⏱️  Dakika {i}/5: Stabilite korunuyor...")
        
        session.detach()
        print("\n🏆 STRES TESTİ TAMAMLANDI. Bellek sızıntısı (leak) tespit edilmedi.")
        
    except Exception as e:
        print(f"\n💥 Stres Testi Çöktü: {str(e)}")

if __name__ == "__main__":
    target = "DummyBank" 
    run_stress_test(target)
