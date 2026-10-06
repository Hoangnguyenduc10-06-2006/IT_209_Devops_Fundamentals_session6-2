#!/usr/bin/env bash
# Bài 2 - Tạo group/user và cấp quyền sudo giới hạn cho systemctl
# Chạy bằng user có quyền sudo:  bash setup.sh
set -euo pipefail

GROUP=devops-admin
USER_NAME=deployer
SUDOERS_FILE=/etc/sudoers.d/devops-admin

# 1. Tạo group
getent group "$GROUP" >/dev/null || sudo groupadd "$GROUP"

# 2. Tạo user (adduser sẽ hỏi mật khẩu) và thêm vào group
id "$USER_NAME" >/dev/null 2>&1 || sudo adduser "$USER_NAME"
sudo usermod -aG "$GROUP" "$USER_NAME"
id "$USER_NAME"

# 3. Kiểm tra đường dẫn thực của systemctl (sudoers yêu cầu đường dẫn tuyệt đối)
SYSTEMCTL=$(command -v systemctl)
echo "systemctl path: $SYSTEMCTL"

# 4. Ghi rule vào /etc/sudoers.d (tương đương thêm bằng `sudo visudo`)
RULE="%${GROUP} ALL=(ALL) NOPASSWD: ${SYSTEMCTL} start *, ${SYSTEMCTL} stop *, ${SYSTEMCTL} restart *, ${SYSTEMCTL} status *"
TMP=$(mktemp)
echo "$RULE" > "$TMP"

# Kiểm tra cú pháp trước khi áp dụng để tránh làm hỏng sudo
sudo visudo -cf "$TMP"
sudo install -m 0440 -o root -g root "$TMP" "$SUDOERS_FILE"
rm -f "$TMP"

sudo visudo -c
echo "Đã thêm rule: $RULE"
