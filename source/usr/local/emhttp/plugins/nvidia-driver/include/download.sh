#!/bin/bash

# Define Variables
export KERNEL_V="$(uname -r)"
export PACKAGE="nvidia"
export DRIVER_AVAIL="$(wget -qO- https://api.github.com/repos/ich777/unraid-nvidia-driver/releases/tags/${KERNEL_V} | jq -r '.assets[].name' | grep -E ${PACKAGE} | grep -E -v '\.md5$' | sort -V)"
export BRANCHES="$(wget -qO- https://raw.githubusercontent.com/ich777/versions/master/nvidia_versions | grep -v "UPDATED")"
export DL_URL="https://github.com/ich777/unraid-nvidia-driver/releases/download/${KERNEL_V}"
export SET_DRV_V="$(grep "driver_version" "/boot/config/plugins/nvidia-driver/settings.cfg" | cut -d '=' -f2)"
export CUR_V="$(ls -p /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*} 2>/dev/null | grep -E -v '\.md5' | sort -V | tail -1)"

#Download Nvidia Driver Package
download() {
if wget -q -nc --show-progress --progress=bar:force:noscroll -O "/boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}" "${DL_URL}/${LAT_PACKAGE}" ; then
  wget -q -nc --show-progress --progress=bar:force:noscroll -O "/boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}.md5" "${DL_URL}/${LAT_PACKAGE}.md5"
  if [ "$(md5sum /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE} | awk '{print $1}')" != "$(cat /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}.md5 | awk '{print $1}')" ]; then
    echo
    echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
    echo "--------------------------------CHECKSUM ERROR!---------------------------------"
    rm -rf /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}
    exit 1
  fi
  echo
  echo "-----------Successfully downloaded Nvidia Driver Package v$(echo $LAT_PACKAGE | cut -d '-' -f2)-----------"
else
  echo
  echo "---------------Can't download Nvidia Driver Package v$(echo $LAT_PACKAGE | cut -d '-' -f2)----------------"
  exit 1
fi
}

#Check if driver is already downloaded
check() {
if ! ls -1 /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/ | grep -q "${PACKAGE}-$(echo $LAT_PACKAGE | cut -d '-' -f2)" ; then
  echo
  echo "+=============================================================================="
  echo "| WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING"
  echo "|"
  echo "| Don't close this window with the red 'X' in the top right corner until the 'DONE' button is displayed!"
  echo "|"
  echo "| WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING"
  echo "+=============================================================================="
  echo
  echo "----------------Downloading Nvidia Driver Package v$(echo $LAT_PACKAGE | cut -d '-' -f2)-----------------"
  echo "---------This could take some time, please don't close this window!------------"
  download
else
  echo
  echo "---------Noting to do, Nvidia Drivers v$(echo $LAT_PACKAGE | cut -d '-' -f2) already downloaded!---------"
  echo
  echo "------------------------------Verifying CHECKSUM!------------------------------"
  if [ "$(md5sum /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE} | awk '{print $1}')" != "$(cat /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}.md5 | awk '{print $1}')" ]; then
    rm -rf /boot/config/plugins/nvidia-driver/packages/${LAT_PACKAGE}
    echo
    echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR-----"
    echo "--------------------------------CHECKSUM ERROR!--------------------------------"
    echo
    echo "---------------Trying to redownload the Nvidia Driver v$(echo $LAT_PACKAGE | cut -d '-' -f2)-------------"
    echo
    echo "+=============================================================================="
    echo "| WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING"
    echo "|"
    echo "| Don't close this window with the red 'X' in the top right corner until the 'DONE' button is displayed!"
    echo "|"
    echo "| WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING"
    echo "+=============================================================================="
    download
  else
    echo
    echo "----------------------------------CHECKSUM OK!---------------------------------"
  fi
  exit 0
fi
}

if [ ! -d "/boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}" ]; then
  mkdir -p "/boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}"
fi

if [ "${SET_DRV_V}" == "latest" ]; then
  export LAT_PACKAGE="$(echo "$DRIVER_AVAIL" | tail -1)"
  if [ -z "$LAT_PACKAGE" ]; then
    if [ -z "${CUR_V}" ]; then
      echo
      echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
      echo "---Can't get latest Nvidia driver version and found no installed local driver---"
      echo "-----Please wait for an hour and try it again, if it then also fails please-----"
      echo "------go to the Support Thread on the Unraid forums and make a post there!------"
      exit 1
    else
      LAT_PACKAGE=$CUR_V
    fi
  fi
elif [ "${SET_DRV_V}" == "latest_prb" ]; then
  LAT_PRB_AVAIL="$(echo "$BRANCHES" | grep 'PRB' | cut -d '=' -f2 | sort -V)"
  if [ -z "$LAT_PRB_AVAIL" ]; then
    if [ -z "${CUR_V}" ]; then
      echo
      echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
      echo "----Can't get Production Branch version and found no installed local driver-----"
      echo "-----Please wait for an hour and try it again, if it then also fails please-----"
      echo "------go to the Support Thread on the Unraid forums and make a post there!------"
      exit 1
    else
      LAT_PACKAGE=$CUR_V
    fi
  elif [ -z "$DRIVER_AVAIL" ]; then
    if [ -z "${CUR_V}" ]; then
      echo
      echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
      echo "------Can't get Nvidia driver versions and found no installed local driver------"
      echo "-----Please wait for an hour and try it again, if it then also fails please-----"
      echo "------go to the Support Thread on the Unraid forums and make a post there!------"
      exit 1
    else
      LAT_PACKAGE=$CUR_V
    fi
  else
    if [ -z "$(comm -12 <(echo "$DRIVER_AVAIL" | cut -d '-' -f2) <(echo "$LAT_PRB_AVAIL") | sort -V | tail -1)" ]; then
      if [ -z "${CUR_V}" ]; then
        echo
        echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
        echo "---Can't get latest Nvidia driver version and found no installed local driver---"
        echo "-----Please wait for an hour and try it again, if it then also fails please-----"
        echo "------go to the Support Thread on the Unraid forums and make a post there!------"
        exit 1
      else
        LAT_PACKAGE="$(echo "$DRIVER_AVAIL" | tail -1)"
        echo "---Can't find Nvidia Driver v${SET_DRV_V} for your Kernel v${KERNEL_V%%-*} falling back to latest Nvidia Driver v$(echo $LAT_PACKAGE | cut -d '-' -f2)---"
        sed -i '/driver_version=/c\driver_version=latest' "/boot/config/plugins/nvidia-driver/settings.cfg"
      fi
    else
      LAT_PACKAGE="$(echo "$DRIVER_AVAIL" | grep "$LAT_PRB_AVAIL")"
    fi
  fi
elif [ "${SET_DRV_V}" == "latest_nfb" ]; then
  LAT_NFB_AVAIL="$(echo "$BRANCHES" | grep 'NFB' | cut -d '=' -f2 | sort -V)"
  if [ -z "$LAT_NFB_AVAIL" ]; then
    if [ -z "${CUR_V}" ]; then
      echo
      echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
      echo "----Can't get New Feature Branch version and found no installed local driver----"
      echo "-----Please wait for an hour and try it again, if it then also fails please-----"
      echo "------go to the Support Thread on the Unraid forums and make a post there!------"
      exit 1
    else
      LAT_PACKAGE=$CUR_V
    fi
  elif [ -z "$DRIVER_AVAIL" ]; then
    if [ -z "${CUR_V}" ]; then
      echo
      echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
      echo "------Can't get Nvidia driver versions and found no installed local driver------"
      echo "-----Please wait for an hour and try it again, if it then also fails please-----"
      echo "------go to the Support Thread on the Unraid forums and make a post there!------"
      exit 1
    else
      LAT_PACKAGE=$CUR_V
    fi
  else
    if [ -z "$(comm -12 <(echo "$DRIVER_AVAIL" | cut -d '-' -f2) <(echo "$LAT_NFB_AVAIL") | sort -V | tail -1)" ]; then
      if [ -z "${CUR_V}" ]; then
        echo
        echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
        echo "------Can't get Nvidia driver versions and found no installed local driver------"
        echo "-----Please wait for an hour and try it again, if it then also fails please-----"
        echo "------go to the Support Thread on the Unraid forums and make a post there!------"
        exit 1
      else
        LAT_PACKAGE="$(echo "$DRIVER_AVAIL" | tail -1)"
        echo "---Can't find Nvidia Driver v${SET_DRV_V} for your Kernel v${KERNEL_V%%-*} falling back to latest Nvidia Driver v$(echo $LAT_PACKAGE | cut -d '-' -f2)---"
        sed -i '/driver_version=/c\driver_version=latest' "/boot/config/plugins/nvidia-driver/settings.cfg"
      fi
    else
      LAT_PACKAGE="$(echo "$DRIVER_AVAIL" | grep "$LAT_PRB_AVAIL")"
    fi
  fi
else
  if [ -z "$DRIVER_AVAIL" ]; then
    if [ -z "${CUR_V}" ]; then
      echo
      echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
      echo "---Can't get latest Nvidia driver version and found no installed local driver---"
      echo "-----Please wait for an hour and try it again, if it then also fails please-----"
      echo "------go to the Support Thread on the Unraid forums and make a post there!------"
      exit 1
    else
      LAT_PACKAGE="${CUR_V}"
    fi
  else
    LAT_PACKAGE="$(echo "$DRIVER_AVAIL" | grep "$SET_DRV_V")"
    if [ -z "${LAT_PACKAGE}" ]; then
      export LAT_PACKAGE="$(echo "$DRIVER_AVAIL" | tail -1)"
      echo
      echo "---Can't find Nvidia Driver v${SET_DRV_V} for your Kernel v${KERNEL_V%%-*} falling back to latest Nvidia Driver v$(echo $LAT_PACKAGE | cut -d '-' -f2)---"
      sed -i '/driver_version=/c\driver_version=latest' "/boot/config/plugins/nvidia-driver/settings.cfg"
    fi
  fi
fi

#Begin Check
check

#Check for old packages that are not suitable for this Kernel and not suitable for the current Nvidia driver version
rm -f $(ls -d /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/* 2>/dev/null | grep -v "${KERNEL_V%%-*}")
rm -f $(ls /boot/config/plugins/nvidia-driver/packages/${KERNEL_V%%-*}/* 2>/dev/null | grep -v "$LAT_PACKAGE")

#Display message to reboot server both in Plugin and WebUI
echo
echo "----To install the new Nvidia Driver v$(echo $LAT_PACKAGE | cut -d '-' -f2) please reboot your Server!----"
/usr/local/emhttp/plugins/dynamix/scripts/notify -e "Nvidia Driver" -d "To install the new Nvidia Driver v$(echo $LAT_PACKAGE | cut -d '-' -f2) please reboot your Server!" -i "alert" -l "/Main"
