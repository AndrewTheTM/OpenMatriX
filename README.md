# OpenMatriX

OpenMatriX is a Ruby Gem to read (Open Matrix files)[https://sites.google.com/site/openmodeldata/]. This was built for use on the web and to eventually have APIs that can return values from a matrix.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'OpenMatriX'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install OpenMatriX

## Usage

```ruby
# Open file
# OMX::OMXFile.new(filename)
file = OMX::OMXFile.new('filename.omx')

# Get the attributes from the file
at = OMX::OMXAttr.new(file)
puts "Version: #{at.getVersion()}"
puts "Zones: #{at.getZones()}"

# Get the tables from the file
t = OMX::OMXTables.new(file)
puts "Tables: #{t.getNTables()}"
puts "Table Names: #{t.getTableNames()}"

# Get data from the file
# OMX::OMXData.new(file,"Tablename", nZones)
tt = OMX::OMXData.new(file,"DIST",at.getZones())
puts tt.getI(zone) # Returns array of all J from zone
puts tt.getJ(zone) # Returns array of all I to zone
puts tt.getIJ(i,j) # Returns value at i,j

# Close the file
file.close()
```

## Important Concepts for Non-Travel-Modelers

Note that our use of matrices may be a little different from others', and we
have some of our own nomenclature.

The use of the term "zone" refers to a geographic location called a Traffic
Analysis Zone, or TAZ.  These TAZs are created by the model "owner", which
differs by state and jurisdiction.

Zones are generally sequentially numbered starting with 1.  OMX files, depending
on how they are viewed and/or accessed likely start at 0, so increments/decrements
are fairly common in code.

In travel modeling, there is a nomenclature that I is a production or origin
zone and J is an attraction or destination zone.  "Production" and "Attraction"
are not the same as "Origin" and "Destination".  We treat I as the matrix ROW and
J as the matrix COLUMN.  So I=10, J=20 would be row 10 (1-based, row 9 if 0-based)
and column 20 (1-based, column 19 of 0-based).

## Contributing

This is still under some development.  Bug reports and pull requests are welcome on GitHub at https://github.com/okiandrew/OpenMatriX.  

## Contact

Old School Email: arohne (at) oki (dot) org

Twitter: @okiAndrew
