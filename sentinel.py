#!/usr/bin/env python3
"""
Sentinel Hook CLI Tool
Phase 6 Automations: Profile System, Hot-Reload, HTML Reporting

Usage:
  python sentinel.py -t DummyBank -b all
  python sentinel.py --gen-profile DummyBank
  python sentinel.py -p configs/profiles/DummyBank.json
"""

import frida
import sys
import os
import json
import argparse
import time
import threading
from datetime import datetime
from rich.console import Console
from rich.panel import Panel
from rich.table import Table

console = Console()

HOOKS_DIR = "src/hooks"
PROFILES_DIR = "configs/profiles"
REPORTS_DIR = "reports"

MODULE_MAP = {
    "biometrics": "01_biometrics",
    "camera": "02_camera",
    "ml_vision": "03_ml_vision",
    "anti_tamper": "04_anti_tamper"
}

REPORT_TIMELINE = []
TARGET_NAME = "Unknown"

def print_banner():
    banner = """[bold red]
███████╗███████╗███╗   ██╗████████╗██╗███╗   ██╗███████╗██╗          
██╔════╝██╔════╝████╗  ██║╚══██╔══╝██║████╗  ██║██╔════╝██║          
███████╗█████╗  ██╔██╗ ██║   ██║   ██║██╔██╗ ██║█████╗  ██║          
╚════██║██╔══╝  ██║╚██╗██║   ██║   ██║██║╚██╗██║██╔══╝  ██║          
███████║███████╗██║ ╚████║   ██║   ██║██║ ╚████║███████╗███████╗     
╚══════╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝    
                       H  O  O  K                                         
[/bold red]
[cyan]Advanced Dynamic Instrumentation Framework[/cyan]
[cyan]Biometric · Liveness · AI/ML Security Bypass[/cyan]
"""
    console.print(banner)

def get_script_files(module_names):
    files = []
    if "all" in module_names:
        module_names = list(MODULE_MAP.keys())

    ordered_modules = []
    if "anti_tamper" in module_names:
        ordered_modules.append("anti_tamper")
    for m in module_names:
        if m != "anti_tamper" and m in MODULE_MAP:
            ordered_modules.append(m)

    for mod in ordered_modules:
        dir_name = MODULE_MAP.get(mod)
        if not dir_name:
            console.print(f"[bold yellow][!] Warning: Unknown module '{mod}' ignored. Available: {list(MODULE_MAP.keys())}[/bold yellow]")
            continue
            
        mod_path = os.path.join(HOOKS_DIR, dir_name)
        if os.path.exists(mod_path):
            for f in sorted(os.listdir(mod_path)):
                if f.endswith(".js"):
                    files.append(os.path.join(mod_path, f))
    return files

seen_errors = set()

def on_message(message, data):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    if message['type'] == 'send':
        console.print(f"[bold green][*][/bold green] {message['payload']}")
        REPORT_TIMELINE.append({"time": timestamp, "type": "SUCCESS", "message": message['payload']})
    elif message['type'] == 'error':
        err = message.get('description', 'Unknown Error')
        # Deduplicate repeated TypeError floods (e.g. hooked syscalls called 1000x/sec)
        err_key = err[:80]
        if err_key not in seen_errors:
            seen_errors.add(err_key)
            console.print(f"[bold red][!][/bold red] [dim]{err}[/dim]")
            REPORT_TIMELINE.append({"time": timestamp, "type": "ERROR", "message": err})
    else:
        console.print(f"[bold blue][?][/bold blue] {message}")
        REPORT_TIMELINE.append({"time": timestamp, "type": "INFO", "message": str(message)})

def generate_html_report():
    if not os.path.exists(REPORTS_DIR):
        os.makedirs(REPORTS_DIR)
        
    filename = os.path.join(REPORTS_DIR, f"Sentinel_Report_{TARGET_NAME}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.html")
    
    html = f"""
    <html>
    <head>
        <title>Sentinel Hook Report: {TARGET_NAME}</title>
        <style>
            body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #1e1e1e; color: #d4d4d4; padding: 20px; }}
            h1 {{ color: #569cd6; border-bottom: 1px solid #4a4a4a; padding-bottom: 10px; }}
            table {{ width: 100%; border-collapse: collapse; margin-top: 20px; }}
            th, td {{ padding: 12px; text-align: left; border-bottom: 1px solid #333; }}
            th {{ background-color: #2d2d2d; color: #9cdcfe; }}
            tr:hover {{ background-color: #2a2d2e; }}
            .SUCCESS {{ color: #4ec9b0; font-weight: bold; }}
            .ERROR {{ color: #f48771; font-weight: bold; }}
            .INFO {{ color: #ce9178; }}
        </style>
    </head>
    <body>
        <h1>🛡️ Sentinel Hook Penetration Report</h1>
        <p><strong>Target:</strong> {TARGET_NAME}</p>
        <p><strong>Date:</strong> {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
        <p><strong>Total Events:</strong> {len(REPORT_TIMELINE)}</p>
        
        <table>
            <tr><th>Timestamp</th><th>Type</th><th>Message / Payload</th></tr>
    """
    
    for event in REPORT_TIMELINE:
        html += f"<tr><td>{event['time']}</td><td class='{event['type']}'>{event['type']}</td><td>{event['message']}</td></tr>"
        
    html += """
        </table>
    </body>
    </html>
    """
    
    with open(filename, "w", encoding="utf-8") as f:
        f.write(html)
        
    console.print(f"\n[bold green][✓] Bypass raporu başarıyla oluşturuldu: {filename}[/bold green]")

class HotReloader:
    def __init__(self, session, script_files):
        self.session = session
        self.script_files = script_files
        self.loaded_scripts = {}  # filepath: frida_script_object
        self.file_mtimes = {}     # filepath: last_modified_time
        self.running = True

    def load_script(self, filepath, silent=False):
        try:
            with open(filepath, "r") as f:
                source = f.read()
                
            # Polyfill: use globalThis (ES2020) — works in Frida 17 QuickJS strict mode
            polyfill = """
(function() {
    if (typeof ObjC === 'undefined') {
        globalThis.ObjC = { available: false, classes: {}, protocols: {}, Block: function(){} };
    }
    if (typeof Java === 'undefined') {
        globalThis.Java = { available: false, use: function(){ return {}; }, perform: function(fn){} };
    }
    if (typeof Interceptor === 'undefined') {
        globalThis.Interceptor = { attach: function(){}, replace: function(){} };
    }
    if (typeof Module !== 'undefined' && typeof Module.findExportByName === 'undefined') {
        Module.findExportByName = function(moduleName, exportName) {
            if (moduleName === null) {
                return (typeof Module.findGlobalExportByName === 'function') ? Module.findGlobalExportByName(exportName) : null;
            }
            try { return Process.getModuleByName(moduleName).findExportByName(exportName); } catch(e) { return null; }
        };
    }
})();
"""
            source = polyfill + "\n" + source
            
            script = self.session.create_script(source)
            script.on("message", on_message)
            script.load()
            
            self.loaded_scripts[filepath] = script
            self.file_mtimes[filepath] = os.path.getmtime(filepath)
            
            if not silent:
                console.print(f"[bold magenta]↻ [Hot-Reload][/bold magenta] {os.path.basename(filepath)} yeniden yüklendi.")
        except Exception as e:
            console.print(f"[bold red][!] '{filepath}' yüklenirken hata oluştu: {e}[/bold red]")

    def initial_load(self):
        for script_file in self.script_files:
            self.load_script(script_file, silent=True)

    def watch_loop(self):
        while self.running:
            time.sleep(1) # Check interval
            for filepath in self.script_files:
                try:
                    current_mtime = os.path.getmtime(filepath)
                    if current_mtime > self.file_mtimes.get(filepath, 0):
                        old_script = self.loaded_scripts.get(filepath)
                        if old_script:
                            try:
                                old_script.unload()
                            except:
                                pass
                        self.load_script(filepath)
                except Exception:
                    pass

    def stop(self):
        self.running = False
        for script in self.loaded_scripts.values():
            try:
                script.unload()
            except:
                pass

def inject(target, usb_mode, module_names, spawn_mode=False, bundle_id=None, device_id=None, gadget_mode=False):
    global TARGET_NAME
    TARGET_NAME = target
    
    try:
        # Smart Device Discovery: Simulator targets are often better handled as 'local' on macOS
        target_device = None
        if device_id:
            if "." in device_id or ":" in device_id:
                try:
                    target_device = frida.get_device_manager().add_remote_device(device_id)
                    console.print(f"[cyan][*][/cyan] Uzak TCP Gadget'ına bağlanılıyor: [bold yellow]{device_id}[/bold yellow]")
                    target = "Gadget" # TCP listener her zaman we call it Gadget or attach to 0
                    target_pid = 0 # Gadget portu üzerinden PID 0'a bağlanılır.
                except:
                    console.print(f"[yellow][!][/yellow] Uzak cihaza bağlanılamadı ({device_id}).")
            else:
                try:
                    target_device = frida.get_device_manager().get_device(device_id, timeout=2)
                    console.print(f"[cyan][*][/cyan] Simülatör cihazına bağlanılıyor: [bold yellow]{device_id}[/bold yellow]")
                except:
                    console.print(f"[yellow][!][/yellow] Cihaz ID ({device_id}) üzerinden bulunamadı, Lokal Aramaya geçiliyor...")
        
        if not target_device:
            if usb_mode:
                console.print("[cyan][*][/cyan] USB cihaza bağlanılıyor...")
                target_device = frida.get_usb_device(timeout=2)
            else:
                console.print("[cyan][*][/cyan] Lokal sisteme bağlanılıyor...")
                target_device = frida.get_local_device()
        
        console.print(f"[cyan][*][/cyan] Hedef process [bold magenta]{target}[/bold magenta] aranıyor...")
        if 'target_pid' not in locals():
            target_pid = int(target) if target.isdigit() else target
        session = target_device.attach(target_pid)
        console.print(f"[green][✓][/green] Başarıyla {target} uygulamasına attach olundu!")
        
        # Platform diagnostics with a small delay for ObjC bridge to settle
        time.sleep(1.0)
        probe = session.create_script("""
            var stats = {
                platform: Process.platform,
                arch: Process.arch,
                objc: (typeof ObjC !== 'undefined' && ObjC.available),
                java: (typeof Java !== 'undefined' && Java.available)
            };
            send(stats);
        """)
        probe_result = {}
        def _probe_msg(msg, data):
             if msg['type'] == 'send': probe_result.update(msg['payload'])
        probe.on('message', _probe_msg)
        probe.load()
        time.sleep(0.5)
        probe.unload()

        plat = probe_result.get('platform', 'unknown')
        arch = probe_result.get('arch', '?')
        objc = probe_result.get('objc', False)
        java = probe_result.get('java', False)

        console.print(f"[cyan][*][/cyan] Platform: [bold yellow]{plat}[/bold yellow]  Arch: [bold yellow]{arch}[/bold yellow]  ObjC: {'[bold green][+][/bold green]' if objc else '[bold red][-][/bold red]'}  Java: {'[bold green][+][/bold green]' if java else '[bold red][-][/bold red]'}")
        
        if not objc and not java:
            console.print(Panel.fit(
                "[bold yellow]⚠ ObjC/Java Runtime Bulunamadı.\nSimulator'da en iyi sonuç için Xcode'dan 'Debug' modunda başlatın.[/bold yellow]",
                title="Sistem Uyarısı", border_style="yellow"
            ))
    except frida.ProcessNotFoundError:
        console.print(f"[bold red][!][/bold red] '{target}' isimli veya ID'li açık uygulama bulunamadı.")
        sys.exit(1)
    except Exception as e:
        console.print(f"[bold red][!] Attach hatası: {e}[/bold red]")
        sys.exit(1)

    scripts_to_load = get_script_files(module_names)
    if not scripts_to_load:
        console.print("[bold red][!][/bold red] Yüklenecek script bulunamadı!")
        sys.exit(1)
    
    table = Table(title="Yüklenecek Sentinel Modülleri")
    table.add_column("Sıra", justify="right", style="cyan", no_wrap=True)
    table.add_column("Modül", style="magenta")
    for idx, f in enumerate(scripts_to_load, 1):
        table.add_row(str(idx), os.path.basename(f))
    console.print(table)
    console.print()

    reloader = HotReloader(session, scripts_to_load)
    reloader.initial_load()

    if spawn_mode:
        console.print("[cyan][*][/cyan] Hook'lar yüklendi, uygulama devam ettiriliyor (resume)...")
        device.resume(pid)
        console.print(f"[green][✓][/green] DummyBank başlatıldı. Simülatör ekranına bak!")
    
    watcher_thread = threading.Thread(target=reloader.watch_loop, daemon=True)
    watcher_thread.start()
        
    console.print(Panel.fit("[bold green]Tüm kancalar enjekte edildi. Hot-Reload aktif! Sentinel izlemede...[/bold green]", title="🚀 Başarılı", border_style="green"))
    
    try:
        console.print("[dim]Araçtan çıkmak ve hookları kaldırmak için CTRL+C yapın.[/dim]\n")
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        console.print("\n[yellow][*] Sentinel Hook devreden çıkarılıyor...[/yellow]")
        reloader.stop()
        session.detach()
        generate_html_report()
        console.print("[green][✓] Graceful exit başarılı. Güle güle![/green]")
        sys.exit(0)

def generate_profile(name):
    if not os.path.exists(PROFILES_DIR):
        os.makedirs(PROFILES_DIR)
        
    filepath = os.path.join(PROFILES_DIR, f"{name}.json")
    if os.path.exists(filepath):
        console.print(f"[bold red][!] {filepath} zaten var![/bold red]")
        sys.exit(1)
        
    template = {
        "target": name,
        "platform": "ios",
        "modules": [
            "anti_tamper",
            "camera",
            "ml_vision"
        ],
        "usb": True
    }
    
    with open(filepath, "w") as f:
        json.dump(template, f, indent=4)
        
    console.print(f"[bold green][✓] Şablon profil oluşturuldu: {filepath}[/bold green]")
    console.print(f"Bypass başlatmak için: [yellow]python sentinel.py -p {filepath}[/yellow]")
    sys.exit(0)

def main():
    parser = argparse.ArgumentParser(description="Sentinel Hook - Dynamic Instrumentation CLI")
    
    parser.add_argument("-t", "--target", help="Hedef uygulama adı veya PID (Örnek: DummyBank)")
    parser.add_argument("-b", "--bypass", help="Yüklenecek modüller (örn: biometrics,camera) veya 'all'")
    
    parser.add_argument("-U", "--usb", action="store_true", help="USB cihaz kullan")
    parser.add_argument("-L", "--local", action="store_true", help="Local cihazı kullan (USB'yi ezer)")
    parser.add_argument("-S", "--spawn", action="store_true", help="Uygulama spawn ederek başlat (Simulator için ideal modu)")
    parser.add_argument("-G", "--gadget", action="store_true", help="Frida Gadget enjeksiyonu ile başlat (Simulator ObjC fix)")
    
    parser.add_argument("-p", "--profile", help="JSON profil dosyasının yolu")
    parser.add_argument("--gen-profile", help="Belirtilen isimde boş bir JSON profil şablonu üretir (Örn: DummyBank)")
    
    args = parser.parse_args()
    print_banner()

    if args.gen_profile:
        generate_profile(args.gen_profile)
        
    target = args.target
    bypass_str = args.bypass
    usb_mode = not args.local
    spawn_mode = args.spawn
    bundle_id = None
    device_id = None
    
    if args.profile:
        if not os.path.exists(args.profile):
            console.print(f"[bold red][!] Profil dosyası bulunamadı: {args.profile}[/bold red]")
            sys.exit(1)
        try:
            with open(args.profile, "r") as f:
                prof_data = json.load(f)
            
            console.print(f"[bold magenta][*][/bold magenta] '{args.profile}' profili yüklendi.")
            target = target or prof_data.get("target")
            bundle_id = prof_data.get("bundle_id")
            device_id = prof_data.get("device_id")  # Simulator/USB UDID
            bypass_list = prof_data.get("modules", [])
            bypass_str = ",".join(bypass_list) if bypass_list else bypass_str
            if "usb" in prof_data and not args.local:
                usb_mode = prof_data["usb"]
                
        except json.JSONDecodeError:
            console.print(f"[bold red][!] Geçersiz JSON formatı: {args.profile}[/bold red]")
            sys.exit(1)

    if not target or not bypass_str:
        console.print("[bold red][!] HATA: Lütfen ya (-t ve -b) argümanlarını ya da (-p) ile profil dosyasını belirtin.[/bold red]")
        console.print("Örnek 1: python sentinel.py -t DummyBank -b all")
        console.print("Örnek 2: python sentinel.py -p configs/profiles/DummyBank.json")
        sys.exit(1)
        
    modules = [m.strip().lower() for m in bypass_str.split(",")]
    
    inject(target, usb_mode, modules, spawn_mode=spawn_mode, bundle_id=bundle_id, device_id=device_id, gadget_mode=args.gadget)

if __name__ == "__main__":
    main()
