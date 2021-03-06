   
%%% *************************************************************
%%% Copyright (C) 2003-2005 Torsten Anders (t.anders@qub.ac.uk) 
%%% This program is free software; you can redistribute it and/or
%%% modify it under the terms of the GNU General Public License
%%% as published by the Free Software Foundation; either version 2
%%% of the License, or (at your option) any later version.
%%% This program is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%% GNU General Public License for more details.
%%% *************************************************************

/** % This functor allows to customise a few settings: change to stateful which can be adjusted in, e.g., .ozrc
% */

functor
import
   Browser(browse:Browse)
   %% Inspector(inspect:Inspect)
   Pickle Explorer Error Resolve Emacs
   
   Strasheela at '../Strasheela.ozf'
   GUtils at 'GeneralUtils.ozf'
   LUtils at 'ListUtils.ozf'
   MUtils at 'MusicUtils.ozf'
   Score at 'ScoreCore.ozf'
   Out at 'Output.ozf'

   %% !! dependency on extension!
   ScoreInspector at 'x-ozlib://anders/strasheela/ScoreInspector/ScoreInspector.ozf'
%    HS at 'x-ozlib://anders/strasheela/HarmonisedScore/HarmonisedScore.ozf'
%    Motif at 'x-ozlib://anders/strasheela/Motif/Motif.ozf'
%    Measure at 'x-ozlib://anders/strasheela/Measure/Measure.ozf'
%    CTT at 'x-ozlib://anders/strasheela/ConstrainTimingTree/ConstrainTimingTree.ozf'
%    Pattern at 'x-ozlib://anders/strasheela/Pattern/Pattern.ozf'
   

require
   OS
   %% !! tmp
   Path at 'x-ozlib://anders/tmp/Path/Path.ozf'
   
prepare
   %% NB: functor must be re-compiled whenever it is moved in the file system or to another machine
   /** %% The top-level directory of the Strasheela sources (i.e., where the sources have been compiled) as string. 
   %% */
   StrasheelaSourceDir = {Path.dirname {OS.getCWD}}
%   StrasheelaDir = {Path.dirname {OS.getCWD}}
   
export
   %PATH
   %Csound Sndplay Lilypond PdfViewer SendOSC
   %DefaultSScoDir
   %DefaultCsoundOrcDir DefaultCsoundScoDir DefaultSoundDir
   %DefaultOrcFile DefaultCsoundFlags
   %DefaultLilypondDir DefaultSuperColliderDir
   GetStrasheelaEnv PutStrasheelaEnv GetFullStrasheelaEnv SetFullStrasheelaEnv
   SaveStrasheelaEnv LoadStrasheelaEnv
   SetNoteLengthsRecord SymbolicDurToInt
   GetBeatDuration SetBeatDuration GetTempo SetTempo
   SetTuningTable UnsetTuningTable GetTuningTable
   SetArticulationMap GetArticulationSymbol SetFomusArticulationMap GetFomusArticulation
   SetMaxLilyRhythm
   AddExplorerOuts_Standard AddExplorerOuts_Extended
%   StrasheelaDir
   StrasheelaSourceDir StrasheelaInstallDir
   
define

   /** %% The top-level directory of the Strasheela installation (i.e. the full local pathname of 'x-ozlib://anders/strasheela/') as atom. 
   %% */
   StrasheelaInstallDir = {Resolve.localize 'x-ozlib://anders/strasheela/'}.1
   
   %% $PATH environment var: seems I need to do {OS.putEnv 'PATH' Init.pATH} on MacOS
   %%
   % PATH = '/Users/t/bin/:/usr/local/bin/:/Users/t/.oz/bin:/usr/local/oz/bin:/sw/bin:/sw/sbin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/X11R6/bin'
   % PATH = '/usr/java/jdk1.3.1_08/bin:/usr/local/plt/bin:/home/t/oz/mozart-install/bin:/home/t/.oz/bin:/home/t/scripte:/usr/lib/mozart/bin:/usr/java/jdk1.3.1_08/bin:/usr/local/plt/bin:/home/t/oz/mozart-install/bin:/home/t/.oz/bin:/home/t/scripte:/usr/lib/mozart/bin:/usr/local/bin:/usr/bin:/bin:/usr/X11R6/bin:/home/t/bin'
   
   %% Please adjust pathes here, if necessary. The (re-)compile the SDL by executing the script in <SDL-dir>/scripts/make-SDL
   %%
   %% !! temp: absolute paths ($PATH of shell forked by
   %% Oz  not bound be .profile on Mac)
   %% Csound = '/usr/local/bin/csound' % csound
   %% Sndplay = '/usr/local/bin/sndplay' % sndplay % sweep 
   %% Lilypond = '/sw/bin/lilypond' %lilypond
   % PdfViewer = '/Applications/Preview.app/Contents/MacOS/Preview'  % gv
   % SendOSC = '/Users/t/Desktop/OSC/sendOSCFolder/sendOSC'
   %Csound = csound
   %Sndplay = sndplay 
   %Sndplay = sweep 
   %Lilypond = lilypond
   %PdfViewer = '/Applications/Preview.app/Contents/MacOS/Preview'  % gv
   %PdfViewer = gv
   %SendOSC = sendOSC

   %DefaultCsoundOrcDir = '/home/t/csound/SDL-demo/'
   %DefaultCsoundScoDir = '/home/t/tmp/'
   %DefaultSoundDir = '/home/t/tmp/'
   %DefaultLilypondDir = '/home/t/tmp/'
   %TmpDir = '/tmp/'
   %TmpDir = '/Users/t/tmp/'
   %TmpDir = '/home/t/sound/tmp/'
   %DefaultCsoundOrcDir = '/Users/t/csound/SDL-demo/'
   %DefaultSScoDir = TmpDir
   %DefaultCsoundOrcDir = '/home/t/csound/SDL-demo/'
   %DefaultCsoundScoDir = TmpDir
   %DefaultSoundDir = TmpDir 
   % SFDIR = '/Users/t/tmp/'
   %DefaultLilypondDir = TmpDir
   %DefaultSuperColliderDir = TmpDir 

   %DefaultOrcFile = 'pluck.orc'
   %DefaultOrcFile = 'simple-organ.orc'
   %DefaultCsoundFlags = ['-A' '-g']
   %DefaultCsoundFlags = ['-A']

   local
      Dict = {NewCell
	      {Record.toDictionary
	       unit(%% apps
		    csound:csound
		    sndPlayer:nil % audacity
		    %% !! BUG/tmp: setting to sndplay instead of nil, because loading init file does not work properly..
%		   cmdlineSndPlayer:sndplay % nil
		    cmdlineSndPlayer:nil
		    lilypond:lilypond
		    'convert-ly':'convert-ly'
		    pdfViewer:acroread
		    sendOSC:sendOSC
		    dumpOSC:dumpOSC
		    csvmidi: csvmidi
		    midicsv: midicsv
		    midiPlayer: nil % pmidi
		    defaultMidiPlayerFlags: nil % pmidi: MIDI output of my sound card: ['-p 64:0']
		    xterm: xterm
		    %% !!?? suitable var name and value?
		    'X11.app': '/Applications/Utilities/X11.app'
		    netcat:nc
		    
		    %% files and dirs
		    strasheelaSourceDir:StrasheelaSourceDir
		    strasheelaInstallDir:StrasheelaInstallDir
		    % strasheelaDir:StrasheelaDir
		    tmpDir:'/tmp/'
		    defaultSoundDir:'/tmp/'
		    defaultSScoDir:'/tmp/'
		    defaultLilypondDir:'/tmp/'
		    defaultLilypondFlags:nil
		    defaultCsoundScoDir:'/tmp/'
		    defaultCsoundOrcDir:StrasheelaInstallDir#"/goodies/csound/"
		    defaultOrcFile:"pluck.orc" 
		    defaultCsoundSoundExtension: ".aiff"
		    defaultCsoundFlags:['-A' '-g']
		    defaultCSVDir:'/tmp/'
		    defaultCSVFlags:['-v']
		    defaultMidiDir:'/tmp/'
		    defaultSuperColliderDir:'/tmp/'
		    defaultCommonMusicDir:'/tmp/'
		    defaultENPDir:'/tmp/'
		    fomus:fomus
		    defaultFomusDir:'/tmp/'
		    firefox:'firefox'
		    
%		    textEditor:emacsclient
% 		    strasheelaFunctors: env('Strasheela':Strasheela
% 					    'HS':HS
% 					    'Motif':Motif
% 					    'Measure':Measure
% 					    'CTT':CTT
% 					    'Pattern':Pattern)
		    strasheelaFunctors: env('Strasheela':Strasheela)
		   )}}
   in
      /** %% Access the value of the Strasheela 'environment variable' Key. 
      %% */
      fun {GetStrasheelaEnv Key}
	 %{Browse GetStrasheelaEnv#Key}
	 {Dictionary.condGet @Dict Key nil} 
      end
      /** %% Set the value of the Strasheela 'environment variable' Key to Value. These variables are used, e.g., by the various output format transformers. 
      %% */
      proc {PutStrasheelaEnv Key Value}
	 {Dictionary.put @Dict Key Value}
      end

      /** %% Returns the full Strasheela environment as record. 
      %% */
      fun {GetFullStrasheelaEnv}
	 {Dictionary.toRecord unit @Dict}
      end
      /** %% Overwrites the full Strasheela environment (R is a record).
      %% */
      proc {SetFullStrasheelaEnv R}
	 Dict := {Record.toDictionary R}
      end
   end
   
   /** %% Save the full Strasheela environment as a pickle at Path. 
   %% */
   proc {SaveStrasheelaEnv Path}
      %% write to standard out..
      {Pickle.save {GetFullStrasheelaEnv} Path}
   end
   /** %% Load the full Strasheela environment from a pickle saved at Path (this was before created with SaveStrasheelaEnv). 
   %% */
   proc {LoadStrasheelaEnv Path}
      {SetFullStrasheelaEnv {Pickle.load Path}}
   end


   %%
   %% symbolic rhythm representation
   %%
   %% NOTE: needs cleaning up, some defs here, some defs in MusicUtils.oz
   % local
   %    NoteLengthsRecord = {NewCell unit}
   % in
      /** %% Sets the global mapping of symbolic note lengths (atoms which are record features) to duration values (integers). Beat (int) is the timeUnit value in beat(Beat) of the score. TupletFractions (list of ints) is a list of tuplet fractions to take into consideration (e.g., [3 5] denotes triplets and quintuplets).
      %% See MUtils.makeNoteLengthsRecord and MUtils.makeNoteLengthsTable for details.
      %%
      %% NB: there is no default defined for this setting, because it depends on the time unit of your score.
      %% */
      proc {SetNoteLengthsRecord Beat TupletFractions}
	 {MUtils.setNoteLengthsRecord Beat TupletFractions}
	 % NoteLengthsRecord := {MUtils.makeNoteLengthsRecord Beat TupletFractions}
      end

      local
	 /** %% Not efficient, but pairs are more convenient to notate than lists..
	 %% */
	 fun {PairRest Pair}
	    {List.toTuple '#' {Record.toList Pair}.2}
	 end
      in
	 /** %% Function expecting a symbolic duration name and returning the corresponding numeric duration depending on the global setting. Tied notes can be notated as pairs of symbolic duration names. If Spec is an integer, it is passed unchanged. 
	 %% */
	 fun {SymbolicDurToInt Spec}
	    case Spec of '#'(...) then
	       if {Width Spec} > 1 then 
		  {SymbolicDurToInt Spec.1} + {SymbolicDurToInt {PairRest Spec}}
	       else {SymbolicDurToInt Spec.1}
	       end
	    else 
	       if {IsInt Spec} then Spec else
		  {MUtils.getNoteLengthsRecord}.Spec
		  % @NoteLengthsRecord.Spec
	       end
	    end
	 end
      % end

   end

   
   local
      BeatDuration = {NewCell 1.0}
   in
      /** %% Access the current beat duration in seconds (a float, defaults to 0.8).
      %% */
      fun {GetBeatDuration}
	 {Cell.access BeatDuration}
      end
      /** %% Access the current tempo in beats per minute (a float, defaults to 75.0).
      %% */
      fun {GetTempo}
	 60.0 / {Cell.access BeatDuration} 
      end
      /** %% Set the beat duration in seconds to Dur which must be a float.
      %% */
      proc {SetBeatDuration Dur}
	 %% assert important, because error would possibly occur much later and would be very hard to identify. Moreover, it is likely that an integer is given as Dur. 
	 {GUtils.assert {IsFloat Dur}
	  kernel(type
		 SetBeatDuration
		 [Dur]		% args
		 float % type
		 1 % arg position
		 nil)}
	 {Cell.assign BeatDuration Dur}
      end
      /** %% Set the tempo in beats per minute which must be a float.
      %% */
      proc {SetTempo Tempo}
	 {GUtils.assert {IsFloat Tempo}
	  kernel(type
		 SetTempo
		 [Tempo]		% args
		 float % type
		 1 % arg position
		 nil)}
	 {Cell.assign BeatDuration (60.0 / Tempo)}
      end
   end

   local
      TuningTable = {NewCell nil}
   in
      /** %% Globally sets the tuning table to Table. The tuning table is used by all output formats which use the (full) float returned by the pitch parameter method getValueInMidi (e.g. the note method getPitchInMidi, which is used by default by Csound and microtonal MIDI output). The format of the tuning table declaration is somewhat similar to the Scala scale file format (cf. http://www.xs4all.nl/~huygensf/scala/scl_format.html). Table is a record of integer features (typically a tuple) of pitch specs. A pitch spec is either a float (measured in cent) or a ratio notated Nom#Den. The first degree is implict (always 1/1 or 0.0). The table value with the highest feature (i.e. the last value in a tuple) is the period interval.
      %%
      %% Optional features of Table
      %% 'size' (an int): the pitch class interval that constitutes an octave. By default, the size is implicit (the width of Table).
      %%
      %% */
      %%
      %% ?? It is recommended to set the pitchUnit of notes to a value matching the size of the tuning table (e.g., for a tuning table with 31 pitches per octave/period, the pitchUnit et31 is recommended). Otherwise, the tuning of some pitch classes is undefined.
      %%
      proc {SetTuningTable Table}
	 TuningTable := {MUtils.fullTuningTable Table}
      end
      /** %% By default, no tuning table is set and methods like getPitchInMidi return pitches corresponding to an equal-tempered scale. UnsetTuningTable sets this default behaviour back. 
      %% */
      proc {UnsetTuningTable}
	 TuningTable := nil
      end

      /** %% [aux def, not intended for user] Returns a full tuning table (cf. MUtils.fullTuningTable for the format). 
      %% */ 
      proc {GetTuningTable ?Table}
	Table = @TuningTable
      end
   end


   /** %% When outputting a Lilypond file, Strasheela automatically splits very long notes (or other score objects notated by notes such as chords or scales) into multiple notes connected by ties. The maximum duration notated by a single note can be set with this procedure. Dur is a float measured in quarternotes. For example, 2.0 indicates a halve note and 0.5 an eighth note. The maximum duration supported by Lilypond is a longa (16.0). The default is 4.0 (a whole note).
   %% It is recommended to set Dur to the length of your bars (e.g., 4.0 for 4/4).
   %%
   %% Note: this definition is an alias for Out.setMaxLilyRhythm.
   %% */ 
   proc {SetMaxLilyRhythm Dur}
      {Out.setMaxLilyRhythm Dur}
   end


   local
      ArticulationMap = {NewCell nil}
      FomusArticulationMap = {NewCell nil}
   in
      /** %% Sets the mapping of an (average) articulation value to the corresponding symbolic articulation. This articulation symbol is abstract and for music output must be mapped to the marks of the corresponding output format (e.g., Fomus or ENP). The default is
      unit(0: rest
	   25: staccatissimo
	   50: staccato
	   70: 'mezzo staccato'
	   90: 'non legato'
	   102: legato)
      %%
      %% When overwriting this default you should only change the integers, but not the symbolic names. Changing these values is useful for fine-tuning which articulation percentage value corresponds to which symbolic articulation. You can also leave out symbolic articulations, e.g., remove the 'mezzo staccato' and 'staccatissimo' to simplify your resulting notation.
      %% */
      proc {SetArticulationMap Map}
	 ArticulationMap := Map
      end
      %% Default Map
      {SetArticulationMap unit(0: rest
			       25: staccatissimo
			       50: staccato
			       70: 'mezzo staccato'
			       95: 'non legato'
			  % 90: portato
			       107: legato)}
      /** %% Expects an articulation parameter value (an int, percentage of duration). Returns the symbolic articulation (an atom) of the given articulation parameter.
      %% */
      fun {GetArticulationSymbol Articulation}
	 ArtMap = @ArticulationMap
	 NumKeys = {Arity ArtMap}
	 MatchingMin = {LUtils.findBest NumKeys
			fun {$ Key1 Key2}
			   {Abs Key1 - Articulation} < {Abs Key2 - Articulation}
			end}
      in
	 ArtMap.MatchingMin
      end
      
      /** %% Sets the mapping of symbolic articulations (see SetArticulationMap) to the corresponding Fomus marks. The default is
      unit(staccatissimo: '!' 
	   staccato: '.' 
	   'mezzo staccato': '/.'
	   'non legato': nil
	   %% start/continue/end legato slur
	   legato: ['(..' '.(.' '..)'] 
	  )

      %% When overwriting this default you should only change the Fomus values, but not the symbolic names.
      
      %% Note that Fomus also supports other legato varieties, depending on whether the mark can (not) span rests, and marks can (not) touch, see http://fomus.sourceforge.net/doc.html/Marks.html.
      %% */
      proc {SetFomusArticulationMap Map}
	 FomusArticulationMap := Map
      end
      %% Default Map
      {SetFomusArticulationMap unit(rest: 'rest'
				    staccatissimo: '!' 
				    staccato: '.' 
				    'mezzo staccato': '/.'
				    'non legato': nil
				    legato: ['(..' '.(.' '..)'] 
				   )}
      
      /** %% Expects an articulation parameter value (an int, percentage of duration). Returns the corresponding Fomus mark(s).
      %% */
      fun {GetFomusArticulation Articulation}
	 @FomusArticulationMap.{GetArticulationSymbol Articulation}
      end
      
   end
   
   
   local
%       fun {ToPPrintRecord MyScore Excluded}
% 	 {MyScore toPPrintRecord($ features:[info items parameters value 'unit']
% 				 excluded:Excluded)}
%       end
%       proc {ScoreBrowse I X Excluded}
% 	 if {Score.isScoreObject X}
% 	 then {Browse I#{ToPPrintRecord X Excluded}}
% 	 else {Browse I#X}
% 	 end
%       end
%       proc {ScoreInspect I X Excluded}
% 	 if {Score.isScoreObject X}
% 	 then {Inspect I#{ToPPrintRecord X Excluded}}
% 	 else {Inspect I#X}
% 	 end
%       end
%       proc {BrowseMini I X}
% 	 {ScoreBrowse I X
% 	  [isTimeInterval isAmplitude
% 	   fun {$ X} 
% 	      Info = {X getInfo($)}
% 	   in
% 	      {IsDet Info} andthen
% 	      Info==endTime 
% 	   end]}
%       end
%       proc {InspectMini I X}
% 	 {ScoreInspect I X
% 	  [isTimeInterval isAmplitude
% 	   fun {$ X} 
% 	      Info = {X getInfo($)}
% 	   in
% 	      {IsDet Info} andthen
% 	      Info==endTime 
% 	   end]}
%       end
%       proc {InspectAllParams I X}
% 	 {ScoreInspect I X nil}
%       end
%       proc {BrowseAllParams I X}
% 	 {ScoreBrowse I X nil}
%       end
%       proc {BrowseInitRecord I X}
% 	 if {Score.isScoreObject X}
% 	 then {Browse I#{X toInitRecord($)}}
% 	 else {Browse I#X}
% 	 end
%       end
%       proc {InspectInitRecord I X}
% 	 if {Score.isScoreObject X}
% 	 then {Inspect I#{X toInitRecord($)}}
% 	 else {Inspect I#X}
% 	 end
%       end
      proc {ArchiveInitRecord I X}
	 if {Score.isScoreObject X}
	 then 
	    FileName = out#{GUtils.getCounterAndIncr}
	 in
	    {Out.outputScoreConstructor X
	     unit(file: FileName)}
	 end
      end
      proc {BrowseInitRecord I X}
	 if {Score.isScoreObject X}
	 then {Browse I#{X toInitRecord($)}}
	 end
      end
%       proc {ShowInitRecord I X}
% 	 if {Score.isScoreObject X}
% 	 then {Out.show {X toInitRecord($)}}
% 	 end
%       end
%       proc {ArchiveENPNonMensural I X}
% 	 if {Score.isScoreObject X}
% 	 then 
% 	    FileName = out#{GUtils.getCounterAndIncr}
% 	 in
% 	    {Out.outputNonmensuralENP X
% 	     unit(file: FileName
% 		  getVoices:fun {$ X} [X] end)}
% 	 end
%       end

      proc {DeclareMyScore I X}
	 if {Score.isScoreObject X}
	 then {Emacs.condSend.compiler
	       enqueue(feedVirtualString(
			  "declare MyScore = {Score.make"
			  #{Out.toScoreConstructor X unit(prefix:"")}
			  #" unit}"
			  ))}
	 end
      end
      
      /** %% In case the outer container of X is a sim, then its content is interpreted as ENP parts (each part with a single voice and multiple chords where each chord contains a single note). Otherwise the whole score is output into a single part (with a single voice and multiple chords where each chord contains a single note).
      %% */
      proc {ArchiveENPNonMensural I X}
	 if {Score.isScoreObject X}
	 then 
	    FileName = out#{GUtils.getCounterAndIncr}
	 in
	    {Out.outputNonmensuralENP X
	     unit(file:FileName
		  getParts:fun {$ X}
			      if {X isSimultaneous($)}
			      then {X getItems($)}
			      else [X]
			      end
			   end
		  getVoices:fun {$ X} [X] end
		  %% !!?? do I need special care for multiple sim notes (forming a chord)?
		  getChords:fun {$ X} {X collect($ test:isNote)} end
		  getNotes:fun {$ X} [X] end)}
	 end
      end
      proc {ArchiveFomus I X}
	 if {Score.isScoreObject X}
	 then 
	    FileName = out#{GUtils.getCounterAndIncr}
	 in
	    {Out.outputFomus X
	     unit(file: FileName)}
	 end
      end
      proc {RenderFomus I X}
	 if {Score.isScoreObject X}
	 then 
	    FileName = out#{GUtils.getCounterAndIncr}
	 in
	    {Out.renderFomus X
	     unit(file: FileName)}
	 end
      end
%       proc {InspectAsFullRecord I X}
% 	 if {Score.isScoreObject X}
% 	 then {Inspect I#{X toFullRecord($)}}
% 	 else {Inspect I#X}
% 	 end
%       end
%       proc {BrowseAsFullRecord I X}
% 	 if {Score.isScoreObject X}
% 	 then {Browse I#{X toFullRecord($)}}
% 	 else {Browse I#X}
% 	 end
%       end
      proc {RenderCsound I X}
	 if {Score.isScoreObject X}
	 then 
	    FileName = out#{GUtils.getCounterAndIncr}
	 in
	    {Out.renderAndPlayCsound X
	     unit(file: FileName
		  title:I)}
	 end
      end
      proc {RenderLilypond I X}
	 if {Score.isScoreObject X}
	 then 
	    FileName = out#{GUtils.getCounterAndIncr}
	 in
	    {Out.renderAndShowLilypond X
	     unit(file: FileName#'-'#I)}
	 end
      end
      proc {RenderLilypondFomus I X}
	 if {Score.isScoreObject X}
	 then 
	    FileName = out#{GUtils.getCounterAndIncr}
	 in
	    {Out.renderFomus X
	     unit(file: FileName#'-'#I)}
	 end
      end
      % %% Problem: def depends on PCs per octave, so I should not include that here
      % proc {RenderLilypondFomus_HS I X}
      % 	 if {Score.isScoreObject X}
      % 	 then 
      % 	    FileName = out#{GUtils.getCounterAndIncr}
      % 	 in
      % 	    {Out.renderFomus X
      % 	     unit(file: FileName#'-'#I
      % 		 eventClauses:[%% HS notes
      % 			       {HS.out.makeNoteToFomusClause
      % 				unit(% getPitchClass: midi
      % 				     % table: ET31.out.fomusPCs_DoubleAccs
      % 				     % table:ET31.out.fomusPCs_Quartertones
      % 				     getSettings: HS.out.makeNonChordTone_FomusMarks)}
      % 			       {HS.out.makeChordToFomusClause
      % 				unit(% getPitchClass: midi
      % 				     % table: ET31.out.fomusPCs_DoubleAccs
      % 				     getSettings:HS.out.makeChordComment_FomusForLilyMarks)}
      % 			       {HS.out.makeScaleToFomusClause
      % 				unit(% getPitchClass: midi
      % 				     table: ET31.out.fomusPCs_DoubleAccs
      % 				     getSettings:HS.out.makeScaleComment_FomusForLilyMarks)}
      % 			       {Measure.out.makeUniformMeasuresToFomusClause
      % 				unit(explicitTimeSig: false)}])}
      % 	 end
      % end
      proc {RenderMidi I X}
	 if {Score.isScoreObject X}
	 then 
	    FileName = out#{GUtils.getCounterAndIncr}
	 in
	    {Out.midi.renderAndPlayMidiFile X
	     unit(file:FileName#'-'#I)}
	 end
      end
%    TestSCEventOut =
%      {Out.makeSCEventOutFn
%       fun {$ X}
% 	 Pitch = {X getPitchInMidi($)}
% 	 Amp = {X getAmplitudeInNormalized($)}
%       in
% 	 %% !! third and forth vibraphone param fixed here  
% 	 %%'~vibraphone.makePlayer(['#Pitch#',3,7,1])'
% 	 %%
% 	 'Patch(\\simpleAnalog,['#Pitch#','#Amp#'])'
%       end}
   in
      
      /** %% Extends the Explorer menu "Notes -> Information Action" by a few entries to output scores into various formats just by clicking the solution nodes in the Explorer.
      %% This procedure adds standard output formats like Csound, Lilypond, and MIDI.
      %% */
      proc {AddExplorerOuts_Standard}	 
% 	 {Explorer.object
% 	  add(information BrowseInitRecord
% 	      label: 'Browse as initRecord')}
	 {Explorer.object
	  add(information  proc {$ I X} {ScoreInspector.inspect I#X} end
	      label: 'Inspect Score (use score object context menu)')}
	 {Explorer.object
	  add(information ArchiveInitRecord
	      label: 'Archive initRecord')}
	 {Explorer.object
	  add(information BrowseInitRecord
	      label: 'Browse initRecord')}
	 {Explorer.object
	  add(information DeclareMyScore
	      label: 'Binds score to MyScore at top level')}
% 	 {Explorer.object
% 	  add(information ShowInitRecord
% 	      label: 'Show initRecord')}
	 {Explorer.object
	  add(information RenderCsound
	      label: 'to Csound')}
	 {Explorer.object
	  add(information RenderLilypondFomus
	      label: 'to Lilypond (via Fomus)')}
	 % {Explorer.object
	 %  add(information RenderLilypondFomus_HS
	 %      label: 'to Lilypond (via Fomus, with HS and Measure objects support)')}
	 {Explorer.object
	  add(information RenderLilypond
	      label: 'to Lilypond')}
	 {Explorer.object
	  add(information RenderMidi
	      label: 'to Midi')}
      end
      /** %% Extends the Explorer menu "Notes -> Information Action" by a few entries to output scores into various formats just by clicking the solution nodes in the Explorer. 
      %% This procedure complements the formats of AddExplorerOuts_Standard by further formats like ENP and Fomus.
      %%
      %% This split into two procedures is only intended to avoid confusing new users with too many options. Anyway, the Explorer actions created by both procs are (hopefully) soon obsolete and replaced by a GUI settings dialog...
      %% */
      proc {AddExplorerOuts_Extended}
% 	 {Explorer.object
% 	  add(information BrowseMini
% 	      label: 'SBrowse mini')}
% 	 {Explorer.object
% 	  add(information BrowseAllParams
% 	      label: 'SBrowse all')}
% 	 {Explorer.object
% 	  add(information InspectMini
% 	      label: 'SInspect mini')}
% 	 {Explorer.object
% 	  add(information InspectAllParams
% 	      label: 'SInspect all')}
% 	 {Explorer.object
% 	  add(information BrowseAsFullRecord
% 	      label: 'SBrowse as full record')}
% 	 {Explorer.object
% 	  add(information InspectAsFullRecord
% 	      label: 'SInspect as full record')}
% 	 {Explorer.object
% 	  add(information InspectInitRecord
% 	      label: 'Inspect as initRecord')}
	 {Explorer.object
	  add(information ArchiveENPNonMensural
	      label: 'Archive ENPNonMensural')}
	 {Explorer.object
	  add(information ArchiveFomus
	      label: 'Archive Fomus')}
	 {Explorer.object
	  add(information RenderFomus
	      label: 'to Fomus')}
      end

      
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% The following calls are automatically executed whenever Strasheela is loaded. Therefore, some standard Strasheela settings which would be otherwise be put into OZRC can be set here.
%%%
%%% NB: These settings often perform stateful operations. Similar to the settings in OZRC, these stateful operations are not effective immediately after Oz is started, but require a little amount of time to take effect. 
%%%   

   /** %% ?? Always add standard explorer outs automatically?
   %% */
%   {AddExplorerOuts_Standard}

   
   /** %% Defines and registers special error formatters for Strasheela. See http://www.mozart-oz.org/documentation/system/node76.html for a documentation of the error formatter format.
   %% NB: for throwing exceptions use Exception.raiseError instead of raise ... end. Doing so automatically includes in the exception the feature-value-pair debug:unit (and that way provides information like tho offending souce file etc automatically), and additionally it allows for including more information with special error formatters like the ones here (this information is excluded if debug:unit is included directly in the exception).
   %%
   %% Example:
   {Exception.raiseError
    strasheela(failedRequirement OffendingValue "Message VS")}
   %% */
   %%
   %% NB: Oz source itself very rarely introduces special exceptions and error formatters. E.g., the whole List functor contains not a single expecitly raised exception. One the one hand, this can lead to hardly conprehend error messages (e.g. if the arguments of Nth are reversed or not a list is given as arg). On the other hand, entering lots of explicit exceptions (e.g. to quasi have some ad-hoc type checking) clutters the code and also makes the code less efficient (e.g. how useful would it be to check always that Nth gets a list and an integer as arg, and perhaps even that the integer is =< {Length Xs}). So, I should also be cautios with explicit exceptions. Only introduce them if specific errors are likely or would be extremely hard to find. Also, try to always avoid some 'default' check (like assert) -- especially if it would be costly (e.g. computes the length of a list).
   
   {Error.registerFormatter strasheela
    fun {$ E}
       %% !! this is still unfinished!
       case E of strasheela(initError Msg) then
	  %% expected Msg: VS 
	  error(kind: 'strasheela: initialisation error'
		% msg: 
		items: [line(Msg)])
       elseof strasheela(illParameterUnit Unit Param Msg) then
	  %% expected Unit: any value, Param: object, MethodCall: VS, Msg: VS 
	  error(kind: 'strasheela: parameter unit error'
		msg: 'The parameter unit is ill-formed.' 
		items: [hint(l:'Unit found' m:oz(Unit))
			hint(l:'for parameter' m:oz(Param))
			line(Msg)])
       elseof strasheela(failedRequirement X Msg) then
	  %% expected X: any value, Msg: VS (or nil)
	  error(kind: 'strasheela: failed requirement error'
		msg: 'Value does not meet requirement'
		items: [hint(l: 'Given value' m: oz(X))
			line(Msg)])
	  %%
%    elseof strasheela(noSpec X Msg) then
	  %% expected X: any value, Msg: VS
	  %%
%     elseof strasheela(missingInitialisation EnvVar Msg) then
	  %% expected EnvVar: atom or list of atoms, Msg: VS
	  %%
       else
	  error(kind: 'strasheela: other error' 
		items: [line(oz(E))])
       end 
    end}
    
end

