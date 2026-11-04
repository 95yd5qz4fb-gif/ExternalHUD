TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e
DEBUG := 0
FINALPACKAGE := 1

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME := ExternalHUD

ExternalHUD_FILES := main.m \
	Application/EHAppDelegate.m \
	HUD/EHHomeViewController.m \
	HUD/EHFloatingHUDView.m \
	System/EHDeviceInfo.m \
	Capabilities/EHCapabilityRegistry.m \
	Diagnostics/EHDiagnostics.m

ExternalHUD_FRAMEWORKS := UIKit Foundation QuartzCore
ExternalHUD_CFLAGS := -fobjc-arc -Wall -Wextra
ExternalHUD_BUNDLE_IDENTIFIER := com.gira983.externalhud
ExternalHUD_INSTALL_PATH := /Applications

include $(THEOS_MAKE_PATH)/application.mk
