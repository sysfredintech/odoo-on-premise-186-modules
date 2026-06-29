# Installation d'un service Odoo on-premise automatisée sur un serveur Ubuntu 24.04

**Ce [script Bash](/setup_odoo.sh) installe Odoo 18 depuis les sources GitHub, configure PostgreSQL, un environnement virtuel Python, installe 186 modules et met en place un service systemd.**

## Prérequis

- Ubuntu 24.04

- Accès root ou sudo

- Aucune installation Odoo préexistante

## Modules installés par défaut

Les 187 modules pré-installés et activés couvrent un large éventail de cas d’utilisation d'Odoo pour les professionnels en France, y compris avec la factur-X. Sont inclus différents modules développés par OCA. À adapter comme décrit ci-dessous.
Il est possible d'activer des modules supplémentaires via la webui après l'installation de façon classique.

## Personnalisation

- Éditer le fichier [.creds](/.creds) pour y définir les identifiants (fichier à supprimer ou protéger après installation)
- Éditer le fichier [list_modules.txt](/list_modules.txt) si besoin de supprimer ou ajouter des modules

## Utilisation

Cloner le dépôt
```bash
git clone https://github.com/sysfredintech/odoo-script.git
```
Se rendre dans le dossier odoo-script
```bash
cd odoo-script
```
Rendre le script exécutable
```bash
chmod +x setup_odoo.sh
```
Lancer le script avec les droits root
```bash
sudo ./setup_odoo.sh
```
Les sources seront téléchargées dans /opt/odoo/odoo-server

## Après installation

- Accès web : http://localhost:8069 ou http://ip_du_serveur:8069
- Identifiants par défaut : admin / admin

## Notes

L'installation du module `hr` génère trois warnings et une erreur pendant le processus d'installation des modules, aucune incidence sur le fonctionnement du service et des modules.

## Logs

- Script: ./setup_odoo.log
- Odoo server: /var/log/odoo/odoo.log
- Installation des modules: /var/log/odoo/odoo-modules.log
- Service systemd: journalctl -u odoo -f

## Désinstallation

Stopper le service
```bash
sudo systemctl stop odoo
```
Supprimer l'utilisateur
```bash
sudo userdel -r odoo
```
Supprimer la base de donnée
```bash
sudo -u postgres dropdb <nom_de_la_base>
```
Supprimer les dossiers
```bash
sudo rm -rf /opt/odoo /etc/odoo /var/log/odoo
```