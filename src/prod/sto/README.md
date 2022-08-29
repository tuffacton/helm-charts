# sto

![Version: 0.1.3](https://img.shields.io/badge/Version-0.1.3-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

A Helm chart for Kubernetes

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | postgresql | 11.6.16 |
| https://harness.github.io/helm-sto-core | sto-core | 0.2.x |
| https://harness.github.io/helm-sto-manager | sto-manager | 0.2.x |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| postgresql.commonLabels.app | string | `"postgres"` |  |
| postgresql.fullnameOverride | string | `"postgres"` |  |
| sto-core.autoscaling.enabled | bool | `false` |  |
| sto-manager.autoscaling.enabled | bool | `false` |  |
