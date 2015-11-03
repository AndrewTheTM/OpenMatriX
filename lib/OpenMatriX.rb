require "OpenMatriX/version"

module OMX

  # Lots of this was built upon the work at https://github.com/edmundhighcock/hdf5
  require 'ffi'
  require 'narray'
  class NArray
    # Returns an FFI::Pointer which points to the location
    # of the actual data array in memory.
    def ffi_pointer
      FFI::Pointer.new(Hdf5.narray_data_address(self))
    end
  end

  class Array
    # Allocate an integer64 chunk of memory, copy the contents of
    # the array into it and return an FFI::MemoryPointer to the memory.
    # The memory will be garbage collected when the pointer goes out of
    # scope. Obviously the array should contain only integers. This method
    # is not fast and shouldn't be used for giant arrays.
    def ffi_mem_pointer_int64
      raise TypeError.new("Array must contain only integers.") if self.find{|el| not el.kind_of? Integer}
      ptr = FFI::MemoryPointer.new(:int64, size)
      ptr.write_array_of_int64(self)
      ptr
    end

    # This method currently assumes that hsize_t is an int64... this needs
    # to be generalised ASAP.
    def ffi_mem_pointer_hsize_t
      ffi_mem_pointer_int64
    end
  end

  # This is a module for reading and manipulating HDF5 (Hierarchical Data Format)
  # files. At the current time (July 2014) it is capable of basic reading operations.
  # However, its use of the FFI library means that extending its capabilities is easy
  # and quick. For a basic example see the test file.
  # Basic usage:
  #     file = OMX::OMXile.new('filename.omx')
  #     file.close
  #module OpenMatriX

    # A module containing functions for relating HDF5 types to the appropriate
    # FFI symbol. At the moment these are set by hand, but at some point in the
    # future they should be set dynamically by interrogation of the the library.
    module H5Types
      extend FFI::Library
      class << self
        def herr_t
          :int
        end
        def hid_t
          :int
        end
        def hbool_t
          :uint
        end
        def htri_t
          :int
        end
        def hsize_t
          :size_t
        end
        def h5t_class_t
          enum [
            :h5t_no_class         , -1,  #*error                                      */
            :h5t_integer          , 0,   #*integer types                              */
            :h5t_float            , 1,   #*floating-point types                       */
            :h5t_time             , 2,   #*date and time types                        */
            :h5t_string           , 3,   #*character string types                     */
            :h5t_bitfield         , 4,   #*bit field types                            */
            :h5t_opaque           , 5,   #*opaque types                               */
            :h5t_compound         , 6,   #*compound types                             */
            :h5t_reference        , 7,   #*reference types                            */
            :h5t_enum    , 8, #*enumeration types                          */
            :h5t_vlen    , 9, #*variable-length types                      */
            :h5t_array           , 10,  #*array types                                */

            :h5t_nclasses                #*this must be last                          */
          ]
        end
        def H5T_C_S1
          :string
        end
        def H5G_obj_t
          enum [:H5G_UNKNOWN, :H5G_GROUP, :H5G_DATASET, :H5G_TYPE, :H5G_LINK,
            :H5G_UDLINK, :H5G_RESERVED_5,	:H5G_RESERVED_6, :H5G_RESERVED_7]
        end
        def time_t
          :int
        end
        def size_t
          :int
        end
      end
    end

    # A module for dynamically interrogating the environment and the library
    # and providing the correct library path etc. Currently very dumb!
    module H5Library
      class << self
        # The location of the hdf5 library. Currently it is assumed to be in
        # the default linker path.
        def library_path
          'hdf5'
        end
      end
    end

    extend  FFI::Library
    ffi_lib H5Library.library_path
    attach_function :group_open, :H5Fopen, [H5Types.hid_t, :string, H5Types.hid_t], H5Types.hid_t
    attach_function :get_type, :H5Iget_type, [H5Types.hid_t], H5Types.hid_t
    attach_variable :h5P_CLS_GROUP_ACCESS_ID, :H5P_CLS_GROUP_ACCESS_ID_g, :int
    attach_variable :h5P_CLS_LINK_ACCESS_ID_g, :H5P_CLS_LINK_ACCESS_ID_g, :int
    #
    # Object for wrapping an OMX file. Basic usage:
    #     file = OMX::OMXFile.new('filename.omx')
    # => Do stuff
    #     file.close
    #
    class OMXFile
      class InvalidFile < StandardError; end
      extend  FFI::Library
      ffi_lib H5Library.library_path

      #htri_t H5Fis_hdf5(const char *name )
      attach_function :basic_is_hdf5, :H5Fis_hdf5, [:string], H5Types.htri_t

      #hid_t H5Fopen( const char *name, unsigned flags, hid_t fapl_id )
      attach_function :basic_open, :H5Fopen, [:string, :uint, H5Types.hid_t], H5Types.hid_t

      #herr_t H5Fclose( hid_t file_id )
      attach_function :basic_close, :H5Fclose, [H5Types.hid_t], H5Types.herr_t

      #hid_t H5Aopen( hid_t obj_id, const char *attr_name, hid_t aapl_id )
      #attach_function :basic_openattr, :H5Aopen, [H5Types.hid_t, :string], H5Types.hid_t

      attr_reader :id
      # Open the file with the given filename. Currently read only
      def initialize(filename)
        raise Errno::ENOENT.new("File #{filename} does not exist") unless FileTest.exist?(filename)
        raise InvalidFile.new("File #{filename} is not a valid hdf5 file") unless basic_is_hdf5(filename) > 0
        @filename = filename
        @id = basic_open(filename, 0x0000, 0)
        raise InvalidFile.new("An unknown problem occured opening #{filename}") if @id < 0
      end
      # Is the file a valid hdf5 file
      def is_hdf5?
        basic_is_hdf5(@filename) > 0
      end
      # Close the file
      def close
        basic_close(@id)
      end
      # Return a group object with the given name
      # (relative to the root of the file)
      def group(name)
        return H5Group.open(@id, name)
      end
      # Return a dataset object with the given name
      # (relative to the root of the file)
      def dataset(name)
        return H5Dataset.open2(@id, name)
      end
    end #Class OMXile

    # A Class to read and return the OMX version and shape (number of zones) attribute
    class OMXAttr
      class InvalidFile < StandardError; end
      extend  FFI::Library
      ffi_lib H5Library.library_path

      #herr_t H5Aread(hid_t attr_id, hid_t mem_type_id, void *buf )
      attach_function :basic_readattr, :H5Aread, [H5Types.hid_t, H5Types.hid_t, :pointer], H5Types.herr_t

      #hid_t H5Aget_type(hid_t attr_id)
      attach_function :get_type, :H5Aget_type, [H5Types.hid_t], H5Types.hid_t

      #hid_t H5Aopen_name( hid_t loc_id, const char *name )
      attach_function :basic_openattr, :H5Aopen, [H5Types.hid_t, :string], H5Types.hid_t

      #hid_t H5Tcopy( hid_t dtype_id )
      attach_function :h5t_copy, :H5Tcopy, [H5Types.hid_t], H5Types.hid_t

      attach_variable :H5T_C_S1_g, :int

      def initialize(file)
        @id = file.id
      end

      # A function to return the OMX Version number
      def getVersion()
        aid = basic_openattr(@id,"OMX_VERSION")
        attrOut = FFI::MemoryPointer.new(H5Types.hsize_t)
        sv = get_type(aid)
        oo = basic_readattr(aid,sv,attrOut)
        raise InvalidFile.new("OMX_VERSION Attribute not found") if oo < 0
        return(attrOut.read_string())
      end

      # A function to return the number of zones
      def getZones()
        aid = basic_openattr(@id,"SHAPE")
        attrOut = FFI::MemoryPointer.new(H5Types.hsize_t)
        sv = get_type(aid)
        oo = basic_readattr(aid,sv,attrOut)
        raise InvalidFile.new("SHAPE Attribute not found") if oo < 0
        return(attrOut.read_int())
      end

    end #Class OMXAttr

    # A class to return the tables in the OMX file
    class OMXTables
      class InvalidFile < StandardError; end
      extend  FFI::Library
      ffi_lib H5Library.library_path

      class H5GInfoT < FFI::Struct
        layout :storType, :int,
          :nLinks, H5Types.hsize_t,
          :maxCOrder, :int,
          :mounted, H5Types.hbool_t
      end

      def cast_to_H5GInfoT pointer
        H5GInfoT.new pointer
      end

      class H5_index < FFI::Struct
        layout :idxUnk, :int,
          :idxName, :string,
          :idxOrder, :int,
          :nIdx, :int
      end

      def cast_to_H5_index pointer
        H5_index.new pointer
      end

      #hid_t H5Dopen( hid_t loc_id, const char *name )
      attach_function :gOpen, :H5Gopen2, [H5Types.hid_t, :string, H5Types.hid_t], H5Types.hid_t

      #herr_t H5Gget_info( hid_t group_id, H5G_info_t *group_info )
      attach_function :nTables, :H5Gget_info, [H5Types.hid_t, H5GInfoT], H5Types.herr_t

      #ssize_t H5Lget_name_by_idx( hid_t loc_id, const char *group_name, H5_index_t index_field, H5_iter_order_t order, hsize_t n, char *name, size_t size, hid_t lapl_id )
      attach_function :tNames2, :H5Lget_name_by_idx, [H5Types.hid_t, :string, :int, :int, :int, :pointer, :int, :int ], :int

      def initialize(file)
        @id = file.id
        @gId = gOpen(@id, "data",0)
      end

      # A function to return the number of matrix tables. Returns an integer value
      # of the number of tables in the matrix
      def getNTables()
        h5gi = cast_to_H5GInfoT(FFI::MemoryPointer.new :char, H5GInfoT.size)
        op = nTables(@gId,h5gi)
        return(h5gi[:nLinks])
      end

      # A function to get the table names. Returns a string array of table names.
      def getTableNames()
        nT = self.getNTables()-1
        gName = FFI::MemoryPointer.new(:string)

        pl = createpl(OMX::h5P_CLS_LINK_ACCESS_ID_g)

        # Note from okiAndrew: this seems seriously kludgy, but it works.
        tN ||= []
        for t in 0..nT
          tn2o = tNames2(@gId, ".", 0, t, 0, gName, 20, pl)
          #puts "gName = #{gName.read_string()}"
          tN << gName.read_string()
        end
        return(tN)
      end

    end #class OMXTables

    #Class to read the data from the OMX file
    class OMXData
      class InvalidFile < StandardError; end
      extend  FFI::Library
      ffi_lib H5Library.library_path

      #hid_t H5Dopen2( hid_t loc_id, const char *name, hid_t dapl_id )
      attach_function :basic_open, :H5Dopen1, [H5Types.hid_t, :string], H5Types.hid_t

      #herr_t H5Dread( hid_t dataset_id, hid_t mem_type_id, hid_t mem_space_id, hid_t file_space_id, hid_t xfer_plist_id, void * buf )
      attach_function :h5dRead, :H5Dread, [H5Types.hid_t, H5Types.hid_t, H5Types.hid_t, H5Types.hid_t, H5Types.hid_t, :pointer], H5Types.herr_t

      #hid_t H5Dget_type(hid_t dataset_id )
      attach_function :h5dtype, :H5Dget_type, [H5Types.hid_t], H5Types.hid_t

      #hid_t H5Dget_space( hid_t dataset_id )
      attach_function :h5dspace, :H5Dget_space, [H5Types.hid_t], H5Types.hid_t

      #int H5Sget_simple_extent_ndims( hid_t space_id )
      attach_function :h5sN, :H5Sget_simple_extent_ndims, [H5Types.hid_t], :int

      #int H5Sget_simple_extent_dims(hid_t space_id, hsize_t *dims, hsize_t *maxdims )
      attach_function :h5sD, :H5Sget_simple_extent_dims, [H5Types.hid_t, :pointer, :pointer], :int

      attach_function :h5dpl, :H5Dget_create_plist, [H5Types.hid_t], :int

      attach_function :h5pLayout, :H5Pget_layout, [H5Types.hid_t], :bool

      #int H5Pget_chunk(hid_t plist, int max_ndims, hsize_t * dims )
      attach_function :h5pGetChunk, :H5Pget_chunk, [H5Types.hid_t, :int, :pointer], :int

      #hid_t H5Screate_simple( int rank, const hsize_t * current_dims, const hsize_t * maximum_dims )
      attach_function :h5sCreate, :H5Screate_simple, [:int, :pointer, :pointer], H5Types.hid_t

      def initialize(file, table, zones)
        @id = file.id
        @gId = OMXTables::gOpen(@id,"data")
        @zones = zones
        b = basic_open(@gId,table)
        filespace = h5dspace(b)
        rank = h5sN(filespace)
        dims = FFI::MemoryPointer.new(H5Types.hsize_t)
        maxdims = FFI::MemoryPointer.new(H5Types.hsize_t)
        status_n = h5sD(filespace,dims,maxdims)
        cparms = h5dpl(b)
        if h5pLayout(cparms)
          chunk_dims = FFI::MemoryPointer.new(H5Types.hsize_t)
          rank_chunk = h5pGetChunk(cparms, maxdims.read_int(), chunk_dims)
        end
        memspace = h5sCreate(2, dims, nil)
        type = h5dtype(b)
        buffer = FFI::MemoryPointer.new(type,2)
        c = h5dRead(b, type, memspace, filespace, 0, buffer)
        ask_zones = zones * zones
        @outAry = buffer.get_array_of_double(0,ask_zones)
      end

      def getI(zone)
        return(@outAry[(zone-1)*@zones,@zones])
      end

      def getIJ(i,j)
        a = @outAry[(i-1)*@zones,@zones]
        return(a[j-1])
      end

      def getJ(j)
        out ||= []
        for i in 0..@zones-1
          x = @outAry[i*@zones,j]
          out << x[j-1]
        end
        return(out)
      end

    end #Class OMXData
  end
#end
