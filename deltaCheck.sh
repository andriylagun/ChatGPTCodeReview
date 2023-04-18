#!/usr/bin/env sh

# Define required plugins
REQUIRED_PLUGINS=(
  "salesforce-alm"
  "@salesforce/sfdx-scanner"
  "sfdx-git-delta"
)
CONFIG_FILE=config.yml
parse_yaml() {
    local prefix=$2
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
    sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
         -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$1" |
    awk -F$fs '{
        indent = length($1)/2;
        vname[indent] = $2;
        for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
        }
    }'
}
# Check if plugins are installed and install if necessary
for PLUGIN in "${REQUIRED_PLUGINS[@]}"; do
  if ! sfdx plugins --core | grep -q "$PLUGIN"; then
    echo "Installing $PLUGIN..."
    sfdx plugins:install "$PLUGIN"
  fi
done


if ! command -v hub &> /dev/null
then
    echo "hub could not be found"

    if [[ "$OSTYPE" == "msys"* ]]; then
        echo "Installing hub via curl"
        curl -L -o hub.zip https://github.com/github/hub/releases/download/v2.14.2/hub-windows-amd64-2.14.2.zip
        unzip hub.zip
        mv hub-windows-amd64-2.15.1/bin/hub /usr/bin/hub
        rm -rf hub.zip hub-windows-amd64-2.15.1
    else
        echo "Unsupported operating system, install 'hub' manually"
        exit 1
    fi
fi

if ! command -v git &> /dev/null
then
    echo "Git is not installed. Please install git and try again."
    exit
fi



if [ ! -f "$CONFIG_FILE" ]; then
  echo "Configuration file not found: $CONFIG_FILE"
  exit 1
fi
eval $(parse_yaml config.yml "")



read -p "Would you like to retrieve changes from a dev sandbox? (y/n) " RETRIEVE_CHANGES
if [ "$RETRIEVE_CHANGES" = "y" ]; then
  if [ -z "$categories" ]; then
    read -p "Please enter the categories to search for changes: " categories
  fi
  read -p "Would you like to use @salesforce/sfdx-scanner to scan for code style issues? (y/n) " SCAN_CODE_STYLE
  sfdx force:source:retrieve -s -u $devSandbox -m "ApexClass,ApexTrigger" -c $categories
  if [ "$SCAN_CODE_STYLE" = "y" ]; then
    sfdx scanner:run --target "**/*.cls" --target "**/*.trigger"
  fi
fi

feature_branch="$gitprefix-$ticketNumber"

if git branch | grep -q "$feature_branch"; then
    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
        echo "Cannot find HEAD commit. Exiting..."
        exit 1
    fi
    if [[ "$(git symbolic-ref --short HEAD)" != "$feature_branch" ]]; then
        git checkout "$feature_branch"
    fi
else
    git checkout -b "$feature_branch" "origin/$remoteBranch" || exit 1
fi


# Пропонуємо закомітити зміни
echo "Do you want to commit the changes? (y/n)"
read commit_changes

# Якщо користувач погоджується з коммітом, то комітимо зміни з повідомленням
if [ "$commit_changes" = "y" ]; then
    # Використовуємо git add, щоб додати всі зміни до коміту
    git add .

    # Пропонуємо ввести повідомлення для коміту
    echo "Enter commit message:"
    read commit_message

    # Комітимо зміни з вказаним повідомленням
    git commit -m "$commit_message"
fi

# Step 6: Validate differences between featureBranch and sourceBranch using sfdx-git-delta package.xml, and deploy with specified parameters

# Check if $testsRun ~= "RunSpecifiedTests" to get list of test classes from package.xml and scan triggers and classes categories for Test suffix
if [[ $testsRun =~ ^RunSpecifiedTests$ ]]
then
  echo "Getting list of test classes from package.xml"
  testClasses=($(grep -o -P "(?<=<members>).*(?=</members>)" manifest/package.xml | grep "Test"))
  echo "Scanning triggers and classes categories for Test suffix"
  for file in $(sfdx force:source:retrieve -m ApexTrigger,ApexClass --json | jq -r '.result[].files | keys[]')
  do
    fileName=$(basename $file)
    if [[ $fileName == *"Trigger"* || $fileName == *"Test"* ]]
    then
      continue
    fi
    className=$(basename $file .cls)
    isTestClass=$(grep -c "$className$" <<< "${testClasses[@]}")
    if [ $isTestClass -eq 1 ]
    then
      continue
    fi
    testClass="${className}Test"
    isTestClass=$(grep -c "$testClass$" <<< "${testClasses[@]}")
    if [ $isTestClass -eq 1 ]
    then
      continue
    fi
    if [ -f "$file" ]
    then
      echo "$file does not have a corresponding test class"
      exit 1
    fi
  done
fi

#Step 6:  Deploy with specified parameters
sfdx force:source:deploy -x manifest/package.xml -c -l $testLevel -r $testsRun --json --loglevel fatal --sourcebranch $sourceBranch --targetusername $targetOrgAlias --checkonly $checkonly > deploy_output.json

if grep -q "\"status\": 0" deploy_output.json; then
        echo "Deployment succeeded"
    else
        echo "Deployment failed"
    fi

# Step 7: Confirm git push to $featureBranch with $gitprefix-$ticketNumber combination
echo "Confirming git push to $featureBranch with $gitprefix-$ticketNumber combination"
read -p "Are you sure you want to push changes to $featureBranch? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push origin $featureBranch
fi

# Step 8: Validate and deploy from $featureBranch to $targetSandbox
echo "Validating and deploying changes from $featureBranch to $targetSandbox"
delta="$(sfdx git:delta -r $featureBranch -x manifest/package.xml -c -q)"
if [[ "$delta" == *"No changes found"* ]]; then
    echo "No changes found between $featureBranch and $targetBranch, skipping validation and deployment"
else
    # Check if there's an existing pull request from $featureBranch to $targetBranch
    pr_id="$(hub pr list -h $featureBranch -b $targetBranch -f '%I')"
    if [[ -z "$pr_id" ]]; then
        # Create a new pull request with $featureBranch as the head and $targetBranch as the base
        echo "Creating new pull request for $featureBranch -> $targetBranch"
        hub pull-request -h $featureBranch -b $targetBranch -r $reviewer
    fi
    # Deploy changes to $targetSandbox and run tests specified in config
    sfdx force:source:deploy -x manifest/package.xml -c -l RunSpecifiedTests -r $testsRun --json --loglevel fatal --sourcebranch $sourceBranch --targetusername $targetOrgAlias --checkonly $checkonly > deploy_output.json
    # Check if deployment succeeded
    if grep -q "\"status\": 0" deploy_output.json; then
        echo "Deployment succeeded"
        pr_check_result="Success"
    else
        echo "Deployment failed"
        pr_check_result="Fail"
        # Get the names of the files that failed and add a comment to the PR
        failed_files="$(grep -oP '\"fullName\":\"\K[^\"]+' deploy_output.json)"
        hub issue comment $pr_id -m "Deployment failed. Failed files: $failed_files"
    fi
    # Add the result of the check to the PR name
    pr_title="$(hub pr show -f '%t' $pr_id)"
    hub pr edit -m "$pr_title [$pr_check_result]" $pr_id
fi

