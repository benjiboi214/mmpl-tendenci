#! /bin/bash 

# Environment
PIP=$(which pip3)

function install_tendenci()
{
    # Installing tendenci
    echo "Installing tendenci" && echo ""
    cd "$TENDENCI_INSTALL_DIR"
    $PIP install tendenci --no-cache-dir
}

function install_dependencies()
{
    # Installing Production Deps
    echo "Installing Production Deps" && echo ""
    $PIP install -r "$APP_CONFIG_DIR"/requirements/prod.txt --upgrade --no-cache-dir
}

install_tendenci
install_dependencies