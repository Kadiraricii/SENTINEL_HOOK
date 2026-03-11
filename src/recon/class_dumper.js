/**
 * Sentinel Hook - Objective-C Class Dumper
 * Phase 1.2: Bellekteki LocalAuthentication sınıflarını ve fonksiyonlarını çıkarır.
 */

if (ObjC.available) {
    console.log("[*] Objective-C Runtime aktif! Sınıflar taranıyor...");

    // Hedeflediğimiz kapalı kaynak Apple güvenlik kütüphanesi
    var targetClassPattern = "LAContext";
    
    for (var className in ObjC.classes) {
        if (className.includes(targetClassPattern)) {
            console.log("\n[🚀] HEDEF SINIF YAKALANDI: " + className);
            
            // Sınıfın sahip olduğu tüm gizli ve açık metotları (fonksiyonları) RAM'den çek
            var methods = ObjC.classes[className].$ownMethods;
            
            console.log("[*] --- " + className + " Sınıfının Gizli/Açık Fonksiyonları ---");
            methods.forEach(function(method) {
                // Sadece evaluatePolicy ile ilgili olanları logla ki kalabalık olmasın
                if(method.includes("evaluatePolicy")) {
                    console.log("    🚨 KRİTİK METOT: " + method);
                }
            });
            console.log("-----------------------------------------------------");
        }
    }
} else {
    console.log("[-] Objective-C Runtime bulunamadı. Lütfen bir iOS uygulamasında çalıştırın.");
}
