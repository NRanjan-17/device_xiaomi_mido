LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := RemovePackages
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_TAGS := optional
LOCAL_OVERRIDES_PACKAGES := Maps Drive PrebuiltGmail YouTube GoogleTTS SoundAmplifierPrebuilt Photos GoogleCamera arcore talkback FilesPrebuilt RecorderPrebuilt FM2 GoogleDialer Chrome PixelLiveWallpaperPrebuilt NexusLauncherRelease Phonesky
LOCAL_UNINSTALLABLE_MODULE := true
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_SRC_FILES := /dev/null
include $(BUILD_PREBUILT)

