use_debug false
use_bpm 82

# +++++ INSTRUMENTS +++++

# KICK:
define :kick do |release = 0.5|
  #midi :C, sustain: 1/8.0, port: "01._ethernet_midi_0", channel: 3
  sample :drum_heavy_kick, release: release, pan: 0.2
  sleep release
end


# SNARE:
define :snare do |release = 0.5|
  #midi :D, sustain: 1/8.0, port: "01._ethernet_midi_4", channel: 4
  sample :drum_snare_hard, release: release, pan: -0.2
  sleep release
end

# HI-HATS:
define :hh do |release = 0.5, accent = false|
  amp = 0.3
  if accent
    amp = 0.5
  end
  
  
  #midi :Bb, sustain: 1/8.0, port: "01._ethernet_midi_4", channel: 5
  with_fx :bpf, centre: hz_to_midi(15000), slide: release do |bpf|
    in_thread do
      control bpf, centre: hz_to_midi(10000)
    end
    in_thread do
      synth :noise, release: release, amp: amp, pan: -0.5
    end
  end
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
  
  with_fx :lpf, cutoff: hz_to_midi(1000), cutoff_slide: rel do |lpf|
    in_thread do
      control lpf, cutoff: hz_to_midi(500)
    end
    in_thread do
      #midi note, sustain: 1/8.0, port: "01._ethernet_midi_4", channel: 6, vel_f: amp
      synth :chipbass, note: note, release: rel*0.7, amp: amp
      synth :blade, note: note-12.02, release: rel, amp: amp
      synth :sine, note: note+7.03, release: rel, amp: amp *0.5
      synth :sine, note: note-12.07, release: rel, amp: 1
    end
  end
  sleep duration
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
    with_fx :compressor, amp: 0, slide: 16, threshold: 1 do |cmp|
      control cmp, amp: 0.6, threshold: 0.7
      16.times do
        bass :E2, 1/4.0, false, true
        bass :E2, 1/4.0, false, true
        bass :E2, 1/2.0, true
      end
    end
  end
  
  # DRUMS
  with_fx :compressor, threshold: 0.2, slope_above: 0.3, amp: 0.85 do
    with_fx :bitcrusher, bits: 1, sample_rate: 5500, slide: 8, amp: 0.1 do |crush|
      control crush, bits: 24, sample_rate: 44100, amp: 1
      in_thread do
        16.times do
          hh 1/4.0, true
          hh 1/4.0
          hh 1/4.0, true
          hh 1/4.0
        end
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
  end
  
  sleep 16
end

define :base_a do |loops = 4, amp = 0.7|
  # DRUMS
  with_fx :compressor, threshold: 0.2, slope_above: 0.3, amp: amp do
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
  end
  
  # BASS
  in_thread do
    with_fx :compressor, amp: 0.6, slide: 16, threshold: amp-0.2 do
      (loops*4).times do
        bass :E2, 1/4.0, true, true
        bass :E2, 1/4.0, false, true
        bass :E2, 1/2.0, true
      end
    end
  end
end

define :base_b do |loops = 4, amp = 0.7, seed = 1|
  # DRUMS
  with_fx :compressor, threshold: 0.2, slope_above: 0.3, amp: amp do
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
  end
  
  # BASS
  b = (scale :E2, :phrygian, num_octaves: 1).ring
  in_thread do
    with_fx :compressor, amp: 0.2, slide: 16, threshold: amp-0.2 do
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
end

# PART A1
define :part_a1 do |loops = 4, seed = 0, amp_offset = 0.5|
  in_thread do
    with_fx :ping_pong, feedback: 0.01, max_phase: 1, mix: 0.3, pan_start: 0.5 do
      use_random_source :light_pink
      notes = (scale :E2, :blues_minor, num_octaves: 3)
      s = seed
      loops.times do
        use_random_seed s
        
        16.times do
          if rand > 0.5
            n = notes.choose
            amp = rand(0.5)+amp_offset
            
            #midi n, sustain: 1/8.0, port: "*", channel: 1, vel_f: amp
            
            synth :pluck, note: n, release: 1/4.0, amp: amp, pan: 0
            #synth :pluck, note: n-12, release: 1/4.0, amp: amp*0.6, pan: 0
            synth :sine, note: n-12, release: 1/3.0, amp: amp*0.5, pan: rand_look-0.5
            synth :pretty_bell, note: n, release: 1/2.0, amp: amp*0.2, pan: rand_look-0.5
          end
          sleep 1/4.0
          #midi_note_off n
        end
        s += 1
        s = ((s-seed) % 4)+seed
      end
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
    
    with_fx :reverb, room: 1, mix: 0.5 do
      (loops/4.0).times do
        use_random_seed s
        
        (4).times do
          ch = chords.choose
          
          # //--- Arpegio
          5.times do
            n = ch.tick
            #midi n, sustain: 1, port: "01._ethernet_midi_4", channel: 2, vel_f: amp_arp
            synth :piano, note: n, release: 4, amp: amp_arp, pan: 0-(wide/2.0)
            synth :piano, note: n-12, release: 4, amp: amp_arp * 0.2, pan: wide/2.0
            sleep 0.1
          end
          
          n = ch.tick
          #midi n, sustain: 1/8.0, port: "01._ethernet_midi_4", channel: 2, vel_f: amp_arp
          synth :piano, note: n, release: 4, amp: amp_arp, pan: 0-(wide/2.0)
          synth :piano, note: n-12, release: 4, amp: amp_arp * 0.2, pan: wide/2.0
          sleep 3.5
        end
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
with_fx :reverb, room: 0.7 do
  # ---------------
  intro_a
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
  
  with_fx :flanger, feedback: 0.2, delay: 0.1, depth: 2 do
    2.times do
      part_a1 2, 1, 0.30
    end
  end
  # ---------------
end
midi_stop
# ========================================