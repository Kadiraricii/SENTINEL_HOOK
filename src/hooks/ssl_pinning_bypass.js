/**
 * Sentinel Hook - Universal SSL Pinning Bypass (Phase 5.3)
 * Hedef: Android (TrustManager) ve iOS (SecTrustEvaluate) SSL korumalarını ekarte etmek.
 * Amaç: Uygulamanın arka planda sunucuya (Backend'e) attığı network paketlerini 
 * BurpSuite/Proxyman gibi araçlarla açık (HTTP) olarak izleyebilmek.
 */

var isAndroid = (Process.platform === "linux");
var isIOS = (Process.platform === "darwin");

if (isAndroid) {
    Java.perform(function () {
        console.log("[🌟] SENTINEL HOOK: Android SSL Pinning Bypass Yükleniyor...");
        var array_list = Java.use("java.util.ArrayList");
        var TrustManagerImpl = Java.use("com.android.org.conscrypt.TrustManagerImpl");

        try {
            // Android TrustManager kütüphanesini hookluyoruz.
            // Bu sınıfın içindeki checkTrusted methodu, bizim proxy'nin SSL'ini "Sahte/Hack" görse bile
            // Biz geri dönüp "Yok yok bu gerçek Banka Sertifikası" (SuccessList) döndüreceğiz.
            TrustManagerImpl.verifyChain.implementation = function(untrustedChain, trustAnchorChain, host, clientAuth, ocspData, tlsSctData) {
                console.log("[💥] SENTINEL GİZLENİYOR: Android SSL TrustChain tarandı. Güvenlik İhlali atlatıldı -> (Bypass)");
                // Asıl doğrulama fonksiyonunu geçip, chain listesini başarılı gibi geri döndür.
                return untrustedChain;
            };
        } catch (e) {
            console.log("[-] TrustManagerImpl hooklanamadı: " + e.message);
        }
    });
}

if (isIOS) {
    console.log("[🌟] SENTINEL HOOK: iOS SSL Pinning (SecTrustEvaluate) Bypass Yükleniyor...");
    // iOS için ana SSL kontrol kapısı "SecTrustEvaluateWithError" veya eski sürümlerde "SecTrustEvaluate"
    var handle_sec = Module.findExportByName("Security", "SecTrustEvaluate");
    
    if (handle_sec) {
        Interceptor.attach(handle_sec, {
            onLeave: function(retval) {
                // kSecTrustResultProceed = 1 (Başarılı Bağlantı)
                console.log("[💥] SENTINEL GİZLENİYOR: iOS SSL SecTrustEvaluate tarandı. Sonuç başarılı gösterildi (KSecTrustResultProceed).");
                retval.replace(ptr(1)); 
            }
        });
    }

    var handle_sec_error = Module.findExportByName("Security", "SecTrustEvaluateWithError");
    if (handle_sec_error) {
        Interceptor.attach(handle_sec_error, {
            onLeave: function(retval) {
                // Return 'true' (byte değeri 1) Error'a ise NULL döneceğiz.
                console.log("[💥] SENTINEL GİZLENİYOR: iOS SSL SecTrustEvaluateWithError tarandı. Hata sansürlendi.");
                retval.replace(ptr(1));
            }
        });
    }
}
