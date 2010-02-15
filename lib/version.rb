require 'version/ext/array'
require 'version/ext/class'
require 'version/ext/hash'
require 'version/ext/string'

require 'pathname'

#
# Encodes version-numbering logic into a convenient class.
#
class Version
  include Comparable
  
  #
  # Searches through the parent directories of the calling method and looks
  # for a VERSION or VERSION.yml file to parse out the current version. Pass
  #
  # Pass a filename to +path+ to override autodetection, or pass a directory
  # name as +path+ to autodetect within a given directory
  #
  def self.current(path = nil)
    # if path is nil, detect automatically; if path is a directory, detect
    # automatically in the directory; if path is a filename, use it directly
    path = path ? Pathname.new(path) : self.version_file(caller.first)
    path = self.version_file(path) unless path.file?
            
    raise 'no VERSION or VERSION.yml found' unless path
    
    case path.extname
      when ''      then path.read.strip.to_version
      when '.yml'  then YAML::load(path.read).to_version
    end
  end
  
  #
  # Attempts to detect the version file for the passed +filename+. Looks up
  # the directory hierarchy for a file named VERSION or VERSION.yml. Returns
  # a Pathname for the file if found, otherwise nil.
  #
  def self.version_file(filename)
    Pathname(filename).dirname.expand_path.ascend do |d|
      break d.join('VERSION')     if d.join('VERSION').exist?
      break d.join('VERSION.yml') if d.join('VERSION.yml').exist?
    end
  end
  
  # 
  # Attempts to detect the .version file containing options for the +version+
  # binary.
  # 
  def self.dotfile
    Pathname(Dir.pwd).ascend do |d|
      break d.join('.version') if d.join('.version').exist?
    end
  end
  
  #
  # Creates a new version number, with a +major+ version number, +minor+
  # revision number, +revision+ number, and optionally more (unnamed)
  # version components.
  #
  def initialize(major, minor = 0, revision = nil, *rest)
    self.components = []
    
    self.major     = major
    self.minor     = minor
    self.revision  = revision
    
    rest.each.with_index {|v, i| self[3 + i] = v }
  end
  
  #
  # For +major+, +minor+, and +revision+, make a helper method that gets and
  # sets each based on accessing indexes.
  #--
  # TODO: make these rdoc-capable
  #++
  #
  [ :major, :minor, :revision ].each.with_index do |component, i|
    define_method(:"#{component}")  {    self[i]          }
    define_method(:"#{component}=") {|v| self[i] = v.to_s }
  end
  
  #
  # Retrieves the component of the Version at +index+.
  #
  def [](index)
    self.components[index].join
  end
  
  #
  # Set the component of the Version at +index+ to +value+. Zeroes out any
  # trailing components.
  #
  # If +index+ is greater than the length of the version number, pads the
  # version number with zeroes until +index+.
  #--
  # TODO: rewrite sanely
  #++
  def []=(index, value)
    self.resize!(index) and return if value.nil? || value.empty?
    
    split = (value =~ %r{\d\D}) || value.length
    value = [ value[0..split].to_i, value[split + 1..-1] ].compact
    
    if index < self.length
      length = self.length - index
      zeroes = Array.new(length, '0')
      
      self.components[index, length] = zeroes
      self.components[index]         = value
    else
      length = index - self.length
      zeroes = Array.new(length, '0')
      
      self.components += zeroes
      self.components << value
    end
  end
  
  #
  # Resizes the Version to +length+, removing any trailing components. Is a
  # no-op if +length+ is greater than its current length.
  #
  def resize!(length)
    self.components = self.components[0, length]
    self
  end
  
  #
  # Bumps the version number. Pass +index+ to bump a component other than the
  # least-significant part. Set +trim+ to true if you want the version to be
  # resized to only large enough to contain the index.
  #
  #    "1.0.4a".bump!          # => "1.0.4b"
  #    "1.0.4b".bump!(1, true) # => "1.2"
  #
  def bump!(index = self.length - 1, trim = false)
    self.resize!(index + 1) if trim
    self[index] = (self[index] || -1).succ
    self
  end
  
  #
  # Returns the current length of the version number.
  #
  def length
    self.components.length
  end
  
  #
  # Compares a Version against any +other+ object that responds to
  # +to_version+.
  #
  def <=>(other)
    self.components <=> other.to_version.components
  end
  
  #
  # Converts the version number into an array of its components.
  #
  def to_a
    self.components.map {|c| c.join }
  end
  
  #
  # Converts the version number into a hash of its components.
  #
  def to_hash
    { :major    => self.major,
      :minor    => self.minor,
      :revision => self.revision,
      :rest     => self.length > 3 ? self.to_a.drop(3) : nil }.
      delete_if {|k,v| v.nil? }
  end
  
  #
  # The canonical representation of a version number.
  #
  def to_s
    self.to_a.join('.')
  end
  
  #
  # Returns +self+.
  #
  def to_version
    self
  end
  
  #
  # Returns a YAML representation of the version number.
  #
  def to_yaml
    YAML::dump(self.to_hash)
  end
  
  #
  # Aliased from +to_s+.
  #
  alias inspect to_s
  
  protected
  
  attr_accessor :components
end

class Version
  is_versioned
end
