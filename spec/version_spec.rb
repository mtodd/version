require 'spec_helper'

describe Version do
  it 'should preserve equality' do
    V["0.0"]      .should == V["0.0"]
    V["0.1.1"]    .should == V["0.1.1"]
    V["0.4.alpha"].should == V["0.4.alpha"]
    V["1.0.2"]    .should == V["1.0.2"]
    V["1.0.2b"]   .should == V["1.0.2b"]
    V["1.01"]     .should == V["1.01"]
    V["1.10"]     .should == V["1.10"]
    V["2.0"]      .should == V["2.0"]
    V["a"]        .should == V["b"]
  end
  
  it 'should order correctly' do
    V["0.0"]    .should < V["0.0.0.0.0.1"]
    V["0.0.0.1"].should < V["1"]
    V["0.1a"]   .should < V["0.1"]
    V["0.01"]   .should < V["0.10"]
    V["0.9"]    .should < V["0.10"]
  end
  
  it 'should reassign the major version and zero out the minor and revisions' do
    (v = V[]).major = 1
    v.should == V['1.0.0']
  end
end
