#!/usr/bin/env bash

# Converted logic from .bat Windows script file to .sh Bash WSL file.
# Only necessary b/c Maven often fails when building the app due to nested dependencies,
# and we thus add new logic in the if-failure block.
#
# Orig:
# cmd.exe "/C" "%USERPROFILE%\repositories\store-checkout-components\apps\register\dev-scripts\self-service-prelaunch.bat"


buildAndDeploySelfServiceWebApp() (
    source "$(realpath "$(dirname "${BASH_SOURCE[0]}")/../../../.profile")" 'Windows/HomeDepot'

    repos "store-checkout-components"

    declare VERSION_APP_SELF_SERVICE="$(
        mvn \
            --non-recursive \
            -Dexec.executable=cmd \
            -Dexec.args='/C echo ${project.version}' 'org.codehaus.mojo:exec-maven-plugin:1.3.1:exec' \
            -q
    )"
    # Trim out any leading/trailing whitespace, esp `\r` bleeding through from Windows
    VERSION_APP_SELF_SERVICE="$(echo "$VERSION_APP_SELF_SERVICE" | sed -E 's/(^\s+)|(\s+$)//g')"

    echo "Building ':SelfServiceWebApp' (apps/register/app-self-service) version $VERSION_APP_SELF_SERVICE"
    echo -e "-----------------------------\n"

    mvn clean install -DskipTests -Djacoco.skip=true --projects ':engage-client'
    echo -e '\n\n'
    ( mvn clean install -DskipTests -Djacoco.skip=true --projects ':SelfServiceWebApp'; )

    if (( $? )); then
        echo -e "\n\nError installing SelfServiceWebApp module. Re-attempting with building sub-dependencies as needed..."

        mvn install -DskipTests -Djacoco.skip=true --projects ':SelfServiceWebApp,!:JettyServer,!:JettyServerJar' -am
    fi

    declare buildOutputWar="$HOME/.m2/repository/com/homedepot/sa/pt/SelfServiceWebApp/$VERSION_APP_SELF_SERVICE/SelfServiceWebApp-$VERSION_APP_SELF_SERVICE.war"
    declare posRegisterWar="/mnt/c/POSrewrite/webapps/SelfServiceWebApp.war"

    echo -e "\nCopying\n\t $buildOutputWar \n to \n\t $posRegisterWar \n ...\n"

    cp "$buildOutputWar" "$posRegisterWar"

    if ! (( $? )); then
        echo "Build successful!"
    fi
)



if [[ "${BASH_SOURCE[0]}" == "${BASH_SOURCE[ ${#BASH_SOURCE[@]} - 1 ]}" ]]; then
    buildAndDeploySelfServiceWebApp "$@"
fi
