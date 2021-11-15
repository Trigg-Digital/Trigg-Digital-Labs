#!/bin/bash

BRANCHNAME="${BRANCH_NAME}"


echo "Branch Name: $BRANCHNAME"

#Set up git commits
git config remote.origin.url "https://github.com/Selina-Finance/salesforce.git"
git config --global user.email ${GITUSERNAME}
git config --global user.name ${GITUSERNAME}


if [[ "$BRANCHNAME" == "sprint/"* ]]
then
    echo "Sprint Branch Created"
    
    # Generate package.xml file
    echo ""
    echo "Generating Package.xml file"
    PACKAGE='manifest/sprintpackage.xml'
    cp templates/sprintpackage.xml $PACKAGE
    echo "Package Created"

    # Commit Changes
    git add $PACKAGE
    git commit -m "Auto-commit - updated Salesforce package.xml for sprint"
    git push

elif [[ "$BRANCHNAME" == "release/"* ]]
then
    echo "Release Branch Created"
    exit 0
elif [[ "$BRANCHNAME" == "feature/"* ]]
then
    echo "Feature Branch Created"
    
    # Generate package.xml file
    echo ""
    echo "Generating Package.xml file"
    PACKAGE='manifest/featurepackage.xml'
    cp templates/featurepackage.xml $PACKAGE
    echo "Package Created"

    # Commit Changes
    git add $PACKAGE
    git commit -m "Auto-commit - updated Salesforce package.xml for feature"
    git push

else
    echo "Branch Type not handled, recreate using naming convention or continue"
    exit 1
fi