#!/bin/bash
# 1 TG_CHAT_ID  2 TOKEN 3 MESSAGE
if [[ -n "${TG_BOT_TOKEN}" ]] && [[ -n "${TG_USER_CHAT_ID}" ]]; then
    :
else
    TG_USER_CHAT_ID=${1}
    TG_BOT_TOKEN=${2}
fi

if [[ -n "${MESSAGE}" ]]; then
    :
else
    if [[ -n "${3}" ]]; then
        MESSAGE=${3}
    elif [[ -n "${1}" ]]; then
        MESSAGE=${1}
    else
        exit 99
    fi
fi
TG_API_URL="https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage"

if ! curl -s -X POST --silent "${TG_API_URL}" -d chat_id="${TG_USER_CHAT_ID}" -d text="${MESSAGE}" >/dev/null; then
    exit 100
fi
