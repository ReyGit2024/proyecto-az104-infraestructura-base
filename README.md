<<<<<<< HEAD

## Proyecto 1 — Infraestructura base (AZ-104)
Infraestructura desplegada en Microsoft Azure utilizando Terraform, diseñada para demostrar dominio de redes, subnets, NSG, máquinas virtuales, Azure Bastion y diagnósticos, siguiendo buenas prácticas del examen AZ‑104.

## Arquitectura
La infraestructura creada incluye:

🔹 Resource Group
rg-<workspace>-empresa  
Contenedor principal de todos los recursos.

🔹 Red Virtual (VNet)
vnet-empresa

Dirección: 10.0.0.0/16

🔹 Subnets
Web → snet-recursos-humanos (10.0.1.0/24)

App → snet-almacen (10.0.2.0/24)

DB → snet-produccion (10.0.3.0/24)

Azure Bastion → AzureBastionSubnet (10.0.10.0/27)

🔹 NSG por subnet
Cada subnet tiene su propio NSG con reglas personalizadas:

Web (RH)

Permite salida hacia App y DB

Permite salida a Internet

Deniega tráfico entrante desde App y DB

App (Almacén)

Permite salida hacia DB

Permite salida a Internet

Deniega salida hacia Web

Permite entrada desde Web

DB (Producción)

Permite salida hacia App

Permite salida a Internet

Deniega salida hacia Web

🔹 Máquinas Virtuales
VM Linux → vm-linux-prod (subnet DB)

VM Windows → vm-win-rh (subnet Web)

VM Windows → vm-win-almacen (subnet App)

🔹 Azure Bastion
bastion-empresa

IP pública: pip-bastion  
Permite acceso seguro a las VMs sin exponer IPs públicas.

🔹 Monitorización
Log Analytics Workspace: law-empresa

Diagnósticos habilitados en la VNet (AllMetrics)

## Decisiones de diseño
Separación por capas (web/app/db)  
Facilita aplicar reglas NSG específicas y aislar tráfico.

Azure Bastion  
Evita IPs públicas en las VMs y mejora la seguridad.

NSG por subnet  
Simplifica la gestión y mantiene un control claro del flujo de tráfico.

Log Analytics + diagnósticos  
Permite visualizar métricas y logs para troubleshooting y auditoría.

Uso de Terraform  
Infraestructura declarativa, reproducible y versionada.

## Comandos usados (Terraform)
bash
terraform init
terraform plan
terraform apply
terraform destroy
Si usas workspaces:

bash
terraform workspace new dev
terraform workspace select dev
terraform apply


## Cómo probar la infraestructura
1. Acceso a las VMs
En el portal de Azure, abre Azure Bastion.

Conéctate:

VM Linux → SSH

VMs Windows → RDP

2. Pruebas de conectividad entre subnets
Desde cada VM:

Web → App  
Debe permitir tráfico (según NSG).

Web → DB  
Permitido.

App → Web  
Debe estar denegado.

DB → Web  
Debe estar denegado.

App → DB  
Permitido.

3. Pruebas hacia Internet
Desde cualquier VM, prueba:

bash
curl https://www.microsoft.com
4. Logs y diagnósticos
En Log Analytics Workspace:

Ejecuta consultas KQL.

Verifica métricas de la VNet y actividad de las VMs.

## Diagrama conceptual (texto)
Código
Azure Subscription
└── Resource Group
    ├── VNet 10.0.0.0/16
    │   ├── Subnet Web (NSG Web)
    │   │   └── VM Windows RH
    │   ├── Subnet App (NSG App)
    │   │   └── VM Windows Almacén
    │   ├── Subnet DB (NSG DB)
    │   │   └── VM Linux Prod
    │   └── AzureBastionSubnet
    │       └── Azure Bastion + Public IP
    └── Log Analytics Workspace
=======
# proyecto-az104-infraestructura-base
Infraestructura base en Azure creada con Terraform. Incluye VNet, subnets, máquinas virtuales, NSG y Bastion. Proyecto orientado a demostrar habilidades en cloud, IaC y administración de recursos en Azure.
>>>>>>> 06aa124cb82cccb7e4e9388a2219104db30139a4
