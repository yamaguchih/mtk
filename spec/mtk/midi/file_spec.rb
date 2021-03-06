require 'mtk/midi/file'
require 'tempfile'

describe MTK::MIDI::File do

  let(:test_mid) { File.join(File.dirname(__FILE__), '..', '..', 'test.mid') }

  def tempfile
    @tempfile ||= Tempfile.new 'MTK-midi_file_writer_spec'
  end

  after do
    if @tempfile
      @tempfile.close
      @tempfile.unlink
    end
  end

  def note_ons_and_offs(track)
    note_ons, note_offs = [], []
    for event in track.events
      note_ons << event if event.is_a? MIDI::NoteOn
      note_offs << event if event.is_a? MIDI::NoteOff
    end
    return note_ons, note_offs
  end

  describe "#to_timelines" do
    it "converts a single-track MIDI file to an Array containing one Timeline" do
      MIDI_File(test_mid).to_timelines.length.should == 1 # one track
    end

    it "converts note on/off messages to Note events" do
      MIDI_File(test_mid).to_timelines.first.should == {
        0.0 => [Note.new(C4, 126/127.0, 0.25)],
        1.0 => [Note.new(Db4, 99/127.0, 0.5)],
        2.0 => [Note.new(D4, 72/127.0, 0.75)],
        3.0 => [Note.new(Eb4, 46/127.0, 1.0), Note.new(E4, 46/127.0, 1.0)]
      }
    end
  end

  describe "#write_timeline" do
    it 'writes Notes in a Timeline to a MIDI file' do
      MIDI_File(tempfile).write_timeline(
        Timeline.from_hash({
          0 => Note.new(C4, 0.7, 1),
          1 => Note.new(G4, 0.8, 1),
          2 => Note.new(C5, 0.9, 1)
        })
      )

      # Now let's parse the file and check some expectations
      File.open(tempfile.path, 'rb') do |file|
        seq = MIDI::Sequence.new
        seq.read(file)
        seq.tracks.size.should == 1

        track = seq.tracks[0]
        note_ons, note_offs = note_ons_and_offs(track)
        note_ons.length.should == 3
        note_offs.length.should == 3

        note_ons[0].note.should == C4.to_i
        note_ons[0].velocity.should be_within(0.5).of(127*0.7)
        note_offs[0].note.should == C4.to_i
        note_ons[0].time_from_start.should == 0
        note_offs[0].time_from_start.should == 480

        note_ons[1].note.should == G4.to_i
        note_ons[1].velocity.should be_within(0.5).of(127*0.8)
        note_offs[1].note.should == G4.to_i
        note_ons[1].time_from_start.should == 480
        note_offs[1].time_from_start.should == 960

        note_ons[2].note.should == C5.to_i
        note_ons[2].velocity.should be_within(0.5).of(127*0.9)
        note_offs[2].note.should == C5.to_i
        note_ons[2].time_from_start.should == 960
        note_offs[2].time_from_start.should == 1440
      end
    end

    it 'writes Chords in a Timeline to a MIDI file' do
      MIDI_File(tempfile).write_timeline(
        Timeline.from_hash({
          0 => Chord.new([C4, E4], 0.5, 1),
          2 => Chord.new([G4, B4, D5], 1, 2)
        })
      )

      # Now let's parse the file and check some expectations
      File.open(tempfile.path, 'rb') do |file|
        seq = MIDI::Sequence.new
        seq.read(file)
        seq.tracks.size.should == 1

        track = seq.tracks[0]
        note_ons, note_offs = note_ons_and_offs(track)
        note_ons.length.should == 5
        note_offs.length.should == 5

        note_ons[0].note.should == C4.to_i
        note_offs[0].note.should == C4.to_i
        note_ons[0].velocity.should == 64
        note_ons[0].time_from_start.should == 0
        note_offs[0].time_from_start.should == 480

        note_ons[1].note.should == E4.to_i
        note_offs[1].note.should == E4.to_i
        note_ons[1].velocity.should == 64
        note_ons[1].time_from_start.should == 0
        note_offs[1].time_from_start.should == 480

        note_ons[2].note.should == G4.to_i
        note_offs[2].note.should == G4.to_i
        note_ons[2].velocity.should == 127
        note_ons[2].time_from_start.should == 960
        note_offs[2].time_from_start.should == 1920

        note_ons[3].note.should == B4.to_i
        note_offs[3].note.should == B4.to_i
        note_ons[3].velocity.should == 127
        note_ons[3].time_from_start.should == 960
        note_offs[3].time_from_start.should == 1920

        note_ons[4].note.should == D5.to_i
        note_offs[4].note.should == D5.to_i
        note_ons[4].velocity.should == 127
        note_ons[4].time_from_start.should == 960
        note_offs[4].time_from_start.should == 1920
      end
    end

    it 'ignores rests (events with negative duration)' do
      MIDI_File(tempfile).write_timeline(
        Timeline.from_hash({
          0 => Note.new(C4, 0.7, 1),
          1 => Note.new(G4, 0.8, -1), # this is a rest because it has a negative duration
          2 => Note.new(C5, 0.9, 1)
        })
      )

      # Now let's parse the file and check some expectations
      File.open(tempfile.path, 'rb') do |file|
        seq = MIDI::Sequence.new
        seq.read(file)
        seq.tracks.size.should == 1

        track = seq.tracks[0]
        note_ons, note_offs = note_ons_and_offs(track)
        note_ons.length.should == 2
        note_offs.length.should == 2

        note_ons[0].note.should == C4.to_i
        note_ons[0].velocity.should be_within(0.5).of(127*0.7)
        note_offs[0].note.should == C4.to_i
        note_ons[0].time_from_start.should == 0
        note_offs[0].time_from_start.should == 480

        note_ons[1].note.should == C5.to_i
        note_ons[1].velocity.should be_within(0.5).of(127*0.9)
        note_offs[1].note.should == C5.to_i
        note_ons[1].time_from_start.should == 960
        note_offs[1].time_from_start.should == 1440
      end
    end
  end

  describe "#write_timelines" do
    it "writes a multitrack MIDI file" do
      MIDI_File(tempfile).write_timelines([
        Timeline.from_hash({
          0 => Note.new(C4, 0.7, 1),
          1 => Note.new(G4, 0.8, 1),
        }),
        Timeline.from_hash({
          1 => Note.new(C5, 0.9, 2),
          2 => Note.new(D5, 1, 2),
        }),
      ])

      # Now let's parse the file and check some expectations
      File.open(tempfile.path, 'rb') do |file|
        seq = MIDI::Sequence.new
        seq.read(file)
        seq.tracks.size.should == 2

        track = seq.tracks[0]
        note_ons, note_offs = note_ons_and_offs(track)
        note_ons.length.should == 2
        note_offs.length.should == 2

        note_ons[0].note.should == C4.to_i
        note_ons[0].velocity.should be_within(0.5).of(127*0.7)
        note_offs[0].note.should == C4.to_i
        note_ons[0].time_from_start.should == 0
        note_offs[0].time_from_start.should == 480

        note_ons[1].note.should == G4.to_i
        note_ons[1].velocity.should be_within(0.5).of(127*0.8)
        note_offs[1].note.should == G4.to_i
        note_ons[1].time_from_start.should == 480
        note_offs[1].time_from_start.should == 960

        track = seq.tracks[1]
        note_ons, note_offs = note_ons_and_offs(track)
        note_ons.length.should == 2
        note_offs.length.should == 2

        note_ons[0].note.should == C5.to_i
        note_ons[0].velocity.should be_within(0.5).of(127*0.9)
        note_offs[0].note.should == C5.to_i
        note_ons[0].time_from_start.should == 480
        note_offs[0].time_from_start.should == 1440

        note_ons[1].note.should == D5.to_i
        note_ons[1].velocity.should == 127
        note_offs[1].note.should == D5.to_i
        note_ons[1].time_from_start.should == 960
        note_offs[1].time_from_start.should == 1920
      end
    end
  end

  describe "#write" do
    it "calls write_timeline when given a Timeline" do
      midi_file = MIDI_File(nil)
      timeline = Timeline.new
      midi_file.should_receive(:write_timeline).with(timeline)
      midi_file.write(timeline)
    end

    it "calls write_timelines when given an Array" do
      midi_file = MIDI_File(nil)
      timelines = [Timeline.new]
      midi_file.should_receive(:write_timelines).with(timelines)
      midi_file.write(timelines)
    end
  end

end
