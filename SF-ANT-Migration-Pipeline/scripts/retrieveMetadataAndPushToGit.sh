
SFUSER="${SFUSER}"
SFPASSWORD="${SFPASSWORD}"
ENV="${ENV}"

echo "DEBUG: SFUSER is ${SFUSER}"
echo "DEBUG: SFPASSWORD is ${SFPASSWORD}"

# Specify allowed sandboxes here:
if [ "$SFUSER" = '' ]
then
    echo "User not available, exiting..."
    exit
else
    echo "User gathered, continuing"
fi

# Check password and token are set
if [ "$SFPASSWORD" = '' ]
then
    echo "Must specify password & token, exiting..."
    exit
fi

# Specify allowed sandboxes here:
if [ "$ENV" = 'DevStaging' ]
then
    echo "User in allowed list, continuing"
else
    echo "User not in allowed list, exiting..."
    exit
fi


# # Create unique retrieveOutput dir
# EPOCHTIME=`date +%s`
# TEMPDIR="/var/tmp/metadataRetrieveOutput.$EPOCHTIME"
# mkdir $TEMPDIR

# cd into ant build.xml dir where ant jobs are defined
#cd ..

# Generate properties file
echo ""
echo "Generating build.properties..."
PROPERTIES_FILE='build.properties'
cp buildFiles/build.properties.template $PROPERTIES_FILE

# Generate build.xml file
echo ""
echo "Generating build.xml..."
BUILDXML_TEMPLATE='buildFiles/buildnotestrun.template.xml'
BUILDXML_FILE='build.xml'
sed "s@<retrieveOutputDir>@src@g" $BUILDXML_TEMPLATE > $BUILDXML_FILE

if [ "$ENV" = 'Dev' ]
then
    #sed -i "s@manifest/package.xml@$manifest@" $BUILDXML_FILE
    cp manifest/retreivePackage.xml manifest/package.xml
    echo "Updated Retrieve Package to All Component Types for Dev Env"
fi

if [ "$ENV" = 'Prod' ]
then
    cp manifest/retreivePackage.xml manifest/package.xml
    echo "Updated Retrieve Package to All Component Types for Production"
    sed -i "s@^sf\.serverurl\ =\ https\://test\.salesforce\.com@sf\.serverurl\ =\ https\://login\.salesforce\.com@g" $PROPERTIES_FILE
    echo "Updated Properties File for Production"
fi

sed -i "s/<salesforceUser>/$SFUSER/g" $PROPERTIES_FILE
sed -i "s/<salesforcePassword><salesforceToken>/$SFPASSWORD/g" $PROPERTIES_FILE

echo ""
echo $PROPERTIES_FILE
echo "Running retrieve for user $SFUSER"
ant retrieve
ANT_RETRIEVE_RETURN_CODE=$?
echo "***********************************************************************"

if [ "$ANT_RETRIEVE_RETURN_CODE" != '0' ]
then
    echo "ant retrieve failed"
    exit 1
else
    echo "ant retrieve successful"
fi

rm $PROPERTIES_FILE
rm $BUILDXML_FILE
git checkout -- src/package.xml

# The following is required otherwise Bamboo only pushes to the local repo!
git config remote.origin.url "https://github.com/Trigg-Digital/Trigg-Digital-Labs"

# Check whether there are any changes under testdata/talend
git status
# Could add manual approval step here...

git config --global user.email ${GITUSERNAME}
git config --global user.name ${GITUSERNAME}

echo "Git Add --all"
git add --all

echo "Add to Files"
files=$(git diff --name-only --cached)
echo "Files:"
echo $files

echo "*************************************************************"
echo "GIT diff:"
echo ""
git diff --name-only --cached
echo ""
echo "*************************************************************"

if [[ ${#files} -gt 0 ]] ; then
    echo "Files to handle, continue..."
    
    featurepackage=src/package.xml
    
    for file in $files; do
        if [[ "$file" == *".app"* ]]
        then
            metadataType='CustomApplication'
            fileext='.app'
            fileloc='applications'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage
        elif [[ "$file" == *".approvalProcess"* ]]
        then
            metadataType='ApprovalProcess'
            fileext='.approvalProcess'
            fileloc='approvalProcesses'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage
        elif [[ "$file" == *".assignmentRules"* ]]
        then
            metadataType='AssignmentRules'
            fileext='.assignmentRules'
            fileloc='assignmentRules'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage
        elif [[ "$file" == *"/aura/"* ]]
        then        
            metadataType='AuraDefinitionBundle'
            fileloc='aura'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            f="$(basename -- "/"$file)"
            memberfiles="${file/"src/$fileloc/"/""}"
            memberfile="${memberfiles/"/"$f/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage

        elif [["$file" == *".cls-meta"*]]
        then
            echo "Metadata file added"
        elif [[ "$file" == *".cls" ]]
        then
            metadataType='ApexClass'
            fileext='.cls'
            fileloc='classes'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage
        elif [[ "$file" == *".trigger"* ]]
        then
            metadataType='ApexTrigger'
            fileext='.trigger'
            fileloc='triggers'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage
        elif [[ "$file" == *".md"* ]]
        then
            metadataType='CustomMetadata'
            fileext='.md'
            fileloc='customMetadata'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage
        elif [[ "$file" == *".flexipage"* ]]
        then
            metadataType='Flexipage'
            fileext='.flexipage'
            fileloc='flexipage'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage
        elif [[ "$file" == *".flow"* ]]
        then
            metadataType='Flow'
            fileext='.flow'
            fileloc='flows'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage
        elif [[ "$file" == *".layout"* ]]
        then
            metadataType='Layouts'
            fileext='.layout'
            fileloc='layouts'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage
        elif [[ "$file" == *".letter"* ]]
        then
            metadataType='Letterhead'
            fileext='.letter'
            fileloc='letterhead'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage
        elif  [[ "$file" == *"/lwc/"* ]]
        then
            metadataType='LightningComponentBundle'
            fileloc='lwc'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            f="$(basename -- "/"$file)"
            memberfiles="${file/"src/$fileloc/"/""}"
            memberfile="${memberfiles/"/"$f/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage
        elif [[ "$file" == *".object"* ]]
        then
            metadataType='CustomObject'
            fileext='.object'
            fileloc='objects'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage
        elif [[ "$file" == *".pathAssistant"* ]]
        then
            metadataType='PathAssistant'
            fileext='.pathAssistant'
            fileloc='pathAssistant'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage
        elif [[ "$file" == *".permissionset"* ]]
        then
            metadataType='PermissionSet'
            fileext='.permissionset'
            fileloc='permissionsets'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage
        elif [[ "$file" == *".profile"* ]]
        then
            metadataType='Profile'
            fileext='.profile'
            fileloc='profiles'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage 
        elif [[ "$file" == *".queue"* ]]
        then
            metadataType='Queue'
            fileext='.queue'
            fileloc='queues'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage  
        elif [[ "$file" == *".quickActions"* ]]
        then
            metadataType='QuickAction'
            fileext='.quickAction'
            fileloc='quickActions'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage  
        elif [[ "$file" == *".reporttype"* ]]
        then
            metadataType='ReportType'
            fileext='.reporttype'
            fileloc='reportTypes'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage  
        elif [[ "$file" == *".role"* ]]
        then
            metadataType='Role'
            fileext='.role'
            fileloc='roles'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage
        elif [[ "$file" == *".settings"* ]]
        then
            metadataType='Setting'
            fileext='.setting'
            fileloc='settings'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage    
        elif [[ "$file" == *".sharingRules"* ]]
        then
            metadataType='SharingRules'
            fileext='.sharingRules'
            fileloc='sharingRules'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage  
        elif [[ "$file" == *".tab"* ]]
        then
            metadataType='CustomTab'
            fileext='.tab'
            fileloc='tabs'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage     
        elif [[ "$file" == *".workflow"* ]]
        then
            metadataType='Workflow'
            fileext='.workflow'
            fileloc='workflows'
            if grep -q "<name>$metadataType</name>" "$featurepackage" 
            then
                echo "Metadata Type Exists"
            else
                sed -i "s@\t<version>@\t<types>\n\t\t<name>$metadataType</name>\n\t</types>\n\t<version>@g" $featurepackage
                echo "Adding $metadatatype Metadata type to package"
            fi
            member="${file/$fileext/""}"
            memberfile="${member/"src/$fileloc/"/""}"
            sed -i "s@<members>$memberfile</members>@""@g" $featurepackage
            sed -i "s@<name>$metadataType</name>@<members>$memberfile</members>\n\t\t<name>$metadataType</name>@g" $featurepackage  
        else
            echo "$file metadata type not handled"
        fi
    done
    
    sed -i "s@<members>*</members>@""@g" $featurepackage

    cat $featurepackage
    
    
    # The following subdirectories capture all declarative changes (UI-based)
    git add $featurepackage
    git commit -m "Auto-commit - updated Salesforce package.xml"
    
    git push
    
else
    echo "No Files Changed, Exiting ..."
fi
