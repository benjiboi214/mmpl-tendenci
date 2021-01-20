#! /bin/bash

# Environment
PIP=$(which pip3)
PYTHON=$(which python3)

copy_config()
{
  # Preparing directories
  echo "Copying config from image to volume" && echo ""
  cp -r "$APP_CONFIG_DIR"/* "$TENDENCI_PROJECT_ROOT"/conf
}

check_directory_permissions()
{
  # Preparing directories
  echo "Preparing directories" && echo ""
  chown "$TENDENCI_USER" /var/log/"$APP_NAME"/
  chmod -R -x+X,g+rw,o-rwx /var/log/"$APP_NAME"/
  chown -R "$TENDENCI_USER" "$TENDENCI_HOME"
  chmod -R -x+X,g-w,o-rwx "$TENDENCI_PROJECT_ROOT"/
  chmod +x                "$TENDENCI_PROJECT_ROOT"/manage.py
  chmod -R ug-x+rwX,o-rwx "$TENDENCI_PROJECT_ROOT"/media/ 
  chmod -R ug-x+rwX,o-rwx "$TENDENCI_PROJECT_ROOT"/themes/ 
  chmod -R ug-x+rwX,o-rwx "$TENDENCI_PROJECT_ROOT"/whoosh_index/   
}

copy_config
check_directory_permissions
