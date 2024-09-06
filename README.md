# FlipBoardPi

Code to support running various applications---including a realtime weather monitor---on a flip board such as [AlphaZeta's flip dot](https://flipdots.com/en/products-services/flip-dot-boards-xy5/) displays. Includes:

- **Basic text display**, for both scrolling and static messages! See examples in the [FlipBoard.jl quickstart guide](FlipBoard.jl/README.md) and in the [weather display](./applications/scroll-message/README.md).

- **Realtime [weather display](./applications/weather/README.md)**!

- **Play Steve Reich's "Clapping Music"**! See the [FlipBoard.jl tour](FlipBoard.jl/scripts/tour.jl) for instructions.

This repository contains the following, each of which is relatively orthogonal and use-case specific:
- [Set-up instructions for the AlphaZeta-provided Raspberry Pi Zero](#raspberry-pi-zero-configuration), to enable running custom applications on an AlphaZeta board
- [Set-up instructions for installing Julia](#install-julia-on-raspberry-pi-zero) and requisite [serial port dependencies](#build-and-install-julia-serial-port-dependencies) on the RaspberryPi Zero, to support running Julia applications that send serial commands (e.g., to a board) 
- [FlipBoard.jl](FlipBoard.jl), a lightweight Julia library for generating and sending display updates over a serial port
- A set of [applications](/applications) designed to run on one or more flip boards.

#### Specifics
The Raspberry Pi board used here is a Raspberry Pi Zero (Pi0), as provided by AlphaZeta; setup instructions may need tweaking for other board models.

The flip boards here are 7x28 AlphaZeta displays; setup instructions may need tweaking for other models/brands. 

The FlipBoard.jl library was written to be board-agnostic, so should be relatively easy to extend to support new boards with different communication protocols.

The Julia/Pi0 limitations were accurate at time of project set-up (~2022) and may no longer be valid at time of reading, as the set-up portion of this project is not under active development/improvement.

Feel free to open a pull request with any documentation clarifications or improvements!

## One-time setup instructions

### Raspberry Pi Zero configuration

Set the Pi to run on a local wifi network, and prevent it from auto-running the pre-installed AlphaZeta Maestro application on start-up. If you're starting from a Pi0 that has been provided by/preconfigured by AlphaZeta, with their Maestro software installed, this section is for you. If not, skip steps that refer to "maestro".

1. Following the instructions provided with the board, set up Pi to connect to your local wifi network:
    1. Plug in and turn on Pi and flip board
    2. On your computer, connect to the Maestro wifi network
    3. In your browser, go to `http://flipdots.local/`. (If you haven't done this previously, play around with the provided AlphaZeta application and make sure that you're able to successfully send commands to your board.)
    3. In the  the `http://flipdots.local/admin` panel, update the SSID and password to that of your local wifi network.
    4. Connect your computer to that same local wifi network.

2. SSH onto the Pi: `ssh pi@flipdots.local` (The default password, unless/until you change it, is `flipdots`)

3. (Optional) Change the Pi's time via its config: `sudo raspi-config`

4. Double-check to make sure your wifi network will be autoconnected next time the Pi starts up:
    1. Do `cat /etc/wpa_supplicant/wpa_supplicant.conf`
    2. You should then see your wifi network as an entry of the form:
    ```
    network={
      ssid="<SSID>"
      psk="<password>"
      priority=1
    }
    ```
    If not, edit this file to add it (`nano /etc/wpa_supplicant/wpa_supplicant.conf`)

5. Disable Maestro from running on Pi startup:
    ```
    sudo rm /etc/systemd/system/maestro.service
    sudo systemctl daemon-reload
    ```

6. Reboot the Pi for the changes to take effect:
    ```
    sudo reboot
    ```

### Install Julia on Raspberry Pi Zero

With many thanks to [@terasakisatoshi](https://discourse.julialang.org/u/terasakisatoshi), via [these instructions](https://discourse.julialang.org/t/have-a-try-julia-v1-5-1-for-arm32bit/45558),:

1. On the Pi, do
    ```
    curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
    sudo gpasswd -a $USER docker
    sudo reboot
    JL_VERSION=v1.5.3
    IMAGE_NAME=terasakisatoshi/jlcross:rpizero-${JL_VERSION}
    CONTAINER_NAME=jltmp_${JL_VERSION}
    docker run --name ${CONTAINER_NAME} $IMAGE_NAME /bin/bash
    docker cp ${CONTAINER_NAME}:/home/pi/julia-${JL_VERSION} .
    docker rm ${CONTAINER_NAME}
    sudo ln -s /home/pi/julia-1.5.3/bin/julia /usr/bin/julia
    ```

3. Sanity check:
    ```
    which julia
    julia --version
    ```
    should yield `/usr/bin/julia` and `julia version 1.5.3`, respectively

4. When running Julia for the first time, you'll need to [re]install the package manager manually.
    ```
    rm -rf ~/.julia/registries/General
    julia   # launch the Julia REPL
    ```
    Then from the REPL do
    ```julia
    using Pkg
    Pkg.Registry.add("General")
    ```

### Build and install Julia serial port dependencies

To send messages to the display from Julia, we'll use [LibSerialPort.jl](https://github.com/JuliaIO/LibSerialPort.jl). This library typically depends on `libserialport` binaries (via [`libserialport_jll.jl`](https://github.com/JuliaBinaryWrappers/libserialport_jll.jl)), but (at least at time of writing) `libserialport_jll.jl` doesn't automatically build artifacts for the Pi Zero architecture, so we need to build them ourselves and then move them to the expected location.

1. Install the `LibSerialPort.jl` dependency:
    ```
    julia -e "using Pkg; Pkg.add("LibSerialPort")"
    ```

2. Build `libserialport` in a temporary directory:
    ```
    sudo apt-get install autoconf
    sudo apt-get install libtool
    sudo apt install git

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

4. Copy the binaries into the directory LibSerialPort.jl will look for them in:
    ```
    sudo cp /usr/local/lib/libserialport* ~/.julia/artifacts/3b640a4f5595d49c1a13088bb157b3098a0c3d82/lib
    ```

5. Enable the Pi to write to the serial ports, then reboot for it to take effect:
    ```
    sudo usermod -a -G dialout pi
    sudo reboot
    ```

1. (Optional) Install additional libopenblas dependency. This dependency is not strictly required, but installing it will prevent a warning from popping up every time you run `LibSerialPort.jl`:
    ```
    sudo apt-get install libopenblas-dev
    ```

7. Try it! From Julia, do:
    ```julia
    using Pkg
    Pkg.add("LibSerialPort")
    using LibSerialPort
    srl = LibSerialPort.open("/dev/ttyS0", 57600; mode=SP_MODE_WRITE)
    ```
    ...this doesn't do anything yet, but unless your system is configured correctly (**and the Pi is connected to the Flip Board!!**) it will likely error.

### Additional Pi configuration

If you want to use do any additional development on your board, including cloning this repo (to, e.g., run any of the included applications), you may want to set up some combination of git and tmux. If not, you can skip this section!

1. (Optional) Install and set up tmux:
    ```
    sudo apt-get update
    sudo apt-get install tmux -y
    touch ~/.tmux.conf
    echo "set -g mouse on" >> ~/.tmux.conf
    ```
    Why might you want tmux? If you're planning to leave an application running long term, and want any errors (or logs) it generates to be available to you when you log in after the fact, you may want to run your application in a tmux pane. 

2. (Optional) Set up github credentials. 
    1. For the account you want to have read (or read/write access) on the Pi, generate a Personal Access Token (PAT): on Github, do `Settings > Developer Settings > Personal Access Tokens` and generate a token. Don't navigate away from this screen yet---you'll need access to the generated token in a later step.

    2. Clone this (or another) repo
    ```
    git config credential.helper store
    git clone https://github.com/hannahilea/FlipDotsPi.git
    ```
    When prompted for a username, give your github username; when prompted for a password, use the PAT you generated in step 1.

### FAQ

_Q. Even though I disabled Maestro from automatically running, I'd like to manually start it. How do I do that?_

A. On the Pi, run
```
maestro/start.sh
```
Then connect by loading [`flipdots.local/`](http://flipdots.local) in your local browser.


_Q. How do I shut the Pi down when I'm done using it?_

A. AlphaZeta recommends that the AlphaZeta boards be flipped fully to white before longer term storage, i.e., before shutting down the board. Once you've updated the display accordingly, do `sudo shutdown -h now` to shut down the Pi.


_Q. I can run messages on the display with Maestro, but something about my Julia installation failed. Is there a faster way to bisect my error?_

A. You can try installing/running [a different flipdots scroller](https://github.com/vwyf/vwyf_door_sensor/tree/2a281e274d4d14e7d020158d55fd5dc94bfccd13) via Python (be sure to first follow the above steps to stop Maestro):

    1. Set up:
    
        ```
        sudo apt-get install python-pip
        pip install pyserial
        cd
        wget https://raw.githubusercontent.com/vwyf/vwyf_door_sensor/2a281e274d4d14e7d020158d55fd5dc94bfccd13/flipdot_demon.py
        python flipdot_demon.py
        ```

    2. Edit the script (`nano flipdot_demon.py`) to change...
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

    3. Run it: `python flipdot_demon.py`

### Acknowledgments

Thanks to the follow resources for helping get us up and running:
- Instructions for [installing Julia (plus additional required binaries) on the Pi Zero](https://discourse.julialang.org/t/have-a-try-julia-v1-5-1-for-arm32bit/45558/22)
- Understanding how [AlphaZeta messages are serialized and constructed](https://ksawerykomputery.pl/tools/flipdigits-player)
- Example of [scrolling message via Python](https://github.com/vwyf/vwyf_door_sensor/tree/2a281e274d4d14e7d020158d55fd5dc94bfccd13)
