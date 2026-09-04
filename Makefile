.PHONY: validate validate-content

validate-content:
	python3 -m json.tool training-content/catalog.json >/dev/null
	scripts/training-checksums.sh check
	PYTHONDONTWRITEBYTECODE=1 python3 -m unittest portal/scripts/test_stage_content.py
	bash -n training-content/lab-assets/LAB-K8S-08/scripts/*.sh training-content/lab-assets/LAB-K8S-13/scripts/*.sh training-content/lab-assets/LAB-K8S-14/scripts/*.sh training-content/lab-assets/LAB-K8S-15/scripts/*.sh
	helm lint charts/labs-portal
	helm lint charts/keycloak --set-string postgres.password=test --set-string admin.password=test --set-string users.admin.password=test --set-string users.devops.password=test --set-string users.kubernetes.password=test --set-string oidc.clientSecret=test

validate: validate-content
	docker build --platform linux/amd64 -t devops-atolyesi/labs-portal:validate -f portal/Dockerfile .
