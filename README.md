# television
> hls-based livestreaming client for second life media surfaces

## in-world setup
copy `screen.lsl` into a brand new box prim, this will turn the prim into your
new video screen

copy `remote.lsl` into a brand new box prim, then take the result to inventory
and attach it as a hud

for best results, make sure all people watching have both `media auto-play` and
`allow inworld scripts to play media` enabled

enable `play media attached to other avatars` to allow the screen to function
as an attachment

## in-world usage
rez, size and position the screen to suit

wear the remote hud and click it to access the menu:

* `URL` will set the current HLS video stream, see [docs/server.md][0] for
  building your own stream server to use

* `ON` and `OFF` turn the video screen on and off

* `SYNC` forces all current viewers to reload the stream

* `ACCESS` allows either `OWNER`, `GROUP` or `PUBLIC` access. the video screen
  must either be tagged or deeded to the group in order for `GROUP` access to
  function. it defaults to `GROUP` so that deeding the screen works smoothly

* `GROW` and `SHRINK` scale the display up and down, locking it to a 16:9
  aspect ratio

* `SHOW` and `HIDE` to make the screen disappear, useful for using this as a
  radio

with a `URL` set and the screen `ON`, views must click the screen to enable
media content, then once the video is playing click to unmute the screen

## site development
the streaming client is available pre-built inside the `docs/` directory. this
client is hosted here on github pages and is what is used by `screen.lsl`. to build
the client yourself, peform the following:

### dependencies
```shell
    # Debian/Ubuntu
    apt -y install nodejs npm
```

### building
```shell
    npm i
    npm run build
```

[0]: https://github.com/hxppxcxlt/television/blob/main/docs/server.md

