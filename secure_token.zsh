#!/bin/zsh

echo "
 ▗▄▄▖▗▄▄▄▖ ▗▄▄▖▗▖ ▗▖▗▄▄▖ ▗▄▄▄▖    ▗▄▄▄▖▗▄▖ ▗▖ ▗▖▗▄▄▄▖▗▖  ▗▖    ▗▄▄▄▖▗▄▄▄▖▗▖  ▗▖
▐▌   ▐▌   ▐▌   ▐▌ ▐▌▐▌ ▐▌▐▌         █ ▐▌ ▐▌▐▌▗▞▘▐▌   ▐▛▚▖▐▌    ▐▌     █   ▝▚▞▘ 
 ▝▀▚▖▐▛▀▀▘▐▌   ▐▌ ▐▌▐▛▀▚▖▐▛▀▀▘      █ ▐▌ ▐▌▐▛▚▖ ▐▛▀▀▘▐▌ ▝▜▌    ▐▛▀▀▘  █    ▐▌  
▗▄▄▞▘▐▙▄▄▖▝▚▄▄▖▝▚▄▞▘▐▌ ▐▌▐▙▄▄▖      █ ▝▚▄▞▘▐▌ ▐▌▐▙▄▄▖▐▌  ▐▌    ▐▌   ▗▄█▄▖▗▞▘▝▚▖
                                                                               
                                                                               
                                                                               
"
echo "Made with love by Ryan Sinclair & Brady Hodge

"
echo "V 1.3.2

"
# Ask for the username and save to a varable for later use
echo "Enter the user's profile name: "
read USERNAME

# Ask for the user password and save
echo "Enter the user's password: "
read -s USER_PASSWORD

# Ask for admin username and save
echo "Enter the local admin username: "
read ADMIN_USERNAME

# Ask for the admin password save
echo "Enter the local admin password: "
read -s ADMIN_PASSWORD

# Check if SecureToken is already disabled
# If it has alredy disabled, skip this step and renable
SECURE_TOKEN_STATUS=$(sysadminctl -secureTokenStatus $USERNAME 2>&1)

if [[ $SECURE_TOKEN_STATUS == *"DISABLED"* ]]; then
    echo "SecureToken is already disabled for $USERNAME. Proceeding to re-enable."
else
    # Disable SecureToken for the saved user and dump the output
    echo "Disabling SecureToken..."
    SECURE_TOKEN_OFF_RESULT=$(sysadminctl -secureTokenOff $USERNAME -password $USER_PASSWORD -adminUser $ADMIN_USERNAME -adminPassword $ADMIN_PASSWORD 2>&1)

    # Check if SecureToken was successfully disabled
    if [[ $SECURE_TOKEN_OFF_RESULT != *"Done"* ]]; then
        echo "Failed to disable SecureToken. Preboot Volume not updated."
        echo "Error: $SECURE_TOKEN_OFF_RESULT"
        echo " (Tip: Check if both the local admin and user's passwords are correct)"
        exit 1
    fi

    echo "SecureToken successfully disabled"
fi

# Re-enable SecureToken for the user and cap the output
echo "Re-enabling SecureToken..."
SECURE_TOKEN_ON_RESULT=$(sysadminctl -secureTokenOn $USERNAME -password $USER_PASSWORD -adminUser $ADMIN_USERNAME -adminPassword $ADMIN_PASSWORD 2>&1)

# Check if SecureToken was successfully re-enabled
if [[ $SECURE_TOKEN_ON_RESULT == *"Done"* ]]; then
    echo "SecureToken successfully re-enabled"

    # Update Preboot Volume and capture the output
    echo "Updating Preboot Volume..."
    PREBOOT_UPDATE_RESULT=$(diskutil apfs UpdatePreboot / 2>&1)

    # Check if the Preboot Volume update was successful
    if [[ $PREBOOT_UPDATE_RESULT == *"Finished APFS operation"* ]]; then
        echo "Preboot Volume update completed successfully"
    else
        # No idea where the output goes prob the system log
        echo "Preboot Volume update may have encountered issues. Please check the system logs for details."
    fi
else
    echo "Failed to re-enable SecureToken. Preboot Volume not updated."
    echo "Error: $SECURE_TOKEN_ON_RESULT"
    echo " (Tip: Check if the local admin is actually an admin in users and groups)"
fi
