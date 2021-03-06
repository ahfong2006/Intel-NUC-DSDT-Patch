# makefile

#
# Patches/Installs/Builds DSDT patches for Intel NUC5/NUC6
#
# Created by RehabMan 
#

BUILDDIR=./build
HDA=NUCHDA
RESOURCES=./Resources_$(HDA)
HDAINJECT=AppleHDA_$(HDA).kext
HDAHCDINJECT=AppleHDAHCD_$(HDA).kext
HDAZML=AppleHDA_$(HDA)_Resources
HDAZML_ALL=$(HDAZML)/Platforms.zml.zlib $(HDAZML)/layout1.zml.zlib $(HDAZML)/layout2.zml.zlib

VERSION_ERA=$(shell ./print_version.sh)
ifeq "$(VERSION_ERA)" "10.10-"
	INSTDIR=/System/Library/Extensions
else
	INSTDIR=/Library/Extensions
endif
SLE=/System/Library/Extensions

IASLFLAGS=-ve
IASL=iasl

ALL_COMMON=$(BUILDDIR)/SSDT-XOSI.aml $(BUILDDIR)/SSDT-LPC.aml $(BUILDDIR)/SSDT-IGPU.aml $(BUILDDIR)/SSDT-USB.aml $(BUILDDIR)/SSDT-Disable_EHCI.aml $(BUILDDIR)/SSDT-XHC.aml $(BUILDDIR)/SSDT-SATA.aml $(BUILDDIR)/SSDT-$(HDA).aml $(BUILDDIR)/SSDT-HDEF.aml $(BUILDDIR)/SSDT-HDAU.aml

ALL=$(BUILDDIR)/SSDT-Config.aml $(ALL_COMMON)

ALL_SC=$(BUILDDIR)/SSDT-Config-SC.aml $(ALL_COMMON)

ALL_ALL=$(BUILDDIR)/SSDT-Config.aml $(BUILDDIR)/SSDT-Config-SC.aml $(ALL_COMMON)

.PHONY: all
all: $(ALL_ALL) $(HDAZML_ALL) #$(HDAINJECT) $(HDAHCDINJECT)

$(BUILDDIR)/%.aml : %.dsl
	iasl $(IASLOPTS) -p $@ $<

.PHONY: clean
clean:
	rm -f $(BUILDDIR)/*.dsl $(BUILDDIR)/*.aml
	make clean_hda

# Clover Install
.PHONY: install
install: $(ALL)
	$(eval EFIDIR:=$(shell sudo ./mount_efi.sh /))
	rm -f $(EFIDIR)/EFI/CLOVER/ACPI/patched/SSDT-*.aml
	cp $(ALL) $(EFIDIR)/EFI/CLOVER/ACPI/patched
	#rm $(EFIDIR)/EFI/CLOVER/ACPI/patched/SSDT-IGPU.aml

.PHONY: install_sc
install_sc: $(ALL_SC)
	$(eval EFIDIR:=$(shell sudo ./mount_efi.sh /))
	rm -f $(EFIDIR)/EFI/CLOVER/ACPI/patched/SSDT-*.aml
	cp $(ALL_SC) $(EFIDIR)/EFI/CLOVER/ACPI/patched
	#rm $(EFIDIR)/EFI/CLOVER/ACPI/patched/SSDT-IGPU.aml

#$(HDAINJECT) $(HDAHCDINJECT) $(HDAZML_ALL): $(RESOURCES)/*.plist ./patch_hda.sh
$(HDAZML_ALL): $(RESOURCES)/*.plist ./patch_hda.sh
	./patch_hda.sh $(HDA)

.PHONY: clean_hda
clean_hda:
	rm -rf $(HDAHCDINJECT) $(HDAZML) # $(HDAINJECT)

.PHONY: update_kernelcache
update_kernelcache:
	sudo touch $(SLE)
	sudo kextcache -update-volume /

.PHONY: install_hdadummy
install_hdadummy:
	sudo rm -Rf $(INSTDIR)/$(HDAINJECT)
	sudo rm -Rf $(INSTDIR)/$(HDAHCDINJECT)
	sudo cp -R ./$(HDAINJECT) $(INSTDIR)
	rm -f $(SLE)/AppleHDA.kext/Contents/Resources/*.zml*
	if [ "`which tag`" != "" ]; then sudo tag -a Blue $(INSTDIR)/$(HDAINJECT); fi
	make update_kernelcache

.PHONY: install_hdahcd
install_hdahcd:
	sudo rm -Rf $(INSTDIR)/$(HDAINJECT)
	sudo rm -Rf $(INSTDIR)/$(HDAHCDINJECT)
	sudo cp -R ./$(HDAHCDINJECT) $(INSTDIR)
	if [ "`which tag`" != "" ]; then sudo tag -a Blue $(INSTDIR)/$(HDAHCDINJECT); fi
	sudo cp $(HDAZML)/*.zml* $(SLE)/AppleHDA.kext/Contents/Resources
	if [ "`which tag`" != "" ]; then sudo tag -a Blue $(SLE)/AppleHDA.kext/Contents/Resources/*.zml*; fi
	make update_kernelcache

.PHONY: install_hda
install_hda:
	sudo rm -Rf $(INSTDIR)/$(HDAINJECT)
	sudo rm -Rf $(INSTDIR)/$(HDAHCDINJECT)
	#sudo cp -R ./$(HDAHCDINJECT) $(INSTDIR)
	#if [ "`which tag`" != "" ]; then sudo tag -a Blue $(INSTDIR)/$(HDAHCDINJECT); fi
	sudo cp $(HDAZML)/*.zml* $(SLE)/AppleHDA.kext/Contents/Resources
	if [ "`which tag`" != "" ]; then sudo tag -a Blue $(SLE)/AppleHDA.kext/Contents/Resources/*.zml*; fi
	make update_kernelcache
