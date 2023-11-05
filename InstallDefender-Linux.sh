#! /bin/bash

: '
    Author:         n4t5u
    Email:          hello@nasru.me
    Version:        1.0
    License:        MIT
    Created:        05/11/2023
    Modified:       -
    ScriptName:     InstallDefender-Linux
    Description:    Automated the installation steps to install Windows Defender Endpoint on Debian Linux Distributions
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

    # Edit [Distro] [Version] [Channel]
    # curl -o microsoft.list https://packages.microsoft.com/config/[distro]/[version]/[channel].list
    # mv ./microsoft.list /etc/apt/sources.list.d/microsoft-[channel].list
    curl -o microsoft.list http://packages.microsoft.com/config/ubuntu/22.04/prod.list
    mv ./microsoft.list /etc/apt/sources.list.d/microsoft-prod.list

    # For Debian 12
    #curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft-prod.gpg > /dev/null

    # For Other Distributions
    curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

    # Update the Repo Metadata
    echo "${green}This machine will update Repo Metadata."
    sleep 10
    $normal
    apt update

    # Now install the MDATP
    apt install mdatp

    # For this Part to work, you will require the ZIP file to be present in the same folder as the script.
    # Microsoft Provided ZIP file Unzip it and run the Python File
    unzip WindowsDefenderATPOnboardingPackage.zip
    python3 MicrosoftDefenderATPOnboardingLinuxServer.py

    # Checking if Device is enrolled.
    echo "${red}Checking if Device has been enrolled."
    mdatp health --field org_id
    sleep 10
    mdatp health --field healthy
    sleep 10
}

#Checks for sudo access before running the main function
if [[ ${UID} == 0 ]]; then
    main

    exit 1
else
    echo "${red}This script requires elevated access. Please run using SUDO or run the Script as ROOT."
    Sleep 5
    exit 1
fi