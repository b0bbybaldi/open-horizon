###
### OPEN HORIZON TOP-LEVEL makefile
###

##
## things TO change - create your own HZN_HZN_ORG_ID_ID and URL files.
##

HZN_ORG_ID ?= $(if $(wildcard HZN_ORG_ID),$(shell cat HZN_ORG_ID),HZN_ORG_ID)

# tag this build environment
TAG ?= $(if ${TAG},${TAG},if $(wildcard TAG),$(shell cat TAG),)

# hard code architecture for build environment
BUILD_ARCH ?= $(if $(wildcard BUILD_ARCH),$(shell cat BUILD_ARCH),)

##
## things NOT TO change
##

BASES = base-alpine base-ubuntu 
SERVICES = cpu hal wan yolo # mqtt hzncli herald yolo4motion mqtt2kafka 
JETSONS = jetson-jetpack jetson-cuda jetson-opencv jetson-yolo # jetson-caffe # jetson-digits
PATTERNS = yolo2msghub # motion2mqtt
SETUP = setup

ALL = $(BASES) $(SERVICES) $(PATTERNS) # ${JETSONS}

##
## targets
##

TARGETS = all clean distclean build push publish verify build-service push-service start-service publish-service test-service verify-service clean-service service-build service-push service-publish service-verify service-test service-stop service-clean

## actual

default: $(ALL)

$(ALL):
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- making $@""${NC}" &> /dev/stderr
	$(MAKE) TAG=$(TAG) HZN_ORG_ID=$(HZN_ORG_ID)  -C $@

$(TARGETS):
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- making $@ in ${ALL}""${NC}" &> /dev/stderr
	@for dir in $(ALL); do \
	  $(MAKE) TAG=$(TAG) HZN_ORG_ID=$(HZN_ORG_ID)  -C $$dir $@; \
	done

pattern-publish:
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- publishing $(PATTERNS)""${NC}" &> /dev/stderr
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=$(TAG) HZN_ORG_ID=$(HZN_ORG_ID)  -C $$dir $@; \
	done

pattern-validate: 
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- validating $(PATTERNS)""${NC}" &> /dev/stderr
	@for dir in $(PATTERNS); do \
	  $(MAKE) TAG=$(TAG) HZN_ORG_ID=$(HZN_ORG_ID)  -C $$dir $@; \
	done

.PHONY: ${ALL} default all build run check stop push publish verify clean start test sync

sync: ../ibm/open-horizon .gitignore CLOC.md 
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- synching ${ALL}""${NC}" &> /dev/stderr
	@rsync -av makefile service.makefile *.md *.sh .gitignore .travis.yml ../ibm/open-horizon
	@for dir in $(ALL) ${SETUP}; do \
	  rsync -a --info=name --exclude='service.json' --exclude='userinput.json' --exclude='pattern.json' --exclude-from=./.gitignore $${dir}/ ../ibm/open-horizon/$${dir}/ ; \
	done
	
CLOC.md: .gitignore .
	@echo "${MC}>>> MAKE --" $$(date +%T) "-- counting source code""${NC}" &> /dev/stderr
	@cloc --md --exclude-list-file=.gitignore . > CLOC.md

##
## COLORS
##
MC=${LIGHT_BLUE}
NC=${NO_COLOR}

NO_COLOR=\033[0m
BLACK=\033[0;30m
RED=\033[0;31m
GREEN=\033[0;32m
BROWN_ORANGE=\033[0;33m
BLUE=\033[0;34m
PURPLE=\033[0;35m
CYAN=\033[0;36m
LIGHT_GRAY=\033[0;37m

DARK_GRAY=\033[1;30m
LIGHT_RED=\033[1;31m
LIGHT_GREEN=\033[1;32m
YELLOW=\033[1;33m
LIGHT_BLUE=\033[1;34m
LIGHT_PURPLE=\033[1;35m
LIGHT_CYAN=\033[1;36m
WHITE=\034[1;37m
