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

function setup_keys()
{
    echo "Creating secret keys"  && echo ""

    SECRET_KEY=${SECRET_KEY:-$(mcookie)}
    SITE_SETTINGS_KEY=${SITE_SETTINGS_KEY:-$(mcookie)}
    sed -i "s/^SECRET_KEY.*/SECRET_KEY='$SECRET_KEY'/" \
       "$TENDENCI_PROJECT_ROOT/conf/settings.py"
    echo "SECRET_KEY: $SECRET_KEY" && echo ""
    sed -i "s/^SITE_SETTINGS_KEY.*/SITE_SETTINGS_KEY='$SITE_SETTINGS_KEY'/" \
        "$TENDENCI_PROJECT_ROOT/conf/settings.py"
    echo "SITE_SETTINGS_KEY: $SITE_SETTINGS_KEY" && echo ""
}

function create_settings
{
    echo "Creating settings"  && echo ""

     sed -i "s/^#DATABASES\['default'\]\['NAME'\].*/DATABASES\['default'\]\['NAME'\] = '${DB_NAME:-tendenci}'/" \
        "$TENDENCI_PROJECT_ROOT/conf/settings.py"

     sed -i "s/^#DATABASES\['default'\]\['HOST'\].*/DATABASES\['default'\]\['HOST'\] = '${DB_HOST:-localhost}'/" \
        "$TENDENCI_PROJECT_ROOT/conf/settings.py"

     sed -i "s/^#DATABASES\['default'\]\['USER'\].*/DATABASES\['default'\]\['USER'\] = '${DB_USER:-tendenci}'/" \
        "$TENDENCI_PROJECT_ROOT/conf/settings.py"

     sed -i "s/^#DATABASES\['default'\]\['PASSWORD'\].*/DATABASES\['default'\]\['PASSWORD'\] = '${DB_PASS:-password}'/" \
        "$TENDENCI_PROJECT_ROOT/conf/settings.py"

     sed -i "s/^#DATABASES\['default'\]\['PORT'\].*/DATABASES\['default'\]\['PORT'\] = '${DB_PORT:-5432}'/" \
        "$TENDENCI_PROJECT_ROOT/conf/settings.py"

     sed -i "s/TIME_ZONE.*/TIME_ZONE='${TIME_ZONE:-GMT+0}'/" \
        "$TENDENCI_PROJECT_ROOT/conf/settings.py"

     sed -i "s/ALLOWED_HOSTS =.*/ALLOWED_HOSTS = \[${ALLOWED_HOSTS:-'\*'}\]/" \
        "$TENDENCI_PROJECT_ROOT/conf/settings.py"

    echo "Finished creating settings" && echo ""
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
    "$PYTHON" manage.py set_setting site global siteurl "$SITE_URL" 	

    create_superuser
    
    touch "$TENDENCI_PROJECT_ROOT/conf/first_run"
    echo  "Intital set up completed" && echo ""

}

function run
{
    cd "$TENDENCI_PROJECT_ROOT" \
    && "$PYTHON" manage.py runserver 0.0.0.0:8000
}


if [ ! -f "$TENDENCI_PROJECT_ROOT/conf/first_run" ]; then
    check_user
    check_dirs
    create_tendenci_project
    create_cronjobs
    setup_keys
    create_settings
    initial_setup
    run "$@"
fi

if [ -f "$TENDENCI_PROJECT_ROOT/conf/first_run" ]; then
    run "$@"
fi
