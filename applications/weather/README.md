# Realtime weather updating

Do
```
julia --project=applications/weather applications/weather/run.jl
```
Update the in-script `DEFAULT_LOCATION` constant to your specific latitude/longitude.

Requires `jq` to be installed. (We can't just install jq_jll as a julia dep, as the julia version running on the pi is too old...)
```
sudo apt-get install jq
```
