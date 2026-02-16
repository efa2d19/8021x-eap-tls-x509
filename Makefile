SHELL := /usr/bin/env zsh

CLIENT_NAME = $(or $(name), $(NAME), personal)
CLIENT_DAYS = $(or $(days), $(DAYS), 365)
EC_CURVE = $(or $(curve), $(CURVE), prime256v1)

.PHONY: all

all: init ca server client

init:
	@touch index.txt
	@[[ -f crlnumber ]] || { echo 1001 > crlnumber }
	@[[ -f serial ]] || { echo 1001 > serial }
	@mkdir -p certs crl csr private newcerts

ca-root:
	openssl ecparam -name $(EC_CURVE) -genkey -noout -out private/ca.key
	openssl req -x509 -days 3650 -key private/ca.key -extensions v3_ca -out certs/ca.crt -config ca.cnf
	cp certs/ca.crt certs/ca-chain.pem
	openssl ca -config ca.cnf -gencrl -out crl/ca.pem
	cat certs/ca-chain.pem crl/ca.pem > certs/ca-crl.pem

verify-root:
	@[[ -e ./root/root.crt && -e ./root/root.key ]] || { echo '[!] No root found' && exit 1 }

ca: verify-root
	openssl ecparam -name $(EC_CURVE) -out ca.param
	openssl req -nodes -newkey ec:ca.param -sha256 -keyout private/ca.key -out csr/ca.csr -config ca.cnf
	openssl ca -startdate "$$(openssl x509 -in root/root.crt -noout -dates | grep -i before | awk -F= '{ print $$2 }' | xargs -I {} date -d '{}' -u '+%Y%m%d%H%M%SZ')" -enddate "$$(openssl x509 -in root/root.crt -noout -dates | grep -i after | awk -F= '{ print $$2 }' | xargs -I {} date -d '{}' -u '+%Y%m%d%H%M%SZ')" -notext -md sha256 -in csr/ca.csr -out certs/ca.crt -cert root/root.crt -keyfile root/root.key -config ca.cnf
	cat root/root.crt certs/ca.crt > certs/ca-chain.pem
	openssl ca -config ca.cnf -gencrl -out crl/ca.pem
	cat certs/ca-chain.pem crl/ca.pem > certs/ca-crl.pem

verify-ca:
	@[[ -e ./certs/ca.crt && -e ./private/ca.key ]] || { echo '[!] No CA found' && exit 1 }

revoke: verify-ca
	@[[ -e certs/$(CLIENT_NAME).crt ]] || { echo '[!] No certificate found - certs/$(CLIENT_NAME).crt' && exit 1 }
	@[[ -e certs/ca-chain.pem ]] || { echo '[!] No ca chain found' && exit 1 }
	openssl ca -revoke certs/$(CLIENT_NAME).crt -keyfile private/ca.key -cert certs/ca.crt -config ca.cnf
	openssl ca -config ca.cnf -gencrl -out crl/ca.pem
	cat certs/ca-chain.pem crl/ca.pem > certs/ca-crl.pem

server: verify-ca
	openssl req -nodes -newkey ec:certs/ca.crt -sha256 -keyout private/server.key -out csr/server.csr -config server.cnf
	openssl ca -days 730 -notext -md sha256 -in csr/server.csr -out certs/server.crt -cert certs/ca.crt -keyfile private/ca.key -config server.cnf

client: verify-ca
	openssl req -nodes -newkey ec:certs/ca.crt -sha256 -keyout private/$(CLIENT_NAME).key -out csr/$(CLIENT_NAME).csr -config client.cnf
	openssl ca -days $(CLIENT_DAYS) -notext -md sha256 -in csr/$(CLIENT_NAME).csr -out certs/$(CLIENT_NAME).crt -cert certs/ca.crt -keyfile private/ca.key -config client.cnf

cleanup:
	@setopt null_glob; rm ca.param index.txt* serial* crlnumber* &>/dev/null || true
	@rm -r certs crl csr private newcerts &>/dev/null || true

