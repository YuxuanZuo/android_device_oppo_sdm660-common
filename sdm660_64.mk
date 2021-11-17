ALLOW_MISSING_DEPENDENCIES := true
TARGET_USES_AOSP := true

TARGET_BOARD_PLATFORM := sdm660
TARGET_BOARD_SUFFIX := _64

# Default vendor configuration.
ifeq ($(ENABLE_VENDOR_IMAGE),)
ENABLE_VENDOR_IMAGE := true
endif

# Default A/B configuration.
ENABLE_AB ?= true

# Disable QTIC until it's brought up in split system/vendor
# configuration to avoid compilation breakage.
ifeq ($(ENABLE_VENDOR_IMAGE), true)
#TARGET_USES_QTIC := false
endif

TARGET_USES_AOSP_FOR_AUDIO := false
TARGET_ENABLE_QC_AV_ENHANCEMENTS := true
TARGET_DISABLE_DASH := true

ifneq ($(wildcard kernel/msm-4.19),)
    TARGET_KERNEL_VERSION := 4.19
    $(warning "Build with 4.19 kernel.")
else ifneq ($(wildcard kernel/msm-4.4),)
    TARGET_KERNEL_VERSION := 4.4
    $(warning "Build with 4.4 kernel.")
else
    $(warning "Unknown kernel")
endif

# Set GRF/Vendor freeze properties
BOARD_SHIPPING_API_LEVEL := 30
BOARD_API_LEVEL := 30

# Enable RRO for Android R
ifeq ($(strip $(TARGET_KERNEL_VERSION)), 4.19)
    TARGET_USES_RRO := true
endif

ifeq ($(TARGET_KERNEL_VERSION),$(filter $(TARGET_KERNEL_VERSION),4.14 4.19))
  SHIPPING_API_LEVEL :=30
  ifeq (true,$(call math_gt_or_eq,$(SHIPPING_API_LEVEL),29))
    # Dynamic-partition enabled by default for new launch config
    BOARD_DYNAMIC_PARTITION_ENABLE := true
    # First launch API level
    PRODUCT_SHIPPING_API_LEVEL := $(SHIPPING_API_LEVEL)
    # Enable virtual-ab by default
    ENABLE_VIRTUAL_AB := true
    # Enable incremental FS feature
    PRODUCT_PROPERTY_OVERRIDES += ro.incremental.enable=1
  else
    BOARD_DYNAMIC_PARTITION_ENABLE := false
    $(call inherit-product, build/make/target/product/product_launched_with_p.mk)
  endif
else
  SHIPPING_API_LEVEL :=28
  BOARD_DYNAMIC_PARTITION_ENABLE := false
  $(call inherit-product, build/make/target/product/product_launched_with_p.mk)
endif

ifeq (true,$(call math_gt_or_eq,$(SHIPPING_API_LEVEL),29))
 # f2fs utilities
 PRODUCT_PACKAGES += \
     sg_write_buffer \
     f2fs_io \
     check_f2fs

 # Userdata checkpoint
 PRODUCT_PACKAGES += \
     checkpoint_gc

 ifeq ($(ENABLE_AB), true)
 AB_OTA_POSTINSTALL_CONFIG += \
     RUN_POSTINSTALL_vendor=true \
     POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
     FILESYSTEM_TYPE_vendor=ext4 \
     POSTINSTALL_OPTIONAL_vendor=true
 endif
endif

# Include mainline components
ifeq (true,$(call math_gt_or_eq,$(SHIPPING_API_LEVEL),29))
  PRODUCT_ENFORCE_ARTIFACT_PATH_REQUIREMENTS := true
endif

# New launch config
ifeq ($(strip $(BOARD_DYNAMIC_PARTITION_ENABLE)),true)
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_PACKAGES += fastbootd
# Add default implementation of fastboot HAL.
PRODUCT_PACKAGES += android.hardware.fastboot@1.0-impl-mock
ifeq ($(ENABLE_AB), true)
PRODUCT_COPY_FILES += $(LOCAL_PATH)/default/fstab_AB_dynamic_partition_variant.qti:$(TARGET_COPY_OUT_RAMDISK)/fstab.default
PRODUCT_COPY_FILES += $(LOCAL_PATH)/emmc/fstab_AB_dynamic_partition_variant.qti:$(TARGET_COPY_OUT_RAMDISK)/fstab.emmc
else
PRODUCT_COPY_FILES += $(LOCAL_PATH)/default/fstab_non_AB_dynamic_partition_variant.qti:$(TARGET_COPY_OUT_RAMDISK)/fstab.default
PRODUCT_COPY_FILES += $(LOCAL_PATH)/emmc/fstab_non_AB_dynamic_partition_variant.qti:$(TARGET_COPY_OUT_RAMDISK)/fstab.emmc
endif

BOARD_AVB_ENABLE := true

# Enable product partition
PRODUCT_BUILD_PRODUCT_IMAGE := true
# Enable System_ext
PRODUCT_BUILD_SYSTEM_EXT_IMAGE := true
# Enable vbmeta_system
BOARD_AVB_VBMETA_SYSTEM := system product system_ext
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2
$(call inherit-product, build/make/target/product/gsi_keys.mk)
endif
# End New launch config

TARGET_SYSTEM_PROP := device/qcom/sdm660_64/system.prop

DEVICE_PACKAGE_OVERLAYS := device/qcom/sdm660_64/overlay

# Disable QTIC until it's brought up in split system/vendor
# configuration to avoid compilation breakage.
ifeq ($(ENABLE_VENDOR_IMAGE), true)
#TARGET_USES_QTIC := false
endif

ifeq ($(ENABLE_VIRTUAL_AB), true)
    $(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)
endif

TARGET_USES_AOSP_FOR_AUDIO := false
TARGET_ENABLE_QC_AV_ENHANCEMENTS := true
TARGET_DISABLE_DASH := true

ifeq ($(TARGET_KERNEL_VERSION),$(filter $(TARGET_KERNEL_VERSION),4.14 4.19))
#Enable llvm support for kernel
KERNEL_LLVM_SUPPORT := true

#Enable sd-llvm support for kernel
KERNEL_SD_LLVM_SUPPORT := true

#Enable libion support
LIBION_PATH_INCLUDES := true
endif

BOARD_FRP_PARTITION_NAME := frp

# enable the SVA in UI area
TARGET_USE_UI_SVA := true

#QTIC flag
-include $(QCPATH)/common/config/qtic-config.mk

# Add soft home, back and multitask keys
PRODUCT_PROPERTY_OVERRIDES += \
    qemu.hw.mainkeys=0

# Video codec configuration files
ifeq ($(TARGET_ENABLE_QC_AV_ENHANCEMENTS), true)
PRODUCT_COPY_FILES += \
    device/qcom/sdm660_64/media_profiles.xml:system/etc/media_profiles.xml \
    device/qcom/sdm660_64/media_profiles_sdm660_v1.xml:system/etc/media_profiles_sdm660_v1.xml \
    device/qcom/sdm660_64/media_profiles.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_vendor.xml \
    device/qcom/sdm660_64/media_profiles_sdm660_v1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_sdm660_v1.xml \
    device/qcom/sdm660_64/media_codecs.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs.xml \
    device/qcom/sdm660_64/media_codecs_vendor.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_vendor.xml \
    device/qcom/sdm660_64/media_codecs_sdm660_v1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_sdm660_v1.xml \
    device/qcom/sdm660_64/media_codecs_performance.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_performance.xml \
    device/qcom/sdm660_64/media_codecs_performance_sdm660_v1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_performance_sdm660_v1.xml \
    device/qcom/sdm660_64/media_codecs_vendor_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_vendor_audio.xml \
    device/qcom/common/media/media_profiles.xml:$(TARGET_COPY_OUT_ODM)/etc/media_profiles_V1_0.xml

# Vendor property overrides
  PRODUCT_PROPERTY_OVERRIDES += debug.stagefright.omx_default_rank=0
endif #TARGET_ENABLE_QC_AV_ENHANCEMENTS

PRODUCT_PROPERTY_OVERRIDES += persist.vendor.camera.dual.isp.sync=0

PRODUCT_PROPERTY_OVERRIDES += persist.vendor.usb.config=diag,serial_cdev,rmnet,adb

# video seccomp policy files
PRODUCT_COPY_FILES += \
    device/qcom/sdm660_64/seccomp/mediacodec-seccomp.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediacodec.policy \
    device/qcom/sdm660_64/seccomp/mediaextractor-seccomp.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediaextractor.policy


PRODUCT_PROPERTY_OVERRIDES += \
    vendor.video.disable.ubwc=1

ifneq ($(TARGET_DISABLE_DASH), true)
    PRODUCT_BOOT_JARS += qcmediaplayer
endif

# split init.target.rc to support OTA and new launch targets
ifeq ($(strip $(BOARD_DYNAMIC_PARTITION_ENABLE)),true)
PRODUCT_PACKAGES += \
    init.target_dap.rc
else
PRODUCT_PACKAGES += \
    init.target_ota.rc
endif

ifeq (false,$(call math_gt_or_eq,$(SHIPPING_API_LEVEL),29))
# Power
PRODUCT_PACKAGES += \
    android.hardware.power@1.0-service \
    android.hardware.power@1.0-impl
endif

# privapp-permissions whitelisting
PRODUCT_PROPERTY_OVERRIDES += ro.control_privapp_permissions=enforce

# Override heap growth limit due to high display density on device
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.heapgrowthlimit=256m
$(call inherit-product, frameworks/native/build/phone-xhdpi-2048-dalvik-heap.mk)
$(call inherit-product, device/qcom/common/common64.mk)

PRODUCT_NAME := sdm660_64
PRODUCT_DEVICE := sdm660_64
PRODUCT_BRAND := qti
PRODUCT_MODEL := sdm660 for arm64

# default is nosdcard, S/W button enabled in resource
PRODUCT_CHARACTERISTICS := nosdcard

# When can normal compile this module,  need module owner enable below commands
# font rendering engine feature switch
#-include $(QCPATH)/common/config/rendering-engine.mk
#ifneq (,$(strip $(wildcard $(PRODUCT_RENDERING_ENGINE_REVLIB))))
#    MULTI_LANG_ENGINE := REVERIE
#    MULTI_LANG_ZAWGYI := REVERIE
#endif

# Enable features in video HAL that can compile only on this platform
TARGET_USES_MEDIA_EXTENSIONS := true

#
# system prop for opengles version
#
# 196610 is decimal for 0x30002 to report major/minor versions as 3/2
PRODUCT_PROPERTY_OVERRIDES += \
    ro.opengles.version=196610

#Android EGL implementation
PRODUCT_PACKAGES += libGLES_android
PRODUCT_BOOT_JARS += tcmiface
PRODUCT_BOOT_JARS += telephony-ext

PRODUCT_PACKAGES += telephony-ext

ifneq ($(strip $(QCPATH)),)
PRODUCT_BOOT_JARS += WfdCommon
#Android oem shutdown hook
#PRODUCT_BOOT_JARS += oem-services
endif

DEVICE_MANIFEST_FILE := device/qcom/sdm660_64/manifest.xml
ifeq ($(strip $(TARGET_KERNEL_VERSION)), 4.19)
  DEVICE_MANIFEST_FILE += device/qcom/sdm660_64/manifest_soundtrigger.xml
endif

ifeq ($(strip $(SHIPPING_API_LEVEL)), 30)
  DEVICE_MANIFEST_FILE += device/qcom/sdm660_64/manifest_target_level_5.xml
else ifeq ($(strip $(SHIPPING_API_LEVEL)), 29)
  DEVICE_MANIFEST_FILE += device/qcom/sdm660_64/manifest_target_level_4.xml
else
  DEVICE_MANIFEST_FILE += device/qcom/sdm660_64/manifest_target_level_3.xml
endif
DEVICE_MATRIX_FILE   := device/qcom/common/compatibility_matrix.xml
DEVICE_FRAMEWORK_MANIFEST_FILE := device/qcom/sdm660_64/framework_manifest.xml
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE := vendor/qcom/opensource/core-utils/vendor_framework_compatibility_matrix.xml

# Audio configuration file
-include $(TOPDIR)hardware/qcom/audio/configs/sdm660/sdm660.mk
-include $(TOPDIR)vendor/qcom/opensource/audio-hal/primary-hal/configs/sdm660/sdm660.mk

USE_LIB_PROCESS_GROUP := true

PRODUCT_PACKAGES += android.hardware.media.omx@1.0-impl

# Sensor HAL conf file
PRODUCT_COPY_FILES += \
    device/qcom/sdm660_64/sensors/hals.conf:$(TARGET_COPY_OUT_VENDOR)/etc/sensors/hals.conf
# Exclude TOF sensor from InputManager
PRODUCT_COPY_FILES += \
    device/qcom/sdm660_64/excluded-input-devices.xml:system/etc/excluded-input-devices.xml

#audio related module
PRODUCT_PACKAGES += \
    libvolumelistener

#Display/Graphics
PRODUCT_PACKAGES += \
    android.hardware.graphics.composer@2.1-impl \
    android.hardware.graphics.composer@2.1-service \
    android.hardware.memtrack@1.0-impl \
    android.hardware.memtrack@1.0-service \
    android.hardware.broadcastradio@1.0-impl

ifeq (true,$(call math_gt_or_eq,$(SHIPPING_API_LEVEL),29))
#Enable Light AIDL HAL
PRODUCT_PACKAGES += android.hardware.lights-service.qti
#Display/Graphics
PRODUCT_PACKAGES += \
    vendor.qti.hardware.display.allocator-service \
    android.hardware.graphics.mapper@3.0-impl-qti-display \
    android.hardware.graphics.mapper@4.0-impl-qti-display
else
#Enable Light HIDL HAL
PRODUCT_PACKAGES += \
android.hardware.light@2.0-impl \
android.hardware.light@2.0-service
#Display/Graphics
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator@2.0-impl \
    android.hardware.graphics.allocator@2.0-service \
    android.hardware.graphics.mapper@2.0-impl-2.1
endif

PRODUCT_PACKAGES += \
    vendor.display.color@1.0-service \
    vendor.display.color@1.0-impl

# Camera configuration file. Shared by passthrough/binderized camera HAL
PRODUCT_PACKAGES += camera.device@3.2-impl
PRODUCT_PACKAGES += camera.device@1.0-impl
PRODUCT_PACKAGES += android.hardware.camera.provider@2.4-impl
# Enable binderized camera HAL
PRODUCT_PACKAGES += android.hardware.camera.provider@2.4-service

PRODUCT_PACKAGES += \
	android.hardware.usb@1.0-service

# Sensor features
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.sensor.barometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.barometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepcounter.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.stepcounter.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepdetector.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.stepdetector.xml

#Facing, CMC and Gesture
PRODUCT_PROPERTY_OVERRIDES += \
    ro.vendor.sensors.facing=false \
    ro.vendor.sensors.cmc=false \
    ro.vendor.sdk.sensors.gestures=false

# SF properties
ifeq ($(call math_gt,$(SHIPPING_API_LEVEL),29),true)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.surface_flinger.force_hwc_copy_for_virtual_displays=true \
    ro.surface_flinger.max_frame_buffer_acquired_buffers=3 \
    ro.surface_flinger.max_virtual_display_dimension=4096
endif

# FBE support
PRODUCT_COPY_FILES += \
    device/qcom/sdm660_64/init.qti.qseecomd.sh:$(TARGET_COPY_OUT_VENDOR)/bin/init.qti.qseecomd.sh
# VB xml
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.verified_boot.xml:system/etc/permissions/android.software.verified_boot.xml

# MIDI feature
PRODUCT_COPY_FILES += frameworks/native/data/etc/android.software.midi.xml:system/etc/permissions/android.software.midi.xml

# MSM IRQ Balancer configuration file for SDM660
PRODUCT_COPY_FILES += device/qcom/sdm660_64/msm_irqbalance.conf:$(TARGET_COPY_OUT_VENDOR)/etc/msm_irqbalance.conf

# MSM IRQ Balancer configuration file for SDM630
PRODUCT_COPY_FILES += device/qcom/sdm660_64/msm_irqbalance_sdm630.conf:$(TARGET_COPY_OUT_VENDOR)/etc/msm_irqbalance_sdm630.conf

ifneq ($(BOARD_AVB_ENABLE), true)
  # dm-verity configuration
  PRODUCT_SUPPORTS_VERITY := true
  PRODUCT_SYSTEM_VERITY_PARTITION := /dev/block/bootdevice/by-name/system
  ifeq ($(ENABLE_VENDOR_IMAGE), true)
    PRODUCT_VENDOR_VERITY_PARTITION := /dev/block/bootdevice/by-name/vendor
  endif
endif

PRODUCT_FULL_TREBLE_OVERRIDE := true

PRODUCT_VENDOR_MOVE_ENABLED := true

#for android_filesystem_config.h
PRODUCT_PACKAGES += \
    fs_config_files

# Add the overlay path
#PRODUCT_PACKAGE_OVERLAYS := $(QCPATH)/qrdplus/Extension/res \
#       $(QCPATH)/qrdplus/globalization/multi-language/res-overlay \
#      $(PRODUCT_PACKAGE_OVERLAYS)


ifeq ($(ENABLE_AB), true)
#A/B related packages
PRODUCT_PACKAGES += update_engine \
                    update_engine_client \
                    update_verifier \
                    android.hardware.boot@1.1-impl-qti \
                    android.hardware.boot@1.1-impl-qti.recovery \
                    android.hardware.boot@1.1-service

PRODUCT_HOST_PACKAGES += \
  brillo_update_payload

#Boot control HAL test app
PRODUCT_PACKAGES_DEBUG += bootctl

PRODUCT_PACKAGES += \
  update_engine_sideload
endif

#Healthd packages
PRODUCT_PACKAGES += android.hardware.health@2.1-impl \
                    android.hardware.health@2.1-service \
                    android.hardware.health@2.1-impl.recovery \
                    libhealthd.msm

#FEATURE_OPENGLES_EXTENSION_PACK support string config file
PRODUCT_COPY_FILES += \
        frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml

TARGET_SUPPORT_SOTER := true

#Enable QTI KEYMASTER and GATEKEEPER HIDLs
ifeq ($(ENABLE_VENDOR_IMAGE), true)
KMGK_USE_QTI_SERVICE := true
endif

#Enable KEYMASTER 4.0
ENABLE_KM_4_0 := true

#Enable AOSP KEYMASTER and GATEKEEPER HIDLs
ifneq ($(KMGK_USE_QTI_SERVICE), true)
PRODUCT_PACKAGES += android.hardware.gatekeeper@1.0-impl \
                    android.hardware.gatekeeper@1.0-service \
                    android.hardware.keymaster@3.0-impl \
                    android.hardware.keymaster@3.0-service
endif

# Kernel modules install path
# Change to dlkm when dlkm feature is fully enabled
KERNEL_MODULES_INSTALL := dlkm
KERNEL_MODULES_OUT := out/target/product/$(PRODUCT_NAME)/$(KERNEL_MODULES_INSTALL)/lib/modules

SDM660_DISABLE_MODULE := true

PRODUCT_COMPATIBLE_PROPERTY_OVERRIDE:=true

# Enable vndk-sp Libraries
PRODUCT_PACKAGES += vndk_package

TARGET_MOUNT_POINTS_SYMLINKS := false

# Disable skip validate
PRODUCT_PROPERTY_OVERRIDES += \
  vendor.display.disable_skip_validate=1

#-------------------------------------------------------------------------------
# wlan specific
#-------------------------------------------------------------------------------
include device/qcom/wlan/sdm660_64/wlan.mk

# For bringup
WLAN_BRINGUP_NEW_SP := true
DISP_BRINGUP_NEW_SP := true
CAM_BRINGUP_NEW_SP := true
SEC_USERSPACE_BRINGUP_NEW_SP := true

#vendor prop to disable advanced network scanning
PRODUCT_PROPERTY_OVERRIDES += \
    persist.vendor.radio.enableadvancedscan=false

# Enable telephpony ims feature
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.telephony.ims.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.ims.xml

ifeq ($(TARGET_KERNEL_VERSION),$(filter $(TARGET_KERNEL_VERSION),4.14 4.19))
PRODUCT_PACKAGES += init.qti.dcvs.sh
endif

PRODUCT_PROPERTY_OVERRIDES += ro.soc.manufacturer=QTI
PRODUCT_PROPERTY_OVERRIDES += ro.soc.model=SDM660

PRODUCT_PACKAGES += libnbaio

# Target specific Netflix custom property
PRODUCT_PROPERTY_OVERRIDES += \
    ro.netflix.bsp_rev=Q660-13149-1

# Display prop to disable Idle time out
PRODUCT_PROPERTY_OVERRIDES += \
    vendor.display.idle_time=32767

###################################################################################
# This is the End of target.mk file.
# Now, Pickup other split product.mk files:
###################################################################################
$(call inherit-product-if-exists, vendor/qcom/defs/product-defs/legacy/*.mk)
###################################################################################
