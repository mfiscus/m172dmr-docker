#!/command/with-contenv bash

set -x

### Use environment variables to configure services

# If the first run completed successfully, we are done
if [ -e /.firstRunComplete ]; then
  exit 0

fi

# $1=Property
function __uncomment() {
    if [ ${#} -eq 1 ]; then
        local property=${1}

        sed -i "/^#${property}=/s/^#//" ${M172DMR_CONFIG_TMP_DIR}/M172DMR.ini

        return

    else
        exit 1

    fi

}

# $1=Property
# $2=Value
function __edit_ini() {
    if [ ${#} -eq 2 ]; then
        local property=${1}
        local value=${2}

        sed -i "s'\(^${property}\=\)[[:print:]]*'\1${value}'g" ${M172DMR_CONFIG_TMP_DIR}/M172DMR.ini

        return

    else
        exit 1

    fi

}

# install configuration files
if [[ -e ${M172DMR_CONFIG_DIR:-} ]] && [[ -e ${M172DMR_CONFIG_TMP_DIR:-} ]]; then
    __uncomment "XLXFile"
    __uncomment "XLXReflector"
    __uncomment "XLXModule"
    __edit_ini "Location" "${LOCATION}"
    __edit_ini "Description" "${DESCRIPTION}"
    __edit_ini "URL" "${URL}"
    __edit_ini "Callsign" "${CALLSIGN}"
    __edit_ini "LocalPort" "${LOCALPORT}"
    __edit_ini "DstName" "${DSTNAME}"
    __edit_ini "DstAddress" "${DSTADDRESS}"
    __edit_ini "DstPort" "${DSTPORT}"
    __edit_ini "GainAdjustdB" "${GAINADJUSTDB}"
    __edit_ini "Daemon" "${DAEMON}"
    __edit_ini "Id" "${ID}"
    __edit_ini "XLXFile" "${XLXFILE}"
    __edit_ini "XLXReflector" "${XLXREFLECTOR}"
    __edit_ini "XLXModule" "${XLXMODULE}"
    __edit_ini "StartupDstId" "${STARTUPDSTID}"
    __edit_ini "StartupPC" "${STARTUPPC}"
    __edit_ini "Address" "${ADDRESS}"
    __edit_ini "Port" "${PORT}"
    __edit_ini "Jitter" "${JITTER}"
    __edit_ini "Password" "${PASSWORD}"
    __edit_ini "File" "${FILE}"

    cp -vupn ${M172DMR_CONFIG_TMP_DIR}/* ${M172DMR_CONFIG_DIR}/ # don't overwrite config files if they exist
    rm -rf ${M172DMR_CONFIG_TMP_DIR} # remove temporary config directory

fi

# set timezone
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

touch /.firstRunComplete
echo "M172DMR first run setup complete"
