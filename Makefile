PYTHON ?= python3

all:
	$(PYTHON) Scripts/apply_externalhud.py
	$(MAKE) -C Dopamine NIGHTLY=1
	cp Dopamine/Application/Dopamine.ipa ExternalHUD.ipa

clean:
	$(MAKE) -C Dopamine clean
	rm -f ExternalHUD.ipa

.PHONY: all clean
