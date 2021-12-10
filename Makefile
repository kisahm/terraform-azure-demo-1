.DEFAULT_GOAL := all

all:
	terraform validate
	terraform apply -auto-approve
	./scripts/deploy_cluster.sh
	./scripts/deploy_kommander.sh
	./scripts/deploy_metallb.sh
	./scripts/get_kommander_credentials.sh

kommander:
	./scripts/deploy_kommander.sh

kommander-creds:
	./scripts/get_kommander_credentials.sh

metallb:
	./scripts/deploy_metallb.sh

cluster:
	./scripts/deploy_cluster.sh

teardown:
	terraform destroy