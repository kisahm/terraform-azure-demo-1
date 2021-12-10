.DEFAULT_GOAL := all

all:
	terraform apply -auto-approve
	./scripts/deploy_cluster.sh
	./scripts/deploy_kommander.sh
	./scripts/deploy_metallb.sh

kommander:
	./scripts/deploy_kommander.sh

metallb:
	./scripts/deploy_metallb.sh

cluster:
	./scripts/deploy_cluster.sh

teardown:
	terraform destroy