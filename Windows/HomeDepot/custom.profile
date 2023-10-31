declare _bashSubsystemDir="${dotfilesDir}/Windows/bash_subsystem"
declare _bashSubsystemProfile="${_bashSubsystemDir}/custom.profile"

source "$_bashSubsystemProfile"


export ARTIFACTORY_USER="$(jq -r '.user' "${reposDir}/maven-token.json")"
export ARTIFACTORY_TOKEN="$(jq -r '.access_token' "${reposDir}/maven-token.json")"
export NPM_TOKEN="$(jq -r '.access_token' "${reposDir}/npm-token.json")"

echo "
ARTIFACTORY_USER=${ARTIFACTORY_USER}
ARTIFACTORY_TOKEN=${ARTIFACTORY_TOKEN}
NPM_TOKEN=${NPM_TOKEN}
" >> "${reposDir}/.env"


vpnIsActive() {
    # See:
    #   - Passing multi-line commands to PowerShell: https://stackoverflow.com/questions/2608144/how-to-split-long-commands-over-multiple-lines-in-powershell/2608186#2608186
    #   - How to tell if GlobalProtect VPN is active on Windows: https://live.paloaltonetworks.com/t5/globalprotect-discussions/checking-if-globalprotect-status-is-active-connected-via-script/td-p/534841
    #   - Native Linux - Tell if logged in via VPN: https://askubuntu.com/questions/219724/how-can-i-see-if-im-logged-in-via-vpn
    powershell.exe -Command '
        Get-NetAdapter `
            | Where-Object { $_.InterfaceDescription -like "PANGP Virtual Ethernet Adapter*" } `
            | Select-Object Status
        ' \
        | awk '{
            lineToPrint = lineToPrint >= 0 ? lineToPrint : -1;

            if ($1 ~ /\s*Status\s*/) {
                lineToPrint = NR + 2;
            };

            if (NR == lineToPrint) {
                print($0);
            };
        }' \
        | grep -Piq 'Up'
}


# See:
#   - Set properties, defaults, etc. in `<activation><property>` in settings.xml:
#       - https://maven.apache.org/guides/introduction/introduction-to-profiles.html#property
#       - https://stackoverflow.com/questions/38570306/how-to-set-default-values-for-missing-environment-variables-in-maven-pom
#       - https://stackoverflow.com/questions/6529020/how-can-i-use-a-default-value-if-an-environment-variable-isnt-set-for-resource
#       - https://stackoverflow.com/questions/899274/setting-default-values-for-custom-maven-2-properties
#       - https://stackoverflow.com/questions/1363514/maven-does-not-replace-a-variable-in-settings-xml-when-it-is-invoked
#       - https://stackoverflow.com/questions/68903524/what-is-maven-d-meaning
#       - https://maven.apache.org/settings.html#properties
# if [[ -z "$MAVEN_OPTS" ]]; then
#     export MAVEN_OPTS="-DupdateDeps=never"
# fi


# Enhanced `mvn` command
#
# Include submodule1 in build but exclude submodule2:
#   mvn --projects 'submodule1,!submodule2' install
# See:
#   - https://stackoverflow.com/questions/8304110/skip-a-submodule-during-a-maven-build/27177197#27177197
#
# Resume building project from specified module:
#   mvn install -DskipTests --resume-from ':my-module-artifactId'
# See:
#   - https://stackoverflow.com/questions/47239084/maven-package-skip-successfully-built-sub-modules/47239996#47239996
#
# Download dependencies directly:
#   mvn org.apache.maven.plugins:maven-dependency-plugin:2.1:get \
#       -DrepoUrl=https://download.java.net/maven/2/ \
#       -Dartifact=robo-guice:robo-guice:0.4-SNAPSHOT
# See:
#   - https://stackoverflow.com/questions/1776496/a-simple-command-line-to-download-a-remote-maven2-artifact-to-the-local-reposito/1776544#1776544
#   - https://stackoverflow.com/questions/1776496/a-simple-command-line-to-download-a-remote-maven2-artifact-to-the-local-reposito/1776808#1776808
#
# Configuration (settings.xml, .mvn/maven.config, etc.):
# See:
#   - https://maven.apache.org/configure.html
#
# Plugins and specifying goals:
# See:
#   - https://stackoverflow.com/questions/3448648/how-do-i-run-a-specific-goal-with-a-particular-configuration-in-a-maven-plugin-w
mvn() {
    # See:
    #   - Change which `settings.xml` file is loaded (default: `~/.m2/settings.xml`): https://stackoverflow.com/a/25279325/5771107
    #   - Set default flags to run every time `mvn` is invoked (: https://stackoverflow.com/questions/61079389/maven-build-set-settings-xml-path-from-environment-variable/71676089#71676089
    declare mvnOrig="$(which mvn)"

    if ! vpnIsActive; then
        declare shouldContinuePrompt='Y'

        read -p "VPN is not active but required for dependency downloads. Are you sure you want to continue? <Y/n> " shouldContinuePrompt

        if echo "$shouldContinuePrompt" | grep -Piq 'n|no'; then
            return 1
        fi
    fi

    if ! [[ -f "$HOME/.m2/toolchains.linux.xml" ]]; then
        cp "${dotfilesDir}/Windows/HomeDepot/configs/toolchains.linux.xml" "$HOME/.m2/"
    elif ! [[ -f "$HOME/.m2/toolchains.windows.xml" ]]; then
        cp "${dotfilesDir}/Windows/HomeDepot/configs/toolchains.windows.xml" "$HOME/.m2/"
    fi

    if isWsl; then
        cp "$HOME/.m2/toolchains.linux.xml" "$HOME/.m2/toolchains.xml"
    else
        cp "$HOME/.m2/toolchains.windows.xml" "$HOME/.m2/toolchains.xml"
    fi

    "$mvnOrig" "$@"
}
