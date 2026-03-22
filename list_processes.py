import sys
import frida
import json

def list_processes(device_id):
    try:
        if device_id == "local":
            device = frida.get_local_device()
        else:
            device = frida.get_device(device_id)
        
        processes = device.enumerate_processes()
        result = [{"pid": p.pid, "name": p.name} for p in processes]
        print(json.dumps(result))
    except Exception as e:
        print(json.dumps({"error": str(e)}))

if __name__ == "__main__":
    dev_id = sys.argv[1] if len(sys.argv) > 1 else "local"
    list_processes(dev_id)
