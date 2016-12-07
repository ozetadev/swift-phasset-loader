# swift-phasset-loader
Load assets from a users camera roll, and manage permissions. Simple class, on first attempt to access photos, user will be prompted to grant you permission (make sure you have the correct privacy settings in your Info.plist). Callbacks will return either content in the form of a PHAsset (Photos library) or an error if you are not granted permission.
