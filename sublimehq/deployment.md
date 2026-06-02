# Deployment

## Server Setup

Setup proper admin accounts and firewall first

```bash
sudo apt install pipx nginx certbot python3-certbot-nginx

sudo groupadd deploy
# Add any admins to deploy
sudo usermod -a -G deploy benjamin

sudo useradd -m thecrawl
sudo mkdir /opt/thecrawl
sudo chown thecrawl:deploy /opt/thecrawl
sudo chmod g+w /opt/thecrawl
```

Run `./sublimehq/deploy.sh` from an admin's computer.

```bash
# Fix up some permissions
chmod a+x /opt/thecrawl/crawl.sh

sudo su - thecrawl
# Setup uv
pipx install uv
# Setup crawling
crontab -e
# Add the following, with a github token
# */5 * * * * bash -l -c "GITHUB_TOKEN=? /opt/thecrawl/crawl.sh" 2>&1 | systemd-cat -t thecrawl
```

Setup nginx:

```bash
# Paste the config below
sudo nano /etc/nginx/sites-available/packages.sublimetext.com
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/packages.sublimetext.com /etc/nginx/sites-enabled/packages.sublimetext.com
# Check nginx config
sudo nginx -t
# Reload nginx
sudo systemctl reload nginx
# Run certbot
sudo certbot --nginx -d packages.sublimetext.com
```

```nginx
server {
    listen [::]:443 ssl ipv6only=on; # managed by Certbot
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/packages.sublimetext.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/packages.sublimetext.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

    server_name packages.sublimetext.com;

    gzip_static on;

    open_file_cache max=1000 inactive=20s;
    open_file_cache_valid 30s;

    sendfile on;
    tcp_nopush on;

    reset_timedout_connection on;

    root /opt/thecrawl/current-release;

    error_page 404 404.html;

    # Redirect away from .html extension
    location ~ ^(.+)\.html$ {
        return 301 $1;
    }

    #if ($http_accept_encoding !~* "zstd") {
    #    location = /channel_v4.json {
    #        add_header Content-Type zstd;
    #        try_files /opt/thecrawl/channel_v4.json.zstd =404;
    #    }
    #
    #    location = /channel_v3.json {
    #        add_header Content-Type zstd;
    #        try_files /opt/thecrawl/channel_v3.json.zstd =404;
    #    }
    #}

    try_files $uri $uri.html $uri/index.html =404;
}

server {
    if ($host = packages.sublimetext.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    listen [::]:80;

    server_name packages.sublimetext.com;
    return 404; # managed by Certbot
}
```
