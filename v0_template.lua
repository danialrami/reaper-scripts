-- LUFS Audio Project Template Generator v4
-- Description: Creates a project template with orchestral folder structure, submixes, and stem outputs

-- Define the CreateTrack function first so it can be used by Main
function CreateTrack(name)
  local trackIndex = reaper.CountTracks(0)
  reaper.InsertTrackAtIndex(trackIndex, true)
  local track = reaper.GetTrack(0, trackIndex)
  reaper.GetSetMediaTrackInfo_String(track, "P_NAME", name, true)
  return track
end

function Main()
  -- Clear any existing project
  reaper.Main_OnCommand(40296, 0) -- Close all projects
  reaper.Main_OnCommand(40023, 0) -- Create new project
  
  -- Get master track and mute it immediately
  local master = reaper.GetMasterTrack(0)
  reaper.SetMediaTrackInfo_Value(master, "B_MUTE", 1) -- Mute the master track
  
  -- Set project properties
  reaper.SetProjectGrid(0, 1/8) -- Set grid to 1/8 note
  reaper.SNM_SetDoubleConfigVar("projsrate", 48000) -- Set sample rate to 48kHz
  reaper.SetCurrentBPM(0, 120, false) -- Set BPM to 120
  
  -- Define colors (in REAPER's RGB format)
  local colors = {
    0x0000FF, -- Red (Woodwinds)
    0x00AAFF, -- Orange (Brass)
    0x00FFFF, -- Yellow (Perc)
    0x00FF00, -- Green (Guitars)
    0x80FF00, -- Blue-Green (Bass)
    0xFF0000, -- Blue (Synths)
    0xFF0080, -- Indigo (Keys)
    0xFF00FF, -- Violet (Vocals)
    0xFF8000, -- Light Blue (SFX)
    0x8000FF  -- Purple (Strings)
  }
  
  local mixColor = 0xCCCCCC -- Light gray color for mix folder
  local stemsColor = 0xFFFFFF -- White color for stems folder
  
  -- Get master track
  local master = reaper.GetMasterTrack(0)
  
  -- Create a MASTER track (channel strip for master output)
  local masterStripTrack = CreateTrack("MASTER")
  reaper.SetTrackColor(masterStripTrack, 0xFFFFFF) -- White color for master track
  
  -- Route MASTER track to the actual master output
  reaper.CreateTrackSend(masterStripTrack, master)
  
  -- Create MIX folder at the top
  local mixFolderTrack = CreateTrack("MIX")
  reaper.SetMediaTrackInfo_Value(mixFolderTrack, "I_FOLDERDEPTH", 1)
  reaper.SetTrackColor(mixFolderTrack, mixColor)
  
  -- Disable folder from receiving audio from children
  reaper.SetMediaTrackInfo_Value(mixFolderTrack, "B_MAINSEND", 0)
  
  -- Create AUDIO SUBMIX bus inside MIX folder
  local audioSubmixTrack = CreateTrack("AUDIO SUBMIX")
  reaper.SetTrackColor(audioSubmixTrack, mixColor)
  
  -- Route AUDIO SUBMIX to MASTER track
  reaper.CreateTrackSend(audioSubmixTrack, masterStripTrack)
  
  -- Create Reference Track (routed directly to MASTER track)
  local referenceTrack = CreateTrack("Reference Track")
  reaper.SetTrackColor(referenceTrack, mixColor)
  
  -- Route Reference Track directly to MASTER track (bypassing AUDIO SUBMIX)
  reaper.CreateTrackSend(referenceTrack, masterStripTrack)
  
  -- Create Pink Noise Track (routed directly to MASTER track)
  local pinkNoiseTrack = CreateTrack("-6dB Pink Noise")
  reaper.SetTrackColor(pinkNoiseTrack, mixColor)
  
  -- Route Pink Noise Track directly to MASTER track (bypassing AUDIO SUBMIX)
  reaper.CreateTrackSend(pinkNoiseTrack, masterStripTrack)
  
  -- Create Click Track for metronome
  local clickTrack = CreateTrack("Click")
  reaper.SetTrackColor(clickTrack, mixColor)
  
  -- Mute the Click track by default to prevent startup clicks
  reaper.SetMediaTrackInfo_Value(clickTrack, "B_MUTE", 1)
  
  -- Route Click Track directly to MASTER track (bypassing AUDIO SUBMIX)
  reaper.CreateTrackSend(clickTrack, masterStripTrack)
  
  -- Programmatically route metronome to Click track if possible
  -- We'll use the SWS extension function if available
  local hasSWS = reaper.APIExists("BR_GetMediaTrackByGUID")
  
  if hasSWS then
    -- Using SWS Extension to route metronome to track
    local clickTrackId = reaper.GetTrackGUID(clickTrack)
    reaper.SNM_SetIntConfigVar("projmetrotype", 1) -- Set metronome to use output routing
    reaper.SetProjExtState(0, "METRONOME", "OUTPUTTRACK", clickTrackId)
  else
    -- Without SWS, use track notes to guide the user
    local _, notesChunk = reaper.GetSetMediaTrackInfo_String(clickTrack, "P_NOTES", "", false)
    notesChunk = notesChunk .. "To route metronome to this track:\n1. Right-click the metronome button\n2. Select 'Route metronome output'\n3. Choose this track as the destination\n\nNote: Installing the SWS extension would allow this script to set up metronome routing automatically."
    reaper.GetSetMediaTrackInfo_String(clickTrack, "P_NOTES", notesChunk, true)
  end
  
  -- Close the MIX folder before adding other content
  reaper.SetMediaTrackInfo_Value(clickTrack, "I_FOLDERDEPTH", -1)
  
  -- Store submix tracks for later stem routing
  local submixTracks = {}
  local verbSubmixTracks = {}
  
  -- Create folders and submixes
  local folders = {"Woodwinds", "Brass", "Perc", "Guitars", "Bass", "Synths", "Keys", "Vocals", "SFX", "Strings"}
  
  for i, folderName in ipairs(folders) do
    -- Create folder track
    local folderTrack = CreateTrack(folderName)
    reaper.SetMediaTrackInfo_Value(folderTrack, "I_FOLDERDEPTH", 1)
    reaper.SetTrackColor(folderTrack, colors[i])
    
    -- Disable folder from receiving audio from children
    reaper.SetMediaTrackInfo_Value(folderTrack, "B_MAINSEND", 0)
    
    -- Create submix track within folder
    local submixTrack = CreateTrack(folderName .. " Submix")
    reaper.SetTrackColor(submixTrack, colors[i])
    reaper.CreateTrackSend(submixTrack, audioSubmixTrack)
    
    -- Store submix track for later stem routing
    submixTracks[folderName] = submixTrack
    
    -- Create line in track within folder
    local lineInTrack = CreateTrack(folderName .. " Line In")
    reaper.SetTrackColor(lineInTrack, colors[i])
    reaper.CreateTrackSend(lineInTrack, submixTrack)
    
    -- Create Verb Submix folder
    local verbFolderTrack = CreateTrack(folderName .. " Verb Submix")
    reaper.SetMediaTrackInfo_Value(verbFolderTrack, "I_FOLDERDEPTH", 1)
    reaper.SetTrackColor(verbFolderTrack, colors[i])
    
    -- Disable verb folder from receiving audio from children
    reaper.SetMediaTrackInfo_Value(verbFolderTrack, "B_MAINSEND", 0)
    
    -- Route Verb Submix directly to AUDIO SUBMIX (not to instrument submix)
    reaper.CreateTrackSend(verbFolderTrack, audioSubmixTrack)
    
    -- Store verb submix track for later stem routing
    verbSubmixTracks[folderName] = verbFolderTrack
    
    -- Create Short Verb track (muted by default, no plugins)
    local shortVerbTrack = CreateTrack("Short Verb")
    reaper.SetTrackColor(shortVerbTrack, colors[i])
    reaper.SetMediaTrackInfo_Value(shortVerbTrack, "B_MUTE", 1) -- Mute the track
    -- Route Short Verb to Verb Submix
    reaper.CreateTrackSend(shortVerbTrack, verbFolderTrack)
    
    -- Create Long Verb track (muted by default, no plugins)
    local longVerbTrack = CreateTrack("Long Verb")
    reaper.SetTrackColor(longVerbTrack, colors[i])
    reaper.SetMediaTrackInfo_Value(longVerbTrack, "B_MUTE", 1) -- Mute the track
    -- Route Long Verb to Verb Submix
    reaper.CreateTrackSend(longVerbTrack, verbFolderTrack)
    
    -- Close the Verb Submix folder
    reaper.SetMediaTrackInfo_Value(longVerbTrack, "I_FOLDERDEPTH", -1)
    
    -- Create sends from Line In to both verb tracks (post-fader, post-pan)
    local sendToShort = reaper.CreateTrackSend(lineInTrack, shortVerbTrack)
    local sendToLong = reaper.CreateTrackSend(lineInTrack, longVerbTrack)
    
    -- Configure sends to be post-fader, post-pan at 0dB
    if sendToShort >= 0 then
      reaper.SetTrackSendInfo_Value(lineInTrack, 0, sendToShort, "I_SENDMODE", 3) -- 3 = post-fader, post-pan
      reaper.SetTrackSendInfo_Value(lineInTrack, 0, sendToShort, "D_VOL", 1.0) -- Set send volume to 0dB
    end
    
    if sendToLong >= 0 then
      reaper.SetTrackSendInfo_Value(lineInTrack, 0, sendToLong, "I_SENDMODE", 3) -- 3 = post-fader, post-pan
      reaper.SetTrackSendInfo_Value(lineInTrack, 0, sendToLong, "D_VOL", 1.0) -- Set send volume to 0dB
    end
    
    -- Close the main instrument folder
    reaper.SetMediaTrackInfo_Value(longVerbTrack, "I_FOLDERDEPTH", -2)
  end
  
  -- Create STEMS folder
  local stemsFolderTrack = CreateTrack("STEMS")
  reaper.SetMediaTrackInfo_Value(stemsFolderTrack, "I_FOLDERDEPTH", 1)
  reaper.SetTrackColor(stemsFolderTrack, stemsColor)
  
  -- Disable folder from receiving audio from children
  reaper.SetMediaTrackInfo_Value(stemsFolderTrack, "B_MAINSEND", 0)
  
  -- Create stem tracks for each submix and verb submix
  for i, folderName in ipairs(folders) do
    -- Create stem track for regular submix
    local stemTrack = CreateTrack(folderName .. " Stem")
    reaper.SetTrackColor(stemTrack, colors[i])
    
    -- Disable the main output of the stem track
    reaper.SetMediaTrackInfo_Value(stemTrack, "B_MAINSEND", 0)
    
    -- Create post-fader send from submix to stem track
    local sendToStem = reaper.CreateTrackSend(submixTracks[folderName], stemTrack)
    if sendToStem >= 0 then
      reaper.SetTrackSendInfo_Value(submixTracks[folderName], 0, sendToStem, "I_SENDMODE", 3) -- 3 = post-fader, post-pan
      reaper.SetTrackSendInfo_Value(submixTracks[folderName], 0, sendToStem, "D_VOL", 1.0) -- Set send volume to 0dB
    end
    
    -- Create stem track for verb submix
    local verbStemTrack = CreateTrack(folderName .. " Verb Stem")
    reaper.SetTrackColor(verbStemTrack, colors[i])
    
    -- Disable the main output of the verb stem track
    reaper.SetMediaTrackInfo_Value(verbStemTrack, "B_MAINSEND", 0)
    
    -- Create post-fader send from verb submix to verb stem track
    local sendToVerbStem = reaper.CreateTrackSend(verbSubmixTracks[folderName], verbStemTrack)
    if sendToVerbStem >= 0 then
      reaper.SetTrackSendInfo_Value(verbSubmixTracks[folderName], 0, sendToVerbStem, "I_SENDMODE", 3) -- 3 = post-fader, post-pan
      reaper.SetTrackSendInfo_Value(verbSubmixTracks[folderName], 0, sendToVerbStem, "D_VOL", 1.0) -- Set send volume to 0dB
    end
  end
  
  -- Create Sum Stem track (for AUDIO SUBMIX)
  local sumStemTrack = CreateTrack("Sum Stem")
  reaper.SetTrackColor(sumStemTrack, stemsColor)
  
  -- Disable the main output of the sum stem track
  reaper.SetMediaTrackInfo_Value(sumStemTrack, "B_MAINSEND", 0)
  
  -- Create post-fader send from AUDIO SUBMIX to Sum Stem track
  local sendToSumStem = reaper.CreateTrackSend(audioSubmixTrack, sumStemTrack)
  if sendToSumStem >= 0 then
    reaper.SetTrackSendInfo_Value(audioSubmixTrack, 0, sendToSumStem, "I_SENDMODE", 3) -- 3 = post-fader, post-pan
    reaper.SetTrackSendInfo_Value(audioSubmixTrack, 0, sendToSumStem, "D_VOL", 1.0) -- Set send volume to 0dB
  end
  
  -- Create Click Stem track
  local clickStemTrack = CreateTrack("Click Stem")
  reaper.SetTrackColor(clickStemTrack, mixColor)
  
  -- Disable the main output of the click stem track
  reaper.SetMediaTrackInfo_Value(clickStemTrack, "B_MAINSEND", 0)
  
  -- Create post-fader send from Click track to Click Stem track
  local sendToClickStem = reaper.CreateTrackSend(clickTrack, clickStemTrack)
  if sendToClickStem >= 0 then
    reaper.SetTrackSendInfo_Value(clickTrack, 0, sendToClickStem, "I_SENDMODE", 3) -- 3 = post-fader, post-pan
    reaper.SetTrackSendInfo_Value(clickTrack, 0, sendToClickStem, "D_VOL", 1.0) -- Set send volume to 0dB
  end
  
  -- Close the STEMS folder
  reaper.SetMediaTrackInfo_Value(clickStemTrack, "I_FOLDERDEPTH", -1)
  
  -- Add Pink Noise generator to the Pink Noise track (if JSFx plugins are available)
  local pinkNoiseJSFX = reaper.TrackFX_AddByName(pinkNoiseTrack, "JS: Tone Generator", false, -1)
  if pinkNoiseJSFX >= 0 then
    -- Set to pink noise, -6dB
    reaper.TrackFX_SetParam(pinkNoiseTrack, pinkNoiseJSFX, 0, 4) -- 4 = Pink noise
    reaper.TrackFX_SetParam(pinkNoiseTrack, pinkNoiseJSFX, 1, 0.5) -- Volume (0.5 = approximately -6dB)
    reaper.TrackFX_SetParam(pinkNoiseTrack, pinkNoiseJSFX, 2, 0) -- Pan center
    
    -- Mute the track by default (user can unmute when needed)
    reaper.SetMediaTrackInfo_Value(pinkNoiseTrack, "B_MUTE", 1)
  end
  
  -- Save project to specified folder
  local projectPath = reaper.GetOS():find("Win") and os.getenv("USERPROFILE") or os.getenv("HOME")
  projectPath = projectPath .. "/Downloads/projects/REAPER/template_v4.rpp"
  
  -- Make sure the directory exists
  local dir = projectPath:match("(.+)/[^/]+$")
  os.execute('mkdir -p "' .. dir .. '"')
  
  -- Save project
  reaper.Main_SaveProjectEx(0, projectPath, 0)
  
  -- Display confirmation message
  reaper.ShowConsoleMsg("Project template saved to: " .. projectPath .. "\n")
  
  -- Add a small delay using os.execute sleep (platform dependent)
  if reaper.GetOS():find("Win") then
    os.execute("timeout /t 2 >nul") -- Windows: wait 2 seconds
  else
    os.execute("sleep 2") -- macOS/Linux: wait 2 seconds
  end
  
  -- Unmute the master track
  reaper.SetMediaTrackInfo_Value(master, "B_MUTE", 0)
  reaper.ShowConsoleMsg("Master track unmuted.\n")
end

Main()