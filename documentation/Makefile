all: makefiles.html

%.html: %.docbook
	xsltproc --output $@ /opt/local/share/xsl/docbook-xsl/html/docbook.xsl $<

clean:
	rm *.html
