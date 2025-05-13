#!/bin/bash

SERIAL="/dev/ttyS1"
TEMP1="/sys/class/hwmon/hwmon0/temp1_input"
TEMP2="/sys/class/hwmon/hwmon1/temp1_input"

DEFAULT=15
MIN=30
MID=50
MAX=100

# Initial command blast to set fan speed on startup to make sure it sticks
for i in {1..10}; do
  echo -ne "set_speed $DEFAULT\r\n" > "$SERIAL" 2>/dev/null
  sleep 0.3
done

# Main loop to monitor temperatures and adjust fan speed
while true; do
  if [[ -f "$TEMP1" && -f "$TEMP2" ]]; then
    CPU1=$(( $(cat "$TEMP1") / 1000 ))
    CPU2=$(( $(cat "$TEMP2") / 1000 ))
    CPU_TEMP=$(( CPU1 > CPU2 ? CPU1 : CPU2 ))
  else
    CPU_TEMP=99
  fi

  SPEED=$DEFAULT
  if (( CPU_TEMP >= 70 )); then
    SPEED=$MAX
  elif (( CPU_TEMP >= 60 )); then
    SPEED=$MID
  elif (( CPU_TEMP >= 50 )); then
    SPEED=$MIN
  fi

  echo "[MD1200 Fan] CPU Temp: ${CPU_TEMP}°C → Speed: ${SPEED}%"

  # Blast the fan command 10 times to ensure it registers
  for i in {1..10}; do
    echo -ne "set_speed $SPEED\r\n" > "$SERIAL" 2>/dev/null
    sleep 0.3
  done

  sleep 60
done

