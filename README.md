# Konvert

How to run the app.

~ node server.js

Konvert is running on localhost:3000




Based on Terraform file this is the System Digram Comes out of it:

                     ┌───────────────────────────┐
                     │         End Users          │
                     └──────────────┬────────────┘
                                    │
                           Internet │
                                    ▼
                     ┌───────────────────────────┐
                     │   AWS Route 53 (DNS)       │
                     └──────────────┬────────────┘
                                    │
                                    ▼
                     ┌───────────────────────────┐
                     │  AWS WAF (Web Firewall)    │
                     └──────────────┬────────────┘
                                    │
                                    ▼
                     ┌───────────────────────────┐
                     │ Application Load Balancer  │
                     │        (Public)            │
                     └──────────────┬────────────┘
                                    │
                           HTTP/HTTPS│
                                    ▼
                     ┌───────────────────────────┐
                     │   EC2 Application Tier     │
                     │      (Public Subnets)      │
                     └──────────────┬────────────┘
                                    │
                           MySQL 3306│
                                    ▼
                     ┌───────────────────────────┐
                     │     RDS MySQL Database     │
                     │     (Private Subnets)      │
                     └──────────────┬────────────┘
                                    │
                           Replication│
                                    ▼
                     ┌───────────────────────────┐
                     │   RDS Read Replica         │
                     │   (Private Subnets)        │
                     └───────────────────────────┘

