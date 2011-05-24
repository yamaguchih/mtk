require 'spec_helper'

describe MTK::PitchSet do

  let(:pitches) { [C4, D4, E4, F4, G4, A4, B4] }
  let(:pitch_set) { PitchSet.new(pitches) }
  let(:c_major) { PitchSet.new([C4,E4,G4]) }
    
  describe '#pitches' do
    it 'is the list of pitches used to construct the scale' do
      pitch_set.pitches.should == pitches
    end

    it "is immutable" do
      lambda { pitch_set.pitches << Db4 }.should raise_error
    end

    it "does not affect the immutabilty of the pitch list used to construct it" do
      pitches << Db4
      pitches.length.should == 8
    end

    it "is not affected by changes to the pitch list used to construct it" do
      pitch_set # force construction before we modify the pitches array
      pitches << Db4
      pitch_set.pitches.length.should == 7
    end

    it "does not include duplicates" do
      PitchSet.new([C4, E4, G4, C4]).pitches.should == [C4, E4, G4]
    end

    it "sorts the pitches" do
      PitchSet.new([G4, E4, C4]).pitches.should == [C4, E4, G4]
    end
  end

  describe "#to_a" do
    it "is equal to #pitches" do
      pitch_set.to_a.should == pitch_set.pitches
    end

    it "is mutable" do
      (c_major.to_a << Bb4).should == [C4, E4, G4, Bb4]
    end
  end

  describe "#to_pitch_class_set" do
    it "is a PitchClassSet" do
      pitch_set.to_pitch_class_set.should be_a PitchClassSet
    end

    it "contains all the pitch_classes in this PitchSet" do
      pitch_set.to_pitch_class_set.pitch_classes.should == pitch_set.pitch_classes
    end
  end

  describe '#pitch_classes' do
    it 'is the list of pitch classes' do
      pitch_set.pitch_classes.should == pitches.map { |p| p.pitch_class }
    end

    it "doesn't include duplicates" do
      PitchSet.new([C4, C5, D5, C6, D4]).pitch_classes.should == [C, D]
    end
  end

  describe '#+' do
    it 'transposes upward by the given semitones' do
      (pitch_set + 12).should == PitchSet.new([C5, D5, E5, F5, G5, A5, B5])
    end
  end

  describe '#-' do
    it 'transposes downward by the given semitones' do
      (pitch_set - 12).should == PitchSet.new([C3, D3, E3, F3, G3, A3, B3])
    end
  end

  describe '#invert' do
    it 'inverts all pitches around the given center pitch' do
      (pitch_set.invert Gb4).should == PitchSet.new([C5, Bb4, Ab4, G4, F4, Eb4, Db4])
    end

    it 'inverts all pitches around the first pitch, when no center pitch is given' do
      pitch_set.invert.should == PitchSet.new([C4, Bb3, Ab3, G3, F3, Eb3, Db3])
    end
  end

  describe '#include?' do
    it 'returns true if the Pitch is in the PitchList' do
      (pitch_set.include? C4).should be_true
    end

    it 'returns false if the Pitch is not in the PitchList' do
      (pitch_set.include? Db4).should be_false
    end
  end

  describe '#==' do
    it "is true when all the pitches are equal" do
      PitchSet.new([C4, E4, G4]).should == PitchSet.new([Pitch.from_i(60), Pitch.from_i(64), Pitch.from_i(67)])
    end

    it "doesn't consider duplicates in the comparison" do
      PitchSet.new([C4, C4]).should == PitchSet.new([C4])
    end

    it "doesn't consider the order of pitches" do
      PitchSet.new([G4, E4, C4]).should == PitchSet.new([C4, E4, G4])
    end
  end

  describe '#inversion' do
    it "adds an octave to the chord's pitches starting from the lowest, for each whole number in a postive argument" do
      c_major.inversion(2).should == PitchSet.new([G4,C5,E5])
    end

    it "subtracts an octave to the chord's pitches starting fromt he highest, for each whole number in a negative argument" do
      c_major.inversion(-2).should == PitchSet.new([E3,G3,C4])
    end

    it "wraps around to the lowest pitch when the argument is bigger than the number of pitches in the chord (positive argument)" do
      c_major.inversion(4).should == PitchSet.new([E5,G5,C6])
    end

    it "wraps around to the highest pitch when the magnitude of the argument is bigger than the number of pitches in the chord (negative argument)" do
      c_major.inversion(-4).should == PitchSet.new([G2,C3,E3])
    end
  end

  describe "#to_s" do
    it "looks like an array of pitches" do
      c_major.to_s.should == "[C4, E4, G4]"
    end
  end

end