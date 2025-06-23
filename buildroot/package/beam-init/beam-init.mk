################################################################################
#
# beam-init
#
################################################################################

BEAM_INIT_VERSION = 1.0.0
BEAM_INIT_SITE = $(BR2_EXTERNAL_MICROBEAM_PATH)/beam-init
BEAM_INIT_SITE_METHOD = local

define BEAM_INIT_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D)
endef

define BEAM_INIT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/beam-init $(TARGET_DIR)/sbin/beam-init
	ln -sf /sbin/beam-init $(TARGET_DIR)/init
endef

$(eval $(generic-package))