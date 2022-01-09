# FlipDotsPi

A RaspberryPi server for an AlphaZeta FlipDots display.

## Normal pi accesss once one-time setup complete

1. Connect to network you've set the pi up to auto-connect to
2. SSH in: `ssh pi@flipdots.local` (default pw unless/until you change it: `flipdots`)
3. Do whatever it is you want to do!
4. Shut it down: `sudo shutdown -h now`

Want to run Maestro? While SSH'd onto the pi, do
```
maestro/start.sh
```
then connect by loading `flipdots.local/` in the browser.

## Pi one-time set up
Assumptions: Starting state is a RaspberryPi that has been preconfigured by AlphaZeta.

1. Following their instructions, set up the pi to use a local wifi network rather than its default hotspot:
a. Plug in/turn on pi (already connected to FlipDots display)
b. Wait a few minutes
c. Connect to "Maestro" wifi network that will appear
c. Go to http://flipdots.local/admin
d. Update SSID/password to be local wifi network
e. Connect computer to local (same) wifi network!

2. SSH onto pi! From terminal: ` ssh pi@flipdots.local` (default pw: `flipdots`)

3. Then change time via config: `sudo raspi-config`

4. Double-check to make sure your wifi network will be autoconnected to next time you startup:
- If you do `cat /etc/wpa_supplicant/wpa_supplicant.conf`, you should see your wifi network as an entry of the form:
```
network={
  ssid="<SSID>"
  psk="<password>"
  priority=1
}
```

5. Prevent Maestro from starting on startup:
```
sudo rm /etc/systemd/system/maestro.service
sudo systemctl daemon-reload
```
Then shut down and restart the pi.
