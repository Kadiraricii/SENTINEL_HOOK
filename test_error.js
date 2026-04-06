try {
    var sysctlPtr = Module.findExportByName(null, "sysctl");
    if (sysctlPtr && !sysctlPtr.isNull()) {
        console.log("Good");
    }
} catch (e) {
    console.log("Error: " + e.message);
}
