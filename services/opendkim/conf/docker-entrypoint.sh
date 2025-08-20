#! /bin/bash

if [[ -z "${DKIM_DOMAIN}" ]] || [[ -z "${DKIM_SELECTOR}" ]]; then
    echo "Please set DKIM_DOMAIN and DKIM_SELECTOR environment variables."
    exit 1
fi

echo -e "\e[32mDKIM_* variables:\e[0m"
echo -e "   DKIM_DOMAIN = ${DKIM_DOMAIN}"
echo -e "   DKIM_SELECTOR = ${DKIM_SELECTOR}"
echo

if [[ ! -f "/etc/opendkim/keys/${DKIM_SELECTOR}.private" ]]; then
    echo -e "\e[32mNo opendkim key found; generation new one ...\e[0m"
    opendkim-genkey \
        -d ${DKIM_DOMAIN} \
        -D /etc/opendkim/keys \
        -h sha256 \
        -r \
        -s ${DKIM_SELECTOR} \
        -v
    echo

    echo -e "\e[32mSet DNS setting to:\e[0m"
    cat /etc/opendkim/keys/${DKIM_SELECTOR}.txt
    echo
fi

echo -e "\e[32mReplacing:\e[0m"
cat /etc/opendkim/*Table
echo -e "\e[32mto:\e[0m"
sed -i -- "s/{{DKIM_DOMAIN}}/${DKIM_DOMAIN}/g" /etc/opendkim/*Table
sed -i -- "s/{{DKIM_SELECTOR}}/${DKIM_SELECTOR}/g" /etc/opendkim/*Table
cat /etc/opendkim/*Table
echo

chown -R opendkim:opendkim /etc/opendkim
chmod -R 0700 /etc/opendkim/keys

# echo "Starting key generation for ${MYHOSTNAME}"
# opendkim-genkey -D /etc/dkimkeys -d ${MYHOSTNAME} -s 2025

# chown opendkim:opendkim /etc/dkimkeys/2025.private
# chmod 600 /etc/dkimkeys/2025.private

# exec opendkim -f