#!/bin/bash

#===================================================================================
#
# FILE: run.sh
#
# USAGE: run.sh operate_command
#
# DESCRIPTION: Provide init project's method.
#
# OPTIONS: see function ’usage’ below
# REQUIREMENTS: ---
# BUGS: ---
# NOTES: ---
# AUTHOR: Lambert Xiao, iamryanshaw24@gmail.com
# COMPANY: Augmentum, Shanghai
# VERSION: 0.1
# CREATED: 12.05.2002 - 12:36:50
# REVISION: 2017-12-01
#===================================================================================

buildBuilderImage() {
  echo -e "==========================================================\n"
  echo "Start to build the builer image..."

  cd ./builder
  docker build -t builder:v1 .

  echo "Build builderImage done."
  echo -e "\n=========================================================="
}

#=== FUNCTION ================================================================
# NAME: init
# DESCRIPTION: Stop all running containers, and restart the containers
# PARAMETER 0: ---
#===============================================================================
init() {
  stop
  echo -e "==========================================================\n"
  echo "Start to init the project..."

  docker-compose up -d

  echo "Init project done."
  echo "Visit http://lambert.com to view the index page."
  echo -e "\n=========================================================="
}

stop() {
  echo -e "==========================================================\n"
  echo "Stop the project..."

  docker-compose stop

  echo "Stop project done."
  echo -e "\n=========================================================="
}

frontendDev() {
  echo "Enter to vue dev mode, you can use npm commands."
  echo `pwd`
  docker run \
    -it \
    --rm \
    --name lambert-frontend-dev \
    -p 7002:7002 \
    -v `pwd`/frontend/:/app/frontend/ \
    -w /app/frontend \
    builder:v1 bash
}

reloadNginxConfig() {
  docker exec -i lambert-web service nginx reload
}

chownModuleDir() {
  moduleName=$1
  echo 'chown' $moduleName
  sudo chown -R `whoami`:`whoami` ./frontend/modules/$moduleName
}

generateModule() {
  moduleName=$1

  docker run \
    --rm \
    --name lambert-generate-template \
    -v `pwd`/frontend/modules:/app/frontend/modules \
    -v `pwd`/backend/modules:/app/backend/modules \
    -w /app/builder/ \
    builder:v1 bash -c "./generateTemplate.sh $moduleName"

  chownModuleDir $moduleName
  linkFrontendToBackend $moduleName
}

linkFrontendToBackend() {
  moduleName=$1
  sudo mkdir -p `pwd`/backend/modules/member/frontend/
  sudo ln -s `pwd`/frontend/modules/${moduleName}/h5 `pwd`/backend/modules/member/frontend/
  sudo ln -s `pwd`/frontend/modules/${moduleName}/pc `pwd`/backend/modules/member/frontend/
}

removeModule() {
  moduleName=$1

  sudo rm -rf frontend/modules/$moduleName
  sudo rm -rf backend/modules/$moduleName
}

printHelp() {
  operations="
    init
    builder_image
    stop
    frontend_dev
    reload_nginx_config
    generate_module
    chown_module_dir
    remove_module
    link_frontend_to_backend
  "
  echo -e "Could not find your operations, you can type ./build.sh with parameter:"

  for operation in $operations
  do
    echo '  - '$operation
  done
}

case $1 in
'init')
    init
    ;;
'builder_image')
    buildBuilderImage
    ;;
'stop')
    stop
    ;;
'frontend_dev')
    frontendDev
    ;;
'reload_nginx_config')
    reloadNginxConfig
    ;;
'generate_module')
    generateModule ${@:2}
    ;;
'chown_module_dir')
    chownModuleDir ${@:2}
    ;;
'remove_module')
    removeModule ${@:2}
    ;;
'link_frontend_to_backend')
    linkFrontendToBackend ${@:2}
    ;;
*)
    printHelp
    ;;
esac
