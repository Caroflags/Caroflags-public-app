#!/bin/bash

# 1. Asks if you updated the build number
read -p "Did you update the build number? (y/n): " answer

if [[ "$answer" != "y" && "$answer" != "Y" && "$answer" != "yes" && "$answer" != "Yes" ]]; then
    echo "You are stupid."
    exit 1
fi

echo "Starting builds in parallel..."

# 2. Compile wearOS, Android, and web on different threads
flutter build appbundle --flavor wear -t lib/main_wear.dart &
WEAR_PID=$!

flutter build appbundle --flavor phone &
PHONE_PID=$!

flutter build web --release &
WEB_PID=$!

# Wait for all of them to finish
wait $WEAR_PID
WEAR_STATUS=$?

wait $PHONE_PID
PHONE_STATUS=$?

wait $WEB_PID
WEB_STATUS=$?

if [[ $WEAR_STATUS -ne 0 || $PHONE_STATUS -ne 0 || $WEB_STATUS -ne 0 ]]; then
    echo "One or more builds failed. Aborting deployment."
    exit 1
fi

# 3. Deploy to Firebase
echo "All builds completed successfully! Deploying to Firebase..."
firebase deploy
