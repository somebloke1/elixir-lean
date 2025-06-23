################################################################################
#
# microbeam-app
#
################################################################################

MICROBEAM_APP_VERSION = 0.1.0
MICROBEAM_APP_SITE = $(BR2_EXTERNAL_MICROBEAM_PATH)/elixir-app
MICROBEAM_APP_SITE_METHOD = local
MICROBEAM_APP_LICENSE = MIT
MICROBEAM_APP_DEPENDENCIES = erlang elixir openssl

define MICROBEAM_APP_BUILD_CMDS
	cd $(@D) && \
		MIX_ENV=prod \
		MIX_TARGET_INCLUDE_ERTS=$(STAGING_DIR)/usr/lib/erlang \
		CC=$(TARGET_CC) \
		CXX=$(TARGET_CXX) \
		CFLAGS="$(TARGET_CFLAGS)" \
		CXXFLAGS="$(TARGET_CXXFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
		mix do deps.get --only prod, compile, release --overwrite
endef

define MICROBEAM_APP_INSTALL_TARGET_CMDS
	rm -rf $(TARGET_DIR)/app
	cp -r $(@D)/_build/prod/rel/microbeam $(TARGET_DIR)/app
	
	# Remove unnecessary files
	rm -rf $(TARGET_DIR)/app/erts-*/bin/*.bat
	rm -rf $(TARGET_DIR)/app/erts-*/bin/*.ps1
	rm -rf $(TARGET_DIR)/app/erts-*/doc
	rm -rf $(TARGET_DIR)/app/erts-*/include
	rm -rf $(TARGET_DIR)/app/erts-*/src
	
	# Strip BEAM files
	find $(TARGET_DIR)/app -name "*.beam" -exec $(HOST_DIR)/bin/beam_lib strip {} \; 2>/dev/null || true
endef

$(eval $(generic-package))