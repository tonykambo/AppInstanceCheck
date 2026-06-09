## Overview
A small app to test techniques for identyfing an app instance under certain scenarios.

1. Delete the app and reinstall - detect if the app was previously installed on the device based on persisted UUID in keychain.
2. Perform iOS Quick Start - determine if app is launched on Quick Start copy of device based on documents folder timestamp compared to initial app registration. 
