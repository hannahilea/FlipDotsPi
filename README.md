## Pi one-time set up
Set up pi to use our local network:
a. Plug in/turn on pi
b. Wait a few minutes; connect to "Maestro" wifi network that appears.
c. Go to http://flipdots.local/admin
d. Update SSID/password to local wifi network
e. Connect to local (same) wifi network!

Now what? SSH to it!
1. ` ssh pi@flipdots.local`
2. pw: `flipdots`

Then change time via config: `sudo raspi-config`

## Mucking about!
### (Existing Python demo)[https://www.instructables.com/Howto-Flipdot-With-a-Raspi/]

1. Copy their script to the pi
```
cd
mkdir mucking
cd mucking
wget https://raw.githubusercontent.com/vwyf/vwyf_door_sensor/2a281e274d4d14e7d020158d55fd5dc94bfccd13/flipdot_demon.py
```

2. Edit that script
`nano flipdot_demon.py`

to change...
...line 135 from
```
with serial.Serial("/dev/ttyUSB0", 9600) as srl:
```
to
```
with serial.Serial("/dev/serial0", 57600) as srl:
```
and also line 112 from
```
panel_address,
```
to
```
0xFF,
```
At the same time, you can also edit the message to be whatever you'd like by editing the `question_string`.


2. Install pip+deps, woo
Not using virtualenv or python3 b/c we won't be using python for long anyway.
```
sudo apt-get install python-pip
pip install pyserial
```

3. Figure out how to stop maestro (which runs by default on the pi)
Probably a better way to do this, but we did `htop` and then killed all the maestro-looking proccesses (which were running as `root`).

3. Run it!
```
python flipdot_demon.py
```

(Thanks to https://ksawerykomputery.pl/tools/flipdigits-player for additional info that made these tweaks understandable!)

4. Be fully done:
```
sudo shutdown -h now
```

Next up:
- no moar python

Other cool projects with flipdots:
- https://hackaday.com/2021/11/09/flip-dot-oscilloscope-is-flippin-awesome/