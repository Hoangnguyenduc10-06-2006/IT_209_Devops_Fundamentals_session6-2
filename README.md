
<img width="1264" height="706" alt="image" src="https://github.com/user-attachments/assets/8e3ee4fa-0b8a-4986-bd9c-c733d1061854" />


# Bài 2: Cấu hình phân quyền Nhóm và sudoers bằng visudo

## 1. Bối cảnh

User `deployer` (công cụ deploy tự động) cần **restart dịch vụ** nhưng **không được cấp toàn quyền root**. Giải pháp: tạo nhóm `devops-admin`, chỉ cho phép nhóm này chạy `systemctl start|stop|restart|status` qua `sudo` mà không cần mật khẩu.

## 2. Nhật ký các lệnh đã thực hiện

```bash
# 1. Tạo group
sudo groupadd devops-admin

# 2. Tạo user và thêm vào group
sudo adduser deployer
sudo usermod -aG devops-admin deployer
id deployer
# uid=1001(deployer) gid=1001(deployer) groups=1001(deployer),1002(devops-admin)

# 3. Xác định đường dẫn tuyệt đối của systemctl
which systemctl
# /usr/bin/systemctl

# 4. Mở sudoers an toàn bằng visudo và thêm rule vào cuối file
sudo visudo
```

### Dòng cấu hình đã thêm vào `/etc/sudoers`

```sudoers
%devops-admin ALL=(ALL) NOPASSWD: /usr/bin/systemctl start *, /usr/bin/systemctl stop *, /usr/bin/systemctl restart *, /usr/bin/systemctl status *
```

| Thành phần | Ý nghĩa |
|---|---|
| `%devops-admin` | Áp dụng cho **group** (dấu `%`) devops-admin |
| `ALL=` | Trên mọi host |
| `(ALL)` | Được chạy lệnh với tư cách bất kỳ user nào (mặc định root) |
| `NOPASSWD:` | Không hỏi mật khẩu |
| `/usr/bin/systemctl restart *` | Chỉ cho phép đúng lệnh này (đường dẫn tuyệt đối) với tham số bất kỳ |

> Cách thay thế (best practice): đặt rule vào file riêng `/etc/sudoers.d/devops-admin` bằng `sudo visudo -f /etc/sudoers.d/devops-admin` — xem [setup.sh](./setup.sh).

## 3. Kiểm tra

<!-- TODO: thay bằng output THỰC TẾ (hoặc ảnh chụp màn hình) từ máy Linux của bạn -->
```text
$ su - deployer
Password:

deployer@server:~$ sudo -l
Matching Defaults entries for deployer on server:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin, use_pty

User deployer may run the following commands on server:
    (ALL) NOPASSWD: /usr/bin/systemctl start *, /usr/bin/systemctl stop *, /usr/bin/systemctl restart *, /usr/bin/systemctl status *

deployer@server:~$ sudo systemctl restart cron
deployer@server:~$ sudo systemctl status cron --no-pager | head -3
● cron.service - Regular background program processing daemon
     Loaded: loaded (/usr/lib/systemd/system/cron.service; enabled; preset: enabled)
     Active: active (running) since ...

# Kiểm tra lệnh KHÔNG được phép -> bị từ chối
deployer@server:~$ sudo cat /etc/shadow
[sudo] password for deployer:
Sorry, user deployer is not allowed to execute '/usr/bin/cat /etc/shadow' as root on server.
```

**Kết quả:** `sudo systemctl restart cron` chạy thành công, không hỏi mật khẩu; các lệnh ngoài danh sách bị từ chối → đúng nguyên tắc *least privilege*.

## 4. Lưu ý

- Luôn dùng `visudo` (có kiểm tra cú pháp) thay vì sửa trực tiếp `/etc/sudoers`; lỗi cú pháp có thể làm mất toàn bộ quyền sudo.
- Sau khi `usermod -aG`, user phải **đăng nhập lại** (`su - deployer`) thì nhóm mới có hiệu lực.
- Wildcard `*` vẫn cho phép thao tác với **mọi** service (kể cả `ssh`, `sudo`...). Ở môi trường production nên giới hạn cụ thể, ví dụ: `/usr/bin/systemctl restart nginx`.
