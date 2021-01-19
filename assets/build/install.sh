#! /bin/bash 

# Environment
PIP=$(which pip3)

function install_tendenci()
{
    # Installing tendenci
    echo "Installing tendenci" && echo ""
    cd "$TENDENCI_INSTALL_DIR"
    $PIP install tendenci
}

install_tendenci