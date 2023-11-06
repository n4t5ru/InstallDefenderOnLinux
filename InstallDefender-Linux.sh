#! /bin/bash

: '
    Author:         n4t5u
    Email:          hello@nasru.me
    Version:        2.0
    License:        MIT
    Created:        05/11/2023
    Modified:       06/11/2023
    ScriptName:     InstallDefender-Linux
    Description:    Automated the installation steps to install Windows Defender Endpoint on Linux Distributions
                    Check https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/microsoft-defender-endpoint-linux?view=o365-worldwide for supported distributions
    How To:         Run the script as Root
'

# Colour output definitions
red=$( tput setaf 1 );
yellow=$( tput setaf 3 );
green=$( tput setaf 2 );
normal=$( tput sgr 0 );

# Main Function
function main() {

    # Installs all the equired libraries
    yum=`which yum 2>/dev/null`
    apt=`which apt 2>/dev/null`
    zypper=`which zypper 2>/dev/null`

    if [[ -z ${yum}${apt}${zypper} ]]
    then
        echo "Unsupported distro"
        exit 1
    fi

    ${yum}${apt}${zypper} install curl libplist-utils gpg gnupg apt-transport-https -y > /dev/null

    # Checks /etc/os-release file and retrieves all the required variables for the require downloads to work
    for file in /etc/*
    do
        if [[ "${file}" == "/etc/os-release" ]]
        then
            OsID=$(grep -w "ID" /etc/os-release)
            OsVer=$(grep -w "VERSION_ID" /etc/os-release)

            if [[ ${OsID} == "ID=debian" ]] && [[ ${OsVer} == 'VERSION_ID="12"' ]]
            then
                curl -o microsoft.list http://packages.microsoft.com/config/debian/12/prod.list
                mv ./microsoft.list /etc/apt/sources.list.d/microsoft-prod.list

                # For Debian 12 this part varies.
                curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft-prod.gpg > /dev/null
                break
            else
                osRemove="ID="
                verRemove="VERSION_ID="

                # Remove double quotes and the specified part from OS ID
                osFinal="${OsID//$osRemove/}"
                osFinal="${osFinal//\"/}"

                # Remove double quotes and the specified part from OS Version
                verFinal="${OsVer//$verRemove/}"
                verFinal="${verFinal//\"/}"

                if [[ ${osFinal} == 'debian']]
                then
                    curl -o microsoft.list http://packages.microsoft.com/config/${osFinal}/$verFinal/prod.list
                elif [[ ${osFinal} == 'ubuntu' ]]
                then
                    curl -o microsoft.list http://packages.microsoft.com/config/${osFinal}/$verFinal/prod.list
                else
                    curl -o microsoft.list http://packages.microsoft.com/config/${osFinal}/$verFinal/prod.repo
                fi

                mv ./microsoft.list /etc/apt/sources.list.d/microsoft-prod.list
                curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
                break
            fi
        fi
    done

    # Update the Repo Metadata
    echo "${green}This machine will update Repo Metadata."
    sleep 5
    $normal
    apt update -y > /dev/null
    sleep 10

    # Now install the MDATP
    apt install mdatp > /dev/null

    # For this Part to work, you will require the ZIP file to be present in the same folder as the script.
    # Microsoft Provided ZIP file Unzip it and run the Python File
    unzip WindowsDefenderATPOnboardingPackage.zip
    python3 MicrosoftDefenderATPOnboardingLinuxServer.py
    sleep 10

    # Checking if Device is enrolled.
    echo "${red}Checking if Device has been enrolled."
    mdatp health --field org_id
    sleep 5
    mdatp health --field healthy
    sleep 5

    # Checking if Realtime Threat Protection is enabled and enables it.
    threat_Protection='mdatp health --field real_time_protection_enabled'

    if [[ ${threat_Protection} == 'false' ]];
    then
        mdatp config real-time-protection --value enabled
        mdatp config tamper_protection --value enabled
        mdatp config tamper_protection --value enabled
        echo "${green} Real-time Threat Protection Enabled."
        sleep 10
    else
        echo "${yellow} Real-time Threat Protection Already Activated"
    fi

    # Exiting the script
    echo "${normal} We done here! Bye"
    sleep 10
    exit
}

#Checks for sudo access before running the main function
if [[ ${UID} == 0 ]]; then
    main
else
    echo "${red}This script requires elevated access. Please run using SUDO or run the Script as ROOT."
    Sleep 5
    exit 1
fi