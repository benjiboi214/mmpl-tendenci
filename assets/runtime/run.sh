#! /bin/bash

# Environment
PIP=$(which pip3)
PYTHON=$(which python3)


# Check directories and create them if necessary
function check_dirs()
{
    for dir in $TENDENCI_INSTALL_DIR\
        $TENDENCI_LOG_DIR;
do
    [ -d "$dir" ] || mkdir "$dir"
    chown "$TENDENCI_USER:" "$dir"
done
}

# Check user to run the application, create it if not done yet
function check_user()
{
    if ! grep -i "^$TENDENCI_USER" /etc/passwd; then
        useradd -b "$TENDENCI_HOME" -U "$TENDENCI_USER"
    fi
}

function create_cronjobs()
{

    echo "Creating cronjobs" && echo ""
    (crontab -l ; echo "30   2 * * * $PYTHON $TENDENCI_INSTALL_DIR/manage.py run_nightly_commands") | crontab -
    (crontab -l ; echo "30   2 * * * $PYTHON $TENDENCI_INSTALL_DIR/manage.py process_unindexed") | crontab -

}


function create_tendenci_project()
{
    # Creating tendenci project
    echo "Creating tendenci project" && echo ""
    cd "$TENDENCI_INSTALL_DIR"
    tendenci startproject "$APP_NAME" "$APP_NAME"
    cd "$APP_NAME"
    $PIP install  -r requirements/prod.txt --upgrade --no-cache-dir 

    #Install theme
    echo "Installing theme" && echo ""
    mkdir "$TENDENCI_PROJECT_ROOT"/themes/tendenci2020
    cd "$TENDENCI_INSTALL_DIR"
    PACKAGE_ORIGIN=$(pip3 show tendenci | grep Location:)
    THEME_ORIGIN=${PACKAGE_ORIGIN//"Location: "/}"/tendenci/themes/t7-tendenci2020"
    cd $THEME_ORIGIN
    cp -r ./* "$TENDENCI_PROJECT_ROOT"/themes/tendenci2020

    # Preparing directories
    echo "Preparing directories" && echo ""
    mkdir "$TENDENCI_PROJECT_ROOT"/static
    chown "$TENDENCI_USER:" /var/log/"$APP_NAME"/
    chmod -R -x+X,g+rw,o-rwx /var/log/"$APP_NAME"/
    chown -R "$TENDENCI_USER:" "$TENDENCI_HOME"
    chmod -R -x+X,g-w,o-rwx "$TENDENCI_PROJECT_ROOT"/
    chmod +x                "$TENDENCI_PROJECT_ROOT"/manage.py
    chmod -R ug-x+rwX,o-rwx "$TENDENCI_PROJECT_ROOT"/media/ 
    chmod -R ug-x+rwX,o-rwx "$TENDENCI_PROJECT_ROOT"/themes/ 
    chmod -R ug-x+rwX,o-rwx "$TENDENCI_PROJECT_ROOT"/whoosh_index/   
}


function create_superuser
{
    echo "Starting super user set-up" && echo ""
    
    cd "$TENDENCI_PROJECT_ROOT"
    echo "from django.contrib.auth import get_user_model; \
        User = get_user_model(); User.objects.create_superuser( \
        '${ADMIN_USER:-admin}', \
        '${ADMIN_MAIL:-admin@example.com}', \
        '${ADMIN_PASS:-password}')" \
        | "$PYTHON" manage.py shell
    
    echo "Finished super user set-up" && echo ""

}

function initial_setup
{

    cd "$TENDENCI_PROJECT_ROOT"
    
    "$PYTHON" manage.py initial_migrate 
    "$PYTHON" manage.py deploy
    "$PYTHON" manage.py load_tendenci_defaults
    "$PYTHON" manage.py update_dashboard_stats
    
    set_site_url

    create_superuser
    
    touch "$TENDENCI_PROJECT_ROOT/conf/first_run"
    echo  "Intital set up completed" && echo ""

}

function copy_config
{
  # Preparing directories
  echo "Copying config from image to volume" && echo ""
  cp -r "$APP_CONFIG_DIR"/* "$TENDENCI_PROJECT_ROOT"/conf
}

function run
{
    cd "$TENDENCI_PROJECT_ROOT" \
    && "$PYTHON" manage.py runserver 0.0.0.0:8000
}

set_site_url()
{
  # Set Site URL
  echo "Setting Site URL" && echo ""
  cd "$TENDENCI_PROJECT_ROOT"
  "$PYTHON" manage.py set_setting site global siteurl "https://tendenci.mmpl.test.jetselliot.com/" 	
}


if [ ! -f "$TENDENCI_PROJECT_ROOT/conf/first_run" ]; then
    check_user
    check_dirs
    create_tendenci_project
    copy_config
    create_cronjobs
    initial_setup
    run "$@"
fi

if [ -f "$TENDENCI_PROJECT_ROOT/conf/first_run" ]; then
    set_site_url
    run "$@"
fi
