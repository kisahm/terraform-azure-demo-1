.DEFAULT_GOAL := all

all: infra cluster kommander metallb kommander-creds

kommander:
	./scripts/deploy_kommander.sh

kommander-creds:
	./scripts/get_kommander_credentials.sh

metallb:
	./scripts/deploy_metallb.sh

cluster:
	./scripts/deploy_cluster.sh
	./scripts/make_selfmanaged.sh

infra:
	terraform validate
	terraform apply -auto-approve

teardown:
	dkp delete bootstrap
	terraform destroy