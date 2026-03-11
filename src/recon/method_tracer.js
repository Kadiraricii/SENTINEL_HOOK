/**
 * Sentinel Hook - Method Tracer
 * Phase 1.2: Biyometrik butonuna basıldığında RAM'de dönen trafiği izler (dinler).
 */

if (ObjC.available) {
    var LAContext = ObjC.classes.LAContext;
    
    // Uygulamanın çağırdığı asıl Orijinal FaceID fonksiyonunun C-imzası
    var targetSensorMethod = "- evaluatePolicy:localizedReason:reply:"; 
    
    console.log("[*] METHOD TRACER AKTİF: " + targetSensorMethod + " bekleniyor...");

    Interceptor.attach(LAContext[targetSensorMethod].implementation, {
        
        onEnter: function(args) {
            // args[0] -> self, args[1] -> selector objesi
            // args[2] -> YAPILAN İSTEĞİN TÜRÜ (LAPolicy enum'u)
            // args[3] -> EKRANA YAZILAN YAZI (Reason)
            // args[4] -> GERİYE 'TRUE/FALSE' DÖNECEK BLOK (Reply)
            
            console.log("\n[💥] EKRANDA BUTONA BASILDI! evaluatePolicy tetiklendi.");
            
            // RAM'den değişkenleri insan diline çeviriyoruz
            var policy = args[2].toInt32();
            var reasonMessage = new ObjC.Object(args[3]).toString();
            
            console.log("   [Hedef İstek Tipi]: " + policy + " (1 ise Biometrik Doğrulama İsteği)");
            console.log("   [Hedefdeki Uyarı Yazısı]: " + reasonMessage);
            
            console.log("\n[!] Tracer sadece izler. Müdahale etmeyiz. Cihazdan gelen gerçeği bekliyoruz.");
        },
        
        onLeave: function(retval) {
            // Bu fonksiyon Async çalıştığı için asıl sonuç onLeave'de değil, Callback Block'ta döner.
            // O yüzden burası sessizdir.
        }
    });

}
