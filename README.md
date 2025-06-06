# Khazadlab

## Introduction

Welcome to my homelab! Everything runs on **Kubernetes k3s**, with services managed by:
- **Traefik**  
- **Keycloak**  
- **Longhorn**  
- **Plex**  
- **Home Assistant**  
- and more.

### Architecture:
- The single master node is a **BMAX B3 Mini PC** (Ubuntu, Intel N5095, **8 GB** DDR4 RAM, 256 GB SSD, Intel UHD Graphics, 1000 Mbps Ethernet).
- The worker node is a **BMAX B4 Plus Mini PC** (Ubuntu, Intel N100, **16 GB** DDR4 RAM, 512 GB SSD, Intel UHD Graphics 750 MHz, 2×HDMI, 1×Type-C, supports 4K @ 60 Hz).

Also, I’ve configured my DIGI router accordingly and set up a DuckDNS DDNS to ensure consistent access.

Main url: *https://pod-test.khazadlab.duckdns.org/*
