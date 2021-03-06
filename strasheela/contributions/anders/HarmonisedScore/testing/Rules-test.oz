
declare
[HS Pattern]
= {ModuleLink ['x-ozlib://anders/strasheela/HarmonisedScore/HarmonisedScore.ozf'
		'x-ozlib://anders/strasheela/pattern/Pattern.ozf']}


/*
declare
Feat = dissonanceDegree

{HS.rules.getFeature Chord Feat I}
*/


{Select.fd [1 2 3 4] {FD.int 1#3}}

{Select.fs [{FS.value.make [1 2]} {FS.value.make [5 6]} {FS.value.make [11 12]}] {FD.int 2#3}}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% test PassingNotes 
%%

declare
Pitches = {FD.list 3 60#72}
MaxStep = 2

{Browse Pitches}

{HS.rules.passingNotes Pitches MaxStep}

{Nth Pitches 2} = 65

Pitches.1 = 66

%% HS.rules.passingNotesR

declare
Pitches = {FD.list 3 60#72}
MaxStep = 2
B

{Browse Pitches#B}

{HS.rules.passingNotesR Pitches MaxStep B}

{Nth Pitches 2} = 65

B = 1

B = 0

Pitches.1 = 66

% rightly causes failure
{Nth Pitches 3} = 4 



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% test Schoenberg 
%%


%%
%% DescendingProgressionR
%%
%% Find all pairs of major chords forming an descending progression, starting with c major.
%% Two sols: E major and G major (no restriction to diatonic chords..). 
declare
proc {MyScript MyScore}
   Chord1 Chord2
in
   MyScore = {Score.makeScore
	      seq(items:[chord(duration:1
			       index:1
			       transposition:0
			       handle:Chord1)
			 chord(duration:1
			       index:1
			       handle:Chord2)]
		  startTime:0
		  timeUnit:beats)
	      add(chord:HS.score.chord)}
   {HS.rules.schoenberg.descendingProgressionR Chord1 Chord2 1}
end
%% browse solutions as init record
{Browse {Map {SDistro.searchAll MyScript
		 unit(order:size
		      value:min)}
	 fun {$ Sol} {Sol toInitRecord($)} end}}



{SDistro.exploreOne MyScript
 unit(order:size
      value:min)}

%%%%%


%% AscendingProgressionR
%%
%% Find all pairs of major chords forming an ascending progression, starting with c major.
%% Four sols: Eb maj, F maj, Ab maj, A maj (no restriction to diatonic chords..). 
declare
proc {MyScript MyScore}
   Chord1 Chord2
in
   MyScore = {Score.makeScore
	      seq(items:[chord(duration:1
			       index:1
			       transposition:0
			       handle:Chord1)
			 chord(duration:1
			       index:1
			       handle:Chord2)]
		  startTime:0
		  timeUnit:beats)
	      add(chord:HS.score.chord)}
   {HS.rules.schoenberg.ascendingProgressionR Chord1 Chord2 1}
end
%% browse solutions as init record
{Browse {Map {SDistro.searchAll MyScript
		 unit(order:size
		      value:min)}
	 fun {$ Sol} {Sol toInitRecord($)} end}}

{SDistro.exploreOne MyScript
 unit(order:size
      value:min)}




%%%%%


%% SuperstrongProgressionR
%%
%% Find all pairs of major chords forming an superstrong progression, starting with c major.
%% five sols: C#, D, F#, Bb, B  (no restriction to diatonic chords..). 
declare
proc {MyScript MyScore}
   Chord1 Chord2
in
   MyScore = {Score.makeScore
	      seq(items:[chord(duration:1
			       index:1
			       transposition:0
			       handle:Chord1)
			 chord(duration:1
			       index:1
			       handle:Chord2)]
		  startTime:0
		  timeUnit:beats)
	      add(chord:HS.score.chord)}
   {HS.rules.schoenberg.superstrongProgressionR Chord1 Chord2 1}
end
%% browse solutions as init record
{Browse {Map {SDistro.searchAll MyScript
		 unit(order:size
		      value:min)}
	 fun {$ Sol} {Sol toInitRecord($)} end}}

{SDistro.exploreOne MyScript
 unit(order:size
      value:min)}



%%% 


%% ProgressionStrength 
%%
%% For all major and minor chords: access progression strength from C maj to this chord.  
%%

declare
%% Args specify 2nd chord
proc {GetProgressionStrength unit(transposition:T
				  index:I)
     ?N}
   Chord1 = {Score.makeScore chord(duration:1
				   index:1
				   transposition:0)
	      unit(chord:HS.score.chord)}
   Chord2 = {Score.makeScore chord(duration:1
				   index:I
				   transposition:T)
	     unit(chord:HS.score.chord)}
in
   {HS.rules.schoenberg.progressionStrength Chord1 Chord2 N}
end



%% indented results:

%% same root: 0
{Browse {GetProgressionStrength unit(transposition:0
				     index:{HS.db.getChordIndex 'major'})}}
{Browse {GetProgressionStrength unit(transposition:0
				     index:{HS.db.getChordIndex 'minor'})}}

%% descending: 1-11
%% E major: 8, E minor:4 (1 vs 2 common tones with C maj, and both are triads)
{Browse {GetProgressionStrength unit(transposition:4 index:{HS.db.getChordIndex 'major'})}}
{Browse {GetProgressionStrength unit(transposition:4 index:{HS.db.getChordIndex 'minor'})}}
%% G maj: 8
{Browse {GetProgressionStrength unit(transposition:7 index:{HS.db.getChordIndex 'major'})}}
%% G dominant seventh: 9
{Browse {GetProgressionStrength unit(transposition:7
				     index:{HS.db.getChordIndex 'dominant seventh'})}}
{Browse {GetProgressionStrength unit(transposition:4
				     index:{HS.db.getChordIndex 'minor seventh'})}}

%% ascending: 13-23
%% F maj: 20
{Browse {GetProgressionStrength unit(transposition:5 index:{HS.db.getChordIndex 'major'})}}
%% A min: 16
{Browse {GetProgressionStrength unit(transposition:9 index:{HS.db.getChordIndex 'minor'})}}
%% Ab maj: 20
{Browse {GetProgressionStrength unit(transposition:8 index:{HS.db.getChordIndex 'major'})}}


%% superstrong: 24
{Browse {GetProgressionStrength unit(transposition:2
				     index:{HS.db.getChordIndex 'major'})}}



%%
%% ResolveDescendingProgressions
%%
%% For three chords, find all solutions which complete a weak progression between the first two chords (I V ??). Solutions are not necessarily diatonic..
%%
%% Solutions for the third root: 1 2 3 5 6 8 9 10 11
%% I.e., no 0, 4, 7 -- the descending progressions from C major.
%% If allowInterchangeProgression is true, then 0 is permitted as well.
declare
proc {MyScript MyScore}
   Chord1 Chord2 Chord3
in
   MyScore = {Score.makeScore
	      seq(items:[chord(duration:1
			       index:{HS.db.getChordIndex 'major'}
			       transposition:0
			       handle:Chord1)
			 chord(duration:1
			       index:{HS.db.getChordIndex 'major'}
			       transposition:7
			       handle:Chord2)
			 chord(duration:1
			       index:{HS.db.getChordIndex 'major'}
			       handle:Chord3)]
		  startTime:0
		  timeUnit:beats)
	      add(chord:HS.score.chord)}
   {HS.rules.schoenberg.resolveDescendingProgressions [Chord1 Chord2 Chord3]
%    unit(allowInterchangeProgression:true)
    unit
   }
end

%% browse solutions as init record
{Browse {Map {SDistro.searchAll MyScript
		 unit(order:size
		      value:min)}
	 fun {$ Sol} {Sol toInitRecord($)} end}}

%% browse roots of all sols of third chord
{Browse {Map {SDistro.searchAll MyScript
		 unit(order:size
		      value:min)}
	 fun {$ Sol}
	    InitR = {Sol toInitRecord($)}
	 in
	    {List.last InitR.items}.root
	 end}}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% HS.rules.voiceLeadingDistance
%%

%% Assumes default harmony DB
declare
C_Major = {Score.make chord(index: {HS.db.getChordIndex 'major'}
			    transposition: {ET12.pc 'C'})
	   unit(chord:HS.score.chord)}
Ab_Major = {Score.make chord(index: {HS.db.getChordIndex 'major'}
			    transposition: {ET12.pc 'Ab'})
	    unit(chord:HS.score.chord)}
G_Major = {Score.make chord(index: {HS.db.getChordIndex 'major'}
			    transposition: {ET12.pc 'G'})
	    unit(chord:HS.score.chord)}
FSharp_Major = {Score.make chord(index: {HS.db.getChordIndex 'major'}
			    transposition: {ET12.pc 'F#'})
	    unit(chord:HS.score.chord)}

%% 0, because nothing changed
{Browse {HS.rules.voiceLeadingDistance C_Major C_Major}}

%% 2 tones changed by a semitone (sum is 2)
{Browse {HS.rules.voiceLeadingDistance C_Major Ab_Major}}

%% 1 tone changed by a semitone, and one by a whole tone (sum is 3)
{Browse {HS.rules.voiceLeadingDistance C_Major G_Major}}

%% C-maj -> F#-maj = 4
%% C->C#=1, C->A#=2, G->F#=1 -- the E of C-maj is ignored in the computation  
{Browse {HS.rules.voiceLeadingDistance C_Major FSharp_Major}}


%%%%

%% 0, because nothing changed
{Browse {HS.rules.voiceLeadingDistance_Percent C_Major C_Major}}

{Browse {HS.rules.voiceLeadingDistance_Percent C_Major Ab_Major}}

{Browse {HS.rules.voiceLeadingDistance_Percent C_Major G_Major}}

{Browse {HS.rules.voiceLeadingDistance_Percent C_Major FSharp_Major}}



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% HS.rules.smallIntervalProgression
%%

%% Assumes default harmony DB
declare
C_Major = {Score.make chord(index: {HS.db.getChordIndex 'major'}
			    transposition: {ET12.pc 'C'})
	   unit(chord:HS.score.chord)}
Ab_Major = {Score.make chord(index: {HS.db.getChordIndex 'major'}
			    transposition: {ET12.pc 'Ab'})
	   unit(chord:HS.score.chord)}

%% 2 of chord tones change by a semitone
{Browse {HS.rules.smallIntervalsInProgression C_Major Ab_Major unit}}

%% 1 tone stays and 2 of chord tones change by a semitone
{Browse {HS.rules.smallIntervalsInProgression C_Major Ab_Major
	 unit(ignoreUnisons:false)}}


%%


%% 2 of 3 chord tones change by a semitone: 66 percent
{Browse {HS.rules.smallIntervalsInProgression_Percent C_Major Ab_Major unit}}

%% 100 percent
{Browse {HS.rules.smallIntervalsInProgression_Percent C_Major Ab_Major
	 unit(ignoreUnisons:false)}}



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% HS.rules.ballistic
%%

%% not really a convincing test...
{ExploreOne
 proc {$ Xs}
    Xs = {FD.list 20 0#20}
    {HS.rules.ballistic Xs unit}
    {FD.distance {Nth Xs 1} {Nth Xs 2}  '>:' 7}
%    {Pattern.noRepetition Xs}
    {FD.distribute ff Xs}
 end}



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% HS.rules.modulation
%%

%%
%% Performs a modulation C -> F major.
%% Result is a score consisting only of chord and scale objects, but no notes.
%%

declare
{HS.db.setDB {ET31.db.makeFullDB unit}}
{GUtils.setRandomGeneratorSeed 0}
proc {MyScript MyScore}
   OldScale NewScale Chords
in
   MyScore = {Score.make sim([seq([chord chord chord chord
				   chord chord chord chord])
			      seq([scale(handle: OldScale
					 duration: 4
					 index: {HS.db.getScaleIndex 'major'}
					 root: {ET31.pc 'C'})
				   scale(handle: NewScale
					 duration: 4
					 index: {HS.db.getScaleIndex 'major'}
					 root: {ET31.pc 'F'})])]
			     startTime: 0
			     timeUnit: beats(1))
	      add(chord: {Score.makeConstructor HS.score.diatonicChord
			  chord(duration: 1
				index: fd#{Sort {Map ['major' 'minor' 'dominant 7th' 'sixte ajoutee'] 
						 HS.db.getChordIndex} Value.'<'}
				inScaleB: 1)}
		  scale: HS.score.scale)}
   Chords = {MyScore collect($ test: HS.score.isChord)}
   {HS.rules.modulation {List.drop Chords 4} OldScale NewScale 
    unit(neutralLength: 1)}
     % {Modulation {List.drop Chords 4} OldScale NewScale 
     % unit(neutralLength: 0)}
   {HS.rules.cadence NewScale {LUtils.lastN Chords 3}}
   {HS.rules.schoenberg.progressionSelector Chords
    resolveDescendingProgressions}
     % {OldScale getRoot($)} \=: {NewScale getRoot($)}
     % {Pattern.for2Neighbours Chords
     %  proc {$ C1 C2} {C1 getRoot($)} \=: {C2 getRoot($)} end}
end
{SDistro.exploreOne MyScript
 unit(order:leftToRight
      value:random)}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% test HS.rules.noParallels2 
%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% HS.rules.isPerfectConsonanceR
%%

%% 12-TET
{HS.rules.isPerfectConsonanceR 12} % 1

{HS.rules.isPerfectConsonanceR {HS.pc 'G'}} % 1

{HS.rules.isPerfectConsonanceR {HS.pc 'F'}} % 0 -- why?



%% 31-TET
{HS.db.setDB {ET31.db.makeFullDB unit}}

{HS.rules.isPerfectConsonanceR 31} % 1

{HS.rules.isPerfectConsonanceR {HS.pc 'G'}} % 1

{HS.rules.isPerfectConsonanceR {HS.pc 'F'}} % 0 -- why?

