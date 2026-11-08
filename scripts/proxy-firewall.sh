#!/usr/bin/env bash
set -euo pipefail
# Docker-published ports bypass ordinary UFW INPUT rules; filter the original destination.
proxy_ip="${PROXY_IP:?Isi PROXY_IP dengan alamat reverse proxy}"
app_ip="${APP_IP:?Isi APP_IP dengan alamat VPS aplikasi}"
app_port="${APP_PORT:-3000}"
iptables -N JALASMARA-UPSTREAM 2>/dev/null || true
iptables -F JALASMARA-UPSTREAM
iptables -A JALASMARA-UPSTREAM -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
iptables -A JALASMARA-UPSTREAM -s "$proxy_ip" -j RETURN
iptables -A JALASMARA-UPSTREAM -s "$app_ip" -j RETURN
iptables -A JALASMARA-UPSTREAM -j DROP
iptables -C DOCKER-USER -p tcp -m conntrack --ctorigdst "$app_ip" --ctorigdstport "$app_port" -j JALASMARA-UPSTREAM 2>/dev/null || iptables -I DOCKER-USER 1 -p tcp -m conntrack --ctorigdst "$app_ip" --ctorigdstport "$app_port" -j JALASMARA-UPSTREAM
