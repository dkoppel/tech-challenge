#!/bin/bash
dnf install -Y httpd
systemctl enable --now httpd