SHELL = bash
.ONESHELL:
.SECONDARY:
.SECONDEXPANSION:

OUTPUTS = tkana.pdf

all: $(OUTPUTS)

# This is a monkey patch to figure out how many passes we have to to to
# garantee the TOC is up to date, simplify when #230 is fixed.
hastoc = [[ -f $(subst .pdf,.toc,$@) ]] && echo true || echo false
pages = pdfinfo $@ | awk '$$1 == "Pages:" {print $$2}' || echo 0
silepass = sile -t $< -m -o $@ && pg0=$${pg} pg=$$($(pages))

define runsile =
	pg0=$$($(pages)) hadtoc=$$($(hastoc))
	$(silepass)
	export -n SILE_COVERAGE
	if $(hastoc); then
		$${hadtoc} || $(silepass)
		[[ $${pg} -gt $${pg0} ]] && $(silepass) ||:
	fi
endef

include $(wildcard %.d)

%.pdf: %.sil
	$(runsile)
	mv tkana.pdf tkana_sile.pdf
	pdftk tkana_sile.pdf ISOform.pdf cat output tkana.pdf
	rm tkana_sile.pdf

clean:
	rm $(OUTPUTS)
