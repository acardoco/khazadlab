## UPS Snapshot Logger

This logger records the UPS status every minute using NUT/`upsc`.

It is safe: it only reads UPS status and does not shut down any machine.

### 1. Create the logger script

```bash
sudo tee /usr/local/sbin/ups-log-snapshot.sh >/dev/null <<'EOF'
#!/usr/bin/env bash
UPS="ups0@192.168.1.65"
LOG_FILE="/var/log/ups-snapshots.log"

{
  echo "===== $(date '+%F %T') ====="
  upsc "$UPS" 2>&1 | egrep 'ups.status|battery.charge|battery.runtime|ups.load|input.voltage|ups.test.result|ups.beeper.status'
} >> "$LOG_FILE"
EOF

sudo chmod +x /usr/local/sbin/ups-log-snapshot.sh
```

### 2. Create the systemd service

```bash
sudo tee /etc/systemd/system/ups-log-snapshot.service >/dev/null <<'EOF'
[Unit]
Description=UPS snapshot logger

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/ups-log-snapshot.sh
EOF
```

### 3. Create the systemd timer

```bash
sudo tee /etc/systemd/system/ups-log-snapshot.timer >/dev/null <<'EOF'
[Unit]
Description=Run UPS snapshot logger every minute

[Timer]
OnBootSec=1m
OnUnitActiveSec=1m
Unit=ups-log-snapshot.service

[Install]
WantedBy=timers.target
EOF
```

### 4. Enable and start the timer

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now ups-log-snapshot.timer
```

### 5. Check timer status

```bash
sudo systemctl status ups-log-snapshot.timer --no-pager
```

```bash
sudo systemctl list-timers --all | grep ups-log
```

Expected state:

```text
Active: active (waiting)
```

### 6. Run the logger manually once

```bash
sudo systemctl start ups-log-snapshot.service
```

### 7. Check service logs

```bash
sudo journalctl -u ups-log-snapshot.service -n 50 --no-pager
```

### 8. Check generated UPS snapshots

```bash
tail -n 50 /var/log/ups-snapshots.log
```

Follow live:

```bash
tail -f /var/log/ups-snapshots.log
```

Example output:

```text
===== 2026-06-26 19:41:32 =====
battery.charge: 100
battery.runtime: 4041
input.voltage: 233.0
ups.beeper.status: enabled
ups.load: 6
ups.status: OL
ups.test.result: No test initiated
```

### 9. Search for abnormal UPS events

```bash
grep -Ei 'OB|LB|CHRG|DISCHRG|No route|Connection|Error|ups.status|input.voltage' /var/log/ups-snapshots.log
```

### 10. Stop the logger

```bash
sudo systemctl stop ups-log-snapshot.timer
```

### 11. Disable the logger

```bash
sudo systemctl disable ups-log-snapshot.timer
```

### 12. Remove the logger

```bash
sudo systemctl stop ups-log-snapshot.timer ups-log-snapshot.service
sudo systemctl disable ups-log-snapshot.timer

sudo rm -f /etc/systemd/system/ups-log-snapshot.timer
sudo rm -f /etc/systemd/system/ups-log-snapshot.service
sudo rm -f /usr/local/sbin/ups-log-snapshot.sh

sudo systemctl daemon-reload
```
