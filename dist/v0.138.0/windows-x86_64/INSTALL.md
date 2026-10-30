# Drain Damage 0.138.0 — Windows x86_64 prototype

Download the Windows ZIP and extract the entire folder. Run **Drain Damage.exe** and keep its PCK beside it.
Godot, Git and Python are not required. The executable is unsigned and may trigger a Windows reputation warning.

**Native Windows execution has not yet been verified.** Export integrity and macOS-host resource-pack checks passed;
these do not test Windows rendering, sound, input, performance or PowerShell execution.

For native initialization checks, open PowerShell in the extracted folder and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Test-Windows.ps1
```

Keep the timestamped test logs, including shutdown warnings. Then play both heroes through menus, Level 1, flush,
landing and ride, checking audio, keyboard/controller input, window behavior and frame pacing. A headless pass does
not establish those results. The campaign is unfinished; the ride is a 13-encounter showcase.

Report Windows version, CPU architecture, GPU/driver, package checksum, hero/difficulty, controls and reproduction steps.
