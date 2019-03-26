build:
	docker build --rm --force-rm -t confluent/gcloud-k8s-hard-way .

run:
	docker run -ti  confluent/gcloud-k8s-hard-way

stop-all:
	docker rm $(docker ps -a -q)