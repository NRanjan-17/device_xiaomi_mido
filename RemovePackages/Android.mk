LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := RemovePackages
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_TAGS := optional
LOCAL_OVERRIDES_PACKAGES := Maps Drive PrebuiltGmail YouTube 
LOCAL_OVERRIDES_PACKAGES += AiWallpapers AICorePrebuilt Photos 
LOCAL_OVERRIDES_PACKAGES += SecureElement SoundAmplifierPrebuilt
LOCAL_OVERRIDES_PACKAGES += NfcNci talkback DeviceAsWebcam
LOCAL_UNINSTALLABLE_MODULE := true
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_SRC_FILES := /dev/null
include $(BUILD_PREBUILT)
