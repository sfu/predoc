Predoc
======

Predoc is a Ruby on Rails web service for in-browser document previews. It converts supported documents — Microsoft Word, Excel, and PowerPoint — into PDFs for web browsers to display.

Installation
------------

### Dependencies

Predoc uses [LibreOffice](http://www.libreoffice.org/) (via [Docsplit](http://documentcloud.github.com/docsplit/)) to convert documents. Install LibreOffice on the web server using aptitude, apt-get, or yum:

    $ aptitude install libreoffice

Usage
-----

To create a preview, point your web browser to the web service:

    http://example.com/documents/view?source=http://path/to/source

*Note: Replace `example.com` with the server hostname, and `http://path/to/source` with an actual web-hosted document*
