################## SWF Config
APP_ID = $(EXT_ID).test
NAME = Facebook
COMPANY = company
VERSION = 1.0
TESTFLIGHT_API_TOKEN = API_TOKEN_HERE
TESTFLIGHT_TEAM_TOKEN = TEAM_TOKEN_HERE
TESTFLIGHT_DLS = DIST_LISTS_HERE
TESTFLIGHT_NOTIFY = False
FACEBOOK_APP_ID = 435432429830213
WIKI_GIT_URL = git@github.com:jlopez/ane-facebook.wiki.git

SRCDIR = $(ROOT)/src/test
SRC_MAIN = $(SRCDIR)/test.mxml
APP_XML_IN = $(SRCDIR)/app.xml.in
ANDROID_PROPERTIES_IN = $(SRCDIR)/android.properties.in
ANES = $(ANE) ../lib/ane/dist/nativelibrary.ane
OTHER_RESOURCES =

################## ANE Config
IOS_SDK = ../lib/facebook-ios-sdk/src

EXT_ID = com.jesusla.facebook
ANE_AS3DIR = ../src/as3 ../lib/graph-1.8.1/api ../lib/graph-1.8.1/mobileAPI
ANE_IOS_LIB_SOURCES = $(call findcfiles,../src/ios $(IOS_SDK) $(IOS_SDK)/JSON)
ANE_IOS_LIB_CFLAGS = -Wno-objc-redundant-literal-use -I../lib/ane/src/ios -I$(IOS_SDK) -I$(IOS_SDK)/JSON
ANE_IOS_RESOURCE_DIRS = $(wildcard $(IOS_SDK)/*.bundle)

NATIVE_LIBRARY_LIB = libNativeLibrary.a
NATIVE_LIBRARY_LIB_SOURCES = $(call findcfiles,../lib/ane/src/ios)
NATIVE_LIBRARY_LIB_CFLAGS = -I$(FLEX_SDK)/include

NATIVE_LIBRARY_JAR = nativeLibrary.jar
NATIVE_LIBRARY_JAR_SOURCES = ../lib/ane/src/android

ANE_ANDROID_JAR_SOURCES = ../src/android ../lib/facebook-android-sdk/facebook
ANE_ANDROID_JAR_CLASSPATH = $(NATIVE_LIBRARY_JAR)

include mk/ane.mk
