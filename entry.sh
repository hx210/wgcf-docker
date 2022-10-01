#!/usr/bin/env bash

set -e

wireguard_conf_name="warp"
wireguard_conf_basic_path="/etc/wireguard"
wireguard_conf_path="${wireguard_conf_basic_path}/${wireguard_conf_name}.conf"
_downwgcf() {
  echo
  echo "clean up"
  if ! wg-quick down "${wireguard_conf_name}"; then
    echo "error down"
  fi
  echo "clean up done"
  exit 0
}

#-4|-6
runwgcf() {
  trap '_downwgcf' ERR TERM INT

  _enableV4="1"
  if [ "$1" = "-6" ]; then
    _enableV4=""
  fi

  if [ ! -e "wgcf-account.toml" ]; then
    wgcf register --accept-tos
  fi

  if [ ! -e "wgcf-profile.conf" ]; then
    wgcf update
    wgcf generate
  fi

  ln -sf /wgcf/wgcf-profile.conf "${wireguard_conf_path}"

  DEFAULT_GATEWAY_NETWORK_CARD_NAME=$(route | grep default | awk '{print $8}' | head -1)
  DEFAULT_ROUTE_IP=$(ifconfig $DEFAULT_GATEWAY_NETWORK_CARD_NAME | grep "inet " | awk '{print $2}' | sed "s/addr://")

  echo "${DEFAULT_GATEWAY_NETWORK_CARD_NAME}"
  echo "${DEFAULT_ROUTE_IP}"

  sed -i "/\[Interface\]/a PostDown = ip rule delete from $DEFAULT_ROUTE_IP  lookup main" "${wireguard_conf_path}"
  sed -i "/\[Interface\]/a PostUp = ip rule add from $DEFAULT_ROUTE_IP lookup main" "${wireguard_conf_path}"

  if [ "$1" = "-6" ]; then
    sed -i 's/AllowedIPs = 0.0.0.0/#AllowedIPs = 0.0.0.0/' "${wireguard_conf_path}"
  elif [ "$1" = "-4" ]; then
    sed -i 's/AllowedIPs = ::/#AllowedIPs = ::/' "${wireguard_conf_path}"
  fi

  modprobe ip6table_raw

  wg-quick up "${wireguard_conf_name}"

  if [ "$_enableV4" ]; then
    _checkV4
  else
    _checkV6
  fi

  echo
  echo "OK, ${wireguard_conf_name} is up."

  echo "配置gost"
  gost -L=:1080

  sleep infinity &
  wait

}

_checkV4() {
  echo "Checking network status, please wait...."
  while ! curl --max-time 2 ipinfo.io; do
    wg-quick down "${wireguard_conf_name}"
    echo "Sleep 2 and retry again."
    sleep 2
    wg-quick up "${wireguard_conf_name}"
  done

}

_checkV6() {
  echo "Checking network status, please wait...."
  while ! curl --max-time 2 -6 ipv6.google.com; do
    wg-quick down "${wireguard_conf_name}"
    echo "Sleep 2 and retry again."
    sleep 2
    wg-quick up "${wireguard_conf_name}"
  done

}

if [ -z "$@" ] || [[ "$1" = -* ]]; then
  runwgcf "$@"
else
  exec "$@"
fi
