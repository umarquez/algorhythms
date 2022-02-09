use_debug false
use_bpm 82

midi_out = "*"

midi_channels = {
  "lead" => 1,
  "piano" => 2,
  "bass" => 6,
  "kick" => 3,
  "snare" => 4,
  "hh" => 5,
}

# +++++ INSTRUMENTS +++++

# KICK:
define :kick do |release = 0.5|
  amp = 0.7
  midi :C, sustain: 1/8.0, port: midi_out, channel: midi_channels["kick"], vel_f: amp
  sleep release
end

# SNARE:
define :snare do |release = 0.5|
  amp = 0.7
  midi :D, sustain: 1/8.0, port: midi_out, channel: midi_channels["snare"], vel_f: amp
  sleep release
end

# HI-HATS:
define :hh do |release = 0.5, accent = false|
  amp = 0.3
  if accent
    amp = 0.5
  end
  
  midi :Bb, sustain: 1/8.0, port: midi_out, channel: midi_channels["hh"], vel_f: amp
  sleep release
end

# BASS:
define :bass do |note = :E2, duration = 0.5, accent = false, stc = false|
  amp = 0.5
  if accent
    amp = 0.7
  end
  
  rel = duration
  if stc
    rel /= 2
  end
  
  midi note, sustain: rel, port: midi_out, channel: midi_channels["bass"], vel_f: amp
  sleep duration
end

# LEAD
define :lead do |note, amp, sust = 1/8.0| do
    midi note, sustain: sust, port: midi_out, channel: midi_channels["lead"], vel_f: amp
end

# PIANO
define :piano do |note, amp, sust = 1/8.0| do
  midi note, sustain: sust, port: midi_out, channel: midi_channels["piano"], vel_f: amp
end

# +++++ Parts +++++

# INTRO A
define :intro_a do
  4.times do
    kick 1
    snare 1
    kick 1/4.0
    kick 3/4.0
    snare 1
  end
end

# INTRO B
define :intro_b do
  # BASS
  in_thread do
      16.times do
        bass :E2, 1/4.0, false, true
        bass :E2, 1/4.0, false, true
        bass :E2, 1/2.0, true
      end
  end
  
  # DRUMS
      control crush, bits: 24
      in_thread do
        16.times do
          hh 1/4.0, true
          hh 1/4.0
          hh 1/4.0, true
          hh 1/4.0
        end
      end
    
    in_thread do
      4.times do
        kick 1
        snare 1
        kick 1/4.0
        kick 3/4.0
        snare 1
      end
    end
  
  sleep 16
end

define :base_a do |loops = 4, amp = 0.7|
  # DRUMS
    in_thread do
      (loops*4).times do
        hh 1/4.0, true
        hh 1/4.0
        hh 1/2.0, true
      end
    end
    
    in_thread do
      (loops).times do
        kick 1
        snare 1
        kick 1/4.0
        kick 3/4.0
        snare 1
      end
    end
  
  # BASS
  in_thread do
      (loops*4).times do
        bass :E2, 1/4.0, true, true
        bass :E2, 1/4.0, false, true
        bass :E2, 1/2.0, true
      end
  end
end

define :base_b do |loops = 4, amp = 0.7, seed = 1|
  # DRUMS
    in_thread do
      (loops*4).times do
        hh 1/2.0, true
        hh 1/2.0
      end
    end
    
    in_thread do
      (loops).times do
        kick 1
        kick 1
        kick 1
        kick 1
      end
    end
  
  # BASS
  b = (scale :E2, :phrygian, num_octaves: 1).ring
  in_thread do
      s = 1337
      (loops).times do
        use_random_seed s
        use_random_source :dark_pink
        4.times do
          bass b.choose, 0.5, true, true
          bass b.choose+12, 0.5, false, false
        end
        s += 256
      end
  end
end

# PART A1
define :part_a1 do |loops = 4, seed = 0, amp_offset = 0.5|
  in_thread do
      use_random_source :light_pink
      notes = (scale :E2, :blues_minor, num_octaves: 3)
      s = seed
      loops.times do
        use_random_seed s
        
        16.times do
          if rand > 0.5
            n = notes.choose
            amp = rand(0.5)+amp_offset
            lead n, amp
          end
          sleep 1/4.0
        end
        s += 1
        s = ((s-seed) % 4)+seed
      end
  end
  
  sleep loops*4
end

# PART A2
define :part_a2 do |loops = 4, seed = 0, amp_offset = 0|
  in_thread do
    part_a1 loops, seed, amp_offset
  end
  
  amp_arp = amp_offset
  wide = 0.4
  in_thread do
    use_random_source :light_pink
    chords = [(chord :E3, :m7, num_octaves: 2),
              (chord :F3, :M7, num_octaves: 2),
              (chord :G3, :M7, num_octaves: 2),
              (chord :A3, :m7, num_octaves: 2),
              (chord :B3, :m7, num_octaves: 2),
              (chord :C4, :M7, num_octaves: 2),
              (chord :D4, :m7, num_octaves: 2)]
    s = seed
    
      (loops/4.0).times do
        use_random_seed s
        
        (4).times do
          ch = chords.choose
          
          # //--- Arpegio
          5.times do
            n = ch.tick
            piano n, amp_arp, 1
            sleep 0.1
          end
          
          n = ch.tick
          piano n, amp_arp, 1/8.0
          sleep 3.5
        end
      end
  end
  
  sleep loops*4
end

midi_all_notes_off

live_loop:clock do
  midi_start if tick == 0
  midi_clock_beat
  sleep 1
end

sleep 4

# ========================================
# MAIN PLAYER
  # ---------------
  #intro_a
  # ---------------
  intro_b
  # ---------------
  base_a 8, 0.5
  part_a1 8, 1
  # ---------------
  2.times do
    base_a 8, 0.3
    part_a2 8, 1, 0.30
    # ---------------
    2.times do
      base_b 4, 0.5
      part_a1 4, 1024, 0.2
    end
    # ---------------
    base_b 4, 0.5
    part_a1 4, 2048, 0.3
    # ---------------
    part_a2 4, 2048, 0.3
    # ---------------
    #base_a 4, 0.4
    part_a2 4, 1, 0.301
  end
  
  part_a2 4, 1, 0.30
  
  2.times do
      part_a1 2, 1, 0.30
    end
  # ---------------
#midi_stop
# ========================================