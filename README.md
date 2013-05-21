Predoc
======

Predoc is a Ruby on Rails web service for in-browser document previews. It converts supported documents — Microsoft Word, Excel, and PowerPoint — into PDFs for web browsers to display.

Installation
------------

### Dependencies

Predoc uses [LibreOffice](http://www.libreoffice.org/) (via [Docsplit](http://documentcloud.github.com/docsplit/)) to convert documents. Install LibreOffice on the web server using aptitude, apt-get, or yum:

    $ aptitude install libreoffice

### Configuration

You need to specify the paths for Predoc to create temporary and cache files. Create `predoc.rb` from the template file `config/initializers/predoc.rb.default` in the same location, and modify these variables:

* `WORKING_DIRECTORY` is where temporary files are downloaded and stored.
* `CACHE_ROOT_DIRECTORY` is where converted files are cached.

Make sure these directories are writable by the web server.

Usage
-----

To create a preview, point your web browser to the web service:

    http://example.com/documents/view?source=http://path/to/source

*Note: Replace `example.com` with the server hostname, and `http://path/to/source` with an actual web-hosted document*
