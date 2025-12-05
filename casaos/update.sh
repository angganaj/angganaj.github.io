#!/usr/bin/env bash
sudo apt update && sudo apt full-upgrade -y && bash -c "$(wget -qLO - https://raw.githubusercontent.com/bigbeartechworld/big-bear-scripts/master/casaos-fix-docker-api-version/run.sh)" && curl -fsSL https://get.casaos.io | sudo bash
