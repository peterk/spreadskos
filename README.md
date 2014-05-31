spreadskos
==========

Having difficulties editing simple vocabularies in Protégé? This tool will help you edit linked data vocabularies created in a spreadsheet and convert them to [SKOS](http://www.w3.org/2004/02/skos/).

This is a Ruby gem and should be installed via 'gem install spreadskos'. Check out [skos2html](https://github.com/peterk/skos2html) for a gem that converts SKOS to a human readable HTML file. Both are used in [SISKOS](http://siskos.herokuapp.com).

An example Excel template is available in the root directory. The template has two sheets. The first with some basic details about your vocabulary, and the second with the actual concepts.

![An example spreadsheet where a user enters terms and definitions](https://github.com/peterk/spreadskos/blob/master/spreadsheet-example.png?raw=true)
