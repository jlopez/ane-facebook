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
ANES = $(ANE)
OTHER_RESOURCES =

################## ANE Config
EXT_ID = com.jesusla.facebook
ANE_AS3DIR = ../src/as3 ../lib/graph-1.8.1/api ../lib/graph-1.8.1/mobileAPI
ANE_IOS_LIB_SOURCES = $(call findcfiles,../src/ios ../src/ios/fb/src)
ANE_IOS_LIB_CFLAGS = -Wno-objc-redundant-literal-use -I../src/ios/ane/src -I../src/ios/fb/src -I../src/ios/fb/src/JSON
ANE_BUNDLED_LIBS = $(NATIVE_LIBRARY_LIB) $(JSON_LIBRARY_LIB)

NATIVE_LIBRARY_LIB = libNativeLibrary.a
NATIVE_LIBRARY_LIB_SOURCES = $(call findcfiles,../src/ios/ane/src)
NATIVE_LIBRARY_LIB_CFLAGS = -I$(FLEX_SDK)/include

JSON_LIBRARY_LIB = libJSON.a
JSON_LIBRARY_LIB_SOURCES = $(call findcfiles,../src/ios/fb/src/JSON)

include mk/ane.mk
