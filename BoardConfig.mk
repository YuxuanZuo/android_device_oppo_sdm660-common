# config.mk
#
# Product-specific compile-time definitions.
#

BUILD_BROKEN_DUP_RULES := true

BUILD_BROKEN_PREBUILT_ELF_FILES := true
include device/qcom/sepolicy/SEPolicy.mk
BUILD_BROKEN_NINJA_USES_ENV_VARS := SDCLANG_AE_CONFIG SDCLANG_CONFIG SDCLANG_SA_ENABLED SDCLANG_CONFIG_AOSP
BUILD_BROKEN_NINJA_USES_ENV_VARS += TEMPORARY_DISABLE_PATH_RESTRICTIONS
BUILD_BROKEN_USES_BUILD_HOST_SHARED_LIBRARY := true
BUILD_BROKEN_USES_BUILD_HOST_STATIC_LIBRARY := true
BUILD_BROKEN_USES_BUILD_HOST_EXECUTABLE := true
BUILD_BROKEN_USES_BUILD_COPY_HEADERS := true

TARGET_BOOTLOADER_BOARD_NAME :=sdm660

TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a73

TARGET_NO_BOOTLOADER := false
TARGET_USES_UEFI := true
TARGET_NO_KERNEL := false

-include $(QCPATH)/common/sdm660_64/BoardConfigVendor.mk

USE_OPENGL_RENDERER := true
BOARD_USE_LEGACY_UI := true

TARGET_USERIMAGES_USE_EXT4 := true
ifeq ($(strip $(BOARD_DYNAMIC_PARTITION_ENABLE)),true)
    TARGET_USERIMAGES_USE_F2FS := true
    BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
endif
BOARD_BOOTIMAGE_PARTITION_SIZE := 0x04000000


# TARGET_KERNEL_APPEND_DTB handling
ifeq ($(strip $(BOARD_DYNAMIC_PARTITION_ENABLE)),true)
    TARGET_KERNEL_APPEND_DTB := false
else
    TARGET_KERNEL_APPEND_DTB := true
endif

BOARD_DO_NOT_STRIP_VENDOR_MODULES := true

ifeq ($(ENABLE_AB), true)
#A/B related defines
AB_OTA_UPDATER := true
# Full A/B partiton update set
# AB_OTA_PARTITIONS := xbl rpm tz hyp pmic modem abl boot keymaster cmnlib cmnlib64 system bluetooth
# Subset A/B partitions for Android-only image update
ifeq ($(ENABLE_VENDOR_IMAGE), true)
  ifeq ($(strip $(BOARD_DYNAMIC_PARTITION_ENABLE)),true)
    AB_OTA_PARTITIONS ?= boot system vendor product vbmeta_system system_ext
  else
    AB_OTA_PARTITIONS ?= boot system vendor
  endif
else
    AB_OTA_PARTITIONS ?= boot system
endif
else
BOARD_CACHEIMAGE_PARTITION_SIZE := 268435456
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
ifeq ($(BOARD_AVB_ENABLE), true)
 BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
 BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
 BOARD_AVB_RECOVERY_ROLLBACK_INDEX := 1
 BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1
endif
endif

### Dynamic partition Handling
ifneq ($(strip $(BOARD_DYNAMIC_PARTITION_ENABLE)),true)
  ifeq ($(ENABLE_VENDOR_IMAGE), true)
      BOARD_VENDORIMAGE_PARTITION_SIZE := 838860800
  endif
  BOARD_SYSTEMIMAGE_PARTITION_SIZE := 3221225472
  BOARD_BUILD_SYSTEM_ROOT_IMAGE := true
  ifeq ($(ENABLE_AB), true)
      TARGET_NO_RECOVERY := true
      BOARD_USES_RECOVERY_AS_BOOT := true
  else
      BOARD_RECOVERYIMAGE_PARTITION_SIZE := 0x04000000
      ifeq ($(BOARD_KERNEL_SEPARATED_DTBO),true)
        # Enable DTBO for recovery image
        BOARD_INCLUDE_RECOVERY_DTBO := true
      endif
  endif
else
  #dtbo support
  BOARD_DTBOIMG_PARTITION_SIZE := 0x0800000
  BOARD_KERNEL_SEPARATED_DTBO := true

  # Product partition support
  TARGET_COPY_OUT_PRODUCT := product
  BOARD_USES_PRODUCTIMAGE := true
  BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4

  # System_ext support
  TARGET_COPY_OUT_SYSTEM_EXT := system_ext
  BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4

  # Define the Dynamic Partition sizes and groups.
  ifeq ($(ENABLE_AB), true)
     ifeq ($(ENABLE_VIRTUAL_AB), true)
        BOARD_SUPER_PARTITION_SIZE := 6442450944
     else
        BOARD_SUPER_PARTITION_SIZE := 12884901888
     endif
  else
    BOARD_SUPER_PARTITION_SIZE := 5318967296
  endif
  ifeq ($(BOARD_KERNEL_SEPARATED_DTBO),true)
    # Enable DTBO for recovery image
    BOARD_INCLUDE_RECOVERY_DTBO := true
  endif
  BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
  BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 5314772992
  BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := system product vendor system_ext
  BOARD_EXT4_SHARE_DUP_BLOCKS := true
  BOARD_RECOVERYIMAGE_PARTITION_SIZE := 67108864
  # Metadata partition (applicable only for new launches)
  BOARD_METADATAIMAGE_PARTITION_SIZE := 16777216
  BOARD_USES_METADATA_PARTITION := true
endif
### Dynamic partition Handling

ifeq ($(BOARD_KERNEL_SEPARATED_DTBO), true)
     # Set Header version for bootimage
     ifneq ($(strip $(TARGET_KERNEL_APPEND_DTB)),true)
           #Enable dtb in boot image
           BOARD_INCLUDE_DTB_IN_BOOTIMG := true
           BOARD_BOOTIMG_HEADER_VERSION := 2
     else
           BOARD_BOOTIMG_HEADER_VERSION := 1
     endif

     BOARD_MKBOOTIMG_ARGS := --header_version $(BOARD_BOOTIMG_HEADER_VERSION)
endif

# Recovery fstab handling
ifneq ($(strip $(BOARD_DYNAMIC_PARTITION_ENABLE)),true)
  ifeq ($(ENABLE_AB), true)
    ifeq ($(ENABLE_VENDOR_IMAGE), true)
      TARGET_RECOVERY_FSTAB := device/qcom/sdm660_64/recovery_AB_split_variant.fstab
    else
      TARGET_RECOVERY_FSTAB := device/qcom/sdm660_64/recovery_AB_non-split_variant.fstab
    endif
  else
    ifeq ($(ENABLE_VENDOR_IMAGE), true)
      TARGET_RECOVERY_FSTAB := device/qcom/sdm660_64/recovery_non-AB_split_variant.fstab
    else
      TARGET_RECOVERY_FSTAB := device/qcom/sdm660_64/recovery_non-AB_non-split_variant.fstab
    endif
  endif
else
  ifeq ($(ENABLE_AB), true)
    TARGET_RECOVERY_FSTAB := device/qcom/sdm660_64/recovery_AB_dynamic_variant.fstab
  else
    TARGET_RECOVERY_FSTAB := device/qcom/sdm660_64/recovery_non-AB_dynamic_variant.fstab
  endif
endif

BOARD_USERDATAIMAGE_PARTITION_SIZE := 42949672960
BOARD_PERSISTIMAGE_PARTITION_SIZE := 33554432
BOARD_PERSISTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_FLASH_BLOCK_SIZE := 131072 # (BOARD_KERNEL_PAGESIZE * 64)

#Enable split vendor image
ENABLE_VENDOR_IMAGE := true
ifeq ($(ENABLE_VENDOR_IMAGE), true)
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true
endif

# Enable suspend during charger mode
BOARD_CHARGER_ENABLE_SUSPEND := true

BOARD_VENDOR_KERNEL_MODULES := \
    $(KERNEL_MODULES_OUT)/wil6210.ko \
    $(KERNEL_MODULES_OUT)/msm_11ad_proxy.ko \
    $(KERNEL_MODULES_OUT)/rdbg.ko \
    $(KERNEL_MODULES_OUT)/mpq-adapter.ko \
    $(KERNEL_MODULES_OUT)/mpq-dmx-hw-plugin.ko

ifeq ($(TARGET_KERNEL_VERSION),$(filter $(TARGET_KERNEL_VERSION),4.14 4.19))
BOARD_VENDOR_KERNEL_MODULES += \
    $(KERNEL_MODULES_OUT)/audio_apr.ko \
    $(KERNEL_MODULES_OUT)/audio_wglink.ko \
    $(KERNEL_MODULES_OUT)/audio_q6_pdr.ko \
    $(KERNEL_MODULES_OUT)/audio_q6_notifier.ko \
    $(KERNEL_MODULES_OUT)/audio_adsp_loader.ko \
    $(KERNEL_MODULES_OUT)/audio_q6.ko \
    $(KERNEL_MODULES_OUT)/audio_usf.ko \
    $(KERNEL_MODULES_OUT)/audio_pinctrl_wcd.ko \
    $(KERNEL_MODULES_OUT)/audio_pinctrl_lpi.ko \
    $(KERNEL_MODULES_OUT)/audio_swr.ko \
    $(KERNEL_MODULES_OUT)/audio_wcd_core.ko \
    $(KERNEL_MODULES_OUT)/audio_swr_ctrl.ko \
    $(KERNEL_MODULES_OUT)/audio_wsa881x.ko \
    $(KERNEL_MODULES_OUT)/audio_platform.ko \
    $(KERNEL_MODULES_OUT)/audio_cpe_lsm.ko \
    $(KERNEL_MODULES_OUT)/audio_hdmi.ko \
    $(KERNEL_MODULES_OUT)/audio_stub.ko \
    $(KERNEL_MODULES_OUT)/audio_wcd9xxx.ko \
    $(KERNEL_MODULES_OUT)/audio_mbhc.ko \
    $(KERNEL_MODULES_OUT)/audio_wcd_spi.ko \
    $(KERNEL_MODULES_OUT)/audio_wcd_cpe.ko \
    $(KERNEL_MODULES_OUT)/audio_wcd9335.ko \
    $(KERNEL_MODULES_OUT)/audio_wcd934x.ko \
    $(KERNEL_MODULES_OUT)/audio_digital_cdc.ko \
    $(KERNEL_MODULES_OUT)/audio_analog_cdc.ko \
    $(KERNEL_MODULES_OUT)/audio_msm_sdw.ko \
    $(KERNEL_MODULES_OUT)/audio_native.ko \
    $(KERNEL_MODULES_OUT)/audio_machine_sdm660.ko \
    $(KERNEL_MODULES_OUT)/audio_wcd934x.ko \
    $(KERNEL_MODULES_OUT)/audio_mbhc.ko \
    $(KERNEL_MODULES_OUT)/audio_wcd9xxx.ko \
    $(KERNEL_MODULES_OUT)/audio_wcd_core.ko
endif

TARGET_USES_ION := true
TARGET_USES_NEW_ION_API :=true
TARGET_USES_QCOM_DISPLAY_BSP := true

#Gralloc h/w specif flags
TARGET_USES_HWC2 := true
TARGET_USES_GRALLOC1 := true
ifeq (true,$(call math_gt_or_eq,$(SHIPPING_API_LEVEL),29))
TARGET_USES_QTI_MAPPER_2_0 := true
TARGET_USES_QTI_MAPPER_EXTENSIONS_1_1 := true
TARGET_USES_GRALLOC4 := true
endif

ifeq ($(BOARD_KERNEL_CMDLINE),)
ifneq ($(TARGET_KERNEL_VERSION),$(filter $(TARGET_KERNEL_VERSION),3.18 4.9))
     BOARD_KERNEL_CMDLINE += console=ttyMSM0,115200,n8 androidboot.console=ttyMSM0 earlycon=msm_serial_dm,0xc170000
else
     BOARD_KERNEL_CMDLINE += console=ttyHSL0,115200,n8 androidboot.console=ttyHSL0 earlycon=msm_hsl_uart,0xc1b0000
endif
BOARD_KERNEL_CMDLINE += androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x37 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 sched_enable_hmp=1 sched_enable_power_aware=1 service_locator.enable=1 loop.max_part=7
ifeq ($(TARGET_KERNEL_VERSION),$(filter $(TARGET_KERNEL_VERSION),4.4))
     BOARD_KERNEL_CMDLINE += swiotlb=1
endif
endif

BOARD_EGL_CFG := device/qcom/sdm660_64/egl.cfg
BOARD_SECCOMP_POLICY := device/qcom/sdm660_32/seccomp

BOARD_KERNEL_BASE        := 0x00000000
BOARD_KERNEL_PAGESIZE    := 4096
BOARD_KERNEL_TAGS_OFFSET := 0x01E00000
BOARD_RAMDISK_OFFSET     := 0x02000000

TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
#TARGET_KERNEL_CROSS_COMPILE_PREFIX := aarch64-linux-android-
TARGET_KERNEL_CROSS_COMPILE_PREFIX := $(shell pwd)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-androidkernel-
TARGET_USES_UNCOMPRESSED_KERNEL := false

MAX_EGL_CACHE_KEY_SIZE := 12*1024
MAX_EGL_CACHE_SIZE := 2048*1024

TARGET_FORCE_HWC_FOR_VIRTUAL_DISPLAYS := true
MAX_VIRTUAL_DISPLAY_DIMENSION := 4096

BOARD_USES_GENERIC_AUDIO := true
USE_CAMERA_STUB := false
BOARD_QTI_CAMERA_32BIT_ONLY := true
TARGET_NO_RPC := true

TARGET_PLATFORM_DEVICE_BASE := /devices/soc.0/
TARGET_INIT_VENDOR_LIB := libinit_msm

NUM_FRAMEBUFFER_SURFACE_BUFFERS := 3
TARGET_COMPILE_WITH_MSM_KERNEL := true

#Enable PD locater/notifier
TARGET_PD_SERVICE_ENABLED := true

#Enable HW based full disk encryption
ifeq ($(TARGET_KERNEL_VERSION), 4.4)
TARGET_HW_DISK_ENCRYPTION := false
else
TARGET_HW_DISK_ENCRYPTION := true
endif

ifeq ($(TARGET_KERNEL_VERSION),$(filter $(TARGET_KERNEL_VERSION),4.14 4.19))
TARGET_HW_DISK_ENCRYPTION_PERF := true
endif

# Enable dex pre-opt to speed up initial boot
ifeq ($(HOST_OS),linux)
    ifeq ($(WITH_DEXPREOPT),)
      WITH_DEXPREOPT := true
      WITH_DEXPREOPT_PIC := true
      ifneq ($(TARGET_BUILD_VARIANT),user)
        # Retain classes.dex in APK's for non-user builds
        DEX_PREOPT_DEFAULT := nostripping
      endif
    endif
endif

#Enable peripheral manager
TARGET_PER_MGR_ENABLED := true

#Enable SSC Feature
TARGET_USES_SSC := true

# Enable sensor multi HAL
USE_SENSOR_MULTI_HAL := true

#Enable CPUSets
ENABLE_CPUSETS := true
ENABLE_SCHEDBOOST := true

#Enabling IMS Feature
TARGET_USES_IMS := true

#Add NON-HLOS files for ota upgrade
ADD_RADIO_FILES := true
TARGET_RECOVERY_UI_LIB := librecovery_ui_msm

ifneq ($(AB_OTA_UPDATER),true)
    TARGET_RECOVERY_UPDATER_LIBS += librecovery_updater_msm
endif

#Enable DRM plugins 64 bit compilation
TARGET_ENABLE_MEDIADRM_64 := true

#Flag to enable System SDK Requirements.
BOARD_SYSTEMSDK_VERSIONS:=$(SHIPPING_API_LEVEL)

#All vendor APK will be compiled against system_current API set.
BOARD_VNDK_VERSION := current


#-------------------------------------------------------------------------------
# wlan specific
#-------------------------------------------------------------------------------
ifeq ($(strip $(BOARD_HAS_QCOM_WLAN)),true)
include device/qcom/wlan/sdm660_64/BoardConfigWlan.mk
endif

#################################################################################
# This is the End of BoardConfig.mk file.
# Now, Pickup other split Board.mk files:
#################################################################################
-include vendor/qcom/defs/board-defs/legacy/*.mk
#################################################################################
