#!/bin/bash

# Script arguments (passed in as Git build vars)
# $1 = <sandboxName>
# $2 = <salesforceUser>
# $3 = <salesforcePassword>
# $4 = <salesforceToken>
# $5 = <checkOnly:1=True,0=False>
# $6 = <testLevel:....>

SANDBOX_NAME="${SANDBOX_NAME}"
SFUSER="${SFUSER}"
SFPASSWORD="${SFPASSWORD}"
CHECKONLY="${CHECKONLY}"
TESTLEVEL="${TESTLEVEL}"

echo "DEBUG: SANDBOX_NAME is ${SANDBOX_NAME}"
echo "DEBUG: SFUSER is ${SFUSER}"
echo "DEBUG: SFPASSWORD is ${SFPASSWORD}"
echo "DEBUG: CHECKONLY is ${CHECKONLY}"
echo "DEBUG: TESTLEVEL is ${TESTLEVEL}"
echo ""
echo "Debug: SANDBOX_NAME is $SANDBOX_NAME"
echo "Debug: SFUSER is $SFUSER"

# Validate arguments

#if [[ "$SANDBOX_NAME" =~ ^("QA" | "UAT" | "DEV" | "CI" )$ ]]
#then
#  echo "Sandbox in allowed list, continuing"
#else
#  echo "Sandbox not in allowed list, exiting..."
#  exit 1
#fi

if [ "$SFUSER" = '' ] || [ "$SFPASSWORD" = '' ]
then
  echo "Must specify user, password & token, exiting..."
  exit 1
fi

# Leaving this in to prevent changing bamboo however, this checkOnly variable seems to have no effect
if [ "$CHECKONLY" = 'true' ] || [ "$CHECKONLY" = 'false' ]
then
  echo "checkOnly set to $CHECKONLY"
else
  echo "checkOnly must be set to either 1 (True) or (False)"
  exit 1
fi

if [ "$TESTLEVEL" = 'NoTestRun' ] || [ "$TESTLEVEL" = 'RunLocalTests' ] || [ "$TESTLEVEL" = 'RunAllTestsInOrg' ] || [ "$TESTLEVEL" = 'RunSpecifiedTests' ]
then
  echo "testLevel set to $TESTLEVEL"
else
  echo "testLevel must be one of NoTestRun|RunLocalTests|RunAllTestsInOrg|RunSpecifiedTests"
  exit 1
fi

TEMPLATE_DIR='..'

if [ "$TESTLEVEL" = 'RunLocalTests' ] || [ "$TESTLEVEL" = 'RunSpecifiedTests' ]
then

  SPECTESTSFILE='manifest/specifictests.xml'
  sed -i "s|\n||g" $SPECTESTSFILE

  cat $SPECTESTSFILE

  BUILDXML_TEMPLATE_FILE='buildFiles/buildrunspecifictests.template.xml'
  SPECTESTS="$(tr '\n' '\r' < $SPECTESTSFILE)"
  #SPECTESTS='Test'
  echo "Specified Tests: "
  echo $SPECTESTS
  sed -i "s|<runTest><\/runTest>|$SPECTESTS|g" $BUILDXML_TEMPLATE_FILE | tr '\r' '\n'
  if [ BUILDXML_TEMPLATE_FILE != '' ]
  then
    echo "File Found"
  fi
elif [ "$TESTLEVEL" = 'NoTestRun' ]
then
  BUILDXML_TEMPLATE_FILE='buildFiles/buildnotestrun.template.xml'
  if [ BUILDXML_TEMPLATE_FILE != '' ]
  then
    echo "File Found"
  fi
else
  echo "no build.xml template exists for test level $TESTLEVEL, exiting."
  exit 1
fi

  echo "***********************************************************************"
  echo "Build Template File"
  echo ""
  cat $BUILDXML_TEMPLATE_FILE
  echo "***********************************************************************"

if [ "$TESTLEVEL" = 'NoTestRun' ] && [ "$SANDBOX_NAME" = 'Pre-Production' ]; 
then
  echo "testLevel can not be set to NoTestRun when deploying in to Pre-Production"
else
  echo "testLevel correct Levels for SBX"
fi

BUILDXML_FILE="build.xml"
BUILDPROPERTIES_TEMPLATE_FILE='buildFiles/build.properties.template'
BUILDPROPERTIES_FILE="build.properties"
#cd $TEMPLATE_DIR
cp $BUILDXML_TEMPLATE_FILE $BUILDXML_FILE
# This is used by the retrieveMetadataAndPushToGit script but needs to be replaced to pass validation"
sed -i "s@<retrieveOutputDir>@retrieveOutput@g" $BUILDXML_FILE

if [ "$SANDBOX_NAME" = 'Production' ] || [ "$SANDBOX_NAME" = 'Pre-Production' ]
then
  sed -i 's/purgeOnDelete="true"/purgeOnDelete="false"/g' $BUILDXML_FILE
  echo "***********************************************************************"
  echo "DEBUG:updated build xml file as follows"
  cat $BUILDXML_FILE
  echo "***********************************************************************"
fi

cp $BUILDPROPERTIES_TEMPLATE_FILE $BUILDPROPERTIES_FILE
if [ "$SANDBOX_NAME" = 'Production' ]
then
  sed -i "s/<salesforceUser>/$SFUSER/g" $BUILDPROPERTIES_FILE
  sed -i "s@^sf\.serverurl\ =\ https\://test\.salesforce\.com@sf\.serverurl\ =\ https\://login\.salesforce\.com@g" $BUILDPROPERTIES_FILE
else
  sed -i "s/<salesforceUser>/$SFUSER/g" $BUILDPROPERTIES_FILE
fi
sed -i "s/<salesforcePassword><salesforceToken>/$SFPASSWORD/g" $BUILDPROPERTIES_FILE
sed -i "s@<checkOnly>@$CHECKONLY@g" $BUILDPROPERTIES_FILE
sed -i "s@<testLevel>@$TESTLEVEL@g" $BUILDPROPERTIES_FILE

echo "***********************************************************************"
echo "DEBUG:updated properties file as follows"
cat $BUILDPROPERTIES_FILE
echo "***********************************************************************"

# Copy package.xml into src dir
#cp manifest/package.xml src/package.xml

# Copy destructuveChanges.xml into src directory
cp manifest/destructiveChangesPre.xml src/destructiveChangesPre.xml
cp manifest/destructiveChangesPost.xml src/destructiveChangesPost.xml


echo "***********************************************************************"
echo "Deploying metadata to $SANDBOX_NAME"
ant deploy
ANT_DEPLOY_RETURN_CODE=$?
echo "***********************************************************************"

if [ "$ANT_DEPLOY_RETURN_CODE" != '0' ]
then
  echo "ant deploy to $SANDBOX_NAME failed"
  exit 1
else
  echo "ant deploy to $SANDBOX_NAME successful"
fi
