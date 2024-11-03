# How to run kanata as a service on startup

I used this `kanata.service` file:

```bash
[Unit]
Description=Kanata key remapping daemon
Requires=local-fs.target
After=local-fs.target

[Service]
Type=simple
ExecStart=/usr/bin/kanata --cfg /etc/kanata/kanata.kbd --port 5829

[Install]
WantedBy=sysinit.target
```

And installed as follows:

1. Install kanata.
2. Copy the configuration file to a system wide place. (I used `/etc/kanata`.)
3. Install the service description for kanata.
4. (re)start the system service.
5. Enable it to auto-start on boot.

```bash
mkdir /etc/kanata
cp my-config-for-kanata.kbd /etc/kanata/kanata.kbd
sudo install -m 644 kanata.service /lib/systemd/system/kanata.service
# sudo systemctl daemon-reload
# maybe this will be required when changing the service file
sudo systemctl start kanata
sudo systemctl enable kanata
```

---

Thanks to [mhantsch](https://github.com/mhantsch) for this guide, link to his original comment [here](https://github.com/jtroo/kanata/discussions/130#discussioncomment-9970020)
