Jute
===

Jute is a partial implementation of [Hadoop][hadoop]'s
[record serialization format][apache-jute]. 

Example (CoffeScript)
---------------------

    jute = require "jute"

    ExampleRecord = jute.RecordType "ExampleRecord",
      name: jute.types.ustring
      size: jute.types.long

    record = new ExampleRecord
      name: "jute"
      size: 0xCAFEBABE

    console.log record
    console.log jute.binary.serialize(record)

[hadoop]: http://hadoop.apache.org/
[apache-jute]: http://java2s.com/Open-Source/Java-Document/Web-Crawler/nutch/org.apache.jute.htm

License
-------

Jute is made available under the terms of the MIT License.

Copyright © 2011 [Eric Naeseth][copyright_holder]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

[copyright_holder]: http://github.com/enaeseth
