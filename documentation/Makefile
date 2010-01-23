all: makefiles.html

%.html: %.docbook
	xsltproc --output $@ /opt/local/share/xsl/docbook-xsl/xhtml/docbook.xsl $<

clean:
	rm *.html
