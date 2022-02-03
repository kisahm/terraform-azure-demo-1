.DEFAULT_GOAL := all

all: infra cluster kommander metallb kommander-creds install-license

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

install-license:
	./scripts/install_license.sh

prepare-truck-demo:
	./scripts/prepare_truck_demo.sh

restart-trucks:
	./scripts/restart_trucks.sh

cleanup-trucks:
	./scripts/cleanup_trucks.sh

watch-demo:
	./scripts/watch_namespace.sh truck-demo