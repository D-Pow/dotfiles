declare _bashSubsystemDir="${dotfilesDir}/Windows/wsl"
declare _bashSubsystemProfile="${_bashSubsystemDir}/custom.profile"

source "$_bashSubsystemProfile"


export ARTIFACTORY_USER="$(jq -r '.user' "${reposDir}/maven-token.json")"
export ART_USER="${ARTIFACTORY_USER}"
export ARTIFACTORY_TOKEN="$(jq -r '.access_token' "${reposDir}/maven-token.json")"
export ART_TOKEN="${ARTIFACTORY_TOKEN}"
export NPM_TOKEN="$(jq -r '.access_token' "${reposDir}/npm-token.json")"
export DOCKER_TOKEN="$(jq -r '.access_token' "${reposDir}/docker-token.json")"

export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
export DOCKER_HOST="unix://${HOME}/.rd/docker.sock"

echo "
ARTIFACTORY_USER=${ARTIFACTORY_USER}
ART_USER=${ARTIFACTORY_USER}
ARTIFACTORY_TOKEN=${ARTIFACTORY_TOKEN}
ART_TOKEN=${ARTIFACTORY_TOKEN}
NPM_TOKEN=${NPM_TOKEN}
DOCKER_USER=${ARTIFACTORY_USER}
DOCKER_TOKEN=${DOCKER_TOKEN}
" > "${reposDir}/.env"

alias docker="docker.exe"


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
    declare specificProjectsToBuildFilter="!:computer-vision-libs-parent,!:cv-client,!:cv-service,!:cv-pos-client,!:cv-contracts,!:CMSDataIntegration,!:CMSWeb,!:CMSRecognitionIntegration,!:CMS_Data_Access"

    declare mvnArgs=("$@")
    declare mvnArgsHasProjectsFlag=

    declare mvnArgIndex=
    for mvnArgIndex in "${!mvnArgs[@]}"; do
        declare mvnArg="${mvnArgs[$mvnArgIndex]}"
        if echo "$mvnArg" | grep -Piq '(-pl)|(--projects)'; then
            mvnArgsHasProjectsFlag=true

            # Don't increment since
            (( mvnArgIndex++ ))

            mvnArg="${mvnArgs["$mvnArgIndex"]}"
            mvnArgs["$mvnArgIndex"]="$mvnArg,$specificProjectsToBuildFilter"
            break
        fi
    done

    if [[ -z "$mvnArgsHasProjectsFlag" ]]; then
        mvnArgs+=(--projects "$specificProjectsToBuildFilter")
    fi

    # Default to Windows' `mvn`
    mvn -Djacoco.skip=true "${mvnArgs[@]}"
}

hdStoreCheckoutComponentsTestCoverage() (
    declare projectsList="${1:-:SelfServiceWebApp}"

    repos store-checkout-components

    echo "Running \`mvn clean test jacoco:check --projects \"$projectsList\" > $(gitGetRootDir)/.jacoco.log\`..."

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

hdUpdateJavaInstallationPolicyFiles() (
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
