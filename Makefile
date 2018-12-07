SHELL := /bin/bash
#
# ROOTPASSWORD ?= $(shell bash -c 'read -s -p "Mysql Root Password: " pwd; echo $$pwd')
# ZIXUSERPASSWORD ?= $(shell bash -c 'read -s -p "Mysql Zix User Password: " pwd; echo $$pwd')
 # --build-arg root_password=$(ROOTPASSWORD) --build-arg zix_user_password=$(ZIXUSERPASSWORD)

docker-build:
	docker build -t vendor-usage-db-image .
	docker run -d --interactive --tty -p 3306:3306/tcp -p 33060:33060/tcp --name=vendor-usage-db-container vendor-usage-db-image

docker-stop:
	docker container stop vendor-usage-db-container

docker-start:
	docker container start vendor-usage-db-container

docker-clean-container:docker-stop
	docker rm vendor-usage-db-container
docker-clean-all: docker-clean-container
	docker rmi vendor-usage-db-image
