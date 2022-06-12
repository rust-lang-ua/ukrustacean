#!/usr/bin/env bash

set -e

apt -y update
apt -y upgrade
apt -y install podman

cat <<EOF > /etc/systemd/system/ukrustacean.service
[Unit]
Description=Ukrustacean Telegram Bot
After=local-fs.target podman.service
Requires=local-fs.target


[Service]
Environment=BOT_CONTAINER_NAME=ukrustacean
Environment=BOT_IMAGE_NAME=docker.io/tyranron/ukrustacean
Environment=BOT_IMAGE_TAG=dev
Environment=TELOXIDE_TOKEN=${telegram_bot_token}

ExecStartPre=-/usr/bin/podman pull \$${BOT_IMAGE_NAME}:\$${BOT_IMAGE_TAG}
ExecStartPre=-/usr/bin/podman stop \$${BOT_CONTAINER_NAME}
ExecStartPre=-/usr/bin/podman rm --volumes \$${BOT_CONTAINER_NAME}
ExecStart=/usr/bin/podman run --network=host \\
  -e RUST_LOG=info \\
  -e TELOXIDE_TOKEN=\$${TELOXIDE_TOKEN} \\
  \$${BOT_IMAGE_NAME}:\$${BOT_IMAGE_TAG}

ExecStop=-/usr/bin/podman stop \$${BOT_CONTAINER_NAME}
ExecStop=-/usr/bin/podman rm --volumes \$${BOT_CONTAINER_NAME}

Restart=always


[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl unmask ukrustacean.service
systemctl enable ukrustacean.service
systemctl restart ukrustacean.service
