require 'spec_helper'
module MTK

  describe MTK::Pitch do

    let(:c) { PitchClass[:C] }
    let(:g) { PitchClass[:G] }
    let(:middle_c) { Pitch.new(c, 4) }
    let(:lowest) { Pitch.new(c, -1) }
    let(:highest) { Pitch.new(g, 9) }
    let(:subjects) { [middle_c, lowest, highest] }
    let(:middle_c_and_50_cents) { Pitch.new(c, 4, 0.5) }
    let(:value) { subject.value }
    subject { middle_c_and_50_cents }

    describe '#pitch_class' do
      it "is the pitch class of the pitch" do
        middle_c.pitch_class.should == c
      end
    end

    describe '#octave' do
      it "is the octave of the pitch" do
        middle_c.octave.should == 4
      end
    end

    describe '#offset' do
      it 'is the third argument of the constructor' do
        Pitch.new(c, 4, 0.6).offset.should == 0.6
      end
      it 'defaults to 0' do
        Pitch.new(c, 4).offset.should == 0
      end
    end

    describe '#offset_in_cents' do
      it 'is #offset * 100' do
        subject.offset_in_cents.should == subject.offset * 100
      end
    end

    describe '.from_i' do
      it("converts 60 to middle C") { Pitch.from_i(60).should == middle_c }
      it("converts 0 to C at octave -1") { Pitch.from_i(0).should == lowest }
      it("converts 127 to G at octave 9") { Pitch.from_i(127).should == highest }
    end

    describe '.from_f' do
      it "converts 60.5 to middle C with a 0.5 offset" do
        p = Pitch.from_f(60.5)
        p.pitch_class.should == c
        p.octave.should == 4
        p.offset.should == 0.5
      end
    end

    describe '.from_s' do
      it("converts 'C4' to middle c") { Pitch.from_s('C4').should == middle_c }
      it("converts 'c4' to middle c") { Pitch.from_s('c4').should == middle_c }
      it("converts 'B#4' to middle c") { Pitch.from_s('B#4').should == middle_c }
    end

    describe '#to_f' do
      it "is 60.5 for middle C with a 0.5 offset" do
        middle_c_and_50_cents.to_f.should == 60.5
      end
    end

    describe '#to_i' do
      it("is 60 for middle C") { middle_c.to_i.should == 60 }
      it("is 0 for the C at octave -1") { lowest.to_i.should == 0 }
      it("is 127 for the G at octave 9") { highest.to_i.should == 127 }
      it "rounds to the nearest integer (the nearest semitone value) when there is an offset" do
        Pitch.new(c, 4, 0.4).to_i.should == 60
        Pitch.new(c, 4, 0.5).to_i.should == 61
      end
    end

    describe '#==' do
      it "compares the pitch_class and octave for equality" do
        middle_c.should == Pitch.from_s('C4')
        middle_c.should_not == Pitch.from_s('C3')
        middle_c.should_not == Pitch.from_s('G4')
        middle_c.should_not == Pitch.from_s('G3')
        highest.should == Pitch.from_s('G9')
      end
    end

    describe '#to_s' do
      it "should be the pitch class name and the octave" do
        for pitch in subjects
          pitch.to_s.should == pitch.pitch_class.name + pitch.octave.to_s
        end
      end
      it "should include the offset_in_cents when the offset is not 0" do
        middle_c_and_50_cents.to_s.should == "C4+50.0cents"
      end
    end

    describe '#+' do
      it 'adds the integer value of the argument and #to_i' do
        (middle_c + 2).should == Pitch.from_i(62)
      end

      it 'handles offsets' do
        (middle_c + Pitch.from_f(0.5)).should == Pitch.from_f(60.5)
      end

      it 'returns a new pitch (Pitch is immutabile)' do
        original = Pitch.from_i(60)
        modified = original + 2
        original.should_not == modified
        original.should == Pitch.from_i(60)
      end
    end

    describe '#-' do
      it 'subtracts the integer value of the argument from #to_i' do
        (middle_c - 2).should == Pitch.from_i(58)
      end

      it 'handles offsets' do
        (middle_c - Pitch.from_f(0.5)).should == Pitch.from_f(59.5)
      end

      it 'returns a new pitch (Pitch is immutabile)' do
        original = Pitch.from_i(60)
        modified = original - 2
        original.should_not == modified
        original.should == Pitch.from_i(60)
      end
    end

    describe '#coerce' do
      it 'allows a Pitch to be added to a Numeric' do
        (2 + middle_c).should == Pitch.from_i(62)
      end

      it 'allows a Pitch to be subtracted from a Numeric' do
        (62 - middle_c).should == Pitch.from_i(2)
      end
    end

    describe 'Constants' do

      it "defines constants for the 128 notes in MIDI" do
        Pitch::Constants.constants.length.should == 129 # there's also the PITCHES constant
        Pitch::Constants::C_1.should == Pitch.from_s('C-1')
        Pitch::Constants::D0.should == Pitch.from_s('D0')
        Pitch::Constants::Eb1.should == Pitch.from_s('Eb1')
        Pitch::Constants::G9.should == Pitch.from_s('g9')
      end

      describe "PITCHES" do
        it "contains all 128 pitch constants" do
          Pitch::Constants::PITCHES.length.should == 128
          Pitch::Constants::PITCHES.should include Pitch::Constants::C_1
          Pitch::Constants::PITCHES.should include Pitch::Constants::D0
          Pitch::Constants::PITCHES.should include Pitch::Constants::Eb1
          Pitch::Constants::PITCHES.should include Pitch::Constants::G9
        end
      end
    end

  end
end
