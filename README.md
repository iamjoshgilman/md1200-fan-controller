# 🌀 MD1200 Fan Controller (Proxmox-native)

This lightweight script runs directly on a Linux host (such as Proxmox) and dynamically controls **Dell MD1200** fan speed using a serial debug cable. It monitors **real CPU temperatures** and sends `set_speed` commands to `/dev/ttyS1` to quiet your disk shelf while keeping it safe under load.

---

## ✅ Features

- 🧠 Dual-CPU socket support
- 🌀 Serial-based fan control (no iDRAC)
- 📈 Temperature-aware logic with thresholds
- 🔧 Native `systemd` service for startup + logging

---

## 📈 How It Works

The script checks the temperatures of both CPUs and uses the highest value to determine how fast to run the fans.

| CPU Temp Range | Fan Speed Sent |
|----------------|----------------|
| < 50°C         | 15%            |
| 50–59°C        | 30%            |
| 60–69°C        | 50%            |
| 70°C+          | 100% (fail-safe)|

It runs every 60 seconds and writes output to the system journal for easy logging and troubleshooting.

---

## 🔧 How to Prepare Your System

### 🖥️ Find Your CPU Temp Paths

Run this on your host to discover your CPU temperature sensors:

```bash
grep -H . /sys/class/hwmon/hwmon*/temp*_label
```

Look for these lines:

```
/sys/class/hwmon/hwmon0/temp1_label:Package id 0
/sys/class/hwmon/hwmon1/temp1_label:Package id 1
```

Take note of the corresponding `temp1_input` files — like:

```
/sys/class/hwmon/hwmon0/temp1_input
/sys/class/hwmon/hwmon1/temp1_input
```

These paths are used in the script.

---

### 🔌 Confirm Serial Port

The MD1200 responds to serial commands over a debug cable connected to the **top left RJ45 port on the left EMM**.

Check available serial ports:

```bash
ls /dev/ttyS*
```

Test manually:

```bash
echo -ne "set_speed 15\r\n" > /dev/ttyS1
```

If the fans spin down, you're good to go.

---

## 🚀 Installation

### 0. Clone the repository

```bash
git clone https://github.com/iamjoshgilman/md1200-fan-controller.git
cd md1200-fan-controller
```

---

### 1. Copy the script

```bash
sudo cp fan.sh /usr/local/bin/md1200-fan-controller.sh
sudo chmod +x /usr/local/bin/md1200-fan-controller.sh
```

> Make sure the script uses the correct `hwmonX` paths from your system!

---

### 2. Install the systemd unit

```bash
sudo cp md1200-fan.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now md1200-fan.service
```

---

### 3. View Live Logs

Check the fan controller’s output:

```bash
journalctl -u md1200-fan.service -f
```

You should see:

```
[MD1200 Fan] CPU Temp: 32°C → Speed: 15%
```

---

## 🧠 Troubleshooting

- **No temperature detected?**

  You may need to install and run `lm-sensors`:

  ```bash
  sudo apt install lm-sensors
  sudo sensors-detect
  ```

- **Write error on serial port?**

  - Double check that your serial device is `/dev/ttyS1`
  - Confirm cable is plugged into the MD1200 debug port
  - Try running the echo test again as root

- **Fans don’t respond?**

  Open a serial session with `picocom`:

  ```bash
  apt install picocom
  picocom -b 38400 /dev/ttyS1
  ```

  Then manually type:  
  `set_speed 15`  
  (Press Enter)

---

## 📦 Future Goals

- [ ] Convert to Docker container (with host `/sys` + `/dev/ttyS1` passthrough)
- [ ] Export Prometheus metrics
- [ ] Auto-detect CPU temp files
- [ ] Alerts on full-speed fan triggers
