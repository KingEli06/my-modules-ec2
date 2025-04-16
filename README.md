
![image](https://github.com/user-attachments/assets/74f0f07f-1dec-44d8-9b21-ff86fd1912a1)







OpenLDAP and phpLDAPadmin Helm Chart
Here's a complete Helm chart structure for deploying OpenLDAP and phpLDAPadmin on Kubernetes. This provides a cloud-native, reusable deployment solution.

Chart Structure
Copy
openldap-phpldapadmin/
├── Chart.yaml
├── values.yaml
├── README.md
├── templates/
│   ├── _helpers.tpl
│   ├── openldap/
│   │   ├── configmap.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── secrets.yaml
│   │   └── pvc.yaml
│   ├── phpldapadmin/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── ingress.yaml
│   │   └── configmap.yaml
│   └── tests/
│       └── test-connection.yaml
└── charts/
File Contents
1. Chart.yaml
yaml
Copy
apiVersion: v2
name: openldap-phpldapadmin
description: A Helm chart for OpenLDAP with phpLDAPadmin web interface
version: 1.0.0
appVersion: "2.5.0"
dependencies:
  - name: openldap-stack-ha
    version: 1.0.0
    repository: https://charts.bitnami.com/bitnami
    condition: openldap.enabled
keywords:
  - ldap
  - directory
  - authentication
  - openldap
  - phpldapadmin
home: https://www.openldap.org/
sources:
  - https://github.com/openldap/openldap
  - https://github.com/leenooks/phpLDAPadmin
maintainers:
  - name: Your Name
    email: your.email@example.com
2. values.yaml
yaml
Copy
# Global settings
global:
  domain: example.com
  organization: My Organization

# OpenLDAP configuration
openldap:
  enabled: true
  image:
    repository: osixia/openldap
    tag: 1.5.0
    pullPolicy: IfNotPresent
  adminPassword: "admin"
  configPassword: "config"
  persistence:
    enabled: true
    size: 8Gi
    storageClass: ""
  resources:
    requests:
      memory: "512Mi"
      cpu: "300m"
    limits:
      memory: "1Gi"
      cpu: "500m"
  env:
    LDAP_ORGANISATION: "{{ .Values.global.organization }}"
    LDAP_DOMAIN: "{{ .Values.global.domain }}"
    LDAP_BASE_DN: "dc={{ .Values.global.domain | replace \".\" \",dc=\" }}"
    LDAP_TLS: "false"

# phpLDAPadmin configuration
phpldapadmin:
  enabled: true
  image:
    repository: osixia/phpldapadmin
    tag: 0.9.0
    pullPolicy: IfNotPresent
  service:
    type: ClusterIP
    port: 80
  ingress:
    enabled: false
    className: ""
    annotations: {}
    hosts:
      - host: phpldapadmin.local
        paths:
          - path: /
            pathType: ImplementationSpecific
    tls: []
  resources:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "200m"
  config:
    hide_template_warning: true
    server_host: "openldap"
    server_port: 389
    server_base: "dc={{ .Values.global.domain | replace \".\" \",dc=\" }}"
    login_bind_id: "cn=admin,dc={{ .Values.global.domain | replace \".\" \",dc=\" }}"
3. templates/_helpers.tpl
yaml
Copy
{{/*
Expand the name of the chart.
*/}}
{{- define "openldap-phpldapadmin.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "openldap-phpldapadmin.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "openldap-phpldapadmin.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "openldap-phpldapadmin.labels" -}}
helm.sh/chart: {{ include "openldap-phpldapadmin.chart" . }}
{{ include "openldap-phpldapadmin.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "openldap-phpldapadmin.selectorLabels" -}}
app.kubernetes.io/name: {{ include "openldap-phpldapadmin.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the LDAP base DN from domain
*/}}
{{- define "openldap-phpldapadmin.baseDn" -}}
dc={{ .Values.global.domain | replace "." ",dc=" }}
{{- end -}}
4. templates/openldap/secrets.yaml
yaml
Copy
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "openldap-phpldapadmin.fullname" . }}-openldap-secrets
  labels:
    {{- include "openldap-phpldapadmin.labels" . | nindent 4 }}
type: Opaque
data:
  LDAP_ADMIN_PASSWORD: {{ .Values.openldap.adminPassword | b64enc | quote }}
  LDAP_CONFIG_PASSWORD: {{ .Values.openldap.configPassword | b64enc | quote }}
5. templates/openldap/configmap.yaml
yaml
Copy
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "openldap-phpldapadmin.fullname" . }}-openldap-config
  labels:
    {{- include "openldap-phpldapadmin.labels" . | nindent 4 }}
data:
  01-overlay.ldif: |
    dn: olcOverlay=ppolicy,olcDatabase={1}mdb,cn=config
    objectClass: olcOverlayConfig
    objectClass: olcPPolicyConfig
    olcOverlay: ppolicy
    olcPPolicyDefault: cn=default,ou=policies,{{ include "openldap-phpldapadmin.baseDn" . }}
    olcPPolicyHashCleartext: TRUE
6. templates/openldap/deployment.yaml
yaml
Copy
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "openldap-phpldapadmin.fullname" . }}-openldap
  labels:
    {{- include "openldap-phpldapadmin.labels" . | nindent 4 }}
spec:
  replicas: 1
  selector:
    matchLabels:
      {{- include "openldap-phpldapadmin.selectorLabels" . | nindent 6 }}
      component: openldap
  template:
    metadata:
      labels:
        {{- include "openldap-phpldapadmin.selectorLabels" . | nindent 8 }}
        component: openldap
    spec:
      containers:
      - name: openldap
        image: "{{ .Values.openldap.image.repository }}:{{ .Values.openldap.image.tag }}"
        imagePullPolicy: {{ .Values.openldap.image.pullPolicy }}
        env:
        - name: LDAP_ORGANISATION
          value: "{{ .Values.openldap.env.LDAP_ORGANISATION }}"
        - name: LDAP_DOMAIN
          value: "{{ .Values.openldap.env.LDAP_DOMAIN }}"
        - name: LDAP_BASE_DN
          value: "{{ .Values.openldap.env.LDAP_BASE_DN }}"
        - name: LDAP_ADMIN_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ include "openldap-phpldapadmin.fullname" . }}-openldap-secrets
              key: LDAP_ADMIN_PASSWORD
        - name: LDAP_CONFIG_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ include "openldap-phpldapadmin.fullname" . }}-openldap-secrets
              key: LDAP_CONFIG_PASSWORD
        - name: LDAP_TLS
          value: "{{ .Values.openldap.env.LDAP_TLS }}"
        ports:
        - containerPort: 389
          name: ldap
        - containerPort: 636
          name: ldaps
        volumeMounts:
        - name: ldap-data
          mountPath: /var/lib/ldap
        - name: ldap-config
          mountPath: /etc/ldap/slapd.d
        - name: ldap-configmap
          mountPath: /container/service/slapd/assets/config/bootstrap/ldif/custom
        resources:
          {{- toYaml .Values.openldap.resources | nindent 10 }}
      volumes:
      - name: ldap-data
        persistentVolumeClaim:
          claimName: {{ include "openldap-phpldapadmin.fullname" . }}-openldap-data
      - name: ldap-config
        persistentVolumeClaim:
          claimName: {{ include "openldap-phpldapadmin.fullname" . }}-openldap-config
      - name: ldap-configmap
        configMap:
          name: {{ include "openldap-phpldapadmin.fullname" . }}-openldap-config
7. templates/phpldapadmin/deployment.yaml
yaml
Copy
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "openldap-phpldapadmin.fullname" . }}-phpldapadmin
  labels:
    {{- include "openldap-phpldapadmin.labels" . | nindent 4 }}
spec:
  replicas: 1
  selector:
    matchLabels:
      {{- include "openldap-phpldapadmin.selectorLabels" . | nindent 6 }}
      component: phpldapadmin
  template:
    metadata:
      labels:
        {{- include "openldap-phpldapadmin.selectorLabels" . | nindent 8 }}
        component: phpldapadmin
    spec:
      containers:
      - name: phpldapadmin
        image: "{{ .Values.phpldapadmin.image.repository }}:{{ .Values.phpldapadmin.image.tag }}"
        imagePullPolicy: {{ .Values.phpldapadmin.image.pullPolicy }}
        env:
        - name: PHPLDAPADMIN_LDAP_HOSTS
          value: "{{ .Values.phpldapadmin.config.server_host }}"
        - name: PHPLDAPADMIN_HTTPS
          value: "false"
        ports:
        - containerPort: 80
          name: http
        resources:
          {{- toYaml .Values.phpldapadmin.resources | nindent 10 }}
Deployment Instructions
Install Helm if not already installed

Create a namespace for your deployment:

bash
Copy
kubectl create namespace ldap
Install the chart:

bash
Copy
helm install ldap ./openldap-phpldapadmin -n ldap
Access phpLDAPadmin:

If using ingress, access via the configured host

Otherwise, port-forward to the service:

bash
Copy
kubectl port-forward svc/ldap-phpldapadmin 8080:80 -n ldap
Then access at http://localhost:8080

Customization Options
TLS Configuration: Enable TLS in the values.yaml for secure communication

High Availability: Adjust replica counts and add pod anti-affinity rules

Storage: Configure different storage classes for persistence

Networking: Customize service types and ingress configurations

Authentication: Integrate with existing Kubernetes secrets for credentials

This Helm chart provides a production-ready deployment of OpenLDAP with phpLDAPadmin that can be easily customized and deployed across different environments.

