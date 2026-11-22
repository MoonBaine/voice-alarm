#!/usr/bin/env python3
"""Dopasowuje wygenerowany przez `flutter create` projekt Android:
uprawnienia budzika/mikrofonu, usluga plugina `alarm`, minSdk 23.
Uzycie: python3 tools/patch_android.py   (z katalogu glownego projektu)"""
import re, sys, pathlib

root = pathlib.Path(__file__).resolve().parent.parent / "android" / "app"
manifest = root / "src" / "main" / "AndroidManifest.xml"
if not manifest.exists():
    sys.exit("Brak android/. Najpierw: flutter create --platforms=android --org com.example .")

PERMS = [
    "RECEIVE_BOOT_COMPLETED", "WAKE_LOCK", "VIBRATE", "USE_FULL_SCREEN_INTENT",
    "FOREGROUND_SERVICE", "ACCESS_NOTIFICATION_POLICY", "POST_NOTIFICATIONS",
    "READ_EXTERNAL_STORAGE", "FOREGROUND_SERVICE_MEDIA_PLAYBACK",
    "FOREGROUND_SERVICE_MICROPHONE", "USE_EXACT_ALARM", "SCHEDULE_EXACT_ALARM",
    "RECORD_AUDIO",
]
SERVICE = '<service android:name="com.gdelataillade.alarm.services.NotificationOnKillService" />'

m = manifest.read_text()
missing = [p for p in PERMS if f"android.permission.{p}" not in m]
block = "".join(f'    <uses-permission android:name="android.permission.{p}"/>\n' for p in missing)
if block:
    m = re.sub(r"(<manifest[^>]*>\n)", lambda x: x.group(1) + block, m, count=1)
if "NotificationOnKillService" not in m:
    m = m.replace("</application>", f"        {SERVICE}\n    </application>", 1)
manifest.write_text(m)

for name in ("build.gradle.kts", "build.gradle"):
    g = root / name
    if g.exists():
        t = g.read_text()
        t2 = re.sub(r"minSdk(Version)?\s*=?\s*flutter\.minSdkVersion", lambda x: "minSdk = 23" if name.endswith("kts") else "minSdkVersion 23", t)
        g.write_text(t2)
        print(f"{name}: minSdk -> 23" if t2 != t else f"{name}: bez zmian")
# --- stale podpisywanie wydania (jesli workflow przygotowal key.properties) ---
keyprops = root.parent / "key.properties"
kts = root / "build.gradle.kts"
if keyprops.exists() and kts.exists():
    t = kts.read_text()
    if 'create("release")' not in t:
        block = """    signingConfigs {
        create("release") {
            val props = java.util.Properties()
            val f = rootProject.file("key.properties")
            if (f.exists()) { f.inputStream().use { props.load(it) } }
            keyAlias = props["keyAlias"] as String?
            keyPassword = props["keyPassword"] as String?
            storeFile = (props["storeFile"] as String?)?.let { file(it) }
            storePassword = props["storePassword"] as String?
        }
    }

"""
        t = t.replace("    buildTypes {", block + "    buildTypes {", 1)
        t = t.replace('signingConfigs.getByName("debug")', 'signingConfigs.getByName("release")')
        kts.write_text(t)
        print("build.gradle.kts: podpisywanie kluczem release wlaczone")
elif keyprops.exists():
    print("UWAGA: brak build.gradle.kts - podpisywanie nie zostalo wlaczone")
print("AndroidManifest.xml zaktualizowany (dodano:", ", ".join(missing) or "nic", ")")
