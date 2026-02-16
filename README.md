# 802.1x EAP-TLS x509 certificates

## 🔎 Overview

x509 certificate creation for EAP-TLS using openssl cnf files plus usage info
> Also see [freeradius configuration example](https://github.com/efa2d19/8021x-eap-tls-freeradius)

## 💡 Usage options

- `make`/`make all`
  > Create all key pairs and certificates\
  > Invokes init, ca, server, and client (with default params, see `make client` section)\
  > Use created ca-crl.crt as ca_file in eap configuration, enable check_crl, and set certificate/private_key files to server ones

- `make ca`
  > Create server ca certificate as an intermediate from existing root certificate\
  > Default keypair will be created as EC prime256v1, to change the curve specify desired one in `CURVE` env\
  > To create server ca as a root one instead of intermediate with using existing root ca use `make ca-root`\

- `make ca-root`
  > Same as one above but create server ca certificate as a root ca

- `make server`
  > Create server leaf certificate\
  > Default ttl is 700 for newer systems to accept it

- `make client`
  > Create client leaf certificate\
  > Use `NAME` env to specify CN (default: personal)\
  > Use `DAYS` env to specify ttl in days (default: 365)

- `make revoke`
  > Revoke certificate updates crl file as well as ca-crl.crt\
  > Use `NAME` env to specify certificate name to be revoked (default: personal)\
  > Certificate with specified name must exist in certs dirictory

- `make cleanup`
  > Delete all generated files and certificates as well as the dir structure

- `make init`
  > Creates miscellaneous files: dir structure for cnf, empty index, crlnumber, and serial

## 🔗 How to connect

###  MacOS/iOS/WatchOS/iPadOS
- install Apple Configurator
- open a new file
- fill desired info in "General" tab (at least a name)
- add root ca and server ca in "Certificates" tab
    - if unable to specify desired certificates make sure they are in pem format and with .crt extension
- add client certificate and key as p12 or pfx file
    - pem keypair can be converted to p12 like this
    ```bash
    openssl pkcs12 -export -in client.crt -inkey client.key -out client.pfx -legacy -passout 'pass:<password>'
    ```
    - specified password must be entered in a passowrd input field in imported certificate
- save and install on all desired devices
    - Profiles on WatchOS installed via companion app on connected device\
    (you will be prompted to choose a destination while intalling profile)
- on connection
    - specify EAP-TLS as eap method
    - select client certificate as "Identity"

#### 🛜 Wi-Fi section in Apple Configurator
You can specify SSID, security type, identity, and trusted certificates there \
but all my attempts resulted it radius sending auth chalange and device completely ghosting the server

If you have any clue how to fix that issue with details will be appreciated

### 📱 Android
- install root ca and server ca as wifi certificate
- install client certificate and key in p12 file as wifi certificate
    - pem keypair can be converted to p12 like this
    ```bash
    openssl pkcs12 -export -in client.crt -inkey client.key -out client.p12 -legacy -passout 'pass:<password>'
    ```
    - on installation specified password will be prompted
- on connection
    - specify EAP-TLS as eap method
    - specify min TLS version according to radius server rules (if there is options to do so)
    - select client certificate as "User Certificate"
    - select root ca certificate in "CA Certificate"
    - specify CN from client cert as "Identity"
    - specify SAN or CN from server cert as "Domain" (if there is options to do so)\
    (if there is SAN use it otherwise use CN, default one is radius.8021x.lan) 

### 🐧 Linux
Should be similar to Android but using wpa_suplicant
Here is an example (not tested this one)
```
network={
ssid="SSID"
scan_ssid=1
key_mgmt=WPA-EAP
pairwise=CCMP TKIP
group=CCMP TKIP
eap=TLS
identity="CN"
ca_cert="/system/etc/wifi/ca-crl.pem"
client_cert="/system/etc/wifi/server.crt"
private_key="/system/etc/wifi/server.key"
private_key_passwd=
priority=20
}
```

## 📝 License

All set to go under the [Apache-2.0 License](/LICENSE). Use it, modify it, share it.
