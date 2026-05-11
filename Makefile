# Initial benign Makefile — what the repo has at HEAD before any PR.
# Mirrors the structure of minikube's e2e-windows-amd64.exe target.

.PHONY: e2e-windows-amd64.exe

e2e-windows-amd64.exe:
	@echo "BENIGN BUILD — would compile e2e-windows-amd64.exe in a real workflow"
	@touch e2e-windows-amd64.exe
