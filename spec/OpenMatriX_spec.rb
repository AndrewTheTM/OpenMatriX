require 'spec_helper'

# TESTING
# There is a supplied matrix in OMX format to help.  The matrix includes
# four tables and 10 zones (they are a 10x10 matrices):
# 1. "All Ones": Each cell in the matrix has the value of 1
# 2. "Col Num": Each cell counts 1 to 10 increasing via column, rows repeat
# 3. "Row Num": Each cell counts 1 to 10 increasing via row, columns repeat
# 4. "Counting": The matrix counts up via column, from 1 (at r1,c1) to
#    2 (at r1,c2), etc. to 100 (at r10,c10)
#
# IMPORTANT NOTE!
# In travel modeling, we look at matrix files to be 1-based, and the code
# is setup as 1-based.  If you look at the supplied OMX file in HDView, you will
# notice that the row and column IDs are 0-based.  This is taken care of in the
# code so when a user expects zone 1, they get the FIRST ROW.

describe OpenMatriX do
  it 'has a version number' do
    expect(OpenMatriX::VERSION).not_to be nil
  end

  it 'returns the correct matrix version number' do
    file = OMX::OMXFile.new("./spec/TestMat.omx")
    at = OMX::OMXAttr.new(file)
    mVer = at.getVersion()
    nZones = at.getZones()
    file.close()
    expect(mVer).to eq("0.2")
  end

  it 'reads a matrix full of ones' do
    file = OMX::OMXFile.new("./spec/TestMat.omx")
    at = OMX::OMXAttr.new(file)
    nZones = at.getZones()
    tt = OMX::OMXData.new(file,"All Ones",at.getZones())
    pass = true
    for i in 1..nZones
      for j in 1..nZones
        if tt.getIJ(i,j) != 1
          pass = false
        end
      end
    end

    file.close()
    expect(pass).to eq(true)
  end

  it 'reads by row' do
    file = OMX::OMXFile.new("./spec/TestMat.omx")
    at = OMX::OMXAttr.new(file)
    nZones = at.getZones()
    tt = OMX::OMXData.new(file,"Row Num",at.getZones())
    pass = true
    for i in 1..nZones
      for j in 1..nZones
        if tt.getIJ(i,j) != i
          pass = false
        end
      end
    end
    file.close()
    expect(pass).to eq(true)
  end

  it 'reads by column' do
    file = OMX::OMXFile.new("./spec/TestMat.omx")
    at = OMX::OMXAttr.new(file)
    nZones = at.getZones()
    tt = OMX::OMXData.new(file,"Col Num",at.getZones())
    pass = true
    for i in 1..nZones
      for j in 1..nZones
        if tt.getIJ(i,j) != j
          pass = false
        end
      end
    end
    file.close()
    expect(pass).to eq(true)
  end

  it 'reads sequentially' do
    file = OMX::OMXFile.new("./spec/TestMat.omx")
    at = OMX::OMXAttr.new(file)
    nZones = at.getZones()
    tt = OMX::OMXData.new(file,"Counting",at.getZones())
    pass = true
    cnt = 1
    for i in 1..nZones
      for j in 1..nZones
        if tt.getIJ(i,j) != cnt
          pass = false
        end
        cnt += 1
      end
    end
    file.close()
    expect(pass).to eq(true)
  end
end
