## TODO

- [ ] Update readme for now-working changelog instructions!
  - remove installation cruft from old attempts

- set up server for pi
  - install julia on pi
  - run same startup steps as for previous pi
- auto-run it on boot


## Work log

### Jan 13 2022
Trying to build libserialport manually (instructions here: https://github.com/sigrokproject/libserialport):

1. remove old one:
```
sudo apt-get remomve libserialport-dev
sudo apt-get remomve libserialport0
```
verify nothing:
```
apt list --installed | grep libserialport
```

2. build new one
```
sudo apt-get install autoconf
sudo apt-get install libtool

git clone https://github.com/sigrokproject/libserialport.git
./autogen.sh
./configure
make
sudo make install
```
confirm existance:
```
ls /usr/local/lib/
```

3. Copy it over:
```
sudo cp /usr/local/lib/libserialport* ~/.julia/artifacts/3b640a4f5595d49c1a13088bb157b3098a0c3d82/lib
```
confirm:
```
ls ~/.julia/artifacts/3b640a4f5595d49c1a13088bb157b3098a0c3d82/lib
```
4. Try it:
```julia
using LibSerialPort
srl = LibSerialPort.open("/dev/ttyS0", 57600; mode=SP_MODE_WRITE)

#note: using /dev/serial0 fails?!? still?!? dunno why.

```

### Jan 9 2022
- Spent a lot of time trying to figure out how to get LibSerialPort deps running. Maybe succeeded? Instructions are now up to date; lots of thanks to https://discourse.julialang.org/t/have-a-try-julia-v1-5-1-for-arm32bit/45558/22

- Looks like our serial port isn't enabled by default; must have been previously set up by maestro? Trying to figure out how to set that up.
    - For future: in maestro/displayConfig.yml, option to uncomment type to make it different type of screen

- After a bunch of mucking around, unable to make LibSerialPorts.jl work, reran the old python script as a sanity-check. It worked. -__- Giving up on LibSerialPorts, moving to SerialPorts.jl (which wraps the python library).
- For future reference, to get the

### Jan 8 2022

- made a repo! (https://github.com/hannahilea/FlipDotsPi)

- Poked around at install scripts:
    - `cat maestro/install_maestro.sh`
    - `cat maestro/install_autohotspot.sh`
    - We probably want to disable the autohotspot? At least after we set up the wifi correctly...Actually it seems like maybe not, that's a good fallback if for whatever reason our private network is down (like it was when we started today).

- Time to disable the run-on-start maestro! How do we do that?
    - Thanks to the helpful https://www.thedigitalpictureframe.com/ultimate-guide-systemd-autostart-scripts-raspberry-pi/

- Spent a lot of time trying to figure out how to get LibSerialPort deps running. Did not succeed. Instructions are now up to date; lots of thanks to https://discourse.julialang.org/t/have-a-try-julia-v1-5-1-for-arm32bit/45558/22

### Jan 4 2022

From maestro, connected to our wifi.
SSH'd in, updated local time on pi.
Ran python script:

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

