#!/bin/bash
dnf install -y httpd
systemctl enable --now httpd