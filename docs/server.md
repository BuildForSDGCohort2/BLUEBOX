# television server
this is a complete set of instructions on how to compile your very own
custom nginx server ready for live rtmp-to-hls video streaming. ffmpeg will
be used as the streaming client. a shell function is provided for managing
the streaming client

## dependencies
* a server, domain and an ssl certificate for it. how you make this happen is
  beyond the scope of this document

* a `www-data` user with its own `www-data` group on your system. typically:
```shell
    useradd -d /var/www -m -s /bin/false www-data
```

* a C toolchain:
```shell
    # Debian/Ubuntu
    apt -y install gcc g++ libc-dev binutils make patch
```

* nginx's dependencies:
```shell
    # Debian/Ubuntu
    apt -y install libpcre3-dev libz-dev libssl-dev
```

* ffmpeg:
```shell
    # Debian/Ubuntu
    apt -y install ffmpeg
```

## server installation
```shell
wget "http://nginx.org/download/nginx-1.20.0.tar.gz"
tar xf nginx-1.20.0.tar.gz
cd nginx-1.20.0

wget "https://www.openssl.org/source/openssl-1.1.1l.tar.gz"
wget "https://github.com/arut/nginx-rtmp-module/archive/refs/tags/v1.2.2.tar.gz"

tar xf openssl-1.1.1l.tar.gz
tar xf v1.2.2.tar.gz

CFLAGS="-fPIC" ./configure \
  --with-pcre-jit \
  --with-http_ssl_module \
  --with-http_gzip_static_module \
  --with-threads \
  --with-cc-opt=" -fPIC " \
  --with-ld-opt="-pie " \
  --with-openssl="$(pwd)/openssl-1.1.1l" \
  --add-module="$(pwd)/nginx-rtmp-module-1.2.2"

CFLAGS="-fPIC" make -j4
make install

mkdir -p /tmp/hls
openssl dhparam -out /usr/local/nginx/conf/dhparam.pem 3072 >/dev/null 2>&1
```

edit `/usr/local/nginx/conf/nginx.conf`:
> **NOTE:** change `slive.invalid` in `nginx.conf` to your domain!

```nginx
user www-data;
worker_processes auto;
worker_rlimit_nofile 8192;

events {
  worker_connections 4096;
  multi_accept on;
}

http {
  include mime.types;
  default_type application/octet-stream;

  access_log off;
  sendfile on;
  tcp_nopush on;
  reset_timedout_connection on;
  server_tokens off;

  ssl_ciphers 'AES+EECDH:AES+EDH:+AES256';
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_session_cache shared:SSL:10m;
  ssl_prefer_server_ciphers on;
  ssl_dhparam dhparam.pem;

  add_header "Access-Control-Allow-Origin" "*";

  server {
    listen *:80;
    server_name _;
    location / {
      deny all;
    }
  }

  server {
    listen *:80;
    server_name slive.invalid;
    return 301 https://$host$request_uri;
  }

  server {
    listen *:443 ssl;
    server_name slive.invalid;
    ssl_certificate slive.invalid.crt;
    ssl_certificate_key slive.invalid.key;
    add_header Strict-Transport-Security "max-age=31536000;";

    location /hls {
      root /tmp/hls;
      open_file_cache off;
      add_header Cache-Control no-store;
      add_header Strict-Transport-Security "max-age=31536000;";
      add_header Access-Control-Allow-Origin "*" always;
      types {
        application/x-mpegurl m3u8;
        video/mp2t ts;
      }
    }

    location /sync {
      return 200 $msec;
    }
  }
}

rtmp {
  server {
    listen 127.0.0.1:1935;

    application show {
      live on;

      hls on;
      hls_path /tmp/hls;
      hls_fragment_naming system;

      allow publish 127.0.0.1;
      deny publish all;
      deny play all;
    }
  }
}
```

**NOTE**: be sure to copy your ssl key and certificate either to the paths you
have specified in the above vhost or to `/usr/local/nginx/conf/` where it
will check by default for them

once completed, use `nginx` to launch the server

## ffmpeg client
add the following function to your `.profile`:

```shell
stream() {
  seek="00:00:00"
  args=""
  file=""
  while true; do
    case "$1" in
      -a|--args) shift; args="$@"; continue;;
      -f|--file) file="$2"; shift; shift; continue;;
      -s|--seek) seek="$2"; shift; shift; continue;;
      *) break;;
    esac
  done
  [ -z "$file" ] && file="$1"

  scale=""
  need_scale=false
  height=$(ffprobe -v error \
    -select_streams v:0 \
    -show_entries stream=height \
    -of csv=s=x:p=0 \
    "$file")
  [ $height -gt 720 ] && need_scale=true
  $need_scale && \
    scale="-vf scale=-2:720 -sws_flags lanczos"

  ffmpeg -re -ss "$seek" -i "$file" $args \
    -c:a aac -ac 2 -ar 48000 -b:a 192k \
    -c:v libx264 -bsf:v h264_mp4toannexb -pix_fmt yuv420p \
    -force_key_frames "expr:gte(t,n_forced*3)" $scale \
    -tune film -maxrate 3000k -bufsize 5000k \
    -err_detect ignore_err -ignore_unknown \
    -f flv rtmp://localhost/show/stream
}
```

once active, you may now livestream files by using `stream <path to file>`. the
above settings provide decent quality for livestreaming film content at 720p,
automatically downscaling content above 720p as needed

you may `stream -f <file> -s "00:10:00"` to seek ten minutes into the
file, which can be useful for pausing and resuming

you may also provide additional flags by using `-a` as your last argument. the
following example will select the default video track, as well as any track
with metadata tagging it as English language:

`stream -f <file> -a -map 0:v:0 -map 0:m:language:eng`

you typically will be using `-a` for selecting the correct audio tracks and
burning in subtitles. consult the `ffmpeg` manual for more details

