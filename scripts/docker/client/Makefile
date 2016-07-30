

all: run

image:
	docker build -t fenyoa/vpnoverdns .

run:
	docker run -t -i fenyoa/vpnoverdns

debug:
	docker run -t -i --entrypoint "/bin/sh" fenyoa/vpnoverdns

clean:
	docker ps -a | sed 's/.* //' | sed 1d | xargs docker rm
	docker images -a | awk '{ print $3; }' | xargs docker rmi
