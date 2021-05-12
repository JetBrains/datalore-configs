#!/bin/bash

init_hub() {
  /run.sh configure \
    --base-url="${HUB_BASE_URL}" \
    --disable.configurationWizard=true \
    -J-Djetbrains.hub.installation.type=DOCKER \
    -J-Ddisable.configuration.wizard.on.clean.install=true \
    -J-Djetbrains.jetpass.admin.login=${HUB_ADMIN_LOGIN} \
    -J-Djetbrains.jetpass.admin.name=${HUB_ADMIN_LOGIN} \
    -J-Djetbrains.jetpass.admin.password=${HUB_ADMIN_PASSWORD} \
    -J-Djetbrains.hub.block-not-verified-accounts.disabled=false \
    -J-Djetbrains.hub.jabber.settings.hide=true \
    -J-Djetbrains.hub.user.vcsusernames.hide=true \
    -J-Djetbrains.hub.user.sshpublickeys.hide=true
}

[ -f /opt/hub/conf/hub/service-config.properties ] || init_hub

/run.sh

