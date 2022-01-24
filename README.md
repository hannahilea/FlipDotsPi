# FlipDotsPi

WIP. A RaspberryPi server (in Julia) for an [AlphaZeta flip dot](https://flipdots.com/en/products-services/flip-dot-boards-xy5/) display.

Currently: scroll a single message on a flip dot board.
Future: set up a server on the pi to handles incoming messages.

## Set up

These instructions are for a Raspberry Pi Zero; ymmv on any other board.

### Disable auto-running Maestro service

If you're starting from a Raspberry Pi Zero that has been provided by/preconfigured by AlphaZeta, with their Maestro software installed, this section is for you.  If you're starting from your own Raspberry Pi Zero, skip to the following section.

1. Following the instructions provided with the board, set your pi up to connect to your local network:
    1. Plug in/turn on your Pi+display
    2. From your computer, connect to the Maestro wifi network
    3. In your browser, go to `http://flipdots.local/`. If you haven't yet, play around and make sure that you're able to send commands and that your board displays them.
    3. In the  the `http://flipdots.local/admin` panel, update SSID/password to be your local wifi network.
    4. Connect your computer to that same local wifi network.

2. SSH onto the Pi: `ssh pi@flipdots.local` (default pw unless/until you change it: `flipdots`)

3. (Pedantic) Change time via config: `sudo raspi-config`

4. Double-check to make sure your wifi network will be autoconnected next time the Pi starts up. Do `cat /etc/wpa_supplicant/wpa_supplicant.conf`; you should see your wifi network as an entry of the form:
```
network={
  ssid="<SSID>"
  psk="<password>"
  priority=1
}
```
If not, edit this file to add it.

5. Disable Maestro from running on Pi startup:
```
sudo rm /etc/systemd/system/maestro.service
sudo systemctl daemon-reload
```
Then reboot for the changes to take effect:
```
sudo reboot
```

### Install Julia on Raspberry Pi Zero
Install Julia (v1.5.3)!

1. With many thanks to @terasakisatoshi (via https://discourse.julialang.org/t/have-a-try-julia-v1-5-1-for-arm32bit/45558):
```
curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
sudo gpasswd -a $USER docker
exit
ssh pi@flipdots.local
JL_VERSION=v1.5.3
IMAGE_NAME=terasakisatoshi/jlcross:rpizero-${JL_VERSION}
CONTAINER_NAME=jltmp_${JL_VERSION}
docker run --name ${CONTAINER_NAME} $IMAGE_NAME /bin/bash
docker cp ${CONTAINER_NAME}:/home/pi/julia-${JL_VERSION} .
docker rm ${CONTAINER_NAME}
sudo ln -s /home/pi/julia-1.5.3/bin/julia /usr/bin/julia
```

2. Install dependency. When running Julia for the first time, you'll need to install the package manager manually (Why? Not sure! It failed otherwise.)
```
rm -rf ~/.julia/registries/General
julia
using Pkg
Pkg.Registry.add("General")
```

### Build and install libserialport

To send messages to the display from Julia, we'll use [LibSerialPort.jl](https://github.com/JuliaIO/LibSerialPort.jl). This library typically depends on `libserialport` binaries (via [`libserialport_jll.jl`](https://github.com/JuliaBinaryWrappers/libserialport_jll.jl)), but `libserialport_jll.jl` doesn't automatically build artifactsfor the Pi Zero architecture, so we'll need to build them ourselves and then move them to the expected location.

1. Install the `LibSerialPort.jl` dependency:
```
julia -e "using Pkg; Pkg.add("LibSerialPort")"
```

2. Build `libserialport` in a temporary directory:
```
sudo apt-get install autoconf
sudo apt-get install libtool

git clone https://github.com/sigrokproject/libserialport.git
cd libserialport
./autogen.sh
./configure
make
sudo make install
```

3. Confirm that the binaries have been built/installed correctly:
```
ls /usr/local/lib/
```
should yield at least
```
libserialport.a   libserialport.so    libserialport.so.0.1.0
libserialport.la  libserialport.so.0
```

4. Copy the binaries into the directory LibSerialPort.jl will look for it in:
```
sudo cp /usr/local/lib/libserialport* ~/.julia/artifacts/3b640a4f5595d49c1a13088bb157b3098a0c3d82/lib
```

5. Enable the Pi to write to the serial ports (then reboot for it to take effect):
```
sudo usermod -a -G dialout pi
sudo reboot
```

5. Try it! From Julia, do:
```julia
using LibSerialPort
srl = LibSerialPort.open("/dev/ttyS0", 57600; mode=SP_MODE_WRITE)
```
...this doesn't do anything yet, but it also shouldn't error.

### Additional Pi configuration

If you want to use do any additional development, including cloning this repo, you may want to set up some combination of git and tmux. If not, you can skip this section.

1. (Optional) Install and set up tmux:
```
sudo apt-get update
sudo apt-get install tmux -y
touch ~/.tmux.conf
echo "set -g mouse on" >> ~/.tmux.conf
```

2. Get github credentials. For the account you want to have read (or read/write access) on the pi, generate a Personal Access Token (PAT): from Github, go to Settings > Developer Settings > PPersonal Access Tokens and generate a token. (Don't navigate away from this screen yet---you'll need access to the token soon!)

3. On the pi, do
```
sudo apt install git
git config credential.helper store
```

11. Clone this repo!
```
git clone https://github.com/hannahilea/FlipDotsPi.git
cd FlipDotsPi
```
When prompted for a username, give your github username. When prompted for a password, use the PAT you generated in step 1.



### Displaying messages

Currently there are two options for running the : command line and REPL.

To display a one-time message on the pi, do
```
julia --project=. fliptdot_message.jl "FLIP FLIP HOORAY!!!"
```
This will then display the message `FLIP FLIP HOORAY!!!`.

Additional configuration options are available through this command line interface; to see them, do
```
julia --project=. flipdot_message.jl --help
```

Alternatively, if you want to play around and don't want to deal with the precompilation overhead for each message, use the REPL: `julia --project=.`

```julia
include("flipdot_message.jl")
display_message("HUZZAH!")
display_message("O_o")
display_message("YAY!")
```

### Acknowledgments

Thanks to the follow resources for helping get us up and running:
-
-
-




4. Shut it down: `sudo shutdown -h now`

Want to run Maestro? While SSH'd onto the pi, do
```
maestro/start.sh
```
then connect by loading `flipdots.local/` in the browser.
