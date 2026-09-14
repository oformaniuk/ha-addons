#!/bin/bash

# begin hass addon persistent data block
# Home Assistant add-ons persist /data automatically.
# The "map": ["addon_config:rw"] in config.json provides host access at /addon_configs/<slug>/
# We keep ioBroker data under /data (which is accessible on host via the addon_config map).
echo "Configuring persistent ioBroker data dir"

PERSIST_BASE="/data"
PERSIST_IOB="${PERSIST_BASE}/iobroker"

# NOTE: The upstream base image may mount /opt/iobroker as a volume/mountpoint.
# In that case it cannot be moved/removed/replaced with a symlink.
# We therefore run ioBroker directly from /data (HA persistent storage)
# and only use /opt/iobroker as a seed source on first run.
IMAGE_IOB="/opt/iobroker"
IOB_DIR="${PERSIST_IOB}"
IOB_JSON="${IOB_DIR}/iobroker-data/iobroker.json"

mkdir -p "${IOB_DIR}"

# Seed persistent storage on first run (or if iobroker executable is missing)
if [ ! -f "${IOB_DIR}/iobroker" ] && [ -d "${IMAGE_IOB}" ]; then
  echo "ioBroker not found in ${IOB_DIR}, seeding from ${IMAGE_IOB}"
  # Clear any partial/corrupted data first
  rm -rf "${IOB_DIR:?}"/*
  cp -a "${IMAGE_IOB}/." "${IOB_DIR}/"
  touch "${IOB_DIR}/.ha_addon_seeded"
fi

# Set ownership if Supervisor provided UID/GID
if [ -n "${SETUID:-}" ] && [ -n "${SETGID:-}" ]; then
  chown -R "${SETUID}:${SETGID}" "${IOB_DIR}" || true
fi

# Ensure backups directory exists inside ioBroker data dir
mkdir -p "${IOB_DIR}/backups"

# end hass addon persistent data block

# Setting healthcheck status to "starting"
echo "starting" > /opt/scripts/.docker_config/.healthcheck

# Reading ENV
adminport=$IOB_ADMINPORT
avahi=$AVAHI
multihost=$IOB_MULTIHOST
objectsdbhost=$IOB_OBJECTSDB_HOST
objectsdbport=$IOB_OBJECTSDB_PORT
objectsdbtype=$IOB_OBJECTSDB_TYPE
packages=$PACKAGES
setgid=$SETGID
setuid=$SETUID
statesdbhost=$IOB_STATESDB_HOST
statesdbport=$IOB_STATESDB_PORT
statesdbtype=$IOB_STATESDB_TYPE
usbdevices=$USBDEVICES
zwave=$ZWAVE

# Getting date and time for logging
dati=`date '+%Y-%m-%d %H:%M:%S'`

# Logging header
echo ' '
echo "$(printf -- '-%.0s' {1..60})"
echo -n "$(printf -- '-%.0s' {1..15})" && echo -n "     "$dati"      " && echo "$(printf -- '-%.0s' {1..15})"
echo "$(printf -- '-%.0s' {1..60})"
echo ' '
echo "$(printf -- '-%.0s' {1..60})"
echo "-----       Welcome to your ioBroker-container!        -----"
echo "-----          Startupscript is now running.           -----"
echo "-----                Please be patient!                -----"
echo "$(printf -- '-%.0s' {1..60})"
echo ' '
echo "$(printf -- '-%.0s' {1..60})"
echo "-----              Debugging information               -----"
echo "-----                                                  -----"
echo "-----                      System                      -----"
echo -n "-----               " && echo -n "$(printf "%-10s %-23s" arch: $(uname -m))" && echo " -----"
echo "-----                                                  -----"
echo "-----                     Versions                     -----"
echo -n "-----               " && echo -n "$(printf "%-10s %-23s" image: $VERSION)" && echo " -----"
echo -n "-----               " && echo -n "$(printf "%-10s %-23s" node: $(node -v))" && echo " -----"
echo -n "-----               " && echo -n "$(printf "%-10s %-23s" npm: $(npm -v))" && echo " -----"
echo "-----                                                  -----"
echo "-----                       ENV                        -----"
if [ "$adminport" != "" ]; then echo -n "-----               " && echo -n "$(printf "%-10s %-23s" IOB_ADMINPORT: $adminport)" && echo " -----"; fi
if [ "$avahi" != "" ]; then echo -n "-----               " && echo -n "$(printf "%-10s %-23s" AVAHI: $avahi)" && echo " -----"; fi
if [ "$multihost" != "" ]; then echo -n "-----               " && echo -n "$(printf "%-10s %-23s" IOB_MULTIHOST: $multihost)" && echo " -----"; fi
if [ "$objectsdbhost" != "" ]; then echo -n "-----               " && echo -n "$(printf "%-10s %-23s" IOB_OBJECTSDB_HOST: $objectsdbhost)" && echo " -----"; fi
if [ "$objectsdbport" != "" ]; then echo -n "-----               " && echo -n "$(printf "%-10s %-23s" IOB_OBJECTSDB_PORT: $objectsdbport)" && echo " -----"; fi
if [ "$objectsdbtype" != "" ]; then echo -n "-----               " && echo -n "$(printf "%-10s %-23s" IOB_OBJECTSDB_TYPE: $objectsdbtype)" && echo " -----"; fi
if [ "$packages" != "" ]; then echo -n "-----               " && echo -n "$(printf "%-10s %-23s" PACKAGES: $packages)" && echo " -----"; fi
if [ "$setgid" != "" ]; then echo -n "-----               " && echo -n "$(printf "%-10s %-23s" SETGID: $setgid)" && echo " -----"; fi
if [ "$setuid" != "" ]; then echo -n "-----               " && echo -n "$(printf "%-10s %-23s" SETUID: $setuid)" && echo " -----"; fi
if [ "$statesdbhost" != "" ]; then echo -n "-----               " && echo -n "$(printf "%-10s %-23s" IOB_STATESDB_HOST: $statesdbhost)" && echo " -----"; fi
if [ "$statesdbport" != "" ]; then echo -n "-----               " && echo -n "$(printf "%-10s %-23s" IOB_STATESDB_PORT: $statesdbport)" && echo " -----"; fi
if [ "$statesdbtype" != "" ]; then echo -n "-----               " && echo -n "$(printf "%-10s %-23s" IOB_STATESDB_TYPE: $statesdbtype)" && echo " -----"; fi
if [ "$usbdevices" != "" ]; then echo -n "-----               " && echo -n "$(printf "%-10s %-23s" USBDEVICES: $usbdevices)" && echo " -----"; fi
if [ "$zwave" != "" ]; then echo -n "-----               " && echo -n "$(printf "%-10s %-23s" ZWAVE: $zwave)" && echo " -----"; fi
echo "$(printf -- '-%.0s' {1..60})"
echo ' '

#####
# STEP 1 - Preparing container
#####
echo "$(printf -- '-%.0s' {1..60})"
echo "-----         Step 1 of 5: Preparing container         -----"
echo "$(printf -- '-%.0s' {1..60})"
echo ' '

# Installing additional packages and setting uid/gid
if [ "$packages" != "" ] || [ $(cat /etc/group | grep 'iobroker:' | cut -d':' -f3) != $setgid ] || [ $(cat /etc/passwd | grep 'iobroker:' | cut -d':' -f3) != $setuid ] || [ -f /opt/.firstrun ]
then
  if [ "$packages" != "" ]
  then
    echo "Installing additional packages is set by ENV."
    echo "The following packages will be installed:" $packages"..."
    echo $packages > /opt/scripts/.packages
      bash /opt/scripts/setup_packages.sh
    echo "Done."
    echo ' '
  fi
  if [ $(cat /etc/group | grep 'iobroker:' | cut -d':' -f3) != $setgid ] || [ $(cat /etc/passwd | grep 'iobroker:' | cut -d':' -f3) != $setuid ]
  then
    echo "Different UID and/ or GID is set by ENV."
    echo "Changing UID to "$setuid" and GID to "$setgid"..."
      usermod -u $setuid iobroker
      groupmod -g $setgid iobroker
    echo "Done."
    echo ' '
  fi
  if [ -f /opt/.firstrun ]
  then
    echo "Registering maintenance script as command."
    echo "alias maintenance=\'/opt/scripts/maintenance.sh\'" >> /root/.bashrc
    echo "Done."
    echo ' '
  fi
else
  echo "Nothing to do here."
  echo ' '
fi

# Change directory for next steps
cd "${IOB_DIR}"


#####
# Detecting ioBroker-Installation
#####
echo "$(printf -- '-%.0s' {1..60})"
echo "-----   Step 2 of 5: Detecting ioBroker installation   -----"
echo "$(printf -- '-%.0s' {1..60})"
echo ' '

if [ -f "${IOB_DIR}/iobroker" ]
then
  echo "Existing installation of ioBroker detected in ${IOB_DIR}."
    rm -f /opt/scripts/.docker_config/.install_host
elif [ $(ls *_backupiobroker.tar.gz 2> /dev/null | wc -l) != "0" ] && [ $(tar -ztvf "${IOB_DIR}"/*_backupiobroker.tar.gz "backup/backup.json" 2> /dev/null | wc -l) != "0" ]
then
  if [ "$multihost" = "slave" ]
  then
    echo "IoBroker backup file detected in ${IOB_DIR}. But Multihost is set to \"slave\"."
    echo "Restoring a backup is not supported on Multihost slaves. Please check configuration and start over."
    echo "For more information see readme.md on Github (https://github.com/buanet/docker-iobroker)."
    exit 1
  else
    echo "IoBroker backup file detected in ${IOB_DIR}. Preparing restore..."
      mv "${IOB_DIR}"/*.tar.gz /opt/
      tar -xf /opt/initial_iobroker.tar -C /
      mkdir -p "${IOB_DIR}/backups"
      mv /opt/*.tar.gz "${IOB_DIR}/backups/"
      chown -R $setuid:$setgid "${IOB_DIR}"                        # fixes permission error during restore
    echo "Done."
    echo "Restoring ioBroker..."
      iobroker restore 0 > "${IOB_DIR}/log/restore.log" 2>&1
    echo "Done."
    echo ' '
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!!!!                             IMPORTANT NOTE                             !!!!!"
    echo "!!!!!        The sartup script restored iobroker from a backup file.         !!!!!"
    echo "!!!!! Check ${IOB_DIR}/log/restore.log to see if restore was successful.  !!!!!"
    echo "!!!!! When ioBroker now starts it will reinstall all Adapters automatically. !!!!!"
    echo "!!!!!         This might be take a looooong time! Please be patient!         !!!!!"
    echo "!!!!!  You can view installation process by taking a look at ioBroker log.   !!!!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  fi
else
  echo "There is data detected in ${IOB_DIR} but it looks like it is no instance of ioBroker or a valid backup file!"
  echo "Please check/ recreate mounted folder/ volume and start over."
  # exit 1
fi
echo ' '


#####
# Checking ioBroker-Installation
#####
echo "$(printf -- '-%.0s' {1..60})"
echo "-----   Step 3 of 5: Checking ioBroker installation    -----"
echo "$(printf -- '-%.0s' {1..60})"
echo ' '

# (Re)Setting permissions to ioBroker dir and "/opt/scripts"
echo "(Re)Setting folder permissions (This might take a while! Please be patient!)..."
  chown -R $setuid:$setgid "${IOB_DIR}"
  chown -R $setuid:$setgid /opt/scripts
echo "Done."
echo ' '

# Backing up original iobroker-file and changing sudo to gosu
echo "Fixing \"sudo-bug\" by replacing sudo in iobroker with gosu..."
  cp -a "${IOB_DIR}/iobroker" "${IOB_DIR}/iobroker.bak"
  chmod 755 "${IOB_DIR}/iobroker"
  sed -i 's/sudo -H -u/gosu/g' "${IOB_DIR}/iobroker"
echo "Done."
echo ' '

# Checking for first run of a new installation and renaming ioBroker
if [ -f /opt/scripts/.docker_config/.install_host ]
then
  echo "Looks like this is a new and empty installation of ioBroker."
  echo "Hostname needs to be updated to " $(hostname)"..."
    bash iobroker host $(cat /opt/scripts/.docker_config/.install_host)
    rm -f /opt/scripts/.docker_config/.install_host
  echo "Done."
  echo ' '
elif [ $(bash iobroker object get system.adapter.admin.0 --pretty | grep -oP '(?<="host": ")[^"]*') != $(hostname) ]
then
  echo "Hostname in ioBroker does not match the hostname of this container."
  echo "Updating hostname to " $(hostname)"..."
    bash iobroker host $(iobroker object get system.adapter.admin.0 --pretty | grep -oP '(?<="host": ")[^"]*')
  echo "Done."
  echo ' '
fi


#####
# Setting up prerequisites for some ioBroker-adapters
#####
echo "$(printf -- '-%.0s' {1..60})"
echo "-----      Step 4 of 5: Applying special settings      -----"
echo "$(printf -- '-%.0s' {1..60})"
echo ' '

echo "Some adapters have special requirements/ settings which can be activated by the use of environment variables."
echo "For more information take a look at readme.md on Github!"
echo ' '


# Checking ENV for Adminport
if [ "$adminport" != "" ]
then
  if [ "$adminport" != $(bash iobroker object get system.adapter.admin.0 --pretty | grep -oP '(?<="port": )[^,]*') ]
  then
    echo "Adminport set by ENV does not match port configured in ioBroker installation."
    echo "Setting Adminport to \""$adminport"\"..."
      bash iobroker set admin.0 --port $adminport
    echo "Done."
    echo ' '
  fi
fi


# Checking ENV for AVAHI
if [ "$avahi" != "" ]
then
  if [ "$avahi" = "true" ]
  then
    echo "Avahi-daemon is activated by ENV."
      chmod 755 /opt/scripts/setup_avahi.sh
      bash /opt/scripts/setup_avahi.sh
    echo "Done."
    echo ' '
  fi
fi


# Checking ENV for Z-WAVE
if [ "$zwave" != "" ]
then
  if [ "$zwave" = "true" ]
  then
    echo "Z-Wave is activated by ENV."
      chmod 755 /opt/scripts/setup_zwave.sh
      bash /opt/scripts/setup_zwave.sh
    echo "Done."
    echo ' '
  fi
fi


# checking ENV for USBDEVICES
if [ "$usbdevices" != "" ]
then
  if [ "$usbdevices" != "none" ]
  then
    echo "Usb-device-support is activated by ENV."
    IFS=';' read -ra devicearray <<< "$usbdevices"
      for i in "${devicearray[@]}"
      do
        echo "Setting permissions for" $i"..."
        chown root:dialout $i
        chmod g+rw $i
      done
    echo "Done."
    echo ' '
  fi
fi


# Checking ENV for multihost setup
# Configuring objects db host
if [ "$multihost" = "master" ] && [ "$objectsdbtype" = "" ] && [ "$objectsdbhost" = "" ] && [ "$objectsdbport" = "" ]
then
  echo "Multihost is set as \"master\" by ENV and no external objects db is set."
  echo "Setting host of objects db to \"0.0.0.0\" to allow external communication..."
    jq --arg objectsdbhost "0.0.0.0" '.objects.host = $objectsdbhost' "${IOB_JSON}" > "${IOB_JSON}.tmp" && mv "${IOB_JSON}.tmp" "${IOB_JSON}"
    chown -R $setuid:$setgid "${IOB_JSON}" && chmod 674 "${IOB_JSON}"
  echo "Done."
  echo ' '
elif [ "$multihost" = "master" ] && [ "$objectsdbhost" = "127.0.0.1" ]
then
  echo "Multihost is set as \"master\" by ENV. But objects db host is set to \"127.0.0.1\" by ENV too."
  echo "This configuration will not work! Please change or remove ENV \"IOB_OBJECTSDB_HOST\" and start over!"
  echo "For more information see readme.md on Github (https://github.com/buanet/docker-iobroker)."
  exit 1
elif [ "$multihost" = "master" ] &&  [ "$objectsdbtype" != "" ] && [ "$objectsdbhost" != "" ] && [ "$objectsdbport" != "" ]
then
  echo "Multihost is set as \"master\" by ENV and external objects db is set."
  echo "Skipping this step..."
  echo "Done."
  echo ' '
elif ([ "$multihost" = "slave" ] && [ "$objectsdbtype" = "" ]) || ([ "$multihost" = "slave" ] && [ "$objectsdbhost" = "" ]) || ([ "$multihost" = "slave" ] && [ "$objectsdbport" = "" ])
then
  echo "Multihost is set as \"slave\" by ENV. But no external objects db is set."
  echo "You have to configure ENVs \"IOB_OBJECTSDB_TYPE\", \"IOB_OBJECTSDB_HOST\" and \"IOB_OBJECTSDB_PORT\" to connect to a maser objects db."
  echo "Please check your settings and start over."
  echo "For more information see readme.md on Github (https://github.com/buanet/docker-iobroker)."
  exit 1
elif [ "$multihost" = "slave" ] && [ "$objectsdbtype" != "" ] && [ "$objectsdbhost" != "" ] && [ "$objectsdbport" != "" ]
then
  echo "Multihost is set as \"slave\" by ENV and external objects db is set."
  echo "Skipping this step..."
  echo "Done."
  echo ' '
elif [ "$multihost" != "" ]
then
  echo "Multihost is set but it seems like some configuration is missing."
  echo "Please checke if you have configured the ENVs \"MULTIHOST\", \"IOB_OBJECTSDB_TYPE\", \"IOB_OBJECTSDB_HOST\" and \"IOB_OBJECTSDB_PORT\" correctly and start over."
  echo "For more information see readme.md on Github (https://github.com/buanet/docker-iobroker)."
  exit 1
fi
#Configuring states db host
if [ "$multihost" = "master" ] && [ "$statesdbtype" = "" ] && [ "$statesdbhost" = "" ] && [ "$statesdbport" = "" ]
then
  echo "Multihost is set as \"master\" by ENV and no external states db is set."
  echo "Setting host of states db to \"0.0.0.0\" to allow external communication..."
    jq --arg statesdbhost "0.0.0.0" '.states.host = $statesdbhost' "${IOB_JSON}" > "${IOB_JSON}.tmp" && mv "${IOB_JSON}.tmp" "${IOB_JSON}"
    chown -R $setuid:$setgid "${IOB_JSON}" && chmod 674 "${IOB_JSON}"
  echo "Done."
  echo ' '
elif [ "$multihost" = "master" ] && [ "$statesdbhost" = "127.0.0.1" ]
then
  echo "Multihost is set as \"master\" by ENV. But states db host is set to \"127.0.0.1\" by ENV too."
  echo "This configuration will not work! Please change or remove ENV \"IOB_STATESDB_HOST\" and start over!"
  echo "For more information see readme.md on Github (https://github.com/buanet/docker-iobroker)."
  exit 1
elif [ "$multihost" = "master" ] && [ "$statesdbtype" != "" ] && [ "$statesdbhost" != "" ] && [ "$statesdbport" != "" ]
then
  echo "Multihost is set as \"master\" by ENV and external states db is set."
  echo "Skipping this step..."
  echo "Done."
  echo ' '
elif ([ "$multihost" = "slave" ] && [ "$statesdbtype" = "" ]) || ([ "$multihost" = "slave" ] && [ "$statesdbhost" = "" ]) || ([ "$multihost" = "slave" ] && [ "$statesdbport" = "" ])
then
  echo "Multihost is set as \"slave\" by ENV. But no external states db is set."
  echo "You have to configure ENVs \"IOB_STATESDB_TYPE\", \"IOB_STATESDB_HOST\" and \"IOB_STATESDB_PORT\" to connect to a maser states db."
  echo "Please check your settings and start over."
  echo "For more information see readme.md on Github (https://github.com/buanet/docker-iobroker)."
  exit 1
elif [ "$multihost" = "slave" ] && [ "$statesdbtype" != "" ] && [ "$statesdbhost" != "" ] && [ "$statesdbport" != "" ]
then
  echo "Multihost is set as \"slave\" by ENV and external states db is set."
  echo "Skipping this step..."
  echo "Done."
  echo ' '
elif [ "$multihost" != "" ]
then
  echo "Multihost is set but it seems like some configuration is missing."
  echo "Please checke if you have configured the ENVs \"MULTIHOST\", \"IOB_STATESDB_TYPE\", \"IOB_STATESDB_HOST\" and \"IOB_STATESTDB_PORT\" correctly and start over."
  echo "For more information see readme.md on Github (https://github.com/buanet/docker-iobroker)."
  exit 1
fi


# Checking ENVs for custom setup of objects db
if [ "$objectsdbtype" != "" ] || [ "$objectsdbhost" != "" ] || [ "$objectsdbport" != "" ]
then
  if [ "$objectsdbtype" != $(jq -r '.objects.type' "${IOB_JSON}") ]
  then
    echo "ENV IOB_OBJECTSDB_TYPE is set and value is different from detected ioBroker installation."
    echo "Setting type of objects db to \""$objectsdbtype"\"..."
      jq --arg objectsdbtype "$objectsdbtype" '.objects.type = $objectsdbtype' "${IOB_JSON}" > "${IOB_JSON}.tmp" && mv "${IOB_JSON}.tmp" "${IOB_JSON}"
      chown -R $setuid:$setgid "${IOB_JSON}" && chmod 674 "${IOB_JSON}"
    echo "Done."
  else
    echo "ENV IOB_OBJECTSDB_TYPE is set and value meets detected ioBroker installation. Nothing to do here."
  fi
  if [ "$objectsdbhost" != $(jq -r '.objects.host' "${IOB_JSON}") ]
  then
    echo "ENV IOB_OBJECTSDB_HOST is set and value is different from detected ioBroker installation."
    echo "Setting host of objects db to \""$objectsdbhost"\"..."
      jq --arg objectsdbhost "$objectsdbhost" '.objects.host = $objectsdbhost' "${IOB_JSON}" > "${IOB_JSON}.tmp" && mv "${IOB_JSON}.tmp" "${IOB_JSON}"
      chown -R $setuid:$setgid "${IOB_JSON}" && chmod 674 "${IOB_JSON}"
    echo "Done."
  else
    echo "ENV IOB_OBJECTSDB_HOST is set and value meets detected ioBroker installation. Nothing to do here."
  fi
  if [ "$objectsdbport" != $(jq -r '.objects.port' "${IOB_JSON}") ]
  then
    echo "ENV IOB_OBJECTSDB_PORT is set and value is different from detected ioBroker installation."
    echo "Setting port of objects db to \""$objectsdbport"\"..."
      jq --arg objectsdbport $objectsdbport '.objects.port = $objectsdbport' "${IOB_JSON}" > "${IOB_JSON}.tmp" && mv "${IOB_JSON}.tmp" "${IOB_JSON}"
      chown -R $setuid:$setgid "${IOB_JSON}" && chmod 674 "${IOB_JSON}"
    echo "Done."
  else
    echo "ENV IOB_OBJECTSDB_PORT is set and value meets detected ioBroker installation. Nothing to do here."
  fi
  echo ' '
fi


# Checking ENVs for custom setup of states db#
if [ "$statesdbtype" != "" ] || [ "$statesdbhost" != "" ] || [ "$statesdbport" != "" ]
then
  if [ "$statesdbtype" != $(jq -r '.states.type' "${IOB_JSON}") ]
  then
    echo "ENV IOB_STATESDB_TYPE is set and value is different from detected ioBroker installation."
    echo "Setting type of states db to \""$statesdbtype"\"..."
      jq --arg statesdbtype "$statesdbtype" '.states.type = $statesdbtype' "${IOB_JSON}" > "${IOB_JSON}.tmp" && mv "${IOB_JSON}.tmp" "${IOB_JSON}"
      chown -R $setuid:$setgid "${IOB_JSON}" && chmod 674 "${IOB_JSON}"
    echo "Done."
  else
    echo "ENV IOB_STATESDB_TYPE is set and value meets detected ioBroker installation. Nothing to do here."
  fi
  if [ "$statesdbhost" != $(jq -r '.states.host' "${IOB_JSON}") ]
  then
    echo "ENV IOB_STATESDB_HOST is set and value is different from detected ioBroker installation."
    echo "Setting host of states db to \""$statesdbhost"\"..."
      jq --arg statesdbhost "$statesdbhost" '.states.host = $statesdbhost' "${IOB_JSON}" > "${IOB_JSON}.tmp" && mv "${IOB_JSON}.tmp" "${IOB_JSON}"
      chown -R $setuid:$setgid "${IOB_JSON}" && chmod 674 "${IOB_JSON}"
    echo "Done."
  else
    echo "ENV IOB_STATESDB_HOST is set and value meets detected ioBroker installation. Nothing to do here."
  fi
  if [ "$statesdbport" != $(jq -r '.states.port' "${IOB_JSON}") ]
  then
    echo "ENV IOB_STATESDB_PORT is set and value is different from detected ioBroker installation."
    echo "Setting port of states db to \""$statesdbport"\"..."
      jq --arg statesdbport $statesdbport '.states.port = $statesdbport' "${IOB_JSON}" > "${IOB_JSON}.tmp" && mv "${IOB_JSON}.tmp" "${IOB_JSON}"
      chown -R $setuid:$setgid "${IOB_JSON}" && chmod 674 "${IOB_JSON}"
    echo "Done."
  else
    echo "ENV IOB_STATESDB_PORT is set and value meets detected ioBroker installation. Nothing to do here."
  fi
  echo ' '
fi


# Checking for Userscripts in /opt/userscripts
if [ `find /opt/userscripts -type f | wc -l` -lt 1 ]
then
  echo "There is no data detected in /opt/userscripts. Restoring exapmple userscripts..."
    tar -xf /opt/initial_userscripts.tar -C /
    chmod 755 /opt/userscripts/userscript_firststart_example.sh
    chmod 755 /opt/userscripts/userscript_everystart_example.sh
  echo "Done."
  echo ' '
elif [ -f /opt/userscripts/userscript_firststart.sh ] || [ -f /opt/userscripts/userscript_everystart.sh ]
then
  if [ -f /opt/userscripts/userscript_firststart.sh ] && [ -f /opt/.firstrun ]
  then
    echo "Userscript for first start detected and this is the first start of a new container."
    echo "Running userscript_firststart.sh..."
      chmod 755 /opt/userscripts/userscript_firststart.sh
      bash /opt/userscripts/userscript_firststart.sh
    echo "Done."
    echo ' '
  fi
  if [ -f /opt/userscripts/userscript_everystart.sh ]
  then
    echo "Userscript for every start detected. Running userscript_everystart.sh..."
      chmod 755 /opt/userscripts/userscript_everystart.sh
      bash /opt/userscripts/userscript_everystart.sh
    echo "Done."
    echo ' '
  fi
fi

# Removing first run marker when exists
if [ -f /opt/.firstrun ]
then
rm -f /opt/.firstrun
fi

#####
# Starting ioBroker
#####
echo "$(printf -- '-%.0s' {1..60})"
echo "-----          Step 5 of 5: ioBroker startup           -----"
echo "$(printf -- '-%.0s' {1..60})"
echo ' '
echo "Starting ioBroker..."
echo ' '

echo "Running 'eval' commands"
if [ -f /data/options.json ]; then
  eval $(jq -r .eval /data/options.json)
fi

# Setting healthcheck status to "running"
echo "running" > /opt/scripts/.docker_config/.healthcheck

# Function for graceful shutdown by SIGTERM signal
shut_down() {
  echo ' '
  echo "Recived termination signal (SIGTERM)."
  echo "Shutting down ioBroker..."
  pid=$(ps -ef | awk '/[j]s.controller/{print $2}')
  kill -SIGTERM "$pid"
  exit
}

# Trap to get signal for graceful shutdown
trap 'shut_down' SIGTERM

# IoBroker start
gosu iobroker node node_modules/iobroker.js-controller/controller.js & wait

# Fallback process for keeping container running when ioBroker is stopped for maintenance (e.g. js-controller update)
tail -f /dev/null