import { useState, useEffect, useRef } from 'react';
import { Terminal, Shield, Play, Square, Crosshair, Fingerprint, Lock, Camera, Eye, Zap, Cpu, Activity, RefreshCw, ChevronRight, Info, Tablet, Smartphone, Laptop, Trash2 } from 'lucide-react';
import './index.css';

export default function App() {
  const [logs, setLogs] = useState([]);
  const [target, setTarget] = useState('DummyBank');
  const [activeModules, setActiveModules] = useState([]);
  const [devices, setDevices] = useState([]);
  const [selectedDevice, setSelectedDevice] = useState(null);
  const [isConnected, setIsConnected] = useState(false);
  const [isScanning, setIsScanning] = useState(false);
  
  const logEndRef = useRef(null);
  const ws = useRef(null);

  useEffect(() => {
    let socket;
    function connect() {
      // Daha önceki bağlantı varsa temizle
      if (ws.current) {
          ws.current.onclose = null;
          ws.current.close();
      }
      
      socket = new WebSocket('ws://127.0.0.1:8000/ws');
      ws.current = socket;

      socket.onmessage = (event) => {
        const msg = event.data;
        setLogs((prev) => [...prev, msg]);

        // DURUM SENKRONIZASYONU
        if (msg.includes('[OK] Modül')) {
            const match = msg.match(/'(.*?)'/);
            if (match) setActiveModules(prev => [...new Set([...prev, match[1]])]);
        }
        
        // HATA DURUMUNDA (Kapanan süreci yakala)
        if (msg.includes('oturumu kapandı')) {
            const match = msg.match(/'(.*?)'/);
            if (match) setActiveModules(prev => prev.filter(m => m !== match[1]));
        }

        // HEDEF BULUNAMADI HATASI (Tümünü temizle)
        if (msg.includes('[!] ERROR') && msg.includes('Target')) {
            setActiveModules([]);
        }
      };

      socket.onclose = () => {
        setLogs((prev) => [...prev, '[SYSTEM] Signal lost. Re-establishing link...']);
        setTimeout(connect, 3000);
      };
    }
    
    connect();
    scanDevices();
    
    return () => {
        if (socket) {
            socket.onclose = null;
            socket.close();
        }
    };
  }, []);

  useEffect(() => {
    logEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [logs]);

  const scanDevices = async () => {
    setIsScanning(true);
    try {
      const res = await fetch('http://127.0.0.1:8000/api/devices', { cache: 'no-cache' });
      const data = await res.json();
      setDevices(data);
      if (data.length > 0 && !selectedDevice) setSelectedDevice(data[0]);
    } catch (e) {
      setLogs((prev) => [...prev, `[!] ERROR: Device scan failed: ${e.message}`]);
    }
    setIsScanning(false);
  };

  const handleConnect = () => {
    if (!selectedDevice) return;
    setLogs((prev) => [...prev, `[INIT] Handshake with ${selectedDevice.name} [ID: ${selectedDevice.id.substring(0,8)}...]`]);
    setLogs((prev) => [...prev, `[OK] Sentinel Intel: Signal established via Tunnel.`]);
    setIsConnected(true);
  };

  const clearLogs = () => setLogs([]);

  const handleInject = async (module) => {
    const isAlreadyActive = activeModules.includes(module);
    
    if (isAlreadyActive) {
        setLogs((prev) => [...prev, `[PURGE] Detaching module: ${module.toUpperCase()}`]);
        try {
            const res = await fetch('http://127.0.0.1:8000/api/inject', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ target, device_id: selectedDevice.id, modules: [] }),
            });
            setActiveModules((prev) => prev.filter(m => m !== module));
            setLogs((prev) => [...prev, `[SYSTEM] Tactical signal lost for '${module}'.`]);
        } catch(e) {
            setLogs((prev) => [...prev, `[!] CRITICAL: ${e.message}`]);
        }
        return;
    }

    setLogs((prev) => [...prev, `[EXEC] Requesting Injection: ${module.toUpperCase()}`]);

    try {
      const res = await fetch('http://127.0.0.1:8000/api/inject', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ target, device_id: selectedDevice.id, modules: [module] }),
      });
      
      const data = await res.json();
      if (data.status === 'detached') {
          setActiveModules((prev) => prev.filter(m => m !== module));
      }
    } catch(e) {
      setLogs((prev) => [...prev, `[!] CRITICAL: ${e.message}`]);
    }
  };

  const handleStop = async () => {
    try {
      await fetch('http://127.0.0.1:8000/api/stop', { method: 'POST' });
      setActiveModules([]);
      setIsConnected(false);
    } catch(e) {
      setLogs((prev) => [...prev, `[!] CRITICAL: Shutdown failure: ${e.message}`]);
    }
  };

  const modules = [
    { id: 'biometrics', name: 'BIO-LOGIC BYPASS', icon: <Fingerprint size={24} />, color: '#bb86fc', intel: 'Intercepts policy evaluation to bypass FaceID/TouchID security. Redirection: LAContext.' },
    { id: 'camera', name: 'CAMERA INJECTOR', icon: <Camera size={24} />, color: '#03dac6', intel: 'Overrides AVCaptureSession to inject tactical image assets into live feed. Bypass: AVFoundation.' },
    { id: 'vision', name: 'AI VISION SPOOF', icon: <Eye size={24} />, color: '#cf6679', intel: 'Manipulates VNDetectFaceRectanglesRequest output to defeat AI liveness detection. Spoofing: VNFaceObservation.' },
    { id: 'security', name: 'DETECTION SHIELD', icon: <Zap size={24} />, color: '#ffd700', intel: 'Masks jailbreak artifacts and prevents Frida-related environment detection. Masking: Sysctl/ProcFS.' },
    { id: 'deepfake', name: 'DEEPFAKE PIPELINE', icon: <Crosshair size={24} />, color: '#ff5555', intel: 'Real-time OpenCV dynamic face overlay piped directly into CVPixelBuffer. Targets ML Liveness Checks.' },
  ];

  return (
    <>
      <div className="ambient-bg"></div>
      <div className="dashboard">
        
        <div className="sidebar">
          <div className="glass-panel logo-panel">
            <div className="logo-icon"><Shield size={32} color="#000" /></div>
            <div>
              <h1 className="brand-name">SENTINEL</h1>
              <div className="status-badge">
                <span className={`dot ${isConnected ? 'online' : 'offline'}`}></span>
                <span className="mono">{isConnected ? 'INTEL LINK ESTABLISHED' : 'PENDING TRANSPORT'}</span>
              </div>
            </div>
          </div>

          <div className="glass-panel device-panel">
            <div className="panel-header"><h3 className="panel-title"><Cpu size={18} /> Target Discovery</h3><button className="icon-btn" onClick={scanDevices} disabled={isScanning}><RefreshCw size={14} className={isScanning ? 'spin' : ''} /></button></div>
            <div className="device-list">
              {devices.map(d => (
                <div key={d.id} className={`device-item ${selectedDevice?.id === d.id ? 'selected' : ''}`} onClick={() => !isConnected && setSelectedDevice(d)}>
                  <div className="device-icon-box" style={{ color: d.device_type === 'simulator' ? '#bb86fc' : '#03dac6' }}>{d.device_type === 'usb' ? <Smartphone size={18} /> : <Tablet size={18} />}</div>
                  <div className="device-info">
                    <div className="device-top"><span className="device-name">{d.name}</span><span className={`device-badge ${d.device_type}`}>{d.device_type.toUpperCase()}</span></div>
                    <div className="device-id mono">{d.id.substring(0, 16)}...</div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="glass-panel">
            <h3 className="panel-title mono" style={{ fontSize: '0.8rem', letterSpacing: '2px', color: 'var(--text-muted)' }}>TARGET PROCESS</h3>
            <input type="text" className="cyber-input" value={target} onChange={(e) => setTarget(e.target.value)} disabled={isConnected} />
            {!isConnected ? (
              <button className="cyber-btn primary" onClick={handleConnect} disabled={!selectedDevice}><Activity size={18} /> INITIATE SYNC</button>
            ) : (
              <button className="cyber-btn danger" onClick={handleStop}><Square size={18} /> PURGE SESSIONS</button>
            )}
          </div>
        </div>

        <div className="main-content">
          <div className={`glass-panel modules-panel ${!isConnected ? 'locked' : ''}`}>
            <h3 className="panel-title"><Zap size={20} /> Tactical Injection Payloads</h3>
            <div className="modules-grid-container">
              {modules.map((m) => (
                <button key={m.id} className={`tactical-card ${activeModules.includes(m.id) ? 'active' : ''} ${!isConnected ? 'disabled' : ''}`} onClick={() => isConnected && handleInject(m.id)} disabled={!isConnected}>
                  <div className="card-accent" style={{ background: m.color }}></div>
                  <div className="card-content">
                    <div className="tactical-card-header">
                        <div className="card-icon" style={{ color: m.color }}>{m.icon}</div>
                        <div className="card-title">{m.name}</div>
                        <div className={`cyber-switch ${activeModules.includes(m.id) ? 'on' : 'off'}`}>
                            <div className="switch-knob"></div>
                        </div>
                    </div>
                    <div className="intel-report mono"><p>{m.intel}</p></div>
                  </div>
                  <div className="card-id-stamp mono" style={{marginTop: '10px', fontSize: '0.65rem'}}>SENTINEL_UID::{m.id.toUpperCase()}</div>
                </button>
              ))}
              {!isConnected && <div className="lock-overlay"><Lock size={64} className="lock-icon" /><div className="lock-text mono">ESTABLISH HANDSHAKE TO ENABLE DEPLOYMENT</div></div>}
            </div>
          </div>

          <div className="glass-panel console-panel">
            <div className="panel-header" style={{ justifyContent: 'space-between', display: 'flex', width: '100%' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <Terminal size={18} />
                    <h3 className="panel-title" style={{ margin: 0 }}>Live Tactical Feed</h3>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <button className="cyber-btn danger" style={{ padding: '4px 10px', width: 'auto', fontSize: '0.7rem' }} onClick={clearLogs}><Trash2 size={12} /> CLEAR</button>
                    <div className="active-sessions-badge mono">SESS: {activeModules.length}</div>
                </div>
            </div>
            <div className="console-stream">
              {logs.map((log, i) => (
                <div key={i} className={`log-line-large ${log.includes('[!]') || log.includes('ERROR') ? 'log-error' : ''}`}>
                   <span className="log-ts mono">{new Date().toLocaleTimeString()}</span>
                   <span className="log-msg">{log}</span>
                </div>
              ))}
              <div ref={logEndRef} />
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
