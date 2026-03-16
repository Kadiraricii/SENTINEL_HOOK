/**
 * Sentinel Hook - Root & Jailbreak Detection Bypass (Phase 5.1)
 * Hedef: Cihazın modifiye edilmiş olduğunu anlayan güvenlik SDK'larını kör etmek.
 */

console.log("[🌟] SENTINEL HOOK: Root & Jailbreak Bypass Aktif Ediliyor...");

var isIOS = (Process.platform === "darwin");
var isAndroid = (Process.platform === "linux");

// Banka uygulamalarının sıklıkla aradığı "Kara Liste" dosyaları
var jailbreakFiles = [
    // iOS Blacklist
    "/Applications/Cydia.app",
    "/Applications/Sileo.app",
    "/usr/sbin/sshd",
    "/bin/bash",
    "/Library/MobileSubstrate/MobileSubstrate.dylib",
    "/etc/apt",
    "/Applications/Safari.app", // <--- SIMÜLATÖR TESTİ İÇİN: Mac'in Safari'sini Cydia gibi farz edeceğiz
    // Android Blacklist
    "/system/app/Superuser.apk",
    "/system/xbin/su",
    "/system/bin/su",
    "/sbin/su",
    "/data/local/su",
    "/magisk/.core/bin/su"
];

// iOS: En sağlam yöntem olan Objective-C FileManager (NSFileManager) Hook'u
if (ObjC.available) {
    try {
        var NSFileManager = ObjC.classes.NSFileManager;
        Interceptor.attach(NSFileManager["- fileExistsAtPath:"].implementation, {
            onEnter: function(args) {
                this.path = new ObjC.Object(args[2]).toString();
                this.shouldFake = false;
                
                for (var i = 0; i < jailbreakFiles.length; i++) {
                    if (this.path && this.path.indexOf(jailbreakFiles[i]) !== -1) {
                        console.log("[💥] SENTINEL GİZLENİYOR: Uygulama yasaklı doya aradı (" + this.path + ")");
                        this.shouldFake = true;
                        break;
                    }
                }
            },
            onLeave: function(retval) {
                if (this.shouldFake) {
                    // Bulamadım (False / 0) Dönüyoruz.
                    retval.replace(ptr("0x0"));
                }
            }
        });
        console.log("[+] Objective-C 'NSFileManager.fileExistsAtPath' kancalandı. Cihaz temiz gösterilecek.");
    } catch(e) {
        console.log("NSFileManager hook hatası: " + e);
    }
}

// Android ve fallback C-Level Hook'u (open / access)
try {
    var openPtr = Module.findExportByName(null, "open");
    if (openPtr) {
        Interceptor.attach(openPtr, {
            onEnter: function(args) {
                var path = Memory.readUtf8String(args[0]);
                for (var i = 0; i < jailbreakFiles.length; i++) {
                    if (path && path.indexOf(jailbreakFiles[i]) !== -1) {
                        args[0] = Memory.allocUtf8String("/dev/null");
                        break;
                    }
                }
            }
        });
    }
} catch (e) {}

if (isAndroid) {
    // Android "su" command execution bypass
    try {
        var Runtime = Java.use("java.lang.Runtime");
        Runtime.exec.overload('java.lang.String').implementation = function(command) {
            if (command.indexOf("su") !== -1) {
                console.log("[💥] SENTINEL GİZLENİYOR: 'su' komutu çalıştırılmak istendi. İptal edildi.");
                return this.exec("echo sentinel_bypass");
            }
            return this.exec(command);
        };
    } catch(e) {}
}
