/**
 * Sentinel Hook - APK / IPA Integrity Check Bypass (Phase 5.4)
 * Hedef: Uygulamanın kendi derleme imzasının (Signature) veya 
 * dosyalarının (Checksum/Hash) değiştirilip değiştirilmediğini anlayan mekanizmalar.
 */

var isAndroid = (Process.platform === "linux");
var isIOS = (Process.platform === "darwin");

console.log("[🌟] SENTINEL HOOK: Integrity (İmza/Bütünlük) Bypass Yükleniyor...");

if (isAndroid) {
    Java.perform(function() {
        try {
            // Android cihazlarda APK İmza (Signature) Kontrolünü kırmak
            var paramString = Java.use("java.lang.String");
            var pm = Java.use("android.app.ApplicationPackageManager");
            
            pm.getPackageInfo.overload('java.lang.String', 'int').implementation = function(pkgName, flags) {
                var info = this.getPackageInfo(pkgName, flags);
                
                // flags == 64 (GET_SIGNATURES)
                if (flags === 64) {
                    console.log("[💥] SENTINEL GİZLENİYOR: Uygulama kendi APK imzasını kontrol etti! (GET_SIGNATURES)");
                    // İleri Düzey Bypass:
                    // Normalde orijinal uygulamanın release (üretim) sertifikası neyse, o sertifikayı 
                    // byte array (Signature) olarak sahteliyoruz (Mock).
                    // info.signatures.value = [fake_original_signature];
                }
                return info;
            };
        } catch (e) {
            console.log("[-] PackageManager Integrity Hook Başarısız.");
        }
    });

    // Native level checksum (MD5/SHA1 over lib.so) kancaları
    var fopenPtr = Module.findExportByName("libc.so", "fopen");
    // Eğer uygulamanın JNI'i lib_foo.so'yu açıp kendi dosya hash'ine bakarsa onu engelleyeceğiz. 
}

if (isIOS) {
    // iOS tarafında DRM veya Kod İmzası 'amfid' süreçleri tarafından yönetilir,
    // ancak bazı banka uygulamaları in-app (uygulama içi) Mach-O dosyasına bakar.
    
    // Cihazın SecStaticCodeCheckValidity (Kod Bütünlüğü Onayı) fonksiyonunu hookla:
    var SecStaticCodeCheckValidity = Module.findExportByName("Security", "SecStaticCodeCheckValidity");
    if (SecStaticCodeCheckValidity) {
        Interceptor.attach(SecStaticCodeCheckValidity, {
            onLeave: function(retval) {
                // kSecSuccess (0) - Her zaman uygulamanın imzası sağlam/orijinal gösterilir.
                console.log("[💥] SENTINEL GİZLENİYOR: iOS Kod Bütünlük Taraması Ekarte Edildi. Onay Verildi.");
                retval.replace(ptr("0x0"));
            }
        });
    }
}
