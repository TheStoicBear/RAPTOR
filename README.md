# RAPTOR  
**Realistic Active Power Torque & Oversteer Regulation**  
Advanced Vehicle Stability Suite for FiveM

![RAPTOR Banner](https://imgimp.xyz/images/Stoic-2025-04-23_03-14-31-68085b176f0fa.png)

---

## 🛠️ Overview

**RAPTOR** is a high-fidelity vehicle stability system for FiveM that simulates real-world **ABS**, **TCS**, and **ESP** systems with precision. Designed for realism and smooth in-game integration, RAPTOR improves vehicle handling during hard braking, acceleration, and cornering scenarios.

---

## 🚀 Features

### 🟥 ABS (Anti-lock Braking System) v3.0
- Per-wheel brake pulsing at ~20Hz
- Rear brake pressure bias (e.g. 70% rear)
- Slip-ratio based activation logic
- Realistic e-brake detection
- Smooth toggle in and out with UI indicator

### 🟩 TCS (Traction Control System)
- Slip ratio and steering angle-based torque cut
- Turning-aware slip detection (lower threshold while turning)
- Engine torque reduction based on intensity
- RPM and speed gating to avoid false positives
- Dynamic UI indicator

### 🟨 ESP (Electronic Stability Program)
- Drift correction with hysteresis & torque ramping
- Heading vs velocity vector analysis
- Brake intervention on individual wheels
- Realistic over/understeer handling
- Slip angle threshold and smooth ramp logic
- Live UI status indicator

---

## 📸 UI Indicators

Each system (ABS, TCS, ESP) has a clean UI box that:
- Fades in on activation
- Displays status (Active/Inactive)
- Fades out on deactivation

You can customize these in the provided HTML/CSS/JS files inside the `nui/` folder.

---

## 📁 Installation

1. Clone the repository to your local machine.
2. Move the resource into your FiveM `resources` folder.
3. Add `ensure raptor` to your `server.cfg`.


---

## ⚙️ Configuration

All main tuning values are defined at the top of the main script:

- ABS slip ratio threshold
- ESP slip angle threshold and ramp speed
- TCS slip trigger, cutoff, and torque limits
- Rear brake bias and pulse interval

You can adjust these to fit your server's vehicle physics and driving style.

---

## 🔍 Debugging

You can enable debug mode to see real-time slip data, intervention status, and torque adjustments via console printouts.

Just set the `debug` flag to `true` in the config section.

---

## 📌 To-Do / Roadmap

- [ ] Vehicle-specific tuning profiles
- [ ] Sound effects for ESP/TCS/ABS triggers
- [ ] In-game toggle system (command or hotkey)
- [X] Config.json support
- [ ] Log telemetry to file or UI overlay

---

## 📜 License

MIT License — Free to use, modify, and distribute with attribution.

---

## 🤝 Contributions

Pull requests, issues, and suggestions are always welcome! Help bring realistic driving to the next level in FiveM.

---

## 💬 Credits

Made with 💡 and tire smoke by **Azure** *Stoicly Developed*
Inspired by real-world automotive dynamics & simulation theory.

---

## 📷 Screenshots

