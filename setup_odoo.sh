#!/bin/bash
LOG_FILE=./setup_odoo.log
exec > >(tee ${LOG_FILE}) 2>&1
PACKAGES="git python3-pip python3-venv build-essential wget python3-dev python3-venv libxslt-dev libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libjpeg-dev libpq-dev gcc g++ postgresql"
source ./.creds
source ./list_modules.txt
echo "Vérification des fichiers de configuration"
for req in .creds list_modules.txt; do
    if [ ! -f "$req" ]; then
        echo "Le fichier : $req est manquant"
        exit 1
    fi
done
: "${ADMIN_LOGIN?}" "${ADMIN_PASSWORD?}" "${DB_NAME?}" "${PASSWORD_ODOO?}" "${MODULES?}" "${MODULES_PATH}"
echo "Installation des dépendances"
locale-gen fr_FR fr_FR.UTF-8
apt-get update -qq
apt install -y --no-install-recommends $PACKAGES
systemctl enable --now postgresql
sudo -u postgres /bin/bash << EOF
createuser -s $ADMIN_LOGIN
psql -c "ALTER USER $ADMIN_LOGIN PASSWORD '$ADMIN_PASSWORD';"
EOF
WKHTML=$(dpkg -l | grep wkhtmltox)
if [[ -z "$WKHTML" ]]; then
    wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_amd64.deb
    dpkg -i wkhtmltox_0.12.6.1-3.jammy_amd64.deb
    apt-get install -f -y
    rm wkhtmltox_0.12.6.1-3.jammy_amd64.deb
fi
echo "Création de l'utilisateur odoo"
ODOO_EXIST=$(getent passwd | grep odoo)
if [[ -z "$ODOO_EXIST" ]]; then
    useradd --system -m odoo
else
    userdel -r odoo
    useradd --system -m odoo
fi
mkdir -p /opt/odoo/custom-addons
chown -R odoo:odoo /opt/odoo
echo "Création de la configuration d'odoo"
mkdir -p /var/log/odoo
chown odoo:odoo /var/log/odoo
mkdir -p /etc/odoo
cat > /etc/odoo/odoo.conf <<EOF
[options]
admin_passwd = $PASSWORD_ODOO
db_host = localhost
db_port = 5432
db_user = $ADMIN_LOGIN
db_password = $ADMIN_PASSWORD
addons_path = $MODULES_PATH
logfile = /var/log/odoo/odoo.log
EOF
chown odoo:odoo /etc/odoo/odoo.conf && chmod 640 /etc/odoo/odoo.conf
echo "Téléchargements"
sudo -u odoo /bin/bash << EOF
git clone https://github.com/odoo/odoo.git --branch 18.0 --depth=1 /opt/odoo/odoo-server
git clone https://github.com/OCA/l10n-france.git --branch 18.0 --depth=1 /opt/odoo/custom-addons/l10n-france
git clone https://github.com/OCA/account-analytic --branch 18.0 --depth=1 /opt/odoo/custom-addons/account-analytic
git clone https://github.com/OCA/account-financial-tools --branch 18.0 --depth=1 /opt/odoo/custom-addons/account-financial-tools
git clone https://github.com/OCA/account-payment --branch 18.0 --depth=1 /opt/odoo/custom-addons/account-payment
git clone https://github.com/OCA/server-tools --branch 18.0 --depth=1 /opt/odoo/custom-addons/server-tools
git clone https://github.com/OCA/community-data-files --branch 18.0 --depth=1 /opt/odoo/custom-addons/community-data-files
git clone https://github.com/OCA/server-ux --branch 18.0 --depth=1 /opt/odoo/custom-addons/server-ux
git clone https://github.com/OCA/edi --branch 18.0 --depth=1 /opt/odoo/custom-addons/edi
git clone https://github.com/OCA/account-invoicing.git --branch 18.0 --depth=1 /opt/odoo/custom-addons/account-invoicing
git clone https://github.com/OCA/sale-workflow.git --branch 18.0 --depth=1 /opt/odoo/custom-addons/sale-workflow
git clone https://github.com/OCA/reporting-engine.git --branch 18.0 --depth=1 /opt/odoo/custom-addons/reporting-engine
git clone https://github.com/OCA/bank-payment-alternative.git --branch 18.0 --depth=1 /opt/odoo/custom-addons/bank-payment-alternative
git clone https://github.com/OCA/server-env.git --branch 18.0 --depth=1 /opt/odoo/custom-addons/server-env
git clone https://github.com/OCA/queue.git --branch 18.0 --depth=1 /opt/odoo/custom-addons/queue
EOF
echo "Installation des requirements et des modules"
cp ./odoo.service /etc/systemd/system/
sudo -u odoo /bin/bash << EOF
cd /opt/odoo/
python3 -m venv /opt/odoo/odoo-venv
source /opt/odoo/odoo-venv/bin/activate
pip install --upgrade pip
pip install wheel
pip install requests
pip install -r /opt/odoo/odoo-server/requirements.txt
find /opt/odoo/custom-addons -name requirements.txt -exec cat {} \; | sort | uniq > /opt/odoo/odoo-server/requirements_modules.txt
pip install -r /opt/odoo/odoo-server/requirements_modules.txt
/opt/odoo/odoo-server/odoo-bin -c /etc/odoo/odoo.conf -d $DB_NAME -r $ADMIN_LOGIN -w $ADMIN_PASSWORD --update all -i $MODULES --load-language fr_FR --without-demo=all --logfile=/dev/stdout --stop-after-init 2>&1 | tee /var/log/odoo/odoo-modules.log
deactivate
EOF
echo "Démarrage et activation d'odoo"
systemctl daemon-reload && systemctl enable --now odoo
exit 0