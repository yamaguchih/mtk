require 'spec_helper'

describe MTK::Timeline do

  let(:note1) { Note.new(C4, p, 1) }
  let(:note2) { Note.new(G4, f, 2) }
  let(:timeline_raw_data) { { 0 => note1, 1 => [note1, note2] } }
  let(:timeline_hash) { { 0 => [note1], 1 => [note1, note2] } }
  let(:timeline) { Timeline.from_hash(timeline_raw_data) }

  it "wraps lone values in arrays" do
    Timeline.from_hash(timeline_raw_data).should == Timeline.from_hash(timeline_hash)
  end

  describe "from_hash" do
    it "creates an empty timeline when the hash is empty" do
      Timeline.from_hash({}).should be_empty
    end

    it "builds a Timeline from a map of times to single events" do
      t = Timeline.from_hash({ 0 => note1, 1 => note2 })
      t[0].should == [note1]
      t[1].should == [note2]
    end

    it "builds a Timeline from a map of times to event lists" do
      t = Timeline.from_hash({ 0 => [note1, note2], 1 => [note2] })
      t[0].should == [note1, note2]
      t[1].should == [note2]
    end
  end

  describe "#to_hash" do
    it "returns the underlying Hash" do
      timeline.to_hash.should == timeline_hash
    end
  end

  describe "#empty?" do
    it "is true when the timeilne has no events" do
      Timeline.new.empty?.should be_true
    end
  end

  describe "#[]" do
    it "returns an array of the event(s) at the timepoint" do
      timeline[0].should == [note1]
      timeline[1].should == [note1, note2]
    end
    it "returns nil when no events exist at the timepoint" do
      timeline[3].should == nil
    end
  end

  describe "#[]=" do
    it "set a single event at the given timepoint" do
      timeline[5] = note1
      timeline[5].should == [note1]
    end
    it "set an array of events at the given timepoint" do
      timeline[5] = [note1, note2]
      timeline[5].should == [note1, note2]
    end
    it "replaces existing events at the timepoint" do
      timeline[5] = note1
      timeline[5] = note2
      timeline[5].should == [note2]
    end
  end

  describe "#add" do
    it "creates a new event list at a previously empty timepoint" do
      timeline.add(5, note1)
      timeline[5].should == [note1]
    end

    it "appends to existing event lists" do
      timeline.add(5, note1)
      timeline.add(5, note2)
      timeline[5].should == [note1, note2]
    end
  end

  describe "#delete" do
    it "removes an event list at the given time" do
      timeline.delete(1)
      timeline.should == { 0 => [note1] }
    end
  end

  describe "#has_time?" do
    it "returns true if the time has been assigned" do
      (timeline.has_time? 1).should be_true
    end
    it "returns false if the time doesn't exist" do
      (timeline.has_time? 3).should be_false
    end
  end

  describe "#times" do
    it "is the sorted list of times" do
      timeline.times.should == [0,1]
    end
  end

  describe "#==" do
    it "is true when the underlying Hashes are equal" do
      timeline.should == Timeline.from_hash(timeline_hash)
    end
    it "is false when the underlying Hashes are not equal" do
      timeline.should_not == Timeline.from_hash( {0 => [note2], 1 => [note1, note2]} )
    end
    it "allows for direct comparison to hashes" do
      timeline.should == timeline_hash
    end
  end

  describe "#events" do
    it "is all events in a flattened array" do
      timeline.events.should == [note1, note1, note2]
    end
  end

  describe "#each" do
    it "yields each |time,single_event| pair" do
      yielded = []
      timeline.each{|t,e| yielded << [t,e] }
      yielded.should == [ [0,note1], [1,note1], [1,note2] ]
    end
  end

  describe "#each_time" do
    it "yields each |time,event_list| pair" do
      yielded = []
      timeline.each_time{|t,es| yielded << [t,es] }
      yielded.should == [ [0,[note1]], [1,[note1,note2]] ]
    end
  end

  describe "#map" do
    it "returns a new Timeline with each event replaced by the value of the yieled |time,event| block" do
      mapped = timeline.map{|time,event| event.transpose(time+1) }
      mapped.should == Timeline.from_hash({ 0 => note1.transpose(1), 1=> [note1.transpose(2), note2.transpose(2)] })
    end

    it "does not modify this Timeline" do
      original_values = timeline_hash
      timeline.map{|time,event| event.transpose(time+1) }
      timeline.should == original_values
    end
  end

  describe "#map!" do
    it "maps the Timeline in place" do
      timeline.map! {|time,event| event.transpose(time+1) }
      timeline.should == Timeline.from_hash({ 0 => note1.transpose(1), 1=> [note1.transpose(2), note2.transpose(2)] })
    end
  end

  describe "#compact!" do
    it "removes empty event lists" do
      timeline[3] = []
      timeline[4] = []
      timeline.compact!
      timeline.should == timeline_hash
    end
  end

  describe "#clone" do
    it "creates an equal Timeline" do
      timeline.clone.should == timeline
    end

    it "returns a new instance" do
      timeline.clone.should_not equal(timeline)
    end
  end
end

