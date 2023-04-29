@echo off
setlocal EnableDelayedExpansion
echo Loading configuration file...

REM 1. Load configuration file
for /F "eol=; tokens=1* delims==" %%a in ('findstr /v /r /c:"^ *;.*" config.ini') do (
    set %%a=%%b
    echo %%a=%%b
)
echo Configuration file loaded.

REM 2. Check for required plugins and install if necessary
echo Checking for required plugins and installing if necessary...
sfdx plugins --core | findstr /i "sfdx-git-delta" >nul || sfdx plugins:install sfdx-git-delta
sfdx plugins --core | findstr /i "@salesforce/sfdx-scanner" >nul || sfdx plugins:install @salesforce/sfdx-scanner
git --version >nul 2>&1 || (echo Please install Git and restart the script && exit /b 1)
echo Required plugins checked and installed if necessary.

REM 3. Retrieve changes from source sandbox
echo Retrieving changes from !sourceSandbox!...
set RETRIEVE_CHANGES=no
set /p RETRIEVE_CHANGES=Do you want to retrieve changes from !sourceSandbox!? (yes/no):
if /i "%RETRIEVE_CHANGES%"=="yes" goto RETRIEVE_CHANGES_YES
goto RETRIEVE_CHANGES_NO

:RETRIEVE_CHANGES_YES
    set CATEGORIES=!scannerCategories!
    set /p CATEGORIES=Enter categories to retrieve metadata (default: !scannerCategories!):
    echo %CATEGORIES%
    for /f "tokens=*" %%a in ('sfdx force:source:retrieve -o !sourceSandbox! -m !CATEGORIES! --json > retrieve_result.json') do (
        echo %%a
    )
    sfdx force:source:retrieve -o !sourceSandbox! -m !CATEGORIES! --json > retrieve_result.json
    echo Changes retrieved from source sandbox: !RETRIEVE_CHANGES!
goto :checkoutFeatureBranch

:RETRIEVE_CHANGES_NO
goto :checkoutFeatureBranch

:checkoutFeatureBranch
REM 4. Checkout feature branch
set /p TICKET_NUMBER=Enter ticket number:
echo Checking out feature branch...

set FEATURE_BRANCH=!gitprefix!-!TICKET_NUMBER!
set REMOTE_BRANCH=origin/!sourceBranch!
git fetch --all
git stash
git checkout !FEATURE_BRANCH! || git checkout -b !FEATURE_BRANCH! !REMOTE_BRANCH!
if errorlevel 1 (
    echo Error: Could not switch to branch %BRANCH_NAME%. Please review the error, press any key to continue..
    pause
    set "STASH=Use force checkout? Type force or any key to exit (Any local changes will be overriden!!!)
    if /i "!STASH!" == "force" (
        git checkout !FEATURE_BRANCH! --force || git checkout -b !FEATURE_BRANCH! !REMOTE_BRANCH! --force
    )
) else (
    echo Successfully switched to branch %BRANCH_NAME%.
    git stash pop
)
echo Feature branch checked out: !FEATURE_BRANCH!


REM 5. Commit changes
set /p COMMIT_CHANGES=Do you want to commit changes? (yes/no):
if /i "!COMMIT_CHANGES!"=="yes" (
    goto :commitChanges
) else (
    goto :validateAndDeploy
)

:commitChanges
echo Please commit your changes using the built-in Git functionality of your IDE.
echo Press any key to continue once you have committed the changes...
    pause >nul
goto :validateAndDeploy

:validateAndDeploy
REM 6. Validate and deploy changes to source sandbox
echo Validating and deploying changes to source sandbox...
if not exist delta mkdir delta
for /f "tokens=*" %%a in ('sfdx sgd:source:delta -f "!FEATURE_BRANCH!" -t "origin/!targetBranch!" --output "!packageXmlPath!"') do (
    echo %%a
)
set TESTS_RUN="None"
set /p TESTS_RUN=Which tests do you want to run? (All/None/Some/SpecifiedTests):
if /i "!TESTS_RUN!"=="Some" (
    goto :someTests
) else (
    goto :deploy
)

:someTests
set /p TEST_CLASSES=Enter comma-separated test classes:
sfdx force:source:deploy -u %sourceSandbox% -x %SFDX_GIT_DELTA_PACKAGE_XML% -c --testlevel !TESTS_RUN!:!TEST_CLASSES!
echo Validation and deployment to source sandbox completed.
goto :scanner

:deploy
sfdx force:source:deploy -u %sourceSandbox% -x %SFDX_GIT_DELTA_PACKAGE_XML% -c --testlevel !TESTS_RUN!
goto :scanner

:scanner
if /i "%SCANNER_ENABLED%"=="yes" (
    sfdx sfdx-scanner:run --format xml --outfile scan-results.xml %scannerOptions%
)

REM 7. Check which test classes to run

set "testClassesFiles=%SFDX_PROJECT_DIR%\**\*Test.cls"
set "testClassesToAdd="
for /f "tokens=*" %%i in ('type "%SFDX_GIT_DELTA_PACKAGE_XML%" ^| findstr /c:"<members>.*Test"') do (
    set "testClassName=%%~ni"
    set "testClassName=%testClassName:~0,-4%"
    findstr /i /c:"@IsTest" "%SFDX_PROJECT_DIR%\**\%%i" > nul && set "TEST_CLASSES=!TEST_CLASSES!,%testClassName%"
)
for /f "tokens=*" %%i in ('powershell "Get-ChildItem '%testClassesFiles%' -Exclude '*Exception*' -Exclude '*_TEMPLATE*' -Recurse -Name | ForEach-Object { $_.Substring($_.IndexOf('\\') + 1) }"') do (
    set "testClassName=%%~ni"
    set "testClassName=%testClassName:~0,-4%"
    findstr /i /c:"@IsTest" "%SFDX_PROJECT_DIR%\**\%%i" > nul && set "testClassesToAdd=!testClassesToAdd!,%testClassName%"
)
if not "%testClassesToAdd%"=="" (
    echo.
    echo The following test classes were found in the project files:
    echo %testClassesToAdd:~1%
    set /p ADDITIONAL_TEST_CLASSES=Do you want to add any of these test classes to the list of test classes to run? (leave empty if not applicable):
    if not "%ADDITIONAL_TEST_CLASSES%"=="" set TEST_CLASSES=!TEST_CLASSES!,%ADDITIONAL_TEST_CLASSES%
)

set "TEST_CLASSES=%TEST_CLASSES:~1%"
set /p TEST_SUITE=Please enter the name of the test suite to run (leave empty if not applicable):
if not "%TEST_SUITE%"=="" set TEST_SUITE=-n %TEST_SUITE%
set TEST_CLASSES=%TEST_CLASSES%%TEST_SUITE%

REM 8. Push changes to feature branch
set /p PUSH_CHANGES=Do you want to push changes to %FEATURE_BRANCH% branch? (yes/no):
if /i "%PUSH_CHANGES%"=="yes" (
    git push origin %FEATURE_BRANCH%
)

REM 9. Check if pull request exists, validate and deploy changes to target sandbox and create pull request if needed
set CHECK_ONLY=yes
set CREATE_PULL_REQUEST=yes

REM Check if pull request exists
for /f "tokens=* USEBACKQ" %%a in (`curl -s -H "Authorization: token %GITHUB_TOKEN%" https://api.github.com/repos/%GITHUB_ORGANIZATION%/%GITHUB_REPO%/pulls?state=open`) do (
    set RESPONSE_CONTENT=%%a
)
echo %RESPONSE_CONTENT% | findstr /c:"\"head\": { \"ref\": \"%FEATURE_BRANCH%\"" > nul && set CREATE_PULL_REQUEST=no


if /i "%CREATE_PULL_REQUEST%"=="yes" (
    goto create_pull_request
) else (
    goto deploy_changes
)

:create_pull_request
set /p REVIEWER=Please enter the reviewer of the pull request:
set /p TITLE=Please enter the title of the pull request:
REM Create pull request
curl -i -H "Authorization: token %GITHUB_TOKEN%" -H "Content-Type: application/json" -X POST -d "{\"title\":\"%TITLE%\",\"head\":\"%FEATURE_BRANCH%\",\"base\":\"%TARGET_BRANCH%\",\"body\":\"Pull request auto generated by script\",\"reviewers\":[\"%REVIEWER%\"]}" https://api.github.com/repos/%GITHUB_ORGANIZATION%/%GITHUB_REPO%/pulls

goto deploy_changes

:deploy_changes
sfdx force:source:deploy -p %SFDX_GIT_DELTA_PACKAGE_XML% -u %targetSandbox% -l %TEST_LEVEL% -c %CHECK_ONLY% %scannerOptions% %testClassesOption% %testSuiteOption%

if /i "%TARGET_TESTS_RUN%"=="Some" (
    goto get_deployment_status
) else (
    goto end_script
)

:get_deployment_status
REM Get deployment status
sfdx force:mdapi:deploy:report -u %targetSandbox% -c -w 5 -

goto end_script

:end_script