#!/bin/bash
dnf update -y
dnf install -y httpd
systemctl enable --now httpd