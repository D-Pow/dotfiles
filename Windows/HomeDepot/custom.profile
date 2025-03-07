declare _bashSubsystemDir="${dotfilesDir}/Windows/wsl"
declare _bashSubsystemProfile="${_bashSubsystemDir}/custom.profile"

source "$_bashSubsystemProfile"


export ARTIFACTORY_USER="$(jq -r '.user' "${reposDir}/token-maven.json")"
export ART_USER="${ARTIFACTORY_USER}"
export ARTIFACTORY_TOKEN="$(jq -r '.access_token' "${reposDir}/token-maven.json")"
export ART_TOKEN="${ARTIFACTORY_TOKEN}"
export NPM_TOKEN="$(jq -r '.access_token' "${reposDir}/token-npm.json")"
export DOCKER_TOKEN="$(jq -r '.access_token' "${reposDir}/token-docker.json")"

export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
# export DOCKER_HOST="unix://${HOME}/.rd/docker.sock"

echo "
ARTIFACTORY_USER=${ARTIFACTORY_USER}
ART_USER=${ARTIFACTORY_USER}
ARTIFACTORY_TOKEN=${ARTIFACTORY_TOKEN}
ART_TOKEN=${ARTIFACTORY_TOKEN}
NPM_TOKEN=${NPM_TOKEN}
DOCKER_USER=${ARTIFACTORY_USER}
DOCKER_TOKEN=${DOCKER_TOKEN}
" > "${reposDir}/.env"

alias sqlite3="/mnt/c/sqlite/sqlite3.exe"
alias docker="docker.exe"
alias cf="cf.exe"
# alias gcloud="/mnt/c/Program\ Files\ \(x86\)/Google/Cloud\ SDK/google-cloud-sdk/bin/gcloud"
alias gcloud="cmd gcloud.cmd"
alias gcloud-refresh='gcloud auth application-default login && gcloud auth login'
alias k9s="/mnt/c/Users/f76w5no/AppData/Local/Microsoft/WinGet/Packages/Derailed.k9s_Microsoft.Winget.Source_8wekyb3d8bbwe/k9s.exe"
alias kubectl="/mnt/c/Program\ Files\ \(x86\)/Google/Cloud\ SDK/google-cloud-sdk/bin/kubectl.exe"
alias k='kubectl'
export KUBE_EDITOR='subl.exe'


hdreset() {
    declare gitIgnoredFiles=$(gauf)
    gnau $gitIgnoredFiles
    gck -- $gitIgnoredFiles
}

loginToDockerRegistry() {
    # See:
    #   - https://thd.atlassian.net/wiki/spaces/PTM/pages/2111668535/New+Developer+Onboarding
    cmd "docker.exe login docker.artifactory.homedepot.com -u $(str.lower $(whoami)) -p $DOCKER_TOKEN"
}


buildAllFrontends() {
    declare origIFS="$IFS"
    declare IFS=$'\n'
    declare allPkgJsons=($(git ls-files | grep --color=never 'package.json'))
    IFS="$origIFS"

    declare pkgJson=
    for pkgJson in "${allPkgJsons[@]}"; do
        (
            cd "$(dirname "$pkgJson")"
            npm install
        )
    done
}


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


hdArtifactoryLatestJarVersion() {
    declare jarName="$1"

    curl -sS \
        -u "$(whoami):$ARTIFACTORY_TOKEN" \
        "https://maven.artifactory.homedepot.com/artifactory/libs-release-local/com/homedepot/sa/pt/${jarName}/" \
        | grep -Pi '<a href' \
        | grep -Poi '[0-9.]+(?=/)' \
        | tail -n 1
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
# Filter certain projects to include/exclude.
# Syntax is `[groupId]:artifactId` in ONE string which is comma-separated.
# e.g. To include submodule1 in build but exclude submodule2:
#   mvn --projects ':submodule1,!:submodule2' install
# See:
#   - https://stackoverflow.com/questions/8304110/skip-a-submodule-during-a-maven-build/27177197#27177197
#
# Resume building project from specified module:
#   mvn install -DskipTests --resume-from ':my-module-artifactId'
# See:
#   - https://stackoverflow.com/questions/47239084/maven-package-skip-successfully-built-sub-modules/47239996#47239996
#
# Make Maven build projects' dependencies if they aren't already built (if using `--projects`):
#   -am,--also-make
#
# Make Maven build projects that depend on the projects being built (if using `--projects`):
#   -amd,--also-make-dependents
#
# Download dependencies directly:
#   mvn org.apache.maven.plugins:maven-dependency-plugin:2.1:get \
#       -DrepoUrl=https://download.java.net/maven/2/ \
#       -Dartifact=robo-guice:robo-guice:0.4-SNAPSHOT
# See:
#   - https://stackoverflow.com/questions/1776496/a-simple-command-line-to-download-a-remote-maven2-artifact-to-the-local-reposito/1776544#1776544
#   - https://stackoverflow.com/questions/1776496/a-simple-command-line-to-download-a-remote-maven2-artifact-to-the-local-reposito/1776808#1776808
#   - Adding Maven repo via CLI: https://stackoverflow.com/questions/71030/can-i-add-maven-repositories-in-the-command-line/1193664#1193664
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
    declare _runOnLinux=
    declare _runOnWindows=

    declare OPTIND=1
    while getopts ":LW" opt; do
        case "$opt" in
            L)
                _runOnLinux='true'
                ;;
            W)
                _runOnWindows='true'
                ;;
            *)
                break
                ;;
        esac
    done
    shift $(( OPTIND - 1 ))


    if [[ "$(readlink -e "$HOME/.m2")" != "$(readlink -e "/mnt/c/Users/${windowsUser}/.m2")" ]]; then
        echo "Error: $HOME/.m2 needs to be a symlink to /mnt/c/Users/${windowsUser}/.m2 or else you'll experience difficulties." >&2
        return 1
    fi


    # Ensure VPN is running before attempting Maven commands since packages are hosted in private artifactory
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

    # If using WSL2, reading/writing Windows drives is slower than WSL1.
    # Thus set default to "Windows" if using WSL2.
    # See:
    #   - https://stackoverflow.com/questions/68972448/why-is-wsl-extremely-slow-when-compared-with-native-windows-npm-yarn-processing
    declare defaultMvnOs="Windows"

    if [[ -z "${_runOnWindows}${_runOnLinux}" ]]; then
        if echo "$defaultMvnOs" | grep -Piq 'Windows'; then
            _runOnWindows='true'
        elif echo "$defaultMvnOs" | grep -Piq 'Linux|WSL'; then
            _runOnLinux='true'
        fi
    fi


    if [[ -n "$_runOnLinux" ]] || [[ -z "$_runOnWindows" ]] && isWsl; then
        cp "$HOME/.m2/toolchains.linux.xml" "$HOME/.m2/toolchains.xml"
        "$mvnOrig" "$@"
    else
        cp "$HOME/.m2/toolchains.windows.xml" "$HOME/.m2/toolchains.xml"
        cmd mvn "$@"
    fi
}


watchJavaProcs() {
    # See: https://collectivegenius.wordpress.com/2013/09/19/troubleshooting-stuck-processes-on-linux
    strace -p "$(listprocesses -i 'java|mvn' | awk '{ print $2 }' | tail -n +2)"
}



hdmvn() {
    # Not sure why, but the CMS and Computer Vision sub-projects always give me trouble when installing, so ignore them all.
    # !:CMSDataIntegration
    declare specificProjectsToBuildFilter="!:store-payment-orchestration,!:RegisterJre,!:cv-service,!:cv-pos-client,!:cv-contracts,!:computer-vision-mock-service,!:CMSWeb,!:CMSRecognitionIntegration,!:CMS_Data_Access,!:checkout-applications,!:register-components,!:OCBAdmin,!:store-account-management-orchestration,!:ItemService,!:store-config,!:check-endorsement,!:ocb-remediation,!:monarchdatasync"

    declare mvnArgs=("$@")
    declare mvnArgsHasProjectsFlag=

    declare mvnArgIndex=
    for mvnArgIndex in "${!mvnArgs[@]}"; do
        declare mvnArg="${mvnArgs[$mvnArgIndex]}"
        if echo "$mvnArg" | grep -Piq '(-pl)|(--projects)'; then
            mvnArgsHasProjectsFlag=true

            (( mvnArgIndex++ ))

            mvnArg="${mvnArgs["$mvnArgIndex"]}"
            mvnArgs["$mvnArgIndex"]="$mvnArg,$specificProjectsToBuildFilter"
            break
        fi
    done

    if [[ -z "$mvnArgsHasProjectsFlag" ]]; then
        mvnArgs+=(--projects "$specificProjectsToBuildFilter")
    fi

    # --fail-at-end
    mvn -Dmaven.test.skip=true -DskipTests -Djacoco.skip=true "${mvnArgs[@]}"
}

alias mvnt="mvn -Dmaven.test.skip=true -DskipTests -Djacoco.skip=true"

hdmvnall() {
    hdfixpoms
    hdmvn clean install -rf ":${1:-token-provider-spi}"
    gck -- *.js
}

hdfixpoms() {
    declare origIFS="$IFS"
    declare IFS=$'\n'
    declare pomXmlFiles=($(find "${1:-.}" \( -name 'node_modules' \) -prune -false -o -type f -iname '*pom.xml'))
    IFS="$origIFS"

    declare pomXml=
    for pomXml in "${pomXmlFiles[@]}"; do
        # Replace "(2024.12.34,${project.version}]" with "${project.version}"
        # in all `<version>` and `<my.dependency.version>` entries
        sed -Ei 's/(\(|\[)+[0-9]{4}\.[0-9]+\.?[0-9]*, *(\$\{project.version\})(\]|\))+/\2/g' "$pomXml"
    done

    # Comment out cms-data-integration since it causes issues in IntelliJ.
    # Ensure it's only commented out once; for some reason `  <module>` doesn't work when trying to check if `<!-- <module>` is the
    # text or not, so we must do a post-processing extra-comment-removal series of substitutions.
    sed -Ei 's|<module>cms-data-integration</module>|<!-- <module>cms-data-integration</module> -->|; s/<!-- <!--/<!--/; s/--> -->/-->/' ./apps/pom.xml
    # `masker-service` is not versioned the same as everything else, and rarely changes, so choose current latest
    sed -Ei 's|<dependency.masker.service.version>\$\{project.version\}</dependency.masker.service.version>|<dependency.masker.service.version>2024.7.81</dependency.masker.service.version>|' ./apps/store-customer-orchestration/pom.xml

    git update-index --assume-unchanged ${pomXmlFiles[@]}

    if (( $? )); then
        git update-index --assume-unchanged $(gitGetModifiedContaining 'pom.xml')
    fi
}

hdupdatebranch() {
    gst && hdreset && gplo && gst pop && hdmvnall
}

hdStoreCheckoutComponentsTestCoverage() (
    declare projectsList="${1:-:SelfServiceWebApp}"

    repos store-checkout-components

    echo "Running \`mvn clean test jacoco:check --projects \"$projectsList\" > $(gitGetRootDir)/jacoco.log\`..."

    mvn \
        --projects "$projectsList" \
        clean \
        test \
        jacoco:check \
        -X 2>&1 \
        | decolor \
        > ./jacoco.log

    echo "Tests and coverage report generated. View them at \`<path>/target/site/jacoco/index.html\`"
)

hdStoreCheckoutComponentsFixPomXmlDependenciesVersionRange() (
    git stash push -m "WIP - Right before trying to install with updated dependency versions."

    declare repoRootDir="$(git rev-parse --show-toplevel)"

    if isWsl; then
        repoRootDir="$(wslpath "$repoRootDir")"
    fi

    cd "$repoRootDir"

    declare minorVersion="$(
        grep -Pio '^ {2,4}<version>([\d.]+)</version>' "$repoRootDir/pom.xml" \
            | sed -E 's/.*>([.0-9]+)<.*/\1/' \
            | grep -Po '(?<=\.)\d+(?=\.)'
    )"

    declare origIFS="$IFS"
    declare IFS=$'\n'
    declare pomXmlFiles=($(find . \( -name 'node_modules' \) -prune -false -o -type f -iname '*pom.xml'))
    IFS="$origIFS"

    # Running `sed` in the for-loop is the equivalent of running it in `find` via:
    #   <find-command-above> -exec sed -Ei "s/\(2023.[89][0-9]*,/\(2023.${minorVersion},/g" "{}" ';'
    # We run it separately in a for-loop here to maintain file paths of all files for executing other
    # commands on them after this `sed` command is run.
    declare pomXml=
    for pomXml in "${pomXmlFiles[@]}"; do
        sed -Ei "s/\(2023.[89][0-9]*,/\(2023.${minorVersion},/g" "$pomXml"
    done

    declare mvnInstallExitCode=0


    # Cleanup `sed` changes above when this function ends, regardless of success or failure.
    trap "hdStoreCheckoutComponentsExitCode=\$?; git reset --hard HEAD; git stash apply; return \$hdStoreCheckoutComponentsExitCode;" EXIT QUIT INT TERM


    # mvn -DskipTests -am --projects '!:computer-vision-libs-parent,!:cv-service,!:cv-pos-client,!:CMSDataIntegration,!:CMSWeb,!:CMSRecognitionIntegration' clean install
    hdmvn -DskipTests -am clean install

    # # `:register-components` requires access to Docker socket which is unavailable when running
    # # Windows' version of `mvn`, so ignore it as well and build it separately after this command.
    # # Also, ignore `update-checkout-applications` from module MOJO executions since it always errors out.
    # mvn \
    #     -DskipTests \
    #     -am \
    #     --projects "$specificProjectsToBuildFilter,!:register-components" \
    #     -Dexec.skip='update-checkout-applications' \
    #     clean \
    #     install
    #
    # (( mvnInstallExitCode += $? ))
    #
    # # As described above, `:register-components` needs to be built in Linux, so build only it here.
    # mvn \
    #     -L \
    #     -DskipTests \
    #     -am \
    #     --projects "$specificProjectsToBuildFilter,!:deployment" \
    #     -Dexec.skip='update-checkout-applications' \
    #     --resume-from ':register-components' \
    #     clean \
    #     install
    #
    # (( mvnInstallExitCode += $? ))

    for pomXml in "${pomXmlFiles[@]}"; do
        git checkout -- "$pomXml"
    done

    return $mvnInstallExitCode

    # TODO
    #
    # apps/pom.xml -> modules
    # apps/payment/payment-service/pom.xml -> spring-oauth dep
    #       <properties>
    #           <!-- Dependencies -->
    #           <dependency.security-libs.spring-oauth-jwt.version>(2023.100, ${project.version}]</dependency.security-libs.spring-oauth-jwt.version>
    #       ...
    #       <dependency>
    #           <groupId>com.homedepot.sa.pt</groupId>
    #           <artifactId>spring-oauth2-resource-jwt</artifactId>
    #           <version>${dependency.security-libs.spring-oauth-jwt.version}</version> <!-- Inherited from parent -->
    # apps/customer-lookup-service/pom.xml ->dependency.customer.lookup.client.version, and dependency.tokenization.client.version need end of range to be ${project.version}
    # apps/register/checkout-applications/pom.xml -> Remove update-checkout-applications execution
    #       <execution>
    #           <id>update-checkout-applications</id>
    # apps/suspend-resume-service/pom.xml -> May or may not need a version for their quarkus-resteasy-reactive and quarkus-smallrye-jwt deps
    #       <version>${dependency.quarkus.platform.version}</version>
)

_hdUpdateJavaInstallationPolicyFiles() (
    declare javaInstallationDir="${1:-"/mnt/c/java"}"

    cd "$javaInstallationDir"

    declare jdkSecurityDir="conf/security"
    declare jdkSecurityFile="$jdkSecurityDir/java.security"
    declare jdkPolicyFile="$jdkSecurityDir/java.policy"

    declare dir=
    for dir in $(find . -maxdepth 1 -iname 'jdk-*'); do
        mv "$dir/$jdkPolicyFile" "$dir/$jdkPolicyFile.bak"
        mv "$dir/$jdkSecurityFile" "$dir/$jdkSecurityFile.bak"

        cp "jdk11.0.16.1-ms/$jdkSecurityFile" "$dir/$jdkSecurityDir/"
        cp "jdk11.0.16.1-ms/$jdkPolicyFile" "$dir/$jdkSecurityDir/"
    done
)

hduiRun() (
    declare uiStoreCheckoutRepoPath="$reposDir/ui-store-checkout"

    cd "$uiStoreCheckoutRepoPath"

    declare runArgs=("$@")

    if array.empty runArgs; then
        runArgs=(
            'start'
        )
    fi

    cmd npm run "${runArgs[@]}"
)

hdParamsRun() (
    declare runArgs=("$@")

    if array.empty runArgs; then
        runArgs=(
            'bootRun'
        )
    fi

    export ART_TOKEN="$ARTIFACTORY_TOKEN"
    export ART_USER="$ARTIFACTORY_USER"

    # cmd gradlew.bat "${runArgs[@]}"

    declare javaHome="C:/java/jdk-11.0.2"

    cmd.exe \
        /V \
        /C \
        "set \"JAVA_HOME=$javaHome\" && set \"PATH=%JAVA_HOME%/bin:%PATH%\" && gradlew.bat -Djava.home=$javaHome ${runArgs[@]}"
)

hdParamsFix() (
    # `cmd` doesn't exist in Gradle when running `commandLine 'cmd', '/C', 'actual-command'`
    # like it does for these dotfiles.
    # Thus, replace all instances of `'cmd', '/C'` with `'bash'`.
    declare origIFS="$IFS"
    declare IFS=$'\n'
    declare files=($(grep -PiRl "['\"]cmd['\"], *['\"]/[cC]['\"]" .))

    declare file=
    for file in ${files[@]}; do
        sed -Ei "s~['\"]cmd['\"],[ ]*['\"]/[cC]['\"]~'bash'~g" $file
    done

    IFS="$origIFS"
)

hdParamsGitClean() (
    git clean \
        -dx \
        --exclude gradle/ \
        --exclude 'gradlew*' \
        --exclude '.idea' \
        "$@"
)

hdParamsGitCleanShow() {
    hdParamsGitClean --dry-run
}

hdParamsGitCleanForce() (
    hdParamsGitClean -f
)

hdLatestJarVersion() {
    declare jarName="$1"

    curl -sS \
        -u "$(whoami):$ARTIFACTORY_TOKEN" \
        "https://maven.artifactory.homedepot.com/artifactory/libs-release-local/com/homedepot/sa/pt/${jarName}/" \
        | grep -Pi '<a href' \
        | grep -Poi '[0-9.]+(?=/)' \
        | tail -n 1
}

_hdUpdateRegisterVersion() {
    declare CLIENT_INSTALLER_V=${1:-$(hdLatestJarVersion 'saptClientInstaller')}
    declare REGISTER_JRE_V=${2:-$(hdLatestJarVersion 'RegisterJre')}
    declare CLIENT_INSTALLER_PATH="saptClientInstaller/${CLIENT_INSTALLER_V}/saptClientInstaller-${CLIENT_INSTALLER_V}.jar"
    declare REGISTER_JRE_PATH="RegisterJre/${REGISTER_JRE_V}/RegisterJre-${REGISTER_JRE_V}.zip"
    declare root='/c'

    if uname -a | grep -Piq 'MINGW64'; then
        # Git Bash
        root='/c'
    elif uname -a | grep -Piq 'Linux.*Microsoft'; then
        # WSL
        root='/mnt/c'
    fi

    # Start the magic
    if [[ -d /mnt/c/POSrewrite ]]; then
        mv ${root}/POSrewrite ${root}/POSrewrite_$(date '+%m-%d-%Y-%H-%M-%S')
    else
        mkdir ${root}/POSrewrite
    fi

    mkdir -p ${root}/POSrewrite/{data/pos,JRE/RegisterJRE11.0.1,jars}

    # get client installer
    cd jars
    curl -u "${LDAP}:${MAVEN_TOKEN}" -O "https://maven.artifactory.homedepot.com/artifactory/libs-release-local/com/homedepot/sa/pt/${CLIENT_INSTALLER_PATH}"
    mv "saptClientInstaller-${CLIENT_INSTALLER_V}.jar" "clientinstaller.jar"

    # get register jre
    cd ../JRE/RegisterJRE11.0.1
    curl -u "${LDAP}:${MAVEN_TOKEN}" -O "https://maven.artifactory.homedepot.com/artifactory/libs-release-local/com/homedepot/sa/pt/${REGISTER_JRE_PATH}"
    unzip RegisterJre-${REGISTER_JRE_V}.zip
    rm RegisterJre-${REGISTER_JRE_V}.zip

    # move local store xml to pos folder
    cd ${root}/POSrewrite
    cp -r ~/.scripts/register/store.xml ${root}/POSrewrite/data/pos
    ${root}/POSrewrite/JRE/RegisterJRE11.0.1/bin/java.exe -jar ${root}/POSrewrite/jars/clientinstaller.jar -t REGISTER
    rm -rf data/pos/store.xml
    ${root}/POSrewrite/runlocal.bat
}

hdLogLatest() {
    ls -FlAh /mnt/c/POSrewrite/data/logs/regApp.log.2025* \
        | sort -Vr -k 9 \
        | awk '{ print $9 }' \
        | head -n 1 \
        | sed -E 's/\*$//' \
        | decolor
}

hdTransIds() {
    cat $(hdLogLatest) \
        | egrep -i 'pos_trans_id'
}

hdReceiptBarcodeLatest() {
    cat $(hdLogLatest) \
        | egrep -i 'receipt_raw .*</receipt_raw>' \
        | tail -n 1 \
        | egrep -io --color=never '>.*<' \
        | sed -E 's/[><]//g' \
        | decodeBase64 \
        | gzip -d \
        | egrep -io --color=never '(?<=barcode"><data>)\d+'
}


hdRefreshCache() {
    declare flagRegexSearch="${1:-enableHdWalletButtonPos}"
    declare storeFourDigitNumber="$2"
    # Get app name via:
    #   cf apps | grep -i pos-service-parameter | cut -f 1 -d ' ' | grep -vi log4j | sort -Vr | head -n 1
    # Get app GUID via:
    #   cf app --guid ${appName}
    declare appName='pos-service-parameter-2023-074-002'
    declare -A envIdMap=(
        ['za']='da7d9a3e-2175-4d0b-a3ed-e2c87b674501'
        ['zb']='e259e816-aac2-4a76-975c-3180b681d2f5'
        ['eb']='15fe719b-9424-4df7-8637-4896e8eedf99'
    )

    declare env=
    for env in "${!envIdMap[@]}"; do
        declare id="${envIdMap["$env"]}"

        cf login -a "https://api.run-${env}.homedepot.com"

        # Get instance ID via:
        #   cf app ${appName} | grep -Pio '^#\d' | sed -E 's/#//'
        declare i=
        for i in {0,1}; do
            # QA:
            #  curl -sS --header 'cache-control: no-cache' --header 'uuid: refresh' --header "X-CF-APP-INSTANCE: 47123feb-fb32-4e9d-830e-c98cdcd5c545:0" "http://pos-service-parameter-uat.apps-np.homdedepot.com/service/v1/parameters/refreshCache?lcp=QA"
            curl -sS \
                --header 'cache-control: no-cache' \
                --header 'uuid: refresh' \
                --header "X-CF-APP-INSTANCE: ${id}:${i}" \
                "http://${appName}.apps-${env}.homedepot.com/service/v1/parameters/refreshCache?lcp=PR" \
                | grep -Pio "${flagRegexSearch}[^\}]+\}"

            if [[ -n "$storeFourDigitNumber" ]]; then
                # Verify flag value for specific env and store:
                hdFlagCheck -p "$env" "$storeFourDigitNumber" "$flagRegexSearch"
            fi
        done
    done
}

hdFlagCheck() {
    declare prodEnv=

    declare OPTARG=
    declare OPTIND=1
    while getopts ":p:" opt; do
        case "$opt" in
            p)
                prodEnv="$OPTARG"
                ;;
            *)
                echo "
${FUNCNAME[0]} [OPTIONS...] <store-number> <flag-name>

Options:
    -p <env>    |   Sets production env (za, zb, eb).
"
                return 1
                ;;
        esac
    done
    shift $(( OPTIND - 1 ))

    declare storeFourDigitNumber="$1"
    declare flagRegexSearch="${2:-.}"
    declare appName='pos-service-parameter-uat'
    declare env='np'
    declare lcp='QA'

    if [[ -n "$prodEnv" ]]; then
        env="$prodEnv"
        appName='pos-service-parameter-2023-074-002'
        lcp='PR'
    fi

    declare allFlags="$(curl -sS \
        --header 'cache-control: no-cache' \
        --header 'uuid: ADD_YOUR_UUID' \
        "http://${appName}.apps-${env}.homedepot.com/service/v1/parameters/US/st${storeFourDigitNumber}?lcp=${lcp}"
    )"

    # Format JSON and print out `parameters` array for nested objects.
    # grep out the single entry via regex (Use Perl regex instead of `jq ".parameters[] | select(.name == \"${flagRegexSearch}\")"`)
    # Filter out superfluous hyphen lines
    echo "$allFlags" \
        | jq --indent 4 '.parameters[]' \
        | grep -Pi -B 1 -A 2 --color=never "$flagRegexSearch" \
        | grep -Pv '^-+$'
}



################
#  Kubernetes  #
################

kps() {
    declare searchQuery="${1:-store-customer-orchestration}"

    kubectl get pods --all-namespaces \
        | egrep -i "$searchQuery" \
        | awk '{
            if ($3 ~ /[1-9]\/[1-9]/) {
                print($1, $2);
            }
        }' \
        | column -tc 2
}

kpl() {
    declare namespace="${1:-checkout-test}"

    kubectl get pods -n $namespace
}

kpd() {
    declare namespaceAndPod="$(kps "$@" | head -n 1)"
    declare namespace="$(echo "$namespaceAndPod" | awk '{ print($1) }')"
    declare pod="$(echo "$namespaceAndPod" | awk '{ print($2) }')"

    kubectl describe pod -n $namespace $pod
}

ks() {
    declare namespace="${1:-checkout-test}"

    kubectl get secrets -n $namespace
}

ksd() {
    declare namespace="${1:-checkout-test}"
    declare secretName="$2"

    kubectl get secret -n $namespace $secretName -o jsonpath='{.data}'
}

kc() {
    declare contextLocale="$1"

    # Setup contexts for east/central/south
    #   gcloud container clusters get-credentials checkout-np-us-east1-k8s --region us-east1

    if [[ -n "$contextLocale" ]]; then
        # Change context to east/central/south
        kubectl config use-context "gke_np-store-checkout_us-${contextLocale}1_checkout-np-us-${contextLocale}1-k8s"
    else
        echo "Choose between: east, central, south"
        kubectl config get-contexts
    fi
}

ke() {
    declare namespaceAndPod="$(kps "$@" | head -n 1)"
    declare namespace="$(echo "$namespaceAndPod" | awk '{ print($1) }')"
    declare pod="$(echo "$namespaceAndPod" | awk '{ print($2) }')"
    declare container="$(echo "$pod" | sed -E 's/-\w+-\w+$//')"

    # Optional flags:
    #   -c store-customer-orchestration-test
    kubectl exec -it -n $namespace -c $container "$pod" -- bash
}

kl() {
    declare namespaceAndPod="$(kps "$@" | head -n 1)"
    declare namespace="$(echo "$namespaceAndPod" | awk '{ print($1) }')"
    declare pod="$(echo "$namespaceAndPod" | awk '{ print($2) }')"

    kubectl logs -n $namespace $pod
}
