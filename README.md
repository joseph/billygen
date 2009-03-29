billygen  
    by Joseph Pearson  
    of [Inventive Labs](http://inventivelabs.com.au)


## DESCRIPTION:

Billygen takes the data that RDoc collects and dumps it to a readable 
transport format.

Currently only YAML is available; XML and others are trivial to implement and
will be offered if there is a genuine use case.


## SYNOPSIS:

It's just a normal RDoc generator -- use it as you would any other: from the
command-line, from a rake task, etc. Here's an example of using it with
recommended defaults from a script or irb:

    require 'billygen' 
    files = ["README.md", 'lib/**/*.rb']
    Billygen.run('Project Name', 'doc', files)

This will output a file called `rdocdump.yml` in the `doc` directory.

You can also use Billygen to read the dumped file back into Ruby objects:

    require 'billygen'
    @manifest = YAML.load(IO.read("doc/rdocdump.yml"))

    # Then, for example:
    puts @manifest.data['classes'].collect { |klass| klass.name }


## STATUS:

Really early days. Use it to play around with, but don't replace your current
RDoc generator with billygen until a few key bugs are ironed out.

The API for reading billygen output back in will change, and old dumped data
may not continue to be readable by newer billygen versions until we're out
of this early development period.

Ie, give us a few versions to settle things down.


## REQUIREMENTS:

* RDoc >= 2.4


## INSTALL:

For the moment, clone the git repository to your local setup and run:

    $ rake gem:install

We'll package it up as a gem when it's ready.


## LICENSE:

(The MIT License)

Copyright (c) 2009 Joseph Pearson

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
