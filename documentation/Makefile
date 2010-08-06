all: makefiles.html

%.html: %.docbook
	xsltproc --output $@ /usr/share/sgml/docbook/xsl-stylesheets/xhtml/docbook.xsl $<

clean:
	rm *.html
