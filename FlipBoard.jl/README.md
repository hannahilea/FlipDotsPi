# FlipBoard
TODO: Intro, CI, codecov

## Quick start
Currently there are two options for displaying messages with this package: via command line and via REPL.

To display a one-time message on the Pi, use the command line:
```
cd FlipBoard.jl
julia --project=. scripts/scroll_message.jl "FLIP FLIP HOORAY!!!"
```
This will then display the message `FLIP FLIP HOORAY!!!`. (Note: it may take some time to precompile and display the message; don't be discouraged!) The quotes around the message are required.

If you don't see the message, you may need to adjust your port and/or baudrate, which can be done with flags. To see these configuration options, do
```
julia --project=. scripts/scroll_message.jl --help
```

Alternatively, if you want to play around with displaying multiple messages and don't want to deal with the precompilation overhead for each message, run the code via the REPL: `julia --project=.` and then play with the supported functionality by taking the [tour](`scripts/tour.jl`).

