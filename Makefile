.PHONY: validate

validate:
	python3 -m json.tool training-content/catalog.json >/dev/null
	scripts/training-checksums.sh check
	helm lint charts/labs-portal
	helm lint charts/keycloak --set-string postgres.password=test --set-string admin.password=test --set-string users.admin.password=test --set-string users.devops.password=test --set-string users.kubernetes.password=test --set-string oidc.clientSecret=test
	docker build --platform linux/amd64 -t devops-atolyesi/labs-portal:validate -f portal/Dockerfile .
