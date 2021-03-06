
%%% *************************************************************
%%% Copyright (C) 2005-2008 Torsten Anders (www.torsten-anders.de) 
%%% This program is free software; you can redistribute it and/or
%%% modify it under the terms of the GNU General Public License
%%% as published by the Free Software Foundation; either version 2
%%% of the License, or (at your option) any later version.
%%% This program is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%% GNU General Public License for more details.
%%% *************************************************************

/** %% This functor provides many constrains and score classes which facilitate the definition of a theory of harmony. For example, this functor defines constraints between pitches, pitch classes and degrees on the one hand, and classes such as Interval, Chord, Scale, and an extended Note class on the other hand.
%%
%% The functor defines most class extensions as mixins, so they can be combined with other classes (e.g., you can extend your own extension of the Note class provided by the Strasheela core with the mixin PitchClassMixin). In addition, the functor also uses these mixins in class definitions (e.g., the class Note2 inherits from both the core class Score.note and PitchClassMixin). The functor defines many class variants combining the mixins. Selecting the class with the minimal set of additional parameters which meets your needs reduces the memory requirement of your score. However, you may consider defining your CSP with the most extensive classes first (e.g., using FullNote, ScaleDegreeChord, and Scale), and optimise later only if necessary. 
%%
%% This harmony model is designed to cooperate with other Strasheela extensions. For example, it can be used together with the motif model (contribution Motif) or the meter model (contribution Measure). 
%%
%% Moreover, the classes can be used in a score whose hierarchic structure is constrained with the contribution ConstrainTimingTree (CTT). Consequently, many class definitions in this functor enforce their constrains only after they know that the score object in question "exists" (i.e. its duration > 0). Therefore, the distribution strategy should usually determine the duration of a score object early on in the search process. 
%% */

%%
%% TODO -- (partly done):
%%
%% * !!! intensive testing
%%
%% * !! doc for Chord class and other classes
%%
%% * !! add class interval. Add creator with memoization, e.g., given two Strasheela notes.
%%
%% * for all (?) mixin classes create class constructors like MakeInversionChordClass
%% 
%% * add enharmonically correct Lilypond output for enharmonic notes
%%
%% * ?? refactor accidental representation with two parameters: direction and amount (this is only for convenience: adds no expressiveness and degrades performance)
%%
%% * refactor: much code doublication in InChordMixinForNote, InScaleMixinForNote 
%%
%% * OK ChordDB als User settable/changable var: definiere Format und dokumentiere 
%%
%% * OK root as chord attr (FD), roots as feature in chord DB (FS)
%%
%% * OK chord DB: edit format is list of records, internal format is 'mat-transed'
%%
%% * OK wie integriere ich scales? Scale als fixed entry in chord DB is
%% wrong (e.g. in major scale chords on different scale degrees have
%% all the same scale -- the same chord (e.g. major) is then
%% transposed, the scale is not)
%%
%% * OK define scale DB like chord DB -- which chord goes which scale is controlled by constraints as well (e.g. scale may be constant over multiple chords and restricts the possible chords)
%%
%% * OK Noch besser waere es vielleicht, Scale als extra stumme Klasse zu definieren, aehnlich Chord die parallel zur Partitur und den Chords verlaeuft. Dann lassen sich frei Beziehungen zwischen Skala und Chord und Noten Tonhoehen definieren. Z.B.: Chord pitch classes must be subset in Scale pitch classes and consonant Note pitch class must be subset in Chord pitch class and is otherwise in Scale pitch class. Modulationen aendern dann Skala. Tricky sind Skalen wie Moll (muss pitch classes sowohl von melodisch als auch von harmonisch sein -- Auswahl wird durch zusaetzl. constraints geregelt.). Bei komplexerer Harmonik (siehe Schoenberg-Buch weiter hinten) wird Skalendefinition jedoch zunehmend hinderlich oder kompliziert..
%%
%% 
%% * !!?? A chord must have a root. In the chord DB multiple possible roots can be specified. Is it a severe restriction to force that every chord must have a root?
%% -> I may define the class Chord without and a subclass with root. Problemetic is still that I can not combine chords with and without roots easily.
%% -> ?? Even more general would be to easily allow the user to subclass (in some constructor) and to specify an init function to bind additional attr
%%
%%
%% 
%% * OK !!?? record with selection-constrained vars of further database fields except comment.. 
%%
%% * OK !!?? A scale must have a root..
%%
%% * OK keine constraint: root subset of pitch classes 
%%
%% * OK User settable/changable var (ET) pitches per octave. This is var
%% also used to calculate e.g. the domain of pitch class variables
%%
%% * Later: Only add/bind/constraint Chord class attr besides index
%% and transposition (e.g. root, transposedPCs) if they are accessed
%% or dependent to the actual chord DB (define chord subclasses on the
%% fly)
%%
%% * OK all new defs for note class in mixin such that this mixin can be combined with other note extensions (the note subclass itself can not be combined with other note subclasses -- there would be clashes in inheritance scheme..)
%%


%% !! Strasheela to think of: more flexible/extendable parameter representation -- parameter-group to, e.g., 'plug in' different pitch representations (e.g. single param such as pitch or pitch class, or compound representations such as scale degree + accidental) --
%%  Why: I want to save variables and propagators to reduce size of search problem. However, I may then also optimize/reduce, e.g., representation of timing hierarchy etc. -- I should postpone such optimization and first get some full representation running... 
%%
%% -> Hm, pitchClasses of scale and even chord may also be just plain PCs and only Note may alternatively represent pitch as [scaleDegree x accidental x octave] -- No, why should the chord root not be represented as [scaleDegree x accidental]
%%
%% nochmal: three alternative pitch representations (see translation defs below)
%%
%% * pitch
%%
%% * pitchClass + octave
%%
%% * scaleDegree (name?) + accidental (avoid neg...) + octave
%%
%% {DegreeToPitchClass ScaleDegree Accidental} = PitchClass
%%
%% PitchClass + Octave =: Pitch
%%
%% %% there is a more up to date def below
% proc {DegreeToPitchClass ScaleDegree Accidental PitchClass}
%    %% depends on difference of scale and pitch resolution and max number of accumulated accidentals (default 2 for common praxis: bb=0, b=1, neutral=2, #=3, x=4)
%    Offset = 2
% in
%    ScaleDegree + Accidental - Offset =: PitchClass 
% end
%%
%%
%% * additional alternatives: pitch representation with ['scaleDegree' x accidental] absolute or relative? relative: accidentals only for non-diatonic pitches, absolute: accidentals for all pitches not in c-major
%%
%%
%% * possible implementation of alternatives: alternative representations implemented as mixin-classes. Functor exports class creator which returns class with appropriate feature/attribute selection according to user spec. Problemchen: different feature/attribute combinations need different additional init constraints.
%%
%%
%% * Now, to abstract alternative pitch representations for, e.g., either chord root or note pitch I may still need some way to represent a compount parameter -- a compound parameter defines a list of params and additional accessors for each param. The object containing a compound parameter appends its parameter list to the object parameter list. The object does not (necessarily) define new accessors to each 'subparameter', use e.g. {{MyChord getRoot($)} getAccidental($)}
%%


functor
import
   FD FS Combinator System Search
   Browser(browse:Browse) % temp for debugging
%   Inspector(inspect:Inspect) % temp for debugging
   Select at 'x-ozlib://duchier/cp/Select.ozf'
   GUtils at 'x-ozlib://anders/strasheela/source/GeneralUtils.ozf'
   LUtils at 'x-ozlib://anders/strasheela/source/ListUtils.ozf'
   MUtils at 'x-ozlib://anders/strasheela/source/MusicUtils.ozf'
   Score at 'x-ozlib://anders/strasheela/source/ScoreCore.ozf'
   SDistro at 'x-ozlib://anders/strasheela/source/ScoreDistribution.ozf'
   Pattern at 'x-ozlib://anders/strasheela/Pattern/Pattern.ozf'
   CTT at 'x-ozlib://anders/strasheela/ConstrainTimingTree/ConstrainTimingTree.ozf'
   Measure at 'x-ozlib://anders/strasheela/Measure/Measure.ozf'
   DB at 'Database.ozf'
   Rules at 'Rules.ozf'

   
   % SDistro at 'x-ozlib://anders/strasheela/ScoreDistribution.ozf'
   % Pattern at 'x-ozlib://anders/strasheela/Pattern/Pattern.ozf'
   % UtilsAdd at 'UtilsAddon.ozf'
   % GUtilsAdd at 'GeneralUtilsAddon.ozf'
   % ChordDB at 'ChordDB.ozf'
   
   %% tmp: put required defs into functor of this Strasheela contribution
   % ChordProg at 'x-ozlib://anders/strasheela/composition/etude/ChordProgression.ozf'
   
export

   PitchClassToPitch PitchClassToPitch2 % PitchClassToPitchD
%   IntervalPCToInterval
   RatioToInterval
   TransposePC
   DegreeToPC CMajorDegreeToPC
   TransposeDegree
   GetDegree
   AbsoluteToOffsetAccidental OffsetToAbsoluteAccidental
   PcSetToSequence

   GetAdaptiveJIPitch GetAdaptiveJIPitch2
   
   MinimalCadentialSets MinimalCadentialSets2 MakeAllContextScales 

   Interval
   IsInterval
   NoteInterval TransposeNote

   PitchClassMixin IsPitchClassMixin
   RegularTemperamentMixinForNote IsRegularTemperamentMixinForNote
   InChordMixinForNote IsInChordMixinForNote
   InScaleMixinForNote IsInScaleMixinForNote
   EnharmonicSpellingMixinForNote IsEnharmonicSpellingMixinForNote
   ScaleDegreeMixinForNote IsScaleDegreeMixinForNote
   ChordDegreeMixinForNote IsChordDegreeMixinForNote
   Note Note2 RegularTemperamentNote
   FullNote EnharmonicNote ScaleDegreeNote ChordDegreeNote ScaleNote ChordNote
   
   PitchClassCollection IsPitchClassCollection 
   Chord IsChord
   Scale IsScale
   InScaleMixinForChord IsInScaleMixinForChord 
   MakeInScaleChordClass DiatonicChord
   ScaleDegreeMixinForChord IsScaleDegreeMixinForChord
   MakeScaleDegreeChordClass ScaleDegreeChord 
   InversionMixinForChord IsInversionMixinForChord
   MakeInversionChordClass InversionChord
   FullChord
   
   ChordStartMixin % MkChordsStartWithItems MkChordsStartWithItems2
   StartChordWithMarker

   
   
   PitchClass IsPitchClass

   MakeChords MakeScales
   
   HarmoniseScore HarmoniseScore2
   HarmoniseMotifs

   HarmonicRhythmFollowsMarkers
      
%   ChordStartMixin Simultaneous Sequential
   
%    % LinkItemsIntoContainerRecord 
%    % MkChordProgression IsChordProgression

   ChordsToScore ChordsToScore_Script
   
prepare
   %% Name for type checking of chord class. Defined in 'prepare' to
   %% avoid re-evaluation.
   IntervalType = {Name.new}
   PitchClassType = {Name.new}
   PitchClassCollectionType = {Name.new}
   ChordType = {Name.new}
   ScaleType = {Name.new}

   InScaleMixinForChordType = {Name.new}
   ScaleDegreeMixinForChordType = {Name.new}
   InversionMixinForChordType = {Name.new}

   RegularTemperamentForNoteType = {Name.new}
   InChordMixinForNoteType = {Name.new}
   InScaleMixinForNoteType = {Name.new}
   PitchClassMixinType = {Name.new}
   EnharmonicSpellingMixinForNoteType = {Name.new}
   ScaleDegreeMixinForNoteType = {Name.new}
   ChordDegreeMixinForNoteType = {Name.new}
   
   
define

   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% relations between different pitch representations
%%%
   
   /** %% Defines the relation between an absolute pitch number Pitch (FD int) and its PitchClass (FD int) plus Octave component (FD int). Middle c has octave 4, according to conventions (cf. http://en.wikipedia.org/wiki/Scientific_pitch_notation). So (for PitchesPerOctave=12), octave=0 corresponds to Midi pitch 12, and Midi pitch 127 falls in octave 9.
   %% The domain of PitchClass is implicitly restricted to 0#{DB.getPitchesPerOctave}.
   %% Pitch is implicitly declared to a FD int, so PitchClassToPitch can also be used like a deterministic function.
   %% */
   proc {PitchClassToPitch PitchClass#Octave Pitch}
      Pitch = {FD.decl}
      PitchClass :: 0#({DB.getPitchesPerOctave}-1)
      Pitch =: PitchClass + (Octave + 1)*{DB.getPitchesPerOctave}
   end

   /** %% Same as PitchClassToPitch. However, Middle c has octave 5 so that if Pitch = PitchClass, Octave = 0. This is in contrast to PitchClassToPitch, where Pitch is always >= PitchesPerOctave and thus always Pitch > PitchClass (even if Octave = 0). PitchClassToPitch2 is used with intervals, whereas PitchClassToPitch is used with pitches.
   %% The domain of PitchClass is implicitly restricted to 0#{DB.getPitchesPerOctave}.
   %% Pitch is implicitly declared to a FD int, so PitchClassToPitch2 can also be used like a deterministic function.
   %% */
   proc {PitchClassToPitch2 PitchClass#Octave Pitch}
      Pitch = {FD.decl}
      PitchClass :: 0#({DB.getPitchesPerOctave}-1)
      Pitch =: PitchClass + Octave*{DB.getPitchesPerOctave}
   end
   
%    %% Defines the relation between an absolute pitch number Pitch (FD int) and its PitchClass (FD int) plus Octave component (FD int).
%    %% Does domain propagation, which can be very expensive.
%    %% 
%    proc {PitchClassToPitchD PitchClass#Octave Pitch}
%       OctAux = FD.decl
%    in
%       {FD.timesD Octave {DB.getPitchesPerOctave} OctAux} 
%       {FD.plusD PitchClass OctAux Pitch}
%    end

   /** %% Transforms Ratio (either a float or a fraction specification in the form <Int>#<Int>) into the corresponding keynumber interval (an int) of the presently set pitches per octave.
   %% */
   fun {RatioToInterval Ratio}
      {FloatToInt {MUtils.ratioToKeynumInterval Ratio
		   {IntToFloat {DB.getPitchesPerOctave}}}}
   end

   
   /** %% Transposes the pitch class UnTranspPC by the interval TranspositionPC such that the resulting pitch TranspPC is still a pitch class, that is a pitch without an octave component. A pitch class is a FD int with the domain 0#(PitchesPerOctave-1). 
   %% What the actual value of a pitch class means depends on DB.getPitchesPerOctave (see also termonology explanation in the top-level functor).
   %% NB: The transposition interval is limited to a PC (i.e. the domain 0#(PitchesPerOctave-1)) to improve propagation. To transpose by a larger interval, constrain the relation of the (larger) Transposition and TranspositionPC by {PitchClassToPitch TranspositionPC#_ Transposition}.
   %%  All PC arguments are implicitly declared to FD ints with the domain 0#(PitchesPerOctave-1).
   %% */
   %%
   %% TODO: this is ordered pitch-class interval, do also unordered pitch-class interval
   %% http://en.wikipedia.org/wiki/Interval_class
   proc {TransposePC UnTranspPC TranspositionPC TranspPC}
      Aux = {FD.decl}
      PitchesPerOctave = {DB.getPitchesPerOctave}
      PCDomain = 0#PitchesPerOctave-1
   in
      %% redundant basic constraints just in case..      
      UnTranspPC :: PCDomain
      TranspositionPC :: PCDomain
      TranspPC :: PCDomain
      %% main constraints
      Aux =: UnTranspPC + TranspositionPC
      %% NOTE: try domain propagation (it improved at least search for the case I tested immediately after changing this, namely ET31 CSP where chords must be in Hahn pentachordal scale, so chord index is rather large and search took more time with FD.modI)
      TranspPC =: {FD.modD Aux PitchesPerOctave}
%       TranspPC =: {FD.modI Aux PitchesPerOctave}
   end


%    %% !!?? only defined for c-major: does this limit definition to PitchPerOctave=12 and AccidentalOffset=2? -- perhaps I should simply use DegreeToPC with c-major scale as CollectionPCs, propserly defined
%    proc {PitchClassToNoteName PitchClass NoteName Accidental}
%       Offset = {DB.getAccidentalOffset($)} 
%    in
%       % NoteName + Accidental - Offset =: PitchClass 
%    end
   
   
   /** %% Defines the relation between two pitch representations without octave component: the pitch class PC (FD int) and the compound representation consisting in Degree (FD int) and Accidental (FD int) -- depending on CollectionPCs (vector of FD ints).
   %% The Degree denotes quasi an index into CollectionPCs, e.g., the pitches of a scale: if Accidental denotes a neutral (i.e. {AbsoluteToOffsetAccidental 0}), PC is the pitch class in CollectionPCs at position Degree. However, the Accidental can alternate (increase or decrease) PC to a 'chromatic' pitch class not necessarily contained in CollectionPCs.
   %% The meaning of Accidental's actual numeric value is a bit complicated and depends on a two factors: (i) the maximum number of 'accumulated' accidentals (such as bb or x) which may be chosen dependent on the possible pitch classes between the elements in CollectionPCs, and (ii) because Oz FD integers must be non-negative an offset must be added which depends also on (i). For common praxis, this accidentalOffset defaults 2, thus the common accidentals are numerically encoded as such: bb=0, b=1, neutral=2, #=3, x=4.
   %% What the actual numeric value of a pitch class (and the interval denote by Accidental) means depends on DB.getPitchesPerOctave.
   %% To allow the user more flexibility, the accidentalOffset is not automatically set when the user sets the pitchesPerOctave value. Instead, the accidentalOffset can be set independently (see DB.setDB).
   %% In case of determined accidentals in the CSP definition, the user should avoid complicating the definition with accidentals encoded this way. Instead, the use of the accidental conversions Score.absoluteToOffsetAccidental or Score.offsetToAbsoluteAccidental is recommended.
   %% CollectionPCs should be ordered to avoid confusing the meaning of Degree, although this is not formally necessary. Regardless, PC and all elements in CollectionPCs should have the domain of a pitch class (you may use {HarmonisedScore.dB.makePitchClassFDInt}). Be careful to correctly define the Accidental domain. For instance, if the Accidental domain spans an entire octave, Degree can be any degree in CollectionPCs (you may use {HarmonisedScore.dB.makeAccidentalFDInt} which in turn uses the accidentalOffset).
   %% See also the terminology explanation in the top-level functor.
   %%
   %% BTW: To define the relation between a pitch class and the respective numeric 'note name' (i.e. the degrees in C-major) plus their accidentals, you could use DegreeToPC with the CollectionPCs for C-major.
   %% BTW: Similarily, DegreeToPC can also be used to define the relation between a (possibly micro-tonal) pitch class PC and its Degree + Accidental in dimensions of the net of harmonic relations, e.g., the spiral/circle of just fifth. In this usage, the variable name Degree is slightly missleading -- it actually means, e.g., a fifth-index (i.e. in case the Joe Monzo's 'array-pitch-representation' is used, Degree denotes the exponent for the respective ratio-dimension, e.g., the exponent for the 3 that is the fifths. However, it should be noted that the denoted pitch class is still rounded to integers, unlike the fractions denoted by real 'monzos'). For this usage, the order of CollectionPCs should reflect the order of the ratios depending on their exponent (e.g. in the order of the spiral of fifth).
   %% See ../testing/Score-test.oz for an [unfinished but seemingly conceptually clean] way to do something like MonzoToPC.
   %% */
   %%
   proc {DegreeToPC CollectionPCs Degree#Accidental PC}
      AccidentalOffset = {DB.getAccidentalOffset} 
      PitchesPerOctave = {DB.getPitchesPerOctave}
      CollectionPC = {DB.makePitchClassFDInt}
      Aux = {FD.decl}
   in
      %% to avoid neg Aux (when CollectionPC=0 and Accidental=0) I
      %% added PitchesPerOctave -- does not change PC meaning of Aux..
      Aux =: CollectionPC + Accidental - AccidentalOffset + PitchesPerOctave      
      PC = {FD.modI Aux PitchesPerOctave}
      {Select.fd CollectionPCs Degree CollectionPC}
   end

   /** %% Constrains the relation between the FD ints Degree, Accidental, and PC with respect to the just C-major scale. The closest approximation of the Pythagorean C-major scale [1/1 9/8 81/64 4/3 3/2 27/16 243/128] within the present setting of PitchesPerOctave is considered.
   %% CMajorDegreeToPC is the same as DegreeToPC, but with a predefined CollectionPCs (the Pythagorean C-major scale). See DegreeToPC for further details.
   %%
   %% NOTE: this constraint is used to derive an enharmonic notation, even for PitchesPerOctave \= 12. However, this constraint presents only one possible interpretation of the "white piano keys", namely as Pythagorean C-major scale degrees. All pitches with accidentals are understood as deviations of the Pythagorean C-major scale. Other interpretations of the "white piano keys" are possible (e.g., a just intonation of the C-major scale). For different PitchesPerOctave (e.g., if PitchesPerOctave=1200), different interpretations (i.e. different CollectionPCs used as a reference) will result in different accidentals or even different degrees for a given pitch class. 
   %% */
   %% !!?? How to decide for sharp or flat accidentals? I must apply additional constraints on the Degree, e.g., the chord database is defined in degrees with accidentals and not only pitch classes, and this chord information is propagated to note degrees.. 
   proc {CMajorDegreeToPC Degree#Accidental PC}
      CMajorScale = {Map
		     % [1#1 9#8 5#4 4#3 3#2 5#3 15#8]
		     [1#1 9#8 81#64 4#3 3#2 27#16 243#128]
		     fun {$ Ratio}
			{FloatToInt {MUtils.ratioToKeynumInterval Ratio
				     {IntToFloat {DB.getPitchesPerOctave}}}}
		     end}
   in
      {DegreeToPC CMajorScale Degree#Accidental PC}
   end
      
   /** %% Constrains the transposition of the degree-represented pitch UntransposedDegree#UntransposedPC by TranspositionDegree#TranspositionPC to reach the degree-represented pitch TransposedDegree#TransposedPC. The transposition interval is specified by a combination of a degree distance (e.g. in the C major scale 5 represents a fifth) plus the pitch class of this interval (BTW: a similar representation is also used in MusES for an enharmonic representation).
   %% For example, in case CollectionPCs is C major: II# + fifth = VI# (i.e. d# + fifth = a#)
   {TransposeDegree {GUtils.intsToFS [0 2 4 5 7 9 11]}
    2#3
    5#7
    6#10}
   %% If CollectionPCs is a diatonic scale (e.g. C major), then the TranspositionDegree values correspond to the interval names from conventional music theory.
   1 -> prime
   2 -> second
   3 -> third
   4 -> fourth
   5 -> fifth
   6 -> sixth
   7 -> seventh
   %% Please note that the prime (i.e. pitch repetition) is represented by 1 (and not 0). 
   %%
   %% NB: TransposeDegree expects that the relation between each Degree#PC pair (and the respective Accidental) is also constrained. The necessary constraint (i.e. DegreeToPC) is not applied within TransposeDegree to avoid superfluous propagators (usually, the relation between these variables is already constrained elsewhere). 
   %%
   %% NB: The transposition interval is limited to a PC (i.e. an octave-less transposition: TranspositionPC is in the domain 0#(PitchesPerOctave-1)) to improve propagation. Intervals larger then a seventh 'fold back' into the intervals stated above.
   %%
   %% In case an octave component is important, then introduce variables for the absolute TranspositionInterval and its TranspositionOctave and constrain their relation by {IntervalPCToInterval TranspositionPC#TranspositionOctave Transposition}. 
   %% */
   %% TODO: ?? replace CollectionPCs by CollectionFS? Only cardiality of set is needed..
   proc {TransposeDegree CollectionPCsFS
	 UntransposedDegree#UntransposedPC
	 TranspositionDegree#TranspositionPC
	 TransposedDegree#TransposedPC}
      L = {FS.card CollectionPCsFS}
%       L = {Length CollectionPCs}
      Aux = {FD.decl}
      proc {ModVar X Y}
	 %% modulus variation for degrees returns number in [1,L]: {FD.modI (X-1) L} + 1
	 Aux = {FD.decl}
      in
	 X :: 0#FD.sup
	 Y :: 0#FD.sup
	 Aux =: X-1 
	 Y =: {FD.modI Aux L} + 1
      end
      DomainPC = {DB.getPitchesPerOctave}-1
   in
      %% redundant basic constraints
      UntransposedDegree :: 1#L
      TranspositionDegree :: 1#L
      TransposedDegree :: 1#L 
      UntransposedPC :: 0#DomainPC
      TranspositionPC :: 0#DomainPC
      TransposedPC :: 0#DomainPC
      %%
      %% actual constraints
      {TransposePC UntransposedPC TranspositionPC TransposedPC}
      %% - 1, because TranspositionDegree is given 1-based, but
      %% computation must be 0-based (e.g. distance from I to V is
      %% 'fifth', although V-I = 4)
      Aux =: UntransposedDegree + TranspositionDegree - 1
      TransposedDegree =: {ModVar Aux}
   end
%    proc {TransposeDegree CollectionPCs
% 	 UntransposedDegree#UntransposedAccidental
% 	 TranspositionDegree#Transposition
% 	 TransposedDegree#TransposedAccidental}
%       UntransposedPC = {FD.decl}
%       TransposedPC = {FD.decl}
%       Aux = {FD.decl}
%    in 
%       {DegreeToPC CollectionPCs UntransposedDegree#UntransposedAccidental UntransposedPC}
%       {DegreeToPC CollectionPCs TransposedDegree#TransposedAccidental TransposedPC}
%       {TransposePC UntransposedPC Transposition TransposedPC}
%       %% - 1 because TranspositionDegree is specified zero-based (i.e. distance from I to V is 'fifth', although V-I = 'fourth')
%       Aux = UntransposedDegree + TranspositionDegree - 1 
%       TransposedDegree =: {FD.modI Aux {Length CollectionPCs}}
%    end

   /** %% Returns the chord/scale degree (FD int) for PitchClass (FD int). MyPCColl is the chord/scale object to which the degree corresponds.
   %%
   %% Args:
   %% 'accidentalRange' (int) specifies how many pitch class steps PitchClasses can be "off" (if AccidentalRange==0, then all PitClasses must be in the chord/scale).
   %%
   %% Note: very weak propagation -- MyPCColl must first be determined.
   %% */
   fun {GetDegree PitchClass MyPCColl Args}
      Default = unit(accidentalRange: 2) % suitable default for 31 ET?
      As = {Adjoin Default Args}
      AccDom = {AbsoluteToOffsetAccidental ~(As.accidentalRange)}#{AbsoluteToOffsetAccidental As.accidentalRange}
   in
      {MyPCColl degreeToPC($ {FD.int AccDom} PitchClass)}
   end


   /** %% Converts a determined and possibly negative 'absolute accidental' (int) into a non-negative 'offset accidental' (int) used in CSPs. The absolute accidental 0 always denotes no pitch inflection of a scale degree (or noteName), negative values denote a 'decreasing' and positive an 'increasing' chromatic accidental. 
   %% For common praxis, where DB.getAccidentalOffset returns 2, 'absolute accidentals' are encoded like bb=~2, b=~1, neutral=0, #=1, x=2 and 'offset accidentals' as bb=0, b=1, neutral=2, #=3, x=4.
   %% */
   fun {AbsoluteToOffsetAccidental X}
      Result = X + {DB.getAccidentalOffset}
   in
      if Result < 0
      then raise outOfRange(X) end
      else Result
      end
   end
   /** %% Converts a determined 'offset accidental' (int) used in CSPs into a possibly negative 'absolute accidental' (int). The absolute accidental 0 always denotes no pitch inflection of a scale degree (or noteName), negative values denote a 'decreasing' and positive an 'increasing' accidental. 
   %% For common praxis, where DB.getAccidentalOffset returns 2, 'absolute accidentals' are encoded like bb=~2, b=~1, neutral=0, #=1, x=2 and 'offset accidentals' as bb=0, b=1, neutral=2, #=3, x=4.
   %% */
   fun {OffsetToAbsoluteAccidental X}
      if X < 0
      then raise outOfRange(X) end
      else X - {DB.getAccidentalOffset}
      end
   end

   /** %% Expects a set of pitch classes from a scale or chord (PCFS, a determined FS) and a Root (an determined FD) and returns a list of ints in ascending order starting with the root (if root is present in PCFS). If root is not present in PCFS, then the returned list starts with the pitch class which would follow root.  
   %% PCSetToSequence is useful for creating an ordered PC collection to constrain the degree of some PC (e.g., with DegreeToPC). For example, the PC set of the E major scale is {1, 3, 4, 6, 8, 9, 11} and the root is 4: PCSetToSequence returns the ordered sequence [4 6 8 9 11 1 3]. 
   %%
   %% NB: PcSetToSequence blocks until its arguments PCFS and Root are determined.
   %% */
   fun {PcSetToSequence PCFS Root}
%      thread % in case args are not determined
      Card = {FS.card PCFS}
      PCs = {FD.list Card 0#{DB.getPitchesPerOctave}-1}
      RootPosTmp RootPos Leading Trailing
   in
      %% FS.int.match basically takes effect only after PCFS is determined
      %% (before it can only distribute bounds for all vars in PCs)
      PCs = {FS.int.match PCFS}
      %% first element = or > Root (Root itself may not be in PCFS)
      RootPosTmp = {LUtils.findPosition PCs fun {$ X} X >= Root end}
      %% in case Root is greatest, take first
      RootPos = if RootPosTmp==nil then 1 else RootPosTmp end
      {List.takeDrop PCs (RootPos-1) Leading Trailing}
      {Append Trailing Leading}
%      end
   end

   %% TODO:
%    proc {RegularToPC }
%    end



   /** %% Returns an adaptive just intonation pitch (midi float) of MyNote (HS.score.note instance), where the tuning depends on the harmonic context (i.e. the chord object related to MyNote).
   %%
   %% If MyNote is a chord tone (i.e. getInChordB returns 1) and the related chord of MyNote is specified by ratios in the chord database, then the corresponding chord ratio is used for tuning. The chord root is tuned according to the current tuning table, or to the equal temperament defined by its pitch unit if no tuning table is specified.
   %%
   %% Args:
   %% 'tuneNonharmonicNotes' (default true): If true, non-harmonic tones are tuned as the ratio defined in the current interval DB for the PC interval between MyNote and the root of the related chord. Otherwise, the result is {MyNote getPitchInMidi($)} (i.e. either the pitch of the tuning table or the ET depending on the pitch unit).
   %%
   %% Note that you need to define chord/scale databases using ratios (integer pairs) for adaptive JI. Presently, only the predefined chord and scale databases in ET31 and ET22 are defined by ratios.  In the default chord database, chords and scales are (currently) defined by pitch class integers and thus GetAdaptiveJIPitch returns the same pitch as the note method getPitchInMidi.
   %%
   %% */
   %%
   %% TODO:
   %%
   %% - !!?? tune chord roots to corresponding scale degree (if there is a scale). Then other scale notes are in corresponding relation, and I can get JI results if scale is defined by JI intervals.
   %% Currently, if MyNote is the root of MyChord, then the tempered root is played. However, the corresponding scale tone may not be tempered. So, the same note is played differently if it is not a chord tone. (Naturally, it is usually played differently if it is a chord tone but not the root).
   %%
   %% - def arg approximation, e.g., value between 1.0 (justly tuned adaptive pitches), 0.0 (as getPitchInMidi, usually ET), or even ~1.0 (worse than ET)
   %%
   %% - handle multiple chords/scales related to MyNote (see bug below)
   %% 
   %%
   %%
   %% Note
   %%
   %% - I considered using scale ratios for non-harmonic notes, but this was a bad idea: they can be completely wrong for the chord at hand (e.g. for just major scale, nineth of V is 2 syntonic commas too low)
   %% 
   %% 
   fun {GetAdaptiveJIPitch MyNote Args}
      Default = unit(% approximation: 1.0
		     tuneNonharmonicNotes: true
		    )
      As = {Adjoin Default Args}
   in 
      if {MyNote getChords($)} \= nil then
	    % BUG: simplification: could also be "later" chord
	 MyChord = {MyNote getChords($)}.1 
	 ChordRatios = {DB.getUntransposedRatios MyChord}
      in
	 if ChordRatios == nil then
	    %% chord is defined by PCs and not ratios
	    {MyNote getPitchInMidi($)}
	 elseif {MyNote getInChordB($)} == 1 then
	    %% harmonic note
	    MyNoteDegree = {GetDegree {MyNote getPitchClass($)} MyChord
			    %% note: only exact pitches
			    unit(accidentalRange:0)}
	    MyNoteRatio = {Nth ChordRatios MyNoteDegree}
	 in
	    {GetAdaptiveJIPitch2 MyNote MyNoteRatio MyChord As}
	 elseif {MyNote getInChordB($)} == 0 andthen As.tuneNonharmonicNotes then 
	    %% non-harmonic note
	    RootNoteInterval = {TransposePC {MyChord getRoot($)} $ {MyNote getPitchClass($)}}	     
	    MyNoteRatio = {DB.pc2Ratios RootNoteInterval {DB.getEditIntervalDB}}
	 in
	    if MyNoteRatio \= nil then 
	       {GetAdaptiveJIPitch2 MyNote MyNoteRatio.1 MyChord As}
	       %% no interval ratio defined
	    else {MyNote getPitchInMidi($)}
	    end
	    %% non-harmonic note and As.tuneNonharmonicNotes is false
	 else {MyNote getPitchInMidi($)}
	 end
	 %% no related chord
      else {MyNote getPitchInMidi($)}
      end
   end

   %% [aux vars of GetAdaptiveJIPitch2] Freq0_2 defined outside to avoid recomputation for each note
   Freq0 = MUtils.freq0
   Freq0_2 = 2.0*MUtils.freq0

   /** %% Returns the adapted JI pitch of MyNote as Midi float. MyNoteRatio (pair of ints) is the ratio over the root of MyChord which corresponds to the pitch of MyNote.
   %%
   %% Args currently unused, intended for later extensions.
   %% */
   fun {GetAdaptiveJIPitch2 MyNote MyNoteRatio MyChord Args}
      /** %% Expects a frequency ratio (a float) and octave transposes it into interval [1.0, 2.0]
      %% */
      fun {TransposeRatioIntoZeroOctave Freq}	 
	 if Freq >= Freq0_2 then {TransposeRatioIntoZeroOctave Freq / 2.0}
	 elseif Freq < Freq0 then {TransposeRatioIntoZeroOctave Freq * 2.0}
	 else Freq
	 end
      end
      Ratio_Float = {GUtils.ratioToFloat MyNoteRatio} 
      %% MyChord's root as frequency in lowest MIDI octave, tempered depending on {HS.db.getPitchesPerOctave} or the current tuning table
      Root_Freq = {MUtils.keynumToFreq
		   {{MyChord getRootParameter($)} getValueInMidi($)}
		   12.0}
      %% If root ratio in DB is \= 1/1 in database, then all PC ratios are transposed by the root ratio. So, we have to devide in the end any pitch by untransposed root ratio to compensate for this. 
      UntransposedRoot_Float = {GUtils.ratioToFloat
				{DB.getUntransposedRootRatio MyChord}.1}
      Octave_Float = {Pow 2.0 {IntToFloat {MyNote getOctave($)}+1}}
      Note_Freq = Octave_Float * {TransposeRatioIntoZeroOctave
				  Ratio_Float * Root_Freq / UntransposedRoot_Float}
   in
      %% translate to midi float
      {MUtils.freqToKeynum Note_Freq 12.0}
   end

   

   %%
   %% minimal cadential sets
   %% 
   
   /** %% Returns the list of all scales with the given scale indices and transpositions (two lists of integers), more specifically the cartesian product of all the scales with these parameters is created.
   %% */
   fun {MakeAllContextScales ScaleIndices Transpositions}
      {Pattern.mapCartesianProduct ScaleIndices Transpositions
       fun {$ Index Transposition}
	  {Score.makeScore scale(index:Index
				 transposition:Transposition)
	   unit(scale:Scale)}
       end}
   end
   local
      /** %% Returns a script which in turn returns a cadential set (a single FS) for MyScaleFS (a determined FS) and its ContextScaleFSs (a list of determined FS) which can contain MyScaleFS as well.
      %% The optional argument 'card' expects an integer for the cardiality of the resulting FS. The default is false and no cardiality constraint is applied.
      %% */
      fun {MakeCadentialSetScript MyScaleFS ContextScaleFSs Args}
	 Default = unit(card:false)
	 As = {Adjoin Default Args}
      in
	 proc {$ SufficientSet}
	    SufficientSet = {FS.var.decl}
	    {FS.subset SufficientSet MyScaleFS}
	    {ForAll {LUtils.remove ContextScaleFSs
		     fun {$ X} X == MyScaleFS end}
	     proc {$ ContextScaleFS} 
		{FD.nega 
		 {Combinator.'reify' 
		  proc {$} {FS.subset SufficientSet ContextScaleFS} end}
		 1}
	     end}
	    if {IsInt As.card}
	    then {FS.card SufficientSet As.card}
	    end
	    {FS.distribute generic [SufficientSet]}
	 end
      end
      /** %% Comparison constraint for creating a minimal cadencial set by BAB search.
      %% */
      proc {MinimiseCardiality FS1 FS2}
	 {FS.card FS1} >: {FS.card FS2}
      end
   in
      /* %% Returns all minimal cadential sets (a list of determined FSs) for MyScale (a determined scale object) for the ContextScales (a list of determined scale objects), that is the set of pitch classes which unambiguously distinguishes MyScale among ContextScales. The ContextScales are conveniently created with MakeAllContextScales. 
      %% Note that MinimalCadentialSets internally performs a search. 
      %% */
      fun {MinimalCadentialSets MyScale ContextScale}
	 {MinimalCadentialSets2 {MyScale getPitchClasses($)}
	  {Map ContextScale fun {$ X} {X getPitchClasses($)} end}}
      end

      /* %% Returns all minimal cadential sets (a list of determined FSs) for MyScaleFS (a determined FS) for the ContextScaleFSs (a list of determined FS), that is the set of pitch classes which unambiguously distinguishes MyScaleFS among ContextScaleFSs. 
      %% Note that MinimalCadentialSets2 internally performs a search.
      %% */
      fun {MinimalCadentialSets2 MyScaleFS ContextScaleFSs}
	 Sols = {Search.base.best {MakeCadentialSetScript MyScaleFS ContextScaleFSs unit}
		 MinimiseCardiality}
      in
	 if Sols \= nil then 
	    {Search.base.all {MakeCadentialSetScript MyScaleFS ContextScaleFSs
			      unit(card:{FS.card Sols.1})}}
	 else nil
	 end
      end
      
%        /* %% Returns  cadential set (a determined FS) for MyScale (a determined scale object) for the ContextScales (a list of determined scale objects), that is the set of pitch classes which unambiguously distinguishes MyScale among ContextScales. The ContextScales are conveniently created with MakeAllContextScales. 
%       %% Note that MinimalCadentialSet internally performs a search. 
%       %% */
%       fun {AllCadentialSets_Card MyScale ContextScale Cardiality}
% 	 {MinimalCadentialSet_Card2 {MyScale getPitchClasses($)}
% 	  {Map ContextScale fun {$ X} {X getPitchClasses($)} end}
% 	  Cardiality}
%       end

%       /* %% Returns the minimal cadential set (a determined FS) for MyScaleFS (a determined FS) for the ContextScaleFSs (a list of determined FS), that is the set of pitch classes which unambiguously distinguishes MyScaleFS among ContextScaleFSs. 
%       %% Note that MinimalCadentialSet internally performs a search.
%       %% */
%       fun {AllCadentialSet_Card2 MyScaleFS ContextScaleFSs Cardiality}
% 	 {Search.base.all {MakeCadentialSetScript MyScaleFS ContextScaleFSs
% 			   unit(card:Cardiality)}}
%       end
   end
   
   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% def of interval
%%%

   %%
   %% What do I need:
   %%
   %%  - An interval which is limited to the intervals expressed by
   %%  the interval database
   %%
   %%  - Convenient access to interval properties: direction, pitch
   %%  class component, octave compenent, scale/chord degree component
   %%  (for scale/chord degree interval subclasses)
   %%
   %%    ?? I may not constrain and store all of these properties
   %%    directly, by generate them when needed and memoize them (key
   %%    is scale's ID)
   %%
   %%  - Access to interval properties defined in DB (e.g. dissonance
   %%  degree)
   %%
   %%  - A convenient means to compute the interval between two notes
   %%  (incl enharmonic, and scale/chord degree notes)
   %%
   %%    ?? Defined either as proc or as method of classes note,
   %%    chord, scale etc
   %%
   %%    ?? an interval is always the interval between notes. For
   %%    expressing the interval between, e.g., two chord notes, first
   %%    express these chord notes, e.g., as chord degree note objects
   %%    and then create the interval between them (this limits the
   %%    number of special interval cases/creators I would other need
   %%    to define).
   %%
   %%
   %% NB: an interval is (usually) not explicitly represented in the
   %% score (in contrast to notes, scales, chords).
   %%
   %%
   
   %% ?? mixin: scale degree interval (?? correspond to InScaleMixinForChord, ScaleDegreeMixinForNote)
   %% ?? mixin: chord degree interval (?? correspond to ScaleDegreeMixinForChord, ChordDegreeMixinForNote)
   
   local
      /** %% Initialise domains of Interval params and relate them.
      %% */
      proc {InitConstraints Self}
	 thread % don't block init if some information is still missing	    
	    MyDB = {Self getDB($)}
	    PCs = MyDB.interval  % tuple of (FD) ints 
	 in
	    %% init/restrict domains
	    {Self getIndex($)} = {FD.int 1#{Width PCs}} %% !!?? 
	    {Self getDistance($)} = {FD.decl}
	    {Self getDirection($)} = {FD.int 0#2}
	    {Self getPitchClass($)} = {DB.makePitchClassFDInt}
	    {Self getOctave($)} = {DB.makeOctaveFDInt}
	    %%
	    %% constrains
	    %%
	    {Self getPitchClass($)} = {Select.fd PCs {Self getIndex($)}}
	    %% restricts distance domain to (OctaveDomainMin * PitchesPerOctave) # (OctaveDomainMax * PitchesPerOctave + PitchesPerOctave-1) 
	    {PitchClassToPitch2 {Self getPitchClass($)}#{Self getOctave($)}
	     {Self getDistance($)}}
	    %% unison: distance 0 <=> direction = (i.e. neither + nor -)  
	    {FD.equi ({Self getDistance($)} =: 0)
	     ({Self getDirection($)} =: 1)
	     1}
	    %% constrain all dbFeatures of Self to their value dependent
	    %% on the Self index in the Db
	    {Record.forAllInd {Self getDBFeatures($)}
	     proc {$ Feat Val}
		%% implicitly sets Val to FD int or FS
		Val = {Rules.getFeature Self Feat}
	     end}
	 end
      end
   in
      /** %% The class Interval is a data structure for representing the interval, for example, between the pitches of two note objects. Various information on the interval is provided including the absolute pitch distance, its direction, its pitch class, and the fitting value of various additional features defined in the interval database (e.g., its dissonance degree). Like the other classes of Strasheela's harmony model, the interval class supports microtonal music based on freely defined equidistant subdivisions of the octave (e.g., 72 pitches per octave or pitches measured in cent, set in the DB as pitchesPerOctave).
      %% The class Interval defines the following parameters. The distance is the absolute distance between two pitches (e.g. 13 is a minor ninth for PitchesPerOctave=12). The parameter direction denotes the direction of the interval: 'upwards' is represented by 2, unison by 1, and an interval 'downwards' by 0 (cf. Pattern.direction). The parameter pitchClass expresses the interval's pitch class, and the parameter octave the number of octaves added to the pitch class to reach the interval's distance (e.g. if the distance is 13, then the pitchClass is 1 and the octave is 1). Finally, the parameter index is the position of the interval's pitch class in the respective interval database (this parameter corresponds to the index parameter of the classes Chord and Scale).
      %% The class Interval allows the user to access and constrain further interval-specific properties. Besides the compulsary interval database feature interval, the user can define arbitrary further attributes in each database entry (see DB.setDB). For example, the default interval database includes the feature dissonanceDegree.
      %% The init argument dbFeatures allows to accociates self with further FD/FS variables. These variables are constrained to the values at the respective feature of an database entry at the position of self's index. The database features to be used are 'announced' by the init method argument dbFeatures, which expects a list of atoms denoting the database features to include.
      %% Let us assume that the database defines the feature dissonanceDegree for each interval in the database. This feature is 'announced' to self with the init argument init(dbFeatures:[dissonanceDegree] ...). The dissonance degree of self is then accessible -- and further constrainable -- by {self getDBFeature($ dissonanceDegree)}.
      %%
      %% Please note that only interval values defined in the interval database are permitted as pitch class values. For example, if you use an Interval object to express the interval between two specific notes and your interval DB does not specify an interval 7 (a fifth if PitchesPerOctave=12), then the interval between the two note pitches is implicitly constrained not to be a fifth.
      %%
      %% NB: The class Interval inherits from Score.abstractElement -- in contrast to the classes Chord and Scale which inherit (indirectly) from Score.temporalElement. Consequently, an interval does _not_ have associated temporal information such as a start time and can thus not be output, for example, in a Lilypond score -- in contrast to instances of the classes Chord and Scale).
      %% */
      %%
      %% TODO:
      %%
      %% - example (in harmonic CSP examples file?)
      %% - add scale/chord degree
      %% - in the init method, I can currently only specify dbFeature "features" (e.g. dissonanceDegree), but not their value
      %%    -> If I change this for class Interval, I should also change it for class PitchClassCollection 
      %%
      %%
      class Interval from Score.abstractElement
	 feat label:interval
	    !IntervalType:unit
	 attr
	    index distance direction pitchClass octave  % all param with FD int
	    dbFeatures		     % record of constrained vars (FD or FS). Features of the record are symbols in init arg dbFeatures
	 meth init(index:Index<=_ distance:Dist<=_ direction:Dir<=_
		   octave:Oct<=_ pitchClass:PC<=_
		   dbFeatures:DBFeats<=nil % arg list of symbols
		   ...) = M
	    Score.abstractElement, {Record.subtractList M
				    [index distance direction octave pitchClass dbFeatures]} 
	    @index = {New Score.parameter init(value:Index info:index)}
	    @distance = {New Score.parameter init(value:Dist info:distance)}
	    @direction = {New Score.parameter init(value:Dir info:direction)}
	    @octave = {New Score.parameter init(value:Oct info:octave)}
	    @pitchClass = {New PitchClass
			   init(value:PC info:pitchClass
				'unit':{DB.getPitchUnit})}
	    @dbFeatures = {Record.make unit DBFeats}
	    {self bilinkParameters([@index @distance @direction @octave @pitchClass])} 
	    %% implicit constrains
	    {InitConstraints self}
	 end
	 meth getIndex(?X)
	    X = {@index getValue($)}
	 end
	 meth getIndexParameter(?X)
	    X = @index
	 end
	 meth getDistance($)
	    {@distance getValue($)}
	 end
	 meth getDistanceParameter($)
	    @distance
	 end
	 meth getDirection($)
	    {@direction getValue($)}
	 end
	 meth getDirectionParameter($)
	    @direction
	 end
	 meth getPitchClass($)
	    {@pitchClass getValue($)}
	 end
	 meth getPitchClassParameter($)
	    @pitchClass
	 end
	 meth getOctave($)
	    {@octave getValue($)}
	 end
	 meth getOctaveParameter($)
	    @octave
	 end
	 
	 /** %% The interval database is defined by DB.setDB. getDB returns the internal representation of this database (see the DB.setDB for more details).
	 %% */
	 meth getDB(?X)
	    X={DB.getInternalIntervalDB}
	 end
	 /** %% Returns a record with the additional features defined in the database and 'announced' to self with the init argument dbFeatures.
	 %% */
	 meth getDBFeatures(?X)
	    X = @dbFeatures
	 end
	 /** %% Returns the value (FD int or FS) of the additional feature Feat.
	 %% */
	 meth getDBFeature(?X Feat)
	    X = @dbFeatures.Feat
	 end
	 
	 %%
	 %% NOTE: an interval object is usually not explicitly
	 %% contained in a score object, and thus will not be output
	 %% when a score is stored in some format.
	 meth getInitInfo($ ...)	 
	    unit(superclass:Score.abstractElement
		 args:[index#getIndex#noMatch
		       distance#getDistance#noMatch
		       direction#getDirection#{FD.int 0#2}
		       pitchClass#getPitchClass#{DB.makePitchClassFDInt}
		       octave#getOctave#{DB.makeOctaveFDInt}
		      ])
	 end
      end
   end
   fun {IsInterval X}
      {Score.isScoreObject X} andthen {HasFeature X IntervalType}
   end

   /** %% Expects two note objects and returns the interval between the two notes. If the Note1 is higher than Note2, then the intervals direction is downwards (i.e. 0).
   %% Additional interval features can be specified with the optional argument dbFeatures (as Args feature). 
   %% The notes are instances of the class Score.note2 or any of its subclasses (including the note classes defined in this functor).
   %% */
   %%
   %% TODO:
   %%
   %% - what about subclasses of Interval (e.g. for intervals with scale degree parameter)
   %%   ?? possibly, I add suitable methods to the note classes of this functor and add to the doc of this function a comment about this limitation and point to these methods
   %%
   fun {NoteInterval Note1 Note2 Args}
      Defaults = unit(dbFeatures:nil)
      As = {Adjoin Defaults Args}
      MyInterval = {New Interval init(dbFeatures:As.dbFeatures)}
   in
      {Score.initScore MyInterval} % close parameter etc. extendable lists
      {TransposeNote Note1 MyInterval Note2}
      MyInterval
   end

   /** %% Constrains the relation that the pitch of Note1 transposed by MyInterval reaches the pitch of Note2.
   %% The notes are instances of the class Score.note2 or any of its subclasses (including the note classes defined in this functor), MyInterval is an instance of the class Interval (or its subclasses).
   %% Please note that MyInterval (like the notes) should be fully initialised (e.g., otherwise inspecting interval internals does not work properly).
   %% */
   %%
   %% TODO:
   %%
   %% - I probably need an additional constraint for scale degree notes and an interval with scale degree support.
   %%   ?? possibly, I add suitable methods to the note classes of this functor and add to the doc of this function a comment about this limitation and point to these methods
   %%
   proc {TransposeNote Note1 MyInterval Note2}
      {FD.distance {Note1 getPitch($)} {Note2 getPitch($)} '=:'
       {MyInterval getDistance($)}}
      {Pattern.direction {Note1 getPitch($)} {Note2 getPitch($)}
       {MyInterval getDirection($)}}
   end

   %%
   %% TODO: unfinished defs ScaleDegreeMixinForInterval / ChordDegreeMixinForInterval
   %%

%    local
%       %% Initialise domains of Interval params and relate them.
%       %% 
%       proc {InitConstraints Self}
%       end
%    in
%       %% The class ScaleDegreeMixinForInterval introduces the notion of scale degree distances as intervals between notes with a scale degree parameter (i.e. a subclass of ScaleDegreeMixinForNote). For example, in case the reference scale is C-major the scale degree distance 5 denotes a fifth.  
%       %% 
%       %%
%       %% ?? What are the scale degree distances with neutral accidental?
%       %%
%       %% - CASE 1: intervals between scale degrees are degree distances with neutral accidental
%       %%   Problem: equal pitch distances result in different degree distances and vice versa. 
%       %% For example, in C-major the tritone interval between the two pitch classes f and b is 4 scale degrees with neutral accidental (both pitches are scale pitches), and the just fourth interval between f and b-flat is 4 with b accidental (the scale degree b is flattened).

%       %%
%       %% - CASE 2: distances between the scale's root and some scale degree are degree distances with neutral accidental
%       %%   Problem: the interval between scale degree notes without accidental (e.g. in C-major the tritone interval between the two pitch classes f and b) result in degree distances with an accidental (distance 4 with accidental #). In other words: if I constrain the interval accidental to neutral, some intervals between scale degrees are disallowed.     
%       %%   ?? is this a problem: this is actually desirable, e.g., to disallow any diminished or augmented interval, even if it is an interval between scale degrees.
%       %%   Problem is that I can not distinguish between just vs. diminished/augmented intervals and minor vs. major intervals.
%       %%   -> this is impossible to distinguish with interval representation using notion of degree + accidental, but if I introduce a more specific representation (e.g. additional parameters) then generalising the interval for arbitrary PitchesPerOctave and for chord degree distances gets hard. 
%       %%
%       %% - CASE 3: scale degree distances with neutral accidental are specifically marked in the interval database or the scale database
%       %%   ?? problem remains: I can not distinguish between just vs. diminished/augmented intervals and minor vs. major intervals 
%       %%
%       class ScaleDegreeMixinForInterval
%       end
%    end

   
%    local
%       %% Initialise domains of Interval params and relate them.
%       %% 
%       proc {InitConstraints Self}
%       end
%    in
%       class ChordDegreeMixinForInterval
%       end
%    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% def of chord and scale etc
%%%

   /** %% [concrete class] PitchClass defined as a subclass from Score.pitch to inherit, e.g., getValueInMidi for other pitch units (e.g. cent). Consequently, a pitch class returns true for isPitch -- which may sometimes be undesired (e.g. for a concise/efficient distribution strategy definition).
   %% BTW: PitchClass is only applied for pitch class parameters and not for pitch class sets (as defined, e.g., by Chord or Scale).
   %% !! Problem: are the translations of Score.pitch into various units (e.g. freq) really what I am after for pitch classes?
   %%*/
   class PitchClass from Score.pitch
      feat label: pitchClass
	 !PitchClassType:unit
   end
   fun {IsPitchClass X}
      {Score.isScoreObject X} andthen {HasFeature X PitchClassType}
   end
		       
   local
      /** %% Initialises all constrainable variables in Self (a PitchClassCollection) to a FD int respectively a FS, relates these variables to the chord/scale database and interrelates the variables (e.g. by TransposePC).
      %% */
      proc {InitConstrain Self}
	 %% Self::PitchClassCollection 
	 thread % don't block init if some information is still missing
	    MyDB = {Self getDB($)}
	    PCFSs = MyDB.pitchClasses
	    %% unify with parameters/attributes
	    Index = {Self getIndex($)}
	    Transposition = {Self getTransposition($)}
	    TranspRoot = {Self getRoot($)}
	    TranspPCs_FS = {Self getPitchClasses($)}
% 	    TranspPCs_FDs = {Self getPitchClasses_FDs($)}
	    UntranspRoot = {Self getUntransposedRoot($)}
	    UntranspPCs_FS = {Self getUntransposedPitchClasses($)}
% 	    UntranspPCs_FDs = {Self getUntransposedPitchClasses_FDs($)}
	 in
	    %%
	    %% init domains
	    %%
	    Index = {FD.int 1#{Width PCFSs}}
	    Transposition = {DB.makePitchClassFDInt}
	    TranspRoot = {DB.makePitchClassFDInt}	 
	    TranspPCs_FS = {FS.var.upperBound 0#{DB.getPitchesPerOctave}-1} 
	    UntranspRoot = {DB.makePitchClassFDInt}
	    %% constrain chord to be from ChordFSs (reduces domain according
	    %% to the DB)
	    UntranspPCs_FS = {Select.fs PCFSs Index}
	    %%
	    %% further constraints (e.g. transposition constraints)
	    %%
	    {FS.card UntranspPCs_FS} = {FS.card TranspPCs_FS}
	    %% set of roots must not be empty -- which value should UntranspRoot have otherwise?
	    {FS.include UntranspRoot {Select.fs MyDB.roots Index}}
	    {TransposePC UntranspRoot Transposition TranspRoot}

	    %% root is always in set of pitch classes (this is even true for chords like diminished triad or seventh chord: root is not fundamental)
	    {FS.include UntranspRoot UntranspPCs_FS}
	    {FS.include TranspRoot TranspPCs_FS}
	    
	    %% alternative try of transposition constraints with GUtils.intsToFS instead of FS.forAllIn and possibly re-use of the FD variables for other user constraints
	    %% This approach seems to work as well, but the FD variables are not necessarily determined, so the hoped for additional use is not really there. 
% 	    thread
% 	       %% NOTE: completely blocks until cardiality of the chord is known. Can I do better (def FD.list variant expecting an FD int for length and returning a stream always as long as lower bound?)
% 	       TranspPCs_FDs = {FD.list {FS.card UntranspPCs_FS}
% 				0#{DB.getPitchesPerOctave}-1}
% 	       UntranspPCs_FDs = {FD.list {FS.card UntranspPCs_FS}
% 				  0#{DB.getPitchesPerOctave}-1}
% 	       {GUtils.intsToFS TranspPCs_FDs TranspPCs_FS}
% 	       {GUtils.intsToFS UntranspPCs_FDs UntranspPCs_FS}
% 	       %% problem: very weak propagation, because order of PCs in my FDs vars is free and this order is never determined. 
% 	       {ForAll {LUtils.matTrans [TranspPCs_FDs UntranspPCs_FDs]}
% 		proc {$ [TranspPC UntranspPC]}
% 		   {TransposePC UntranspPC Transposition TranspPC}
% 		end}
% 	    end

	    
	    %% NOTE: each of these two FS.forAllIn constraints only works one way (e.g., either from from UntranspPCs_FS to TranspPCs_FS or the other way round. Therefore, I need both constraints.
	    %% Often, not both are needed, so this doubling is inefficient. But it is so far the best definition I came up with...
	    thread
	       %% maps immediately over all known set members but suspends then
	       {FS.forAllIn UntranspPCs_FS
		proc {$ UntranspPC}
		   TranspPC = {DB.makePitchClassFDInt}
		in
		   {TransposePC UntranspPC Transposition TranspPC}
		   {FS.include TranspPC TranspPCs_FS}
		end}
	    end
	    thread
	       {FS.forAllIn TranspPCs_FS
		proc {$ TranspPC}
		   UntranspPC = {DB.makePitchClassFDInt}
		in
		   {TransposePC UntranspPC Transposition TranspPC}
		   {FS.include UntranspPC UntranspPCs_FS}
		end}
	    end
	    
	    %% constrain all dbFeatures of Self to their value dependent
	    %% on the Self index in the Db
	    {Record.forAllInd {Self getDBFeatures($)}
	     proc {$ Feat Val}
		%% implicitly sets Val to FD int or FS
		Val = {Rules.getFeature Self Feat}
	     end}
	 end
      end
   in 
      /** %% [abstract class] Represents a collection of pitch classes (absolute pitches without octave component) which is a transposed version of a pitch class collection from a user-defined database (see ./Database.oz respectively DB). Example subclasses of PitchClassCollection include analytical score objects such as Scale or Chord. The design of PitchClassCollection aims to be highly generic: PitchClassCollection is intended to allow the user to define her/his own theory of harmony based on user defined databases of chords and scales; PitchClassCollection even supports microtonal music based on freely defined equidistant subdivisions of the octave (e.g. et72 or even measured in cent, set in the DB as pitchesPerOctave).
      %% PitchClassCollection defines four parameters (index, transposition, root, untransposedRoot) whose value is a FD integer, and two attributes which are FS (pitchClasses, untransposedPitchClasses). The index is the position of the respective chord/scale in the chord/scale database, transposition denotes how much self is transposed with respect to the database entry, pitchClasses is the set of transposed pitch classes and root is the transposed root pitch class (untransposed roots are defined in the database). untransposedPitchClasses and untransposedRoot are the untransposed pitchClasses and the untransposed root, i.e. the actual pitch classes in the database entry. Except for index, all parameters/attributes denote pitch classes, that is absolute pitches without an octave component. What the actual value of a pitch class means depends on the pitches per octave setting in the database. Consequently, the pitchUnit of all pitch classes is implicitly set accordingly depending on DB.getPitchesPerOctave.
      %% The class PitchClassCollection allows to access and constrain further chord/scale-specific properties. Besides the compulsary chord/scale database features pitchClasses and roots, the user can define arbitrary further attributes in each database entry (see DB.setDB). Examples include dissonanceDegree, resemblanceWithTradition, clearnessOfColour etc. The init argument dbFeatures allows to accociates self with further FD/FS variables. These variables are constrained to the values at the respective feature of an database entry at the position of self's index. The database features to be used are 'announced' by the init method argument dbFeatures, which expects a list of atoms denoting the database features to include.
      %% Let us assume that the database defines the feature dissonanceDegree for each entry in the database. This feature is 'announced' to self with the init argument init(dbFeatures:[dissonanceDegree] ...). The dissonance degree of self is then accessible -- and further constrainable -- by {self getDBFeature($ dissonanceDegree)}.
      %%
      %% NB: In case the database defines only chord/scale entries with single roots, only the parameters index and transposition are necessary to distribute because once index and transposition are determined, all other parameters/attributes are determined as well. Therefore, the distribution strategy may filter out all root and untransposedRoot parameters for efficiency (their info slot contains root or untransposedRoot). However, in case one or more chords/scales in the DB define mutiple possible roots then the root _or_ the untransposedRoot must be distributed explicitly (but one of them is sufficient). 
      %%
      %% BTW: The actual chord/scale database is accessible by the method getDB (see there).
      %% */

      %% !!?? what shall be value of root if chord has no root (has an augmented chord or a cluster a root)? I may simply claim that in this example every chord must have a root (in the database the roots are a list//set which already gives a lot of freedom.).
      %%
      %% I considered representation of pitchClasses by absolute noteNames + accidentals for a more exact representation. However, storing of plain pitch class ints in FS more concise/flexible in Oz CSP than some collection of int pairs. -- I may define a further Mixin for Note with params degree + accidental..
      %%
      %% what shall be parameter (FD or FS) and what shall be just attribute. I need a param in case either distribution of the FD/FS var may be required or the specification of unit of measurement may be required.
      %% Neither of these is required for pitchClasses or untransposedPitchClasses: Pitch classes are always determined by index and transposition their unit is fixed anyway dependent on pitchPerOctave/pitchUnit set in database.
      %% root and untransposedRoot are determined when index and transposition are determined and the cardiality of the root in the DB is 1. However, in case a chord in the DB defines mutiple  possible roots then the root _or_ the untransposedRoot must be distributed explicitly. That is, both root and untransposedRoot are not required for distribution if transposition is distributed.
      %%
      class PitchClassCollection from Score.temporalElement
	 feat label:pitchClassCollection
	    !PitchClassCollectionType:unit
	 attr
	    index 		% param with FD int
	    transposition	% param with FD int
	    pitchClasses	% FS
% 	    pitchClasses_FDs	% list of FD ints, contains same numbers as pitchClasses. Undetermined until cardiality of chord is known.
	    root		% pitch param with FD int
	    %% aux: not necessarily needed by user:
	    untransposedPitchClasses % FS
% 	    untransposedPitchClasses_FDs % list of FD ints, contains same numbers as untransposedPitchClasses. Undetermined until cardiality of chord is known.
	    untransposedRoot	     % pitch param with FD int
	    dbFeatures		     % record of constrained vars (FD or FS). Features of the record are symbols in init arg dbFeatures.
	 meth init(index:Index<=_
		   transposition:Trans<=_
		   root:Root<=_
		   untransposedRoot:UntranspRoot<=_
		   pitchClasses:PitchClasses<=_
% 		   pitchClasses_FDs:PitchClasses_FDs<=_
		   untransposedPitchClasses:UntransposedPitchClasses<=_
% 		   untransposedPitchClasses_FDs:UntransposedPitchClasses_FDs<=_
		   dbFeatures:DBFeats<=nil % arg list of symbols
		   ...) = M
	    Score.temporalElement, {Record.subtractList M
				    [index transposition
				     pitchClasses untransposedPitchClasses
				     root untransposedRoot
				     dbFeatures]}
	    @index = {New Score.parameter init(value:Index info:index)}
	    @transposition = {New PitchClass init(value:Trans info:transposition
						  'unit':{DB.getPitchUnit})}
	    @root = {New PitchClass init(value:Root info:root
					 'unit':{DB.getPitchUnit})}
	    @untransposedRoot = {New PitchClass
				 init(value:UntranspRoot info:untransposedRoot
				      'unit':{DB.getPitchUnit})}
	    @pitchClasses = PitchClasses
% 	    @pitchClasses_FDs = PitchClasses_FDs
	    @untransposedPitchClasses = UntransposedPitchClasses
% 	    @untransposedPitchClasses_FDs = UntransposedPitchClasses_FDs
	    @dbFeatures = {Record.make unit DBFeats}
	    {self bilinkParameters([@index @transposition @root @untransposedRoot])} 
	    %% init domains and implicit constraints
	    {InitConstrain self}
	 end
	 meth getIndex(?X)
	    X = {@index getValue($)}
	 end
	 meth getIndexParameter(?X)
	    X = @index
	 end
	 meth getTransposition(?X)
	    X = {@transposition getValue($)}
	 end
	 meth getTranspositionParameter(?X)
	    X = @transposition
	 end
	 meth getRoot(?X)
	    X = {@root getValue($)}
	 end
	 meth getRootParameter(?X)
	    X = @root
	 end
	 meth getUntransposedRoot(?X)
	    X = {@untransposedRoot getValue($)}
	 end
	 meth getUntransposedRootParameter(?X)
	    X = @untransposedRoot
	 end
	 meth getPitchClasses(?X)
	    X = @pitchClasses
	 end
% 	 meth getPitchClasses_FDs(?X)
% 	    X = @pitchClasses_FDs
% 	 end
	 meth getUntransposedPitchClasses(?X)
	    X = @untransposedPitchClasses
	 end
% 	 meth getUntransposedPitchClasses_FDs(?X)
% 	    X = @untransposedPitchClasses_FDs
% 	 end
	 /** %% Returns a record with the additional features defined in the database and 'announced' to self with the init argument dbFeatures.
	 %% */
	 meth getDBFeatures(?X)
	    X = @dbFeatures
	 end
	 /** %% Returns the value (FD int or FS) of the additional feature Feat.
	 %% */
	 meth getDBFeature(?X Feat)
	    X = @dbFeatures.Feat
	 end
	 
	 /** %% Constraints PC (FD int) to Degree with Accidental (FD ints) in self.
	 %%
	 %% NOTE: very weak propagation -- self must first be determined
	 %% */
	 %% Inconsistency to interface of proc with this name..
	 %%
	 %% -> GetDegree does not work correctly if untransposed root is not 0
	 meth degreeToPC(Degree Accidental PC)
	    thread 		% thread because FD.list blocks until N in known..
	       %% !! inefficient definition: I need the transposed pitch classes in the order of the untransposed pitch classes as vector. I can not extract these from @pitchClasses and therefore FS.match @untransposedPitchClasses and transpose them again (!).
	       %% An alternative differnt implementation of @pitchClasses themselves as vector of FD ints instead of Fs would not be a good idea either: selection/propagation of the cardiality would not work and block until @index is determined.
	       %%
	       %% TODO: memorise TranspPCsList in further attr and abstract creation of this list into some accessor -- creation/constraint is only called once.
	       %%
	       PCDomain = 0#{DB.getPitchesPerOctave}-1
	       Transposition = {self getTransposition($)}
	       Root = {self getRoot($)}
	       UntranspPCsFS = {self getUntransposedPitchClasses($)}
	       N = {FS.card UntranspPCsFS}
	       %% !! blocks until N is determined (i.e. @index is determined or all chords/scales in database or index domain are of equal length)
	       UntranspPCsList = {FD.list N PCDomain} 
	       TranspPCsList = {FD.list N PCDomain}
	       RootPos TranspPCsList_Sorted
	    in
	       %% !!?? is matching a good idea: shall PCs always be in
	       %% increasing order in UntranspPCsList
	       {FS.int.match UntranspPCsFS UntranspPCsList}
	       %% NB: blocks
% 	       thread {GUtils.intsToFS UntranspPCsList UntranspPCsFS} end
	       {ForAll {LUtils.matTrans [UntranspPCsList TranspPCsList]}
		proc {$ [UntranspPC TranspPC]}
		   {TransposePC UntranspPC Transposition TranspPC}
% 		   {TransposePC UntranspPC Root TranspPC}
		end}
	       %% NOTE: sorting greatly impairs propagation, but should at least work correctly for determined chord/scale
	       RootPos = {LUtils.position Root TranspPCsList}
	       TranspPCsList_Sorted = {Append {List.drop TranspPCsList RootPos-1}
				       {List.take TranspPCsList RootPos-1}}
	       {DegreeToPC TranspPCsList_Sorted Degree#Accidental PC}
	    end
	 end
	 /** %% dummy method for documentation -- redefined in subclasses.
	 %% */
	 %% !! shall I skip this?
	 meth getDB(?X)
	    X=unit(...)		% default: empty database
	 end
	 meth toPPrintRecord(?X features:Features<=[items parameters value info 'unit']
			     excluded:Excluded<=nil)
	    {self makePPrintRecord(X Features
				   [containers flags info id parameters
				    index transposition pitchClasses root
				    untransposedPitchClasses untransposedRoot
				    dbFeatures]
				   Excluded)}
	 end
%	 meth getAttributes(?X)
%	    X = {Append
%		 Score.temporalElement, getAttributes($)
%		 [index transposition pitchClasses root
%		  untransposedPitchClasses untransposedRoot
%		  dbFeatures]}
%	 end
% 	 meth toInitRecord(?X exclude:Excluded<=nil)
% 	    X = {Adjoin
% 		 Score.temporalElement, toInitRecord($ exclude:Excluded)
% 		 {Record.subtractList
% 		  %% !!?? overexplicit. E.g. pitchClasses determined by index + transposition. But in case params are undetermined..
% 		  {self makeInitRecord($ [index#getIndex#noMatch
% 					  transposition#getTransposition#noMatch
% 					  root#getRoot#noMatch
% 					  untransposedRoot#getUntransposedRoot#noMatch
% 					  pitchClasses#getPitchClasses#noMatch
% 					  untransposedPitchClasses#getUntransposedPitchClasses#noMatch
% 					  dbFeatures#fun {$ X } {Arity {X getDBFeatures($)}} end#nil
% 					 ])}
% 		  Excluded}}
% 	 end

	 /** %% The parameter 'index' is included if it is undetermined, but it is omitted in case the set of pitch classes, the transposition, and the index are determined. If the index is determined, then the set of pitch classes plus the transposition should be sufficient and the index can be derived from them. Omitting the index makes archived score solutions more stable. Even if the chord/scale database was edited  later (e.g., chords were added) so that the indices changed, the archived score will still work as long as the set of pitch classes for the original chords did not change.
	 %% In principle, it is possible that there are two chords with the same pitchclasses and transposition but different additional db features. However, that should be considered a bug in the database. In case alternative db feature values for a single chord/scale are needed, then these should be defined as variable domain values for a single db entry, not as additional entries.  
	 %% */
	 meth getInitInfo($ ...)	    
	    unit(superclass:Score.temporalElement
		 args: {Append if {IsDet {self getPitchClasses($)}} andthen
				  {IsDet {self getTransposition($)}} andthen
				  {IsDet {self getIndex($)}}
			       then nil
			       else [index#getIndex#noMatch]
			       end
			[transposition#getTransposition#noMatch
			 root#getRoot#noMatch
			 %% untransposedRoot and untransposedPitchClasses are implicit in index and transposition
		       % untransposedRoot#getUntransposedRoot#noMatch
			 pitchClasses#getPitchClasses#noMatch
		       % untransposedPitchClasses#getUntransposedPitchClasses#noMatch
			 dbFeatures#fun {$ X} {Arity {X getDBFeatures($)}} end#nil
			]})
	 end

	 
      end
   end
   fun {IsPitchClassCollection X}
      {Score.isScoreObject X} andthen {HasFeature X PitchClassCollectionType}
   end



   /** %% Chord represents an analytical chord, i.e. a chord which is silent when the score is played but is used to constrain notes simultaneous with the chord. For example, Chord instances can be used to express a roman numeral or functional analysis of the music.
   %% For further information see doc of PitchClassCollection.
   %% */
   class Chord from PitchClassCollection
      feat !ChordType:unit
	 label:chord 
	 /** %% The chord database is defined by DB.setDB. getDB returns the internal representation of this database (see the DB.setDB for more details).
	 %% */
      meth getDB(?X)
	 X={DB.getInternalChordDB}
      end

      %% Try: output code string for creating index instead of index itself. However, as every call to method toInitRecord then shows this code instead of the index, this can be misleading. Besides, exporting would export it as string..
%       meth getInitInfo($ exclude:Excluded)	    
% 	 unit(superclass:Score.temporalElement % skip PitchClassCollection
% 	      args: [index#fun {$ X} "{HS.db.getChordIndex '"#{self getDB($)}.comment.{self getIndex($)}.comment#"'}" end#noMatch
% 		     transposition#getTransposition#noMatch
% 		     root#getRoot#noMatch
% 		     %% untransposedRoot and untransposedPitchClasses are implicit in index and transposition
% 		       % untransposedRoot#getUntransposedRoot#noMatch
% % 			pitchClasses#getPitchClasses#noMatch
% 		       % untransposedPitchClasses#getUntransposedPitchClasses#noMatch
% 		     dbFeatures#fun {$ X} {Arity {X getDBFeatures($)}} end#nil
% 		    ])
%       end
   end
   fun {IsChord X}
      {Score.isScoreObject X} andthen {HasFeature X ChordType}
   end
   
   /** %% Scale represents an analytical scale, i.e. a scale which is silent when the score is played but is used to constrain notes simultaneous with the scale. For example, Scale instances can be used to express a modulation.
   %% For further information see doc of PitchClassCollection.
   %% */
   class Scale from PitchClassCollection
      feat !ScaleType:unit
	 label:scale
	 /** %% The chord database is defined by DB.setDB. getDB returns the internal representation of this database (see the DB.setDB for more details).
	 %% */
      meth getDB(?X)
	 X={DB.getInternalScaleDB}
      end
   end
   fun {IsScale X}
      {Score.isScoreObject X} andthen {HasFeature X ScaleType}
   end

   %% !! definition mirrors InitConstrain of InChordMixinForNote -- some code repetition with different arg etc names.
   local
      proc {InitConstrain Self Args}
	 thread % {Self getScales($)} blocks until Scale candidates are accessible
	    proc {IntersectR FS1 FS2 FS3 B}
	       B = {FD.int 0#1}
	       B = {Combinator.'reify'
		    proc {$} {FS.intersect FS1 FS2 FS3} end}
	    end
	    InScaleB = {Self getInScaleB($)} = {FD.int 0#1}
	    ChordPCsInScaleFS = {Self getChordPCsInScale($)} % FS (declared below)
	    ChordPCsFS = {Self getPitchClasses($)} % FS
	    Scales = {Self getScales($)}	
	    ScalePCFSs = {Map Scales fun {$ X} {X getPitchClasses($)} end} % list of FS
	    RelatedScaleBs	% list of 0/1-ints 
	    = {Self getRelatedScaleBs($)}
	    = {Map Scales 
	       fun {$ Scale}
		  {Args.isRelatedScale Self Scale}
	       end}
	    ExistingChordB = {CTT.isExisting Self} % 0/1-int
	 in
	    ChordPCsInScaleFS = {FS.var.upperBound 0#{DB.getPitchesPerOctave}-1}
	    %% constraints only applied unless Scales==nil (the default!)
	    if {Not (Scales==nil)}
	    then
	       %% only a single related scale permitted
	       1 = {FD.sum RelatedScaleBs '=:'}
	       InScaleB = {FD.sum {Map {LUtils.matTrans [ScalePCFSs RelatedScaleBs]}
				   proc {$ [ScalePCFS RelatedScaleB] B}
				      %% to 'access' the right scale FS:
				      %% imply constraint for RelatedScaleB=1
				      %%
				      %% !!?? should I combine these two statements into single statement (perhaps better propagation?)
				      {FD.impl ExistingChordB
				       {FD.impl RelatedScaleB
					{IntersectR ScalePCFS ChordPCsFS
					 ChordPCsInScaleFS}}
				       1}
				      B = {FD.conj RelatedScaleB
					   {FD.impl ExistingChordB
					    {FS.reified.equal ChordPCsFS ChordPCsInScaleFS}}}
				   end}
			   '=:'}
	       %% in case of Scales==nil 
	    else InScaleB=0	% !!?? OK 
	    end
	 end
      end
   in
      /** %% [abstract class] Mixin class, indented to extend the Chord class (a class with attribute pitchClasses). InScaleMixinForChord has much similarity with class InChordMixinForNote respectively InScaleMixinForNote -- see doc there for details (this documentation only explains the differences to InChordMixinForNote).
      %% Compared with InChordMixinForNote/InScaleMixinForNote, the present class InScaleMixinForChord defines the additional attribute 'chordPCsInScale' (a FS). The set chordPCsInScale includes all chord pitch classes which are also pitch classes of the scale related to the chord. inScaleB = 1 (i.e. true), in case _all_ chord pitch classes are also pitch classes of the related scale.
      %% Nevertheless, the FS chordPCsInScale can be useful to apply further constraints which control the relation between the chord and the related scale even in case inScaleB=0 (i.e. some chord pitch class is no scale pitch class). For instance, degreeToPC could be used to access a specific pitch class of chord (e.g. its third). By constraining a neutral accidental and by constraining that this pitch class is included in chordPCsInScale, the user constraints, e.g., a diatonic third of the chord. [note: this is not so easy, cf. def. of ScaleDegreeMixinForChord which does something related for the chord's root]
      %% 
      %% NB: Contrary to InChordMixinForNote, InScaleMixinForChord does (currently?) not simplify the definition of CSPs involving 'non-existing' notes. Thus, instead of, e.g., setting InScaleB=1 you define something like, {FD.impl {CTT.isExisting MyChord} {MyChord isInChordR($)}}.
      %% */
      %% !! definition mirrors InChordMixinForNote -- much code repetition with different arg etc names. 
      class InScaleMixinForChord
	 feat !InScaleMixinForChordType:unit
	 attr
	    inScaleB		% parameter with 0/1 int
	    chordPCsInScale % FS. May remain undetermined in case inScaleB value = 0.
	    scales  % list of scale candidate objects
	    relatedScaleBs % list of 0/1-ints matching scale candidate objects
	 meth initInScaleMixinForChord(...) = M
	    %% !!?? couldn't I use syntax of meth directly for defining arg defaults??
	    Defaults = unit(inScaleB:_
			    %% !!?? suitable default? 
			    getScales:fun {$ Self}
					 MyScale = {Self findSimultaneousItem($ test:IsScale)}
				      in
					 if MyScale == nil then nil
					 else [MyScale]
					 end
				      end 
			    %% !!?? B=1 OK? (more often needed then just skip). But very wrong when getScales returns more than one candidate! 
			    isRelatedScale:proc {$ Self Scale B} B=1 end
			    chordPCsInScale:_)
	    Args = {Adjoin Defaults M}
	 in
	    @inScaleB = {New Score.parameter init(value:Args.inScaleB info:inScaleB
						  'unit':'0//1 int')}
	    @chordPCsInScale = Args.chordPCsInScale
	    {self bilinkParameters([@inScaleB])}
	    thread
	       %% depending on its definition, getScales may block, e.g., until temporal structure of score is fully determined
	       @scales = {Args.getScales self}
	       {InitConstrain self Args}
	    end
	 end
	 /** %% see doc InChordMixinForNote, isInChord 
	 %% */
	 meth isInScale(?B) B = {self getInScaleB($)} end
	 meth getInScaleB(?X)
	    X = {@inScaleB getValue($)}
	 end
	 meth getInScaleBParameter(?X)
	    X = @inScaleB
	 end
	 meth getChordPCsInScale(?X)
	    X = @chordPCsInScale
	 end
	 /** %% Returns the list of candidate scale objects, i.e. the value returned by the proc set via the getScales init argument. 
	 %% */ 
	 meth getScales(?X)
	    X = @scales
	 end
	 
	 /** %% Returns a list of 0/1-integers returned by {Map {<getScales>} <isRelatedScale>}. <getScales> and <isRelatedScale> are the functions given to initInScaleMixinForNote.
	 %% */
	 meth getRelatedScaleBs(?X)
	    X = @relatedScaleBs
	 end

% 	    /** %% see doc InChordMixinForNote, nonChordNoteConditions
% 	    %% */
% 	    meth nonScalePCConditions(Conditions)
% 	       Bs = {Map Conditions proc {$ Cond B} B = {Cond self} end}
% 	       SumBs = {FD.decl}
% 	    in
% 	       SumBs = {FD.sum Bs '=:'}
% 	       %% if isInScale=0, then (SumBs>0)=1
% 	       %% if isInScale=1 -- no consequences
% 	       %% if SumBs=0 then isInScale=1
% 	       %% if SumBs=1 -- no consequences
% 	       {FD.impl ({self isInScale($)} =: 0) (SumBs >: 0) 
% 		1}
% 	       {FD.impl (SumBs =: 0) ({self isInScale($)} =: 1)
% 		1}
% 	    end
      
% 	 meth getInScaleMixinForChordAttributes(?X)
% 	    X =[inScaleB chordPCsInScale] 
% 	 end
% 	 meth toInScaleMixinForChordInitRecord(?X exclude:Excluded)
% 	    X = {Record.subtractList
% 		 {self makeInitRecord($ [inScaleB#getInScaleB#noMatch
% 					 chordPCsInScale#getChordPCsInScale#noMatch])}
% 		 Excluded}
% 	 end
      end
   end
   fun {IsInScaleMixinForChord X}
      {Score.isScoreObject X} andthen {HasFeature X InScaleMixinForChordType}
   end

   /** %% [class constructur] Expects a chord class and returns a subclass which inherits from this chord class and InScaleMixinForChord. 
   %% */
   fun {MakeInScaleChordClass SuperClass} 
      class $ from  SuperClass InScaleMixinForChord
	 feat label:inScaleChord
	 
	 meth init(...) = M
	    InScaleMixinFeats = [inScaleB getScales isRelatedScale chordPCsInScale]
	 in
	    SuperClass, {Record.subtractList M InScaleMixinFeats}
	    InScaleMixinForChord, {Adjoin
				   {GUtils.takeFeatures M  InScaleMixinFeats}
				   %% replace label
				   initInScaleMixinForChord}
	 end
%      meth getAttributes(?X)
%	 X = {Append
%	      Chord, getAttributes($)
%	      InScaleMixinForChord, getInScaleMixinForChordAttributes($)}
%      end
%       meth toInitRecord(?X exclude:Excluded<=nil)
% 	 X = {Adjoin
% 	      Chord, toInitRecord($ exclude:Excluded)
% 	      InScaleMixinForChord, toInScaleMixinForChordInitRecord($ exclude:Excluded)}
%       end
      
	 meth getInitInfo($ ...)	 
	    unit(superclass:SuperClass
		 args:[inScaleB#getInScaleB#{FD.int 0#1}
		       chordPCsInScale#getChordPCsInScale#noMatch
		       %% !!?? what to do with init args which get procs
		       %%
		       %% I must exclude procedures and classes as init argument if I export into text files.
		       %% Moreover, these will probably not work for pickling: can I pickle a proc which references an object??
		       %%
		       %% ?? when do I need procedures and classes as init argument: if I what to recreate a CSP (e.g. after hand-editing results). I probably don't need these args for score objects which are fully determined and are only archived..
%		     getScales#fun {$ X} X.getScales end#proc {$ Self Scales} Scales=nil end
%		     isRelatedScale#fun {$ X} X.isRelatedScale end#proc {$ Self Scale B} B=1 end
		      ])
	 end
      end
   end

   /** %% [concrete class] Defines a Chord which relates to a Scale (the Scale is defined by getScales and isRelatedScale). When the parameter value of inScaleB (a 0/1 integer) = 1, then all Chord pitch classes are diatonic, i.e. they are also pitch classes of the related Scale. 
   %% See doc for Chord and InScaleMixinForChord for further details.
   %% */
   DiatonicChord = {MakeInScaleChordClass Chord}

      
   local
      /** %% Initialise domains of params and relate them.
      %% */
      proc {InitConstrain Self}
	 thread % {Self getScales($)} blocks until Scale candidates are accessible
% 	 %% init/restrict domains
	    %% I don't know cardiality of related scale and can therefore
	    RootDegree = {Self getRootDegree($)} = {DB.makeScaleDegreeFDInt}
	    RootAccidental = {Self getRootAccidental($)} = {DB.makeAccidentalFDInt}
	    RootPC = {Self getRoot($)}
	    ExistingChordB = {CTT.isExisting Self} % 0/1-int
	    %%
	    Scales = {Self getScales($)}
	    %% list of 0/1-ints
	    RelatedScaleBs = {Self getRelatedScaleBs($)}
	    %% list of FS
	    ScalePCFSs = {Map Scales fun {$ X} {X getPitchClasses($)} end} 
	    %% list of FD
	    ScaleRoots = {Map Scales fun {$ X} {X getRoot($)} end} 	 
	 in
	    %% if all chord pitch classes are in scale, then the root must also be in scale and its scale-related accidental thus neutral -- but not the other way round
	    {FD.impl ({Self getInScaleB($)} =: 1)
	     (RootAccidental =: {AbsoluteToOffsetAccidental 0})
	     1}
	    %% explicitly given, because this constraint is not fully equivalent with constraint before
	    %% !!?? is there a better way to express this?
	    {FD.impl ({Self getInScaleB($)} \=: 1)
	     (RootAccidental \=: {AbsoluteToOffsetAccidental 0})
	     1}
	    %%
	    {ForAll {LUtils.matTrans [ScalePCFSs ScaleRoots RelatedScaleBs]}
	     proc {$ [ScalePCFS ScaleRoot RelatedScaleB]}
		%% apply constraint for related scale (the is always only
		%% one), if note "exists"
		{FD.impl {FD.conj ExistingChordB RelatedScaleB}
		 {Combinator.'reify'
		  proc {$}
		     %% NB: blocks until ScalePCFS and ScaleRoot are determined
		     CollectionPCs = {PcSetToSequence ScalePCFS ScaleRoot}
		  in
		     {DegreeToPC CollectionPCs RootDegree#RootAccidental RootPC}
		  end}
		 1}
	     end}
	 end
      end
   in
      /** %% [abstract class] ScaleDegreeMixinForChord extends the root pitch representation of the class DiatonicChord (HS.score.diatonicChord). Whereas the DiatonicChord root is expressed by a pitch class, ScaleDegreeMixinForChord additional represents the root as a scale degree. This mixin defines the two parameters rootDegree and rootAccidental. rootDegree denotes the degree of the root's pitch in the scale the chord is related to. rootAccidental denotes an accidental for rootDegree in that scale, encoded as described in the doc for DegreeToPC. The relation between pitchClass, scaleDegree and scaleAccidental is constrained. 
      %% ScaleDegreeMixinForChord is defined as a mixin to make it more easy to combine this mixin with other extensions to the class DiatonicChord. ScaleDegreeMixinForChord is designed to extend the class DiatonicChord, because this mixin depends on the mixin InScaleMixinForChord (HS.score.inScaleMixinForChord).      
      %% NB: the parameters rootDegree and rootAccidental are only constrained in their relation to the parameter root _after_ the related scale is known and fully determined.
      %% */      
      %% NB: ScaleDegreeMixinForChord is virtually the same as ScaleDegreeMixinForNote -- except that it is related to the parameter root (not pitchClass) and that it extends all its parameter names by a prefix 'root' to clarify the purpose of these parameters.
      class ScaleDegreeMixinForChord
	 feat !ScaleDegreeMixinForChordType:unit
	 attr rootDegree rootAccidental
	 meth initScaleDegreeMixinForChord(rootDegree:Degree<=_
					   rootAccidental:Accidental<=_) = M
	    @rootDegree = {New Score.parameter init(value:Degree
						    info:rootDegree)}
	    @rootAccidental = {New Score.parameter init(value:Accidental
							info:rootAccidental)}
	    {self bilinkParameters([@rootDegree @rootAccidental])}
	    %% implicit constrains
	    {InitConstrain self}
	 end
	 meth getRootDegree($)
	    {@rootDegree getValue($)}
	 end
	 meth getRootDegreeParameter($)
	    @rootDegree
	 end
	 meth getRootAccidental($)
	    {@rootAccidental getValue($)}
	 end
	 meth getRootAccidentalParameter($)
	    @rootAccidental
	 end
	 %%
% 	 meth getPitchClassMixinAttributes(?X)
% 	    X = [scaleDegree scaleAccidental] 
% 	 end
      end
   end
   fun {IsScaleDegreeMixinForChord X}
      {Score.isScoreObject X} andthen {HasFeature X ScaleDegreeMixinForChordType}
   end

   /** %% [class constructur] Expects a chord class and returns a subclass which inherits from this chord class and ScaleDegreeMixinForChord. 
   %% */
   fun {MakeScaleDegreeChordClass SuperClass} 
      class $ from  SuperClass ScaleDegreeMixinForChord
	 feat label:scaleDegreeChord
	 
	 meth init(...) = M
	    MixinFeats = [rootDegree rootAccidental]
	 in
	    SuperClass, {Record.subtractList M MixinFeats}
	    ScaleDegreeMixinForChord, {Adjoin
				       {GUtils.takeFeatures M  MixinFeats}
				       %% replace label
				       initScaleDegreeMixinForChord}
	 end
      
	 meth getInitInfo($ ...)	 
	    unit(superclass:SuperClass
		 args:[rootDegree#getRootDegree#{FD.decl}
		       rootAccidental#getRootAccidental#{DB.makeAccidentalFDInt}])
	 end
      end
   end

   /** %% [concrete class] ScaleDegreeChord is a chord related to a scale (see DiatonicChord) whose root is additionally expressed in terms of a scale degree with respect to that scale. See the doc of the superclasses DiatonicChord and ScaleDegreeMixinForChord for details.
   %% */
   ScaleDegreeChord = {MakeScaleDegreeChordClass DiatonicChord}

   
   local
      proc {InitConstrain Self}
	 thread
	    BDegree = {Self getBassChordDegree($)} = {DB.makeChordDegreeFDInt} 
	    BAccidental = {Self getBassChordAccidental($)} = {DB.makeAccidentalFDInt}
	    BassPC = {Self getBassPitchClass($)} = {DB.makePitchClassFDInt}
	    SDegree = {Self getSopranoChordDegree($)} = {DB.makeChordDegreeFDInt} 
	    SAccidental = {Self getSopranoChordAccidental($)} = {DB.makeAccidentalFDInt}
	    SopranoPC = {Self getSopranoPitchClass($)} = {DB.makePitchClassFDInt}
	    %% NB: blocks until chord pitch classes and root is determined
	    %% !!??
	    ChordPCs = {PcSetToSequence {Self getPitchClasses($)} {Self getRoot($)}}
	 in
	    {DegreeToPC ChordPCs BDegree#BAccidental BassPC}
	    {DegreeToPC ChordPCs SDegree#SAccidental SopranoPC}
	 end
      end
   in
      /** %% [abstract class] This mixin class extends a chord (sub-)class by information about the bass note (i.e., the chord inversion) and the soprano note (German: die Akkordlage). It defines the following additional parameters: bassChordDegree and sopranoChordDegree (together with bassChordAccidental and sopranoChordAccidental). These parameters represent the chord degree of the bass and the soprano. The chord degree is the position of the bass/soprano pitch class in the ordered list of chord pitch classes starting from the chord root. For example, the PC set of the A-major chord is {1, 4, 9}, and the root pitch class is 9 (PitchesPerOctave=12). The corresponding sorted pitch class sequence is thus [9 1 4]. If the bassChordDegree is set to 2, this means that the chord is a sixth-chord (if the chord is a triad), and the bass pitch class is 1 (the second element of the ordered pitch class sequence). Note that the sorted pitch class sequence always would start with the root. If the root is not contained in the chord pitch classes, then the sequence starts with the first pitch class which would follow the root.
      %% Often, only the bass is interesting, and the sopranoChordDegree is not used. Therefore, the sopranoChordDegree defaults to 1.
      %% The parameters bassChordAccidental and sopranoChordAccidental allow to specify chord note alterations in the soprano or bass. Note that these parameters default to the neutral accidental (i.e., {HS.score.absoluteToOffsetAccidental 0}).
      %% The parameters bassPitchClass and sopranoPitchClass represent the pitch classes which correspond to the bassChordDegree and sopranoChordDegree (together with bassChordAccidental and sopranoChordAccidental).
      %%
      %% NB: the propagation of the constraints on the parameter values of this mixin are delayed until the chord pitch classes and its root is determined! 
      %% */
      %%
      %%
      class InversionMixinForChord
	 feat !InversionMixinForChordType:unit
	 attr
	    bassChordDegree bassChordAccidental bassPitchClass
	    sopranoChordDegree sopranoChordAccidental sopranoPitchClass
	 meth initInversionMixinForChord(bassChordDegree:BDegree<=_
					 bassChordAccidental:BAccidental<={AbsoluteToOffsetAccidental 0}
					 bassPitchClass:BassPC<=_
					 sopranoChordDegree:SDegree<=1
					 sopranoChordAccidental:SAccidental<={AbsoluteToOffsetAccidental 0}
					 sopranoPitchClass:SopranoPC<=_) = M
	    @bassChordDegree = {New Score.parameter
				init(value:BDegree
				     info:bassChordDegree)}
	    @bassChordAccidental = {New Score.parameter
				    init(value:BAccidental
					 info:bassChordAccidental)}
	    @bassPitchClass = {New PitchClass
			       init(value:BassPC
				    info:bassPitchClass
				    'unit':{DB.getPitchUnit})}
	    @sopranoChordDegree = {New Score.parameter
				   init(value:SDegree
					info:sopranoChordDegree)}
	    @sopranoChordAccidental = {New Score.parameter
				       init(value:SAccidental
					    info:sopranoChordAccidental)}
	    @sopranoPitchClass = {New PitchClass
				  init(value:SopranoPC
				       info:sopranoPitchClass
				       'unit':{DB.getPitchUnit})}
	    {self bilinkParameters([@bassChordDegree @bassChordAccidental
				    @bassPitchClass
				    @sopranoChordDegree @sopranoChordAccidental
				    @sopranoPitchClass])}
	    %% implicit constrains
	    {InitConstrain self}
	 end

	 meth getBassChordDegree($)
	    {@bassChordDegree getValue($)}
	 end
	 meth getBassChordDegreeParameter($)
	    @bassChordDegree
	 end
	 meth getBassChordAccidental($)
	    {@bassChordAccidental getValue($)}
	 end
	 meth getBassChordAccidentalParameter($)
	    @bassChordAccidental
	 end
	 meth getBassPitchClass($)
	    {@bassPitchClass getValue($)}
	 end
	 meth getBassPitchClassParameter($)
	    @bassPitchClass
	 end
	 meth getSopranoChordDegree($)
	    {@sopranoChordDegree getValue($)}
	 end
	 meth getSopranoChordDegreeParameter($)
	    @sopranoChordDegree
	 end
	 meth getSopranoChordAccidental($)
	    {@sopranoChordAccidental getValue($)}
	 end
	 meth getSopranoChordAccidentalParameter($)
	    @sopranoChordAccidental
	 end
	 meth getSopranoPitchClass($)
	    {@sopranoPitchClass getValue($)}
	 end
	 meth getSopranoPitchClassParameter($)
	    @sopranoPitchClass
	 end
       
      end
   end
   fun {IsInversionMixinForChord X}
      {Score.isScoreObject X} andthen {HasFeature X InversionMixinForChordType}
   end
   
   /** %% Expects a chord class and returns a subclass which inherits from this chord class and InversionMixinForChord. 
   %% */
   fun {MakeInversionChordClass SuperClass}
      class $ from SuperClass InversionMixinForChord % DissonanceMixinForChord
	 feat label:inversionChord
       
	 meth init(...) = M
	    MixinFeats = [bassChordDegree bassChordAccidental bassPitchClass
			  sopranoChordDegree sopranoChordAccidental sopranoPitchClass]
	 in
	    SuperClass, {Record.subtractList M MixinFeats}
	    InversionMixinForChord, {Adjoin {GUtils.takeFeatures M  MixinFeats}
				     %% replace label
				     initInversionMixinForChord}
	 end
    
	 meth getInitInfo($ ...)	 
	    unit(superclass:SuperClass
		 args:[bassChordDegree#getBassChordDegree#{DB.makeChordDegreeFDInt}
		       bassChordAccidental#getBassChordAccidental#{AbsoluteToOffsetAccidental 0}
		       %% bass and soprano pitch classes are redundant if degree and accidental are given
		       % bassPitchClass#getBassPitchClass#{DB.makePitchClassFDInt}
		       sopranoChordDegree#getSopranoChordDegree#{DB.makeChordDegreeFDInt}
		       sopranoChordAccidental#getSopranoChordAccidental#{AbsoluteToOffsetAccidental 0}
		       % sopranoPitchClass#getSopranoPitchClass#{DB.makePitchClassFDInt}
		      ])
	 end
    
      end
   end
   /** %% Class inheriting from Chord and InversionMixinForChord
   %% */
   InversionChord = {MakeInversionChordClass Chord}
   /** %% Class inheriting from ScaleDegreeChord and InversionMixinForChord
   %% */
   FullChord = {MakeInversionChordClass ScaleDegreeChord}

   
   %% this mixin only adds single param, an 0/1-int -- use makeClass
   %% ScoreCore.oz instead in case you need to add a param.
   %% If I define some 'tools' which make use of this param, I may keep ChordStartMixin just as a mixin here, without defining subclasses
   %% 
   /** %% [abstract class] A mixin class to add the parameter isStartingWithChord to a Score.item subclass. The parameter allows to constrain whether or not self starts with a chord (e.g. to denote chord changes). The parameter value is an 0/1-integer.
   %%
   %% NB: This class does not apply any implicit constraints on the score. Please constrain explicitly using, e.g., MkChordsStartWithItems, MkChordsStartWithItems2, or StartChordWithMarker.
   %% */
   %% !!?? do I really need this? perhaps adding to note etc only optionally?
   %% !!?? rename 0/1-int attr 'chordStartMarker' to 'isChordStart'
   class ChordStartMixin
      attr isStartingWithChord		% a parameter, value is 0/1-int
      meth chordStartInit(isStartingWithChord:IsStartingWithChord<=_)
	 isStartingWithChord = {FD.int 0#1}
	 @isStartingWithChord = {New Score.parameter
				 init(value:IsStartingWithChord
				      info:isStartingWithChord
				      'unit':'0//1 int')}
	 {self bilinkParameters([@isStartingWithChord])}
      end
      meth isStartingWithChord(?X) X={@isStartingWithChord getValue($)} end
      meth getIsStartingWithChordParameter(?X) X=@isStartingWithChord end
      %% Different name to avoid clashes in class hierarchy if subclass does not define the method getAttributes
%      meth getChordStartMixinAttributes(?X) 
%	 X =[isStartingWithChord]
%      end
   end

%    %% Constraints the startTimes of all Chords ...   
%    ChordSeq which unifies the ChordSeq's chord startTimes with the startTimes of Items which match the deterministic test fun at arg test (default are all timed items except chords with isStartingWithChord=1). The number of items matching test must be equal the number of chords (othewise an exception is raised).
%    %% Collecting all items must return them sorted by startTime (which can be undetermined), e.g. collected items must not be in parallel voices (use MkChordsStartWithItems2 in that case).
%    %%
%    %% NB: constraint application suspends until all items matching test are found (e.g. until the parameter isStartingWithChord is determined).
%    %% 
%    proc {ChordsStartWithItems Chords Args}
%       Defaults = unit(test:fun {$ X}
% 			      {X isTimeMixin($)}
% 			      andthen {Not {IsChord X}}
% 			      andthen {X isStartingWithChord($)} == 1
% 			   end)
%       As = {Adjoin Defaults Args}
%    in
%       %% each chord starts with motif matching test
%       Items = {{ChordSeq getTopLevels($ test:isTemporalAspect)}.1
% 	       collect($ test:As.test)}
%    in
%       if {Length Items} \= {Length Chords}
%       then raise
% 	      'ItemsN != ChordsN'(MkChordsStartWithItems
% 				  motifs:Items
% 				  chords:Chords)
% 	   end
%       else 
% 	 for
% 	    Item in Items
% 	    Chord in Chords 
% 	 do
% 	    {Item getStartTime($)} =: {Chord getStartTime($)}
% 	 end
%       end
%    end

%    %% More general but less efficient variant of MkChordsStartWithItems (see that for doc). In MkChordsStartWithItems2, collected items don't need to be sorted by startTime.
%    %%
%    %% NB: constraint application suspends until all items matching test are found (e.g. until the parameter isStartingWithChord is determined).
%    %%
%    %% !! untested
%    %% 
%    fun {MkChordsStartWithItems2 Args}
%       Defaults = unit(test:fun {$ X}
% 			      {X isTimeMixin($)}
% 			      andthen {Not {IsChord X}}
% 			      andthen {X isStartingWithChord($)} == 1
% 			   end)
%       As = {Adjoin Defaults Args}
%    in
%       proc {$ ChordSeq}
% 	 %% each chord starts with motif matching test
% 	 Items = {{ChordSeq getTopLevels($ test:isTemporalAspect)}.1
% 		  collect($ test:As.test)}
% 	 Chords = {ChordSeq getItems($)}
%       in
% 	 if {Length Items} \= {Length Chords}
% 	 then
% 	    raise
% 	       'ItemsN != ChordsN'(MkChordsStartWithItems
% 				   motifs:Items
% 				   chords:Chords)
% 	    end
% 	 else
% 	    %% collect all startTimes of Items in FS, constrain each
% 	    %% Chord startTime to be in this set and all Chord
% 	    %% startTimes to be in ascending order.
% 	    ItemStartTimeFS = {FS.var.decl}
% 	    ItemStartTimes = {Map Items {GUtils.toFun getStartTime}}
% 	    ChordStartTimes = {Map Chords {GUtils.toFun getStartTime}}
% 	 in
% 	    %% !! problematic if some items have equal startTime (which
% 	    %% perhaps shouldn't happen as I don't want to start
% 	    %% multiple chord at the same time, but...)
% 	    {FS.card ItemStartTimeFS {Length ItemStartTimes}}
% 	    {ForAll ItemStartTimes proc {$ X} {FS.include X ItemStartTimeFS} end}
% 	    {ForAll ChordStartTimes proc {$ X} {FS.include X ItemStartTimeFS} end}
% 	    {Pattern.increasing ChordStartTimes}
% 	 end
%       end
%    end
 
   /** %% Constrains startTime of MyChord to equal the startTime of some single temporal item in Items for which isStartingWithChord=1.
   %%
   %% NB: StartChordWithMarker may apply a large number of propagators. 
   %% */
   proc {StartChordWithMarker MyChord Items}
      {FD.sum
       {Map Items proc {$ X B}
		     B = {FD.conj
			  {X isStartingWithChord($)}
			  ({MyChord getStartTime($)} =: {X getStartTime($)})}
		  end}
       '=:' 1}
   end

%    /** %% A Score.simultaneous with an additional parameter chordStartMarker which allows to constrain whether or not a next chord starts with the Simultaneous (e.g. to denote chord changes). See ChordStartMixin.
%    %% */
%    %% !! ?? isChordStart default OK?
%    class Simultaneous from Score.simultaneous ChordStartMixin
%       %feat label:sim		% !! tmp
%       meth init(chordStartMarker:ChordStartMarker<=0 ...) = M
% 	 Score.simultaneous, {Record.subtract M chordStartMarker}
% 	 ChordStartMixin, chordStartInit(chordStartMarker:ChordStartMarker)
%       end
%       meth getAttributes(?X)
% 	 X = {Append
% 	      Score.simultaneous, getAttributes($)
% 	      ChordStartMixin, getChordStartMixinAttributes($)}
%       end
%       %% meth toInitRecord(?X exclude:Excluded<=nil) ... end
%    end
%    /** %% A Score.sequential with an additional parameter chordStartMarker which allows to constrain whether or not a next chord starts with the Sequential (e.g. to denote chord changes). See ChordStartMixin.
%    %% */
%    class Sequential from Score.sequential ChordStartMixin
%       %feat label:seq
%       meth init(chordStartMarker:ChordStartMarker<=0 ...) = M
% 	 Score.sequential, {Record.subtract M chordStartMarker}
% 	 ChordStartMixin, chordStartInit(chordStartMarker:ChordStartMarker)
%       end
%       meth getAttributes(?X)
% 	 X = {Append
% 	      Score.sequential, getAttributes($)
% 	      ChordStartMixin, getChordStartMixinAttributes($)}
%       end
%       %% meth toInitRecord(?X exclude:Excluded<=nil) ... end
%    end


   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Def of extended note class etc 
%%%
   
   local
      /** %% Initialise domains of PitchClassMixin/Note pitch params and relate them.
      %% */
      proc {InitConstrainPitch X}
	 thread % don't block init if some information is still missing
	    %% init/restrict domains
	    {X getPitchClass($)} = {DB.makePitchClassFDInt}
	    {X getOctave($)} = {DB.makeOctaveFDInt}
	    {X getPitch($)} = {FD.decl}
	    %%
	    %% constrain: restricts pitch domain to (OctaveDomainMin * PitchesPerOctave) # (OctaveDomainMax * PitchesPerOctave + PitchesPerOctave-1) 
	    %%
	    {PitchClassToPitch {X getPitchClass($)}#{X getOctave($)} {X getPitch($)}}
	 end
      end
   in
      /** %% [abstract class] PitchClassMixin defines a complementary pitch representation to extend the standard Strasheela Note class (as defined in ScoreCore.oz). In the standard class, on the one hand, the pitch is represented by a single parameter whose meaning depends on the pitch unit (possible units are, e.g., 'frequency' or 'pitch'). The present mixin for the note class, on the other hand, defines two additional parameters to represent pitch in an alternative way: pitchClass and octave. The mixin also constrains the obvious relation between these three parameters (with the help of PitchClassToPitch, see there).
      %% As a consequence, the possible pitch units for the parameter pitch is more limited (e.g. 'frequency' is not valid anymore). However, arbitrary equidistant microtonal divisions of the octave are still possible. The pitches per octave are set globally (with DB.setPitchesPerOctave), and the pitch unit of all note parameters pitch and pitch class are set implicitly. This means that the term 'pitch class' has a broader meaning here than it has in dodecaphonic music analysis: only in case there are 12 pitches per octave the term 'pitch class' has Forte's meaning. 
      %% PitchClassMixin is defined as a mixin to the class Score.note to make it more easy to combine this mixin with other extensions to the note class. In Oz, multiple superclasses must not have a common class as their superclasses. Therefore, multiple note subclasses can not be directly combined, but multiple mixins for the note class can.. 
      %% */
      class PitchClassMixin
	 feat !PitchClassMixinType:unit
	 attr pitchClass octave 
	 meth initPitchClassMixin(octave:Oct<=_ pitchClass:PC<=_) = M
	    %{self getPitchUnit($)} = {GetPitchUnit}
	    {{self getPitchParameter($)} addInfo(notePitch)}
	    @octave = {New Score.parameter init(value:Oct info:octave)}
	    @pitchClass = {New PitchClass
			   init(value:PC info:pitchClass
				'unit':{DB.getPitchUnit})}
	    {self bilinkParameters([@octave @pitchClass])} 
	    %% implicit constrains
	    {InitConstrainPitch self}
	 end
	 meth getPitchClass(X)
	    X = {@pitchClass getValue($)}
	 end
	 meth getPitchClassParameter(X)
	    X= @pitchClass
	 end
	 meth getOctave(X)
	    X = {@octave getValue($)}
	 end
	 meth getOctaveParameter(X)
	    X = @octave
	 end
	 %%
%	 meth getPitchClassMixinAttributes(?X)
%	    X =[pitchClass octave] 
%	 end
      end
   end  
   fun {IsPitchClassMixin X}
      {Score.isScoreObject X} andthen {HasFeature X PitchClassMixinType}
   end


   
   local
      %% Simplified: (Generator1 * GeneratorFactor1 + ...) mod PitchesPerOctave = PitchClass
      %% With offset:
      %% (Generator1 * GeneratorFactor1 + ... - (Generator1*Offset + ...)) mod PitchesPerOctave = PitchClass
      proc {InitConstrain X}
%       thread % don't block init if some information is still missing
	 Offset = {X getGeneratorFactorsOffset($)}
	 Sum1 = {FD.decl}
	 Sum2 = {FD.decl}
      in
	 %% TODO: if generators should be FD ints
% 	 if {All {Record.toList {X getAllGenerators($)}} IsDet}
% 	 then Sum = {FD.sumC {X getAllGenerators($)} {X getAllGeneratorFactors($)} '=:'}
% 	 else
% 	 end
	 Sum1 = {FD.sumC {X getAllGenerators($)} {X getAllGeneratorFactors($)} '=:'}
	 %% subtract generators offsets
	 Sum2 =: (Sum1
		  - {LUtils.accum {Map {X getAllGenerators_list($)} fun {$ G} G*Offset end}
		     Number.'+'}
		  %% add 10 octaves to ensure pos number -- removed by mod
		  + {DB.getPitchesPerOctave}*10)
	 {X getPitchClass($)} = {FD.modI Sum2 {DB.getPitchesPerOctave}}
%       end
      end
   in
      %% TODO: 
      %% - doc
      %% - set generators in HS database, not for every note individuyally 
      %% - def constrain between regular temperament vars and PC in reusable extra proc above, which is then only called in InitConstrain
      /** %% [abstract class] RegularTemperamentMixinForNote defines a complementary pitch representation that represents note pitch classes in terms of 1 or more generators of a regular temperament and their corresponding factors.
      %%
      %% NOTE: arg generators is currently required arg and generators must be determined (ints in cent)
      %%
      %% */
      %%
      %%
      %%
      class RegularTemperamentMixinForNote
	 feat !RegularTemperamentForNoteType:unit
	 attr generators generatorFactors rank generatorFactorsOffset
	    %% args generators and generatorFactors expect list of FD ints with same length; generatorFactors optional
	 meth initRegularTemperamentMixinForNote(generators:Gs<={DB.getGenerators}
						 generatorFactors:Fs<={Map {DB.getGeneratorFactors}
								       fun {$ D} {FD.int D} end}
						 generatorFactorsOffset:Offset<={DB.getGeneratorFactorsOffset}) = M
	    Default = unit(generatorFactorsDomain_1: Offset-12#Offset+12
			   generatorFactorsDomain_others: Offset-2#Offset+2)
	 in
% 	    end
	    @rank = {Length Gs}  % number of generators
	    @generators = {MakeTuple unit @rank}
	    @generatorFactors = {MakeTuple unit @rank}
	    @generatorFactorsOffset = Offset
	    %% 
	    {List.forAllInd Gs
	     proc {$ I G}
		@generators.I = {New Score.parameter init(value:G info:generator#I)}
	     end}
	    {List.forAllInd if {IsDet Fs}
			    then Fs
			    else
			       {FD.int Default.generatorFactorsDomain_1}
			       | {Map {List.make @rank-1}
				  fun {$ _} {FD.int Default.generatorFactorsDomain_others} end}
			    end
	     proc {$ I Fac}
		@generatorFactors.I = {New Score.parameter init(value:Fac info:generatorFactor#I)}
	     end}
	    {self bilinkParameters({Append {Record.toList @generators}
				    {Record.toList @generatorFactors}})} 
	    %% implicit constrains
	    {InitConstrain self}
	 end
	 /** %% Returns the number of generators of the regular temperament (an int). Remember that the octave is always an implicit generator that is not counted.
	 %% */
	 meth getRank($)
	    @rank
	 end
	 meth getGeneratorFactorsOffset($)
	    @generatorFactorsOffset
	 end
	 /** %% Returns the Ith (int) generator of the regular temperament, measured in cent (FD int). Remember that the octave is always an implicit generator.
	 %% */
	 meth getGenerator($ I)
	    {@generators.I getValue($)}
	 end
	 meth getGeneratorParameter($ I)
	    @generators.I
	 end
	 /** %% Returns tuple of all generators (FD ints).
	 %% */
	 meth getAllGenerators($)
	    {Record.map @generators fun {$ G} {G getValue($)} end}
	 end
	 /** %% Returns list of all generators (FD ints).
	 %% */
	 meth getAllGenerators_list($)
	    {Record.toList {self getAllGenerators($)}}
	 end
	 meth getAllGeneratorParameters($)
	    @generators
	 end
	 /** %% Returns the factor (FD int) by which the Ith (int) generator of the regular temperament has been multiplied to obtain the pitch class of this note.
	 %% */
	 meth getGeneratorFactor($ I)
	    {@generatorFactors.I getValue($)}
	 end
	 meth getGeneratorFactorParameter($ I)
	    @generatorFactors.I 
	 end
	 /** %% Returns tuple of all generator factors (FD ints).
	 %% */
	 meth getAllGeneratorFactors($)
	    {Record.map @generatorFactors fun {$ G} {G getValue($)} end}
	 end
	 /** %% Returns list of all generator factors (FD ints).
	 %% */
	 meth getAllGeneratorFactors_list($)
	    {Record.toList {self getAllGeneratorFactors($)}}
	 end
	 meth getAllGeneratorFactorParameters($)
	    @generatorFactors
	 end
      end
   end  
   fun {IsRegularTemperamentMixinForNote X}
      {Score.isScoreObject X} andthen {HasFeature X RegularTemperamentForNoteType}
   end
      
   local
      /** %% Defines relation between Self (a note) and its related chord. 
      %% */
      %% !!?? InitConstraint for InChordMixinForNote and InScaleMixinForNote can generalisiert werden: Args record fuer accessor (getChords vs getScales), test (isRelatedChord / isRelatedScale), varAccessor (getInChordB / getInScaleB)
      proc {InitConstrain Self Args}
	 thread % {Self getChords($)} blocks until Chord candidates are accessible
	    fun {GetPCs X} {X getPitchClasses($)} end
	    Chords = {Self getChords($)}	
	    ChordPCFSs = {Map Chords GetPCs} % list of FS
	    RelatedChordBs
	    = {Self getRelatedChordBs($)}
	    = {Map Chords     % list of 0/1-int 
	       fun {$ Chord}
		  {Args.isRelatedChord Self Chord}
	       end}
	    NotePC = {Self getPitchClass($)} % FD int
	    InChordB = {Self getInChordB($)} = {FD.int 0#1} % 0/1-int
	    ExistingNoteB = {CTT.isExisting Self} % 0/1-int
	 in
	    %% constraints only applied unless Chords==nil (the default!)
	    if {Not (Chords==nil)}
	    then
	       %% note Self is related to exactly 1 chord
	       1 = {FD.sum RelatedChordBs '=:'}
	       %% InChordB=1, if for exactly one chord both
	       %% isRelatedChord is true AND NotePC is in PCs of chord
	       %% (and the note 'exists'). InChordB=0, if this
	       %% conjunction is never true. Besides, this conjunction
	       %% can not be true multiple times (as InChordB is a 0/1
	       %% int).
	       InChordB = {FD.sum {Map {LUtils.matTrans [ChordPCFSs RelatedChordBs]}
				   proc {$ [ChordPCFS RelatedChordB] B}
				      B = {FD.conj RelatedChordB
					   {FD.impl ExistingNoteB
					    %% !!?? is FS.reified.include OK? I
					    %% recall some problems..
					    {FS.reified.include NotePC ChordPCFS}}}
				   end}
			   '=:'}
	       %% in case of Chords==nil 
% 	    else
% 	       {Browse 'Warning: InChordMixinForNote instance without related chord.'}
% 	       {FD.impl ExistingNoteB
% 		(InChordB =: 0)	% !!?? OK
% 		1}
	    end
	 end
      end
   in
      /** %% [abstract class] Mixin class for a note class with pitchClass parameter. Allows to conveniently define relations between self (i.e. a note) and a chord. The parameter inChordB (value is a 0/1 int) states whether the pitch class (a FD int) of self is included in the pitch classes (a FS) of the chord to which self is related.
      %% By default, the related chord is the simultaneous chord object (if there are multiple simultaneous chord objects, then the first found is taken). 
      %% This default behaviour can be overwritten with the arguments getChords and isRelatedChord. Both arguments expect a procedure. getChords expects a unary function which expects self and returns a list of chord candidates to which self may be related (e.g. all chords in the piece). However, self is related to exactly one chord. Therefore, if the function at getChords returns a list with exactly one chord, then the related chord is determined. For example, in case the rhythmic structure of the music is determined in the CSP, the function at getChords may return the chord simultaneous with self: <code> proc {$ Self} [{Self findSimultaneousItem($ test:HS.score.isChord)}] end </code>. In any case, the user should aim to keep the number of related chord candidates low to minimise propagators.
      %% In case of multiple related chord candidates (i.e. the related chord is not determined in the CSP definition, e.g., because the rhythmic structure of the music is undetermined in the problem definition), the procedure at isRelatedChord defines which of the candidates the actual related chord is. This ternary procedure expects self, a chord, and an 0/1-int (the 0/1-int is declared within the proc). For the related chord, the 0/1-int is 1 (and 0 otherwise). For example, to relate self to its simultaneous chord this proc may be defined <code> proc {$ Self Chord B} {Self isSimultaneousItemR(B Chord)} end </code>.  However, as mentioned before only exactly one chord may be related to self (this is an implicit constraint in the class def -- intendent to enhance propagation -- which causes the search to fail otherwise).
      %% In case a single note shall optionally be related to multiple chords (e.g. to express a suspension) consider to represent this single note with multiple note objects. The representation of the note may even explicitly represent tied notes: an additional 0/1-int parameter could state whether a note is tied, e.g., to its predecessor with the implied constraint that their pitches equal.
      %% Additional constraints may be enforced on self dependent on the value of the parameter inChordB, see the method nonChordNoteConditions for details.
      %% NB: To simplify the definition of CSPs involving 'non-existing' notes (i.e. notes of duration 0, see contribution CTT), the value of inChordB is irrelevant for the pitch class of 'non-existing' notes. 
      %% NB: isRelatedChord defaults to <code> proc {$ Self Chord B} B=1 end </code>, which is suitable in case the related chord is already determined in the CSP definition (i.e. getChords returns 1 chord). However, in case the related chord is _not_ determined in the CSP definition (i.e. getChords returns multiple chord candidates) then isRelatedChord must be specified (i.e. the default is unsuitable for multiple chords).
      %% NB: In case the related chord is _not_ determined in the CSP definition (i.e. getChords returns multiple chord candidates), this relation should be determined as early as possible to support propagation. That is, the 0/1 ints returned by isRelatedChord for each chord candidate returned by getChords should be determined as early as possibel. However, these 0/1 ints can not be distributed (they are no parameters). Instead, the respective constraint defined by isRelatedChord should be 'determined' otherwise. E.g., in case isRelatedChord is defined as <code> proc {$ Self Chord B} {Self isSimultaneousItemR(B Chord)} end </code> then determining the timing structure should be 'preferred' by the distribution strategy.
      %% NB: the procedures given as init arguments are lost when the score is transformed to a literal/textual representation (and thus their implicit constraints).
      %% */
      %%
      %% !!?? inChordB as parameter or just attribute: no explicite unit of measurement needed (always 0/1-int). Thus: Is inChordB required as parameter to define some distribution strategy? 
      class InChordMixinForNote
	 feat !InChordMixinForNoteType:unit
	 attr inChordB % nonChordPCConditions:nil
	    chords  % list of chord candidate objects
	    relatedChordBs % list of 0/1-ints matching chord candidate objects
	    % !!?? args and their default go directly into method 'header' record (=M)
	    getChords		% init proc
	    isRelatedChord	% init proc
	 meth initInChordMixinForNote(...) = M
	    Defaults = unit(inChordB:_
			    getChords:fun {$ Self}
					 MyChord = {Self findSimultaneousItem($ test:IsChord)}
				      in
					 if MyChord == nil then nil
					 else [MyChord]
					 end
				      end 
			    %% ?? B=1 OK? (more often needed then just skip)
			    isRelatedChord:proc {$ Self Chord B} B=1 end)
	    Args = {Adjoin Defaults M}
	 in
	    @inChordB = {New Score.parameter init(value:Args.inChordB info:inChordB
						  'unit':'0//1 int')}
	    {self bilinkParameters([@inChordB])}
	    thread 
	       %% NB: depending on its definition getChords may block, e.g., until temporal structure of score is fully determined
	       @chords = {Args.getChords self} 
	       {InitConstrain self Args}
	    end
	    @getChords = Args.getChords
	    @isRelatedChord = Args.isRelatedChord
	 end
	 /** %% Returns an 0/1-int which states whether or not the pitch class of self is included in the pitch classes of its related chord. This definition is an alias for getInChordB.
	 %% */
	 meth isInChord(?B) B = {self getInChordB($)} end
	 meth getInChordB(?X)
	    X = {@inChordB getValue($)}
	 end
	 meth getInChordBParameter(?X)
	    X = @inChordB
	 end
	 /** %% Returns the list of candidate chord objects, i.e. the value returned by the proc set via the getChords init argument. 
	 %% */ 
	 meth getChords(?X)
	    X = @chords
	 end
	 
	 /** %% Returns a list of 0/1-integers returned by {Map {<getChords>} <isRelatedChord>}. <getChords> and <isRelatedChord> are the functions given to initInChordMixinForNote.
	 %% */
	 meth getRelatedChordBs(?X)
	    X = @relatedChordBs
	 end


	 /** %% Defines and applies a 'meta-rule' which conveniently defines a number of conditions which effect self dependent on the value of {self isInChord($)}. Conditions is a list of binary procs expecting self and an 0/1-int (declared within the proc). These conditions form alternative constraints on self. A typical condition example would be a boolean constraint whether self is a passing note, another whether self is a suspension.
	 %% If none of the given conditions is true, then self must be 'in' the chord (i.e. 1={self isInChord($)}). Similarily, if self is not in the chord, at least one of the conditions must be true. However, the opposite is not necessarily true: if one or more conditions are the case then self may or may not be in the chord and also if self is in the chord then one or more conditions still may or may not be true.
	 %% For instance, this meta-rule never constraints a note to necessarily be a non-chord note. You may however easily do this, e.g, by constraining {self isInChord($)}=0 directly -- which would have the consequence that one of Conditions must be true. 
	 %% */
	 %% !!?? conditions get only the note as arg: OK to define, e.g., IsPassingNote. But are there constraints I need more information for??
	 meth nonChordPCConditions(Conditions)
	    Bs = {Map Conditions proc {$ Cond B} B = {Cond self} end}
	    SumBs = {FD.decl}
	 in
	    SumBs = {FD.sum Bs '=:'}
	    %% if isInChord=0, then (SumBs>0)=1
	    %% if isInChord=1 -- no consequences
	    %% if SumBs=0 then isInChord=1
	    %% if SumBs=1 -- no consequences
	    %%
	    %% !!?? more efficient propagator possible?
	    {FD.impl ({self isInChord($)} =: 0) (SumBs >: 0) 
	     1}
	    {FD.impl (SumBs =: 0) ({self isInChord($)} =: 1)
	     1}
	    %% ??
%	    {FD.equi ({self isInChord($)} =: 1) (SumBs =: 0)
%	     1}
	 end
      
%	 meth getInChordMixinForNoteAttributes(?X)
%	    X =[inChordB] 
%	 end
      end
   end
   fun {IsInChordMixinForNote X}
      {Score.isScoreObject X} andthen {HasFeature X InChordMixinForNoteType}
   end
   
   %% !! definition mirrors chord relation above as scale relation -- much code repetition with different arg etc names.
   local
      proc {InitConstrain Self Args}
	 thread % {Self getScales($)} blocks until Scale candidates are accessible
	    fun {GetPCs X} {X getPitchClasses($)} end
	    Scales = {Self getScales($)}
	    ScalePCFSs = {Map Scales GetPCs} % list of FS
	    RelatedScaleBs	% list of 0/1-int 
	    = {Self getRelatedScaleBs($)}
	    = {Map Scales     
	       fun {$ Scale} {Args.isRelatedScale Self Scale} end}
	    NotePC = {Self getPitchClass($)} % FD int 
	    InScaleB = {Self getInScaleB($)} = {FD.int 0#1} % 0/1-int
	    ExistingNoteB = {CTT.isExisting Self} % 0/1-int
	 in
	    %% constraints only applied unless Scales==nil (the default!)
	    if {Not (Scales==nil)}
	       %% see comment for constraints for chord in InChordMixinForNote InitConstrain
	    then 1 = {FD.sum RelatedScaleBs '=:'}
	       InScaleB = {FD.sum {Map {LUtils.matTrans [ScalePCFSs RelatedScaleBs]}
				   proc {$ [ScalePCFS RelatedScaleB] B}
				      B = {FD.conj RelatedScaleB
					   {FD.impl ExistingNoteB
					    {FS.reified.include NotePC ScalePCFS}}}
				   end}
			   '=:'}
	       %% in case of Scales==nil 
% 	    else 
% 	       {Browse 'Warning: InScaleMixinForNote instance without related scale.'}
% 	       {FD.impl ExistingNoteB
% 		(InScaleB =: 0)	% !!?? OK
% 		1}
	    end
	 end
      end
   in
      /** %% [abstract class] Mixin class for a note class with pitchClass parameter. Allows to conveniently define relations between self (i.e. a note) and a scale. This mixin defines for a related scale what InChordMixinForNote defines for a related chord -- see doc there for details.
      %% */
      %% !! definition mirrors InChordMixinForNote as scale relation -- much code repetition with different arg etc names. 
      class InScaleMixinForNote
	 feat !InScaleMixinForNoteType:unit
	 attr inScaleB
	    scales % list of scale candidate objects
	    relatedScaleBs % list of 0/1-ints matching scale candidate objects
	    getScales     % init proc
	    isRelatedScale % init proc
	 meth initInScaleMixinForNote(...) = M
	    Defaults = unit(inScaleB:_
			    getScales: fun {$ Self}
					 MyScale = {Self findSimultaneousItem($ test:IsScale)}
				      in
					 if MyScale == nil then nil
					 else [MyScale]
					 end
				      end 
			    %% ?? B=1 OK? (more often needed then just skip)
			    isRelatedScale:proc {$ Self Scale B} B=1 end)
	    Args = {Adjoin Defaults M}
	 in
	    @inScaleB = {New Score.parameter init(value:Args.inScaleB
						  info:inScaleB
						  'unit':'0//1 int')}
	    {self bilinkParameters([@inScaleB])}
	    thread 
	       %% NB: depending on its definition getScales may block, e.g., until temporal structure of score is fully determined
	       @scales = {Args.getScales self} 
	       {InitConstrain self Args}
	    end
	    @getScales = Args.getScales
	    @isRelatedScale = Args.isRelatedScale
	 end
	 /** %% see doc isInChord
	 %% */
	 meth isInScale(?B) B = {self getInScaleB($)} end
	 meth getInScaleB(?X)
	    X = {@inScaleB getValue($)}
	 end
	 meth getInScaleBParameter(?X)
	    X = @inScaleB
	 end
	 /** %% Returns the list of candidate scale objects, i.e. the value returned by the proc set via the getScale init argument. 
	 %% */ 
	 meth getScales(?X)
	    X = @scales
	 end

	 /** %% Returns a list of 0/1-integers returned by {Map {<getScales>} <isRelatedScale>}. <getScales> and <isRelatedScale> are the functions given to initInScaleMixinForNote.
	 %% */
	 meth getRelatedScaleBs(?X)
	    X = @relatedScaleBs
	 end

	 /** %% see doc nonChordPCConditions
	 %% */
	 meth nonScalePCConditions(Conditions)
	    Bs = {Map Conditions proc {$ Cond B} B = {Cond self} end}
	    SumBs = {FD.decl}
	 in
	    SumBs = {FD.sum Bs '=:'}
	    %% if isInScale=0, then (SumBs>0)=1
	    %% if isInScale=1 -- no consequences
	    %% if SumBs=0 then isInScale=1
	    %% if SumBs=1 -- no consequences
	    {FD.impl ({self isInScale($)} =: 0) (SumBs >: 0) 
	     1}
	    {FD.impl (SumBs =: 0) ({self isInScale($)} =: 1)
	     1}
	 end
      
%	 meth getInScaleMixinForNoteAttributes(?X)
%	    X =[inScaleB] 
%	 end
      end	 
   end
   fun {IsInScaleMixinForNote X}
      {Score.isScoreObject X} andthen {HasFeature X InScaleMixinForNoteType}
   end

   
   local
      /** %% Initialise domains of params and relate them.
      %% */
      proc {InitConstrainPitch Self}
	 thread % don't block init if some information is still missing
	    ExistingNoteB = {CTT.isExisting Self} % 0/1-int
	 in
% 	 %% init/restrict domains
	    {Self getCMajorDegree($)} = {FD.int 1#7}
	    {Self getCMajorAccidental($)} = {DB.makeAccidentalFDInt}
	    %% setting it here makes it impossible to overwrite setting with init arg
%	 {Self getCMajorAccidental($)} = {FD.int {HS.score.absoluteToOffsetAccidental ~1}#{HS.score.absoluteToOffsetAccidental 1}}
	    %%
	    {FD.impl ExistingNoteB
	     {Combinator.'reify'
	      proc {$}
		 {CMajorDegreeToPC
		  {Self getCMajorDegree($)}#{Self getCMajorAccidental($)}
		  {Self getPitchClass($)}}
	      end}
	     1}
	 end
      end
   in
      /** %% [abstract class] EnharmonicSpellingMixinForNote extends the class Note2 (HS.score.note2) by support for (numerically represented!) enharmonic spelling. This mixin defines the two parameters cMajorDegree and cMajorAccidental. cMajorDegree denotes the degree of the note's pitch in C major, which also indicates its note name (i.e. c=0, d=1, ..., b=7). cMajorAccidental denotes an accidental for cMajorDegree in C major, encoded as described in the doc for DegreeToPC. The relation between pitchClass, cMajorDegree and cMajorAccidental is constrained. 
      %% NB: This Mixin is defined as an extension for the class Note2: EnharmonicSpellingMixin relies on the parameter pitchClass as defined in Note2. Nevertheless, EnharmonicSpellingMixinForNote is defined as a mixin to make it more easy to combine this mixin with other extensions to the note class.
      %% NB: cMajorAccidental defaults to {DB.makeAccidentalFDInt} -- which leaves cMajorDegree at its full domain even if the note pitch is determined (at least for an AccidentalOffset >= 2). Even reducing the domain of cMajorAccidental to correspond to {b , natural, #} still does not determine cMajorDegree, but usually leaves two domain values.
      %% ??!! shall I reduce the domain of the cMajorAccidental default to {HS.score.absoluteToOffsetAccidental ~1}#{HS.score.absoluteToOffsetAccidental 1}
      %%
      %% NOTE: Problem: This class presently uses the constraint CMajorDegreeToPC to defined enharmonic spelling. This poses no problem for PitchesPerOctave=12, but can result in undesired enharmonic spelling for microtonal music. In CMajorDegreeToPC, the "white piano keys" are (approximations of) the justly tuned C-Major scale (as in the notation of Ben Johnston). An alternative enharmonic spelling tunes the "white keys" (and beyond) as approximations of the sequence of fifth (e.g. 72 EDO). Again an alternative is a tuning "mixing" fifths and thirds in the definition of the "white keys" and beyond (as meantone tunings). Besides, all the approaches sketched above are simplications: all pitches with accidentals are understood as deviations some "white key" (e.g., e-flat is a "diminished" e-natural).
      %% Shall I make the constraint used to derived the enharmonic spelling user-controllable? I should then also change the parameter names.. Or I just defined an alternative mixin instead :)
      %% */
      %%
      %% NB: The classes EnharmonicSpellingMixin and ScaleDegreeMixin are virtually idential, only the scale to which the degree/accidental relates is different. Nevertheless, two independent mixins are required, because I want to have a note class inheriting from both mixins, and I need different names for the parameters etc.  
      class EnharmonicSpellingMixinForNote
	 feat !EnharmonicSpellingMixinForNoteType:unit
	 attr cMajorDegree cMajorAccidental
	 meth initEnharmonicSpellingMixinForNote(cMajorDegree:Degree<=_
						 cMajorAccidental:Accidental<=_) = M
	    @cMajorDegree = {New Score.parameter init(value:Degree
						      info:cMajorDegree)}
	    @cMajorAccidental = {New Score.parameter init(value:Accidental
							  info:cMajorAccidental)}
	    {self bilinkParameters([@cMajorDegree @cMajorAccidental])}
	    %% implicit constrains
	    {InitConstrainPitch self}
	 end
	 meth getCMajorDegree(X)
	    X = {@cMajorDegree getValue($)}
	 end
	 meth getCMajorDegreeParameter(X)
	    X = @cMajorDegree
	 end
	 meth getCMajorAccidental(X)
	    X = {@cMajorAccidental getValue($)}
	 end
	 meth getCMajorAccidentalParameter(X)
	    X = @cMajorAccidental
	 end
	 %%
% 	 meth getPitchClassMixinAttributes(?X)
% 	    X = [cMajorDegree cMajorAccidental] 
% 	 end
      end
   end
   fun {IsEnharmonicSpellingMixinForNote X}
      {Score.isScoreObject X} andthen {HasFeature X EnharmonicSpellingMixinForNoteType}
   end

   local
      /** %% Initialise domains of params and relate them.
      %% */
      proc {InitConstrain Self}
	 thread % {Self getScales($)} blocks until Scale candidates are accessible
% 	 %% init/restrict domains
	    Degree = {Self getScaleDegree($)} = {DB.makeScaleDegreeFDInt}
	    Accidental = {Self getScaleAccidental($)} = {DB.makeAccidentalFDInt}
	    PC = {Self getPitchClass($)}
	    ExistingNoteB = {CTT.isExisting Self} % 0/1-int
	    %%
	    Scales = {Self getScales($)}
	    %% list of 0/1-ints
	    RelatedScaleBs = {Self getRelatedScaleBs($)}
	    %% list of FS
	    ScalePCFSs = {Map Scales fun {$ X} {X getPitchClasses($)} end} 
	    %% list of FD
	    ScaleRoots = {Map Scales fun {$ X} {X getRoot($)} end} 	 
	 in
	    %% if the note's pitch classes is in scale, then the scale-related accidental must be neutral neutral -- and the other way round
	    {FD.equi ({Self getInScaleB($)} =: 1)
	     (Accidental =: {AbsoluteToOffsetAccidental 0})
	     1}
	    {ForAll {LUtils.matTrans [ScalePCFSs ScaleRoots RelatedScaleBs]}
	     proc {$ [ScalePCFS ScaleRoot RelatedScaleB]}
		%% apply constraint for related scale (there is always only
		%% one), if note "exists"
		{FD.impl {FD.conj ExistingNoteB RelatedScaleB}
		 {Combinator.'reify'
		  proc {$}
		     %% NB: blocks until ScalePCFS and ScaleRoot are determined
		     CollectionPCs = {PcSetToSequence ScalePCFS ScaleRoot}
		  in
		     {DegreeToPC CollectionPCs Degree#Accidental PC}
		  end}
		 1}
	     end}
	 end
      end
   in
      /** %% [abstract class] ScaleDegreeMixinForNote extends the pitch representation of the class Note (HS.score.note). Whereas Note provides a pitch class representation, ScaleDegreeMixinForNote extends this Note class by support for scale degrees. This mixin defines the two parameters scaleDegree and scaleAccidental. scaleDegree denotes the degree of the note's pitch in the scale the note is related to. scaleAccidental denotes an accidental for scaleDegree in that scale, encoded as described in the doc for DegreeToPC. The relation between pitchClass, scaleDegree and scaleAccidental is constrained. 
      %% ScaleDegreeMixinForNote is defined as a mixin to make it more easy to combine this mixin with other extensions to the class Note. ScaleDegreeMixinForNote is designed to extend the class Note, because this mixin depends on the note mixin InScaleMixinForNote (HS.score.inScaleMixinForNote).
      %% NB: Scale accidentals can be large: in case of non-diatonic tones (InScaleB=0), the neares diatonic tones can be several semitones away (or whatever the setting of PitchesPerOctave is). Therefore, set AccidentalOffset sufficiently high. 
      %% NB: the parameters scaleDegree and scaleAccidental are only constrained in their relation to the parameter pitchClass _after_ the related scale is known and fully determined.
      %% */      
      %% NB: The classes EnharmonicSpellingMixinForNote and ScaleDegreeMixin are very similar, only the scale to which the degree/accidental relates is different (in EnharmonicSpellingMixinForNote the related scale is always known -- in contrast to this mixin). Nevertheless, two independent mixins are required, because I want to have a note class optionally inheriting from both mixins, and I need different names for the parameters etc.  
      class ScaleDegreeMixinForNote
	 feat !ScaleDegreeMixinForNoteType:unit
	 attr scaleDegree scaleAccidental
	 meth initScaleDegreeMixinForNote(scaleDegree:Degree<=_
					  scaleAccidental:Accidental<=_) = M
	    @scaleDegree = {New Score.parameter init(value:Degree
						     info:scaleDegree)}
	    @scaleAccidental = {New Score.parameter init(value:Accidental
							 info:scaleAccidental)}
	    {self bilinkParameters([@scaleDegree @scaleAccidental])}
	    %% implicit constrains
	    {InitConstrain self}
	 end
	 meth getScaleDegree($)
	    {@scaleDegree getValue($)}
	 end
	 meth getScaleDegreeParameter($)
	    @scaleDegree
	 end
	 meth getScaleAccidental($)
	    {@scaleAccidental getValue($)}
	 end
	 meth getScaleAccidentalParameter($)
	    @scaleAccidental
	 end
	 %%
% 	 meth getPitchClassMixinAttributes(?X)
% 	    X = [scaleDegree scaleAccidental] 
% 	 end
      end
   end
   fun {IsScaleDegreeMixinForNote X}
      {Score.isScoreObject X} andthen {HasFeature X ScaleDegreeMixinForNoteType}
   end


   
   local
      /** %% Initialise domains of params and relate them.
      %% */
      proc {InitConstrain Self}
	 thread % {Self getChords($)} blocks until Chord candidates are accessible
% 	 %% init/restrict domains
	    Degree = {Self getChordDegree($)} = {DB.makeChordDegreeFDInt}
	    Accidental = {Self getChordAccidental($)} = {DB.makeAccidentalFDInt}
	    PC = {Self getPitchClass($)}
	    ExistingNoteB = {CTT.isExisting Self} % 0/1-int
	    %%
	    Chords = {Self getChords($)}
	    %% list of 0/1-ints
	    RelatedChordBs = {Self getRelatedChordBs($)}
	    %% list of FS
	    ChordPCFSs = {Map Chords fun {$ X} {X getPitchClasses($)} end} 
	    %% list of FD
	    ChordRoots = {Map Chords fun {$ X} {X getRoot($)} end} 	 
	 in
	    %% if the note's pitch classes is in chord, then the chord-related accidental must be neutral neutral -- and the other way round
	    {FD.equi ({Self getInChordB($)} =: 1)
	     (Accidental =: {AbsoluteToOffsetAccidental 0})
	     1}
	    {ForAll {LUtils.matTrans [ChordPCFSs ChordRoots RelatedChordBs]}
	     proc {$ [ChordPCFS ChordRoot RelatedChordB]}
		%% apply constraint for related scale (there is always only
		%% one), if note "exists"
		{FD.impl {FD.conj ExistingNoteB RelatedChordB}
		 {Combinator.'reify'
		  proc {$}
		     %% NB: blocks until ChordPCFS and ChordRoot are determined
		     CollectionPCs = {PcSetToSequence ChordPCFS ChordRoot}
		  in
		     {DegreeToPC CollectionPCs Degree#Accidental PC}
		  end}
		 1}
	     end}
	 end
      end
   in
      /** %% [abstract class] ChordDegreeMixinForNote corresponds to ScaleDegreeMixinForNote, but constrains the relation of the note with respect to a related chord instead of a scale. All parameter names etc. are idential, only 'scale' is always replaced by 'chord'. See ScaleDegreeMixinForNote for details.
      %% NB: Chord accidentals can be large (even larger than scale accidentals): in case of non-chord tones (InChordB=0), the neares chord tones can be many semitones away (or whatever the setting of PitchesPerOctave is). Therefore, set AccidentalOffset sufficiently high. 
      %% NB: Like ScaleDegreeMixinForNote, the constrains posted by ChordDegreeMixinForNote are only effective after the related chord is known and determined. 
      %% */
      class ChordDegreeMixinForNote
	 feat !ChordDegreeMixinForNoteType:unit
	 attr chordDegree chordAccidental
	 meth initChordDegreeMixinForNote(chordDegree:Degree<=_
					  chordAccidental:Accidental<=_) = M
	    @chordDegree = {New Score.parameter init(value:Degree
						     info:chordDegree)}
	    @chordAccidental = {New Score.parameter init(value:Accidental
							 info:chordAccidental)}
	    {self bilinkParameters([@chordDegree @chordAccidental])}
	    %% implicit constrains
	    {InitConstrain self}
	 end
	 meth getChordDegree($)
	    {@chordDegree getValue($)}
	 end
	 meth getChordDegreeParameter($)
	    @chordDegree
	 end
	 meth getChordAccidental($)
	    {@chordAccidental getValue($)}
	 end
	 meth getChordAccidentalParameter($)
	    @chordAccidental
	 end
	 %%
% 	 meth getPitchClassMixinAttributes(?X)
% 	    X = [chordDegree chordAccidental] 
% 	 end
      end
   end      
   fun {IsChordDegreeMixinForNote X}
      {Score.isScoreObject X} andthen {HasFeature X ChordDegreeMixinForNoteType}
   end


   /** %% [concrete class] Note2 extends the Strasheela core class Score.note by the parameters pitchClass and octave. In addition, Note2 constrains the relation between the three pitch parameters pitch, pitchClass, and octave. The pitchUnit for Note2 instances are set implicitly and depend on the pitches per octave set by DB.setPitchesPerOctave. 
   %% For further details, see the doc for PitchClassMixin.
   %% */ 
   %% !!?? why are octave and pitchClass (as well as inChord and inScale) params -- I don't need them for distribution and chord root (e.g.) is therefore no param either. Do I need additional param attr such as unit of measurement for these attr?
   %%
   %% !!?? inherit from Score.note2 or Score.note (ie with or without param amp)
   class Note2 from Score.note PitchClassMixin % ChordStartMixin
      meth init(octave:Oct<=_ pitchClass:PC<=_
		   % chordStartMarker:ChordStartMarker<=0
		...) = M 
	 Score.note, {Adjoin {Record.subtractList M
			      [octave pitchClass]} % chordStartMarker 
		      init(pitchUnit:{DB.getPitchUnit})}
	 PitchClassMixin, initPitchClassMixin(octave:Oct pitchClass:PC) 
	    % ChordStartMixin, chordStartInit(chordStartMarker:ChordStartMarker)
      end
%       meth getAttributes(?X)
% 	 X = {LUtils.accum
% 	      [Score.note, getAttributes($)
% 	       PitchClassMixin, getPitchClassMixinAttributes($)
% 		  %ChordStartMixin, getChordStartMixinAttributes($)
% 	      ]
% 	      Append}
%       end
%       meth toInitRecord(?X exclude:Excluded<=nil)
% 	 X = {Adjoin
% 	      Score.note, toInitRecord($ exclude:Excluded)
% 	      {Record.subtractList
% 	       {self makeInitRecord($ [pitchClass#getPitchClass#noMatch
% 				       octave#getOctave#noMatch
% 					  %chordStartMarker#getChordStartMarker#0
% 				      ])}
% 	       Excluded}}
%       end
      meth getInitInfo($ ...)	 
	 unit(superclass:Score.note
	      args:[pitchClass#getPitchClass#{DB.makePitchClassFDInt}
		    octave#getOctave#{DB.makeOctaveFDInt}
		    %%chordStartMarker#getChordStartMarker#0
		   ])
      end

      /** %% Expects a note object MyNote and returns the interval between self and MyNote. If the self is higher than MyNote, then the intervals direction is downwards (i.e. 0). Additional interval features can be specified with the optional argument dbFeatures (default nil).
      %% */
      meth noteInterval($ MyNote dbFeatures:DBFeats<=nil)	 
	 MyInterval = {New Interval init(dbFeatures:DBFeats)}
      in
	 {Score.initScore MyInterval} % close parameter etc. extendable lists
	 {TransposeNote self MyInterval MyNote}
	 MyInterval
      end
   end


   /** %% [concrete class] Note is an extension of the class Score.note defined by the Strasheela core. Whereas Score.note is style-neutral, Note is designed for harmonic CSPs.
   %% All extensions of Score.note are defined by the three mixins PitchClassMixin, InChordMixinForNote and InScaleMixinForNote: see the documentation of these classes for further details. 
   %% */
   %% 
   class Note from Note2 InChordMixinForNote InScaleMixinForNote
		 /** %% optional Arguments:
		 %% arguments of Score.note: duration (FD int), endTime (FD int), offsetTime (FD int), startTime (FD int), pitch (FD int), amplitude (FD int) amplitudeUnit (atom), ... 
		 %% Please note that pitchUnit is not supported (it is set implicitly by the pitches per octave setting).
		 %% Note supports the following additional arguments: 
		 %% octave (FD int), pitchClass (FD int), 
		 inChordB (0/1 int), getChords (proc {$ Self Chords} ... end), isRelatedChord (proc {$ Self Chord B} ... end), inScaleB (0/1 int), getScales (proc {$ Self Scales} ... end), isRelatedScale (proc {$ Self Chord B} ... end)
		 %% */
      meth init(...) = M
	 InChordMixinFeats = [inChordB getChords isRelatedChord]
	 InScaleMixinFeats = [inScaleB getScales isRelatedScale]
      in
	 Note2, {Record.subtractList M {Append InChordMixinFeats InScaleMixinFeats}}
	 InChordMixinForNote, {Adjoin {GUtils.takeFeatures M InChordMixinFeats}
			       %% replace label
			       initInChordMixinForNote}
	 InScaleMixinForNote, {Adjoin {GUtils.takeFeatures M InScaleMixinFeats}
			       initInScaleMixinForNote}
      end
	 
%       meth getAttributes(?X)
% 	 X = {LUtils.accum
% 	      [Note2, getAttributes($)
% 	       InChordMixinForNote, getInChordMixinForNoteAttributes($)
% 	       InScaleMixinForNote, getInScaleMixinForNoteAttributes($)]
% 	      Append}
%       end
      /** %%
      %% NB: the procedures given as init arguments to InChordMixinForNote and InScaleMixinForNote  are lost when the score is transformed to a literal/textual representation (and thus their implicit constraints).
      %% */
%       meth toInitRecord(?X exclude:Excluded<=nil)
% 	 X = {Adjoin
% 	      Score.note, toInitRecord($ exclude:Excluded)
% 	      {Record.subtractList
% 	       {self makeInitRecord($ [pitchClass#getPitchClass#noMatch
% 				       octave#getOctave#noMatch
% 				       inChordB#getInChordB#noMatch
% 				       inScaleB#getInScaleB#noMatch
% 				      ])}
% 	       Excluded}}
%       end
      
      meth getInitInfo($ ...)	 
	 unit(superclass:Note2
	      args:[inChordB#getInChordB#{FD.int 0#1}
		    inScaleB#getInScaleB#{FD.int 0#1}
		    %% init args which get procs are excluded my default
		    getChords#fun {$ _} @getChords end#noMatch
		    isRelatedChord#fun {$ _} @isRelatedChord end#noMatch
		    getScales#fun {$ _} @getScales end#noMatch
		    isRelatedScale#fun {$ _} @isRelatedScale end#noMatch
		   ])
      end
   end


   %% TODO: doc
   /** %% [concrete class]
   %% */
   %% 
   class RegularTemperamentNote from Note RegularTemperamentMixinForNote
				   /** %% Arguments
				   %% see comment in Note, additionally
				   %% required arg: generators (list of ints, later perhaps list of FD ints)
				   %% optional arg: generatorFactors (list of FD ints, same length as generators), generatorFactorsOffset (int)
				   %% */
      meth init(...) = M
	 RegularTemperamentMixinForNoteFeats = [generators generatorFactors generatorFactorsOffset]
      in
	 Note, {Record.subtractList M RegularTemperamentMixinForNoteFeats}
	 RegularTemperamentMixinForNote, {Adjoin {GUtils.takeFeatures M
						  RegularTemperamentMixinForNoteFeats}
					  %% replace label
					  initRegularTemperamentMixinForNote}
      end
	 
      
      meth getInitInfo($ ...)	 
	 unit(superclass:Note
	      args:[generators#fun {$ _} {Record.toList {self getAllGenerators($)}} end#noMatch
		    generatorFactors#fun {$ _} {Record.toList {self getAllGeneratorFactors($)}} end#_
		   ])
      end
   end
   
   
   /** %% [concrete class] The class FullNote extends the class Note (HS.score.note) by a representation for its scale degree and an enharmonic notation. These extensions are defined by the mixin classes EnharmonicSpellingMixinForNote and ScaleDegreeMixinForNote. See their documentation for details. 
   %% */
   %%
   %% !!?? If I add further note mixins (e.g. for a chord scale degree) I may then all add to this class FullNote?
   class FullNote from Note EnharmonicSpellingMixinForNote ScaleDegreeMixinForNote ChordDegreeMixinForNote
      feat label:fullNote
	 
      meth init(...) = M
	 EnharmonicSpellingMixinFeats = [cMajorDegree cMajorAccidental]
	 ScaleDegreeMixinFeats = [scaleDegree scaleAccidental]
	 ChordDegreeMixinFeats = [chordDegree chordAccidental]
      in
	 Note, {Record.subtractList M
		{Append
		 {Append EnharmonicSpellingMixinFeats ScaleDegreeMixinFeats}
		 ChordDegreeMixinFeats}}
	 EnharmonicSpellingMixinForNote, {Adjoin {GUtils.takeFeatures M
						  EnharmonicSpellingMixinFeats}
					  %% replace label
					  initEnharmonicSpellingMixinForNote}
	 ScaleDegreeMixinForNote, {Adjoin {GUtils.takeFeatures M
					   ScaleDegreeMixinFeats}
				   initScaleDegreeMixinForNote}
	 ChordDegreeMixinForNote, {Adjoin {GUtils.takeFeatures M
					   ChordDegreeMixinFeats}
				   initChordDegreeMixinForNote}
      end
      
      meth getInitInfo($ ...)	 
	 unit(superclass:Note
	      args:[cMajorDegree#getCMajorDegree#{FD.int [1#7]}
		    cMajorAccidental#getCMajorAccidental#{DB.makeAccidentalFDInt}
		    scaleDegree#getScaleDegree#{DB.makeScaleDegreeFDInt}
		    scaleAccidental#getScaleAccidental#{DB.makeAccidentalFDInt}
		    chordDegree#getChordDegree#{DB.makeChordDegreeFDInt}
		    chordAccidental#getChordAccidental#{DB.makeAccidentalFDInt}])
      end
   end

   
   /** %% [concrete class] The class EnharmonicNote extends the class Note (HS.score.note) by a representation for an enharmonic notation. This extension is defined by the mixin class EnharmonicSpellingMixinForNote. See its documentation for details.
   %% */
   class EnharmonicNote from Note EnharmonicSpellingMixinForNote
      feat label:enharmonicNote
	 
      meth init(...) = M
	 EnharmonicSpellingMixinFeats = [cMajorDegree cMajorAccidental]
      in
	 Note, {Record.subtractList M EnharmonicSpellingMixinFeats}
	 EnharmonicSpellingMixinForNote, {Adjoin {GUtils.takeFeatures M
						  EnharmonicSpellingMixinFeats}
					  %% replace label
					  initEnharmonicSpellingMixinForNote}
      end
      
      meth getInitInfo($ ...)	 
	 unit(superclass:Note
	      args:[cMajorDegree#getCMajorDegree#{FD.int [1#7]}
		    cMajorAccidental#getCMajorAccidental#{DB.makeAccidentalFDInt}])
      end
   end


   /** %% [concrete class] The class ScaleDegreeNote extends the class Note (HS.score.note) by a representation for its scale degree. This extension is defined by the mixin class ScaleDegreeMixinForNote. See its documentation for details. 
   %% */
   class ScaleDegreeNote from Note ScaleDegreeMixinForNote
      feat label:scaleDegreeNote
	 
      meth init(...) = M
	 ScaleDegreeMixinFeats = [scaleDegree scaleAccidental]
      in
	 Note, {Record.subtractList M ScaleDegreeMixinFeats}
	 ScaleDegreeMixinForNote, {Adjoin {GUtils.takeFeatures M
					   ScaleDegreeMixinFeats}
				   %% replace label
				   initScaleDegreeMixinForNote}
      end
      
      meth getInitInfo($ ...)	 
	 unit(superclass:Note
	      args:[scaleDegree#getScaleDegree#{DB.makeScaleDegreeFDInt}
		    scaleAccidental#getScaleAccidental#{DB.makeAccidentalFDInt}])
      end
   end

   
   /** %% [concrete class] The class ChordDegreeNote extends the class Note (HS.score.note) by a representation for its chord degree. This extension is defined by the mixin class ChordDegreeMixinForNote. See its documentation for details. 
   %% */
   class ChordDegreeNote from Note ChordDegreeMixinForNote
      feat label:chordDegreeNote
	 
      meth init(...) = M
	 ChordDegreeMixinFeats = [chordDegree chordAccidental]
      in
	 Note, {Record.subtractList M ChordDegreeMixinFeats}
	 ChordDegreeMixinForNote, {Adjoin {GUtils.takeFeatures M
					   ChordDegreeMixinFeats}
				   %% replace label
				   initChordDegreeMixinForNote}
      end
      
      meth getInitInfo($ ...)	 
	 unit(superclass:Note
	      args:[chordDegree#getChordDegree#{DB.makeChordDegreeFDInt}
		    chordAccidental#getChordAccidental#{DB.makeAccidentalFDInt}])
      end
   end

   
   /** %% [concrete class] Note class extended by scale-related mixins (in contrast to ScaleDegreeNote, it does not inherit from InChordMixinForNote). 
   %% */
   class ScaleNote from Score.note PitchClassMixin InScaleMixinForNote ScaleDegreeMixinForNote
      meth init(octave:Oct<=_ pitchClass:PC<=_
		...) = M
	 PitchClassMixinFeats = [octave pitchClass]
	 InScaleMixinFeats = [inScaleB getScales isRelatedScale]
	 ScaleDegreeMixinFeats = [scaleDegree scaleAccidental]
      in
	 Score.note, {Adjoin {Record.subtractList M
			      {Append PitchClassMixinFeats
			       {Append InScaleMixinFeats ScaleDegreeMixinFeats}}}
		      init(pitchUnit:{DB.getPitchUnit})}
	 PitchClassMixin, {Adjoin {GUtils.takeFeatures M PitchClassMixinFeats}
			   initPitchClassMixin}
	 InScaleMixinForNote, {Adjoin {GUtils.takeFeatures M InScaleMixinFeats}
			       initInScaleMixinForNote}
	 ScaleDegreeMixinForNote, {Adjoin {GUtils.takeFeatures M ScaleDegreeMixinFeats}
				   initScaleDegreeMixinForNote}
      end
   
      meth getInitInfo($ ...)	 
	 unit(superclass:Score.note
	      args:[pitchClass#getPitchClass#{DB.makePitchClassFDInt}
		    octave#getOctave#{DB.makeOctaveFDInt}
		    inScaleB#getInScaleB#{FD.int 0#1}
		    scaleDegree#getScaleDegree#{DB.makeScaleDegreeFDInt}
		    scaleAccidental#getScaleAccidental#{DB.makeAccidentalFDInt}])
      end
   end

   /** %% [concrete class] Note class extended by chord-related mixins (in contrast to ChordDegreeNote, it does not inherit from InScaleMixinForNote). 
   %% */
   class ChordNote from Score.note PitchClassMixin InChordMixinForNote ChordDegreeMixinForNote
      meth init(octave:Oct<=_ pitchClass:PC<=_
		...) = M
	 PitchClassMixinFeats = [octave pitchClass]
	 InChordMixinFeats = [inChordB getChords isRelatedChord]
	 ChordDegreeMixinFeats = [chordDegree chordAccidental]
      in
	 Score.note, {Adjoin {Record.subtractList M
			      {Append PitchClassMixinFeats
			       {Append InChordMixinFeats ChordDegreeMixinFeats}}}
		      init(pitchUnit:{DB.getPitchUnit})}
	 PitchClassMixin, {Adjoin {GUtils.takeFeatures M PitchClassMixinFeats}
			   initPitchClassMixin}
	 InChordMixinForNote, {Adjoin {GUtils.takeFeatures M InChordMixinFeats}
			       initInChordMixinForNote}
	 ChordDegreeMixinForNote, {Adjoin {GUtils.takeFeatures M ChordDegreeMixinFeats}
				   initChordDegreeMixinForNote}
      end
   
      meth getInitInfo($ ...)	 
	 unit(superclass:Score.note
	      args:[pitchClass#getPitchClass#{DB.makePitchClassFDInt}
		    octave#getOctave#{DB.makeOctaveFDInt}
		    inChordB#getInChordB#{FD.int 0#1}
		    chordDegree#getChordDegree#{DB.makeChordDegreeFDInt}
		    chordAccidental#getChordAccidental#{DB.makeAccidentalFDInt}])
      end
   end


   
   /** %% Extended script which returns a list of chords (not fully initialised, undetermined temporal params and timeUnit). Arguments are specified as two sub-records Args.iargs (item arguments, given to the chords) and Args.rargs (rule/constraint arguments), so arguments to constraints do not interfere with the arguments given to the chord initialisations. 
   %%
   %% Args.iargs:
   %% 'n': number of chords
   %% 'constructor' (default HS.score.chord): class or function
   %% 'handle': access the resulting list of chords
   %% all other chord init arguments are supported, and arg specs supported by Score.makeItems are supported (e.g., 'each' and 'fenv' args such as myParam: each#Params)
   %%
   %% Args.rargs
   %% 'types' (default false): list of 'chord types' (list of atoms supported by HS.db.getChordIndex) which are permitted. This constraint is skipped if 'types' is false.
   %% */
   MakeChords
   = {Score.defSubscript unit(super:Score.makeItems_iargs
			      rdefaults: unit(types: false) % ['harmonic 7th']
			      idefaults: unit(%n:1
					      constructor: Chord))
      proc {$ MyChords Args}
	 if Args.rargs.types \= false then 
	    {Rules.setEachChordType MyChords Args.rargs.types}
	 end
      end}
   
   /** %% Extended script which returns a list of scales (not fully initialised, undetermined temporal params and timeUnit). Arguments are specified as two sub-records Args.iargs (item arguments, given to the chords) and Args.rargs (rule/constraint arguments), so arguments to constraints do not interfere with the arguments given to the chord initialisations. 
   %%
   %% Args.iargs:
   %% 'n': number of scales
   %% 'constructor' (default HS.score.scale): class or function
   %% 'handle': access the resulting list of scales
   %% all other scale init arguments are supported, and arg specs supported by Score.makeItems are supported (e.g., 'each' and 'fenv' args such as myParam: each#Params)
   %%
   %% Args.rargs
   %% 'types' (default false): list of 'scale types' (list of atoms supported by HS.db.getScaleIndex) which are permitted. This constraint is skipped if 'types' is false.
   %% */
   MakeScales
   = {Score.defSubscript unit(super:Score.makeItems_iargs
			      rdefaults: unit(types: false) % ['major']
			      idefaults: unit(constructor: Scale))
      proc {$ MyChords Args}
	 if Args.rargs.types \= false then 
	    {Rules.setEachScaleType MyChords Args.rargs.types}
	 end
      end}
   

   /** %% Like HarmoniseScore, HarmoniseMotifs simplifies the definition of harmonic CSPs (these two definitions are both designed for convenience, not generality, and they cover different cases). HarmoniseMotifs is an extended script and defines a harmonic CSP for a given list of motifs (arbitrary textual score object specifications, possibly nested). Most of the actual CSP is defined by arguments, but the top-level score topology defined by HarmoniseMotifs is as follows

   sim(items:[seq(items:Motifs)
	      seq(items:[Chord+])
	      seq(items:[Scale+])
	      MyMeasure
	     ])

   % MyMeasure (a Measure.uniformMeasures object) lasts over the full duration of the score, and so do the chord and scale sequences. The harmonic rhythm (and the "scale rhythm") is only affected by user constraints (args chordRule and scaleRule).
   %%
   %% HarmoniseMotifs expects the following arguments:
   %% 
   %% motifs: a list of motif specs (atoms or records). Note: any score objects can be defined here (not necessarily explicit motifs..). Polyphonic music is possible if 'motifs' are containers containing other motif specs. 
   %% constructors: score constructors for motifs (see Score.makeScore doc)
   %% motifsRule: unary prodecure, applied to list of all motifs
   %% chordNo: number of chords
   %% makeChord: Chord constructor, can output textual score representation (must have label chord). If an object is returned instead of a textual score spec, the default chord class (HS.score.diatonicChord) is overwritten
   %% chordsRule: unary prodecure, applied to list of all chords
   %% myChords: return argument for accessing the list of chords
   %% includeScales: whether any scales are used at all. If false, the chord class HS.score.chord is used by default, but makeChord must be specified 
   %% scaleNo: number of scales
   %% makeScale: Scale constructor, can output textual representation (must have label scale). If an object is returned instead of a textual score spec, the default scale class (HS.score.scale) is overwritten 
   %% scaleRule: unary prodecure, applied to list of all scales
   %% includeMeasure: whether a measure object is used
   %% myScales: return argument for accessing the list of scales
   %% measure: Measure spec (a record). NOTE: params beatNumber and beatDuration must be determined in CSP def for simplicity (propagation otherwise blocks). Also, beatDuration depends on timeUnit (e.g., if timeUnit is beats(4), then a 3/4 bar has beatDuration 4). NOTE: if timeUnit is not beats(4), then the default measure value is wrong! 
   %% lilyTimeSignature: Lilypond time signature code, should be set according to measure
   %% measureRule: unary prodecure, applied to measure object
   %% myMeasure: return argument for accessing the measure
   %%
   %% The default arguments are as follows
   unit(motifs:nil	
	constructors:unit
	motifsRule: proc {$ Motifs} skip end
	chordNo:1	  
	makeChord:fun {$}
		     chord(duration:{FD.int 1#FD.sup}  % no non-existing chords of dur 0
			   getScales: fun {$ Self}
					 [{Self findSimultaneousItem($ test:HS.score.isScale)}]
				      end
			   inScaleB:1 % only scale pitches
			  )
		  end
	chordsRule: proc {$ Chords} skip end
	includeScales:true
	scaleNo:1
	makeScale:fun {$} scale(transposition:0) end
	scaleRule: proc {$ Scales} skip end
	includeMeasure: true
	measure: measure(beatNumber:4 %% 4/4 beat. 
			 beatDuration:4)
	lilyTimeSignature: "\\time  4/4"
	measureRule: proc {$ M} skip end
       )
   %%
   %% NOTE: HarmoniseMotifs does not defined the timeUnit. It can be specified, for example, with the motifs.
   %%
   %% HarmoniseScore and HarmoniseMotifs show some similarities, but they also differ in a several ways. For example, in HarmoniseScore the start time of chords is specified with the input score specification. In HarmoniseMotifs, the harmonic rhythm is independent of the input score spec. There are more differences...
   %%
   %% */
   %% TODO: use diatonic chord class ?
   proc {HarmoniseMotifs Args ?MyScore}
      Defaults = unit(motifs:nil	
		      constructors:unit
		      motifsRule: proc {$ Motifs} skip end
		      chordNo:1	     
		      makeChord:fun {$}
				   chord(duration:{FD.int 1#FD.sup}  
					 getScales: fun {$ Self}
						       [{Self findSimultaneousItem($ test:IsScale)}]
						    end 
					 inScaleB:1 
					 %% just to remove symmetries (if inversion chord is used)
					 %% sopranoChordDegree:1
					)
				end
		      chordsRule: proc {$ Chords} skip end
		      myChords:_
		      includeScales:true
		      scaleNo:1
		      makeScale:fun {$} scale(transposition:0) end
		      scaleRule: proc {$ Scales} skip end
		      myScales:_
		      includeMeasure: true
		      measure: measure(beatNumber:4 %% 4/4 beat
				       beatDuration:4
				      )
		      lilyTimeSignature: "\\time  3/4"
		      measureRule: proc {$ M} skip end
		      myMeasure:_
		     )
      As = {Adjoin Defaults Args}
      MainScore = {Score.makeScore2 seq(info:lily("\\set Staff.instrumentName = \"Main Score\" "#As.lilyTimeSignature)
					items:As.motifs)
		   As.constructors}
      ChordSeq = {Score.makeScore2 seq(info:lily("\\set Staff.instrumentName = \"Chords\"")
				       items:{LUtils.collectN As.chordNo
					      As.makeChord})
		  add(chord:if As.includeScales
			    then DiatonicChord
			    else Chord
			    end
		    % chord:HS.score.inversionChord
		     )}
      MyChords = {ChordSeq getItems($)}
      ScaleSeqL MyMeasureL
   in
      ScaleSeqL = if As.includeScales
		  then [{Score.makeScore2 seq(info:lily("\\set Staff.instrumentName = \"Scale\"")
					      items:{LUtils.collectN As.scaleNo
						     As.makeScale})
			 add(scale:Scale)}]
		  else nil
		  end
      MyMeasureL = if As.includeMeasure
		   then [{Score.makeScore2 As.measure
			  unit(measure:Measure.uniformMeasures)}]
		   else nil
		   end
      MyScore = {Score.makeScore sim(items:{LUtils.accum
					    [[MainScore
					      ChordSeq]
					     ScaleSeqL
					     MyMeasureL]
					    Append}
				     startTime:0)
		 As.constructors}
      %% apply user-def constaints
      thread {As.motifsRule {MainScore getItems($)}} end
      %% Constrain temporal structure. Start times are implicitly equal (if no offset time occurs)
      {MainScore getEndTime($)} = {ChordSeq getEndTime($)}
      %%
      thread {As.chordsRule MyChords} end
      As.myChords = MyChords
      %%
      if As.includeScales
      then MyScales = {ScaleSeqL.1 getItems($)} in
	 {MainScore getEndTime($)} = {ScaleSeqL.1 getEndTime($)}
	 thread {As.scaleRule MyScales} end
	 As.myScales = MyScales
      else As.myScales = nil
      end
      if As.includeMeasure
      then MyMeasure = MyMeasureL.1 in
	 {MainScore getEndTime($)} = {MyMeasureL.1 getEndTime($)}
	 thread {As.measureRule MyMeasure} end
	 As.myMeasure = MyMeasure
      else As.myMeasure = nil 
      end
   end

   

   /** %% HarmoniseScore simplifies the definition of harmonic CSPs, typically their top-level definition. HarmoniseScore constrains the pitches of the notes contained in a given score (ActualScore) to follow a harmonic progression. HarmoniseScore's arguments are arranged in the following score topology 
   
   <code>MyScore = {MakeScore2 sim(items:[ActualScore seq(handle:ChordSeq items:[Chord1 ... ChordN])])}</code>
   
   %% HarmoniseScore requires that it is known in the CSP definition which Strasheela items do start with a new chord. A list with these items is given by the argument ItemsStartingWithChord. The items in ItemsStartingWithChord can be freely scattered in the ActualScore but they must be ordered in ascending temporal order in ItemsStartingWithChord. The temporal distance between two neighbouring items in ItemsStartingWithChord determines the duration of the chord matching the first of the two items.
   %%
   %% Creators is a record of optional creator functions/classes similar to the corresponding argument of Score.makeScore. Creators defaults to
   <code>unit(chord:Chord
	      sim:Score.simultaneous
	      seq:Score.sequential)</code>
   %%
   %% NB: ActualScore must not be fully initialised (i.e. created with Strasheela.score.makeScore2). However, HarmoniseScore itself does fully initialise ActualScore, ChordSeq, and HarmonisedScore.
   %%
   %% Moreover, HarmoniseScore does neither set the startTime nor timeUnit, that is, these settings are usually done for ActualScore.
   %%
   %% The ItemsStartingWithChord are best accessed via the handle feature from a textual Strasheela score, because the score must not be fully initialised when using HarmoniseScore, and thus traversing the actual score object is restricted. 
   %% */
   proc {HarmoniseScore ActualScore ItemsStartingWithChord Creators ?ChordSeq ?HarmonisedScore}
      {HarmoniseScore2 ActualScore ItemsStartingWithChord Creators ChordSeq HarmonisedScore}
      {Score.initScore HarmonisedScore}
   end
   /** %% HarmoniseScore2 is idential to HarmoniseScore, except that HarmoniseScore2 does <em>not</em> initialise ActualScore, ChordSeq, nor HarmonisedScore. Instead, the HarmonisedScore must be explicitly initialised after calling HarmoniseScore (cf. the difference between Score.makeScore and Score.makeScore2).
   %% */ 
   proc {HarmoniseScore2 ActualScore ItemsStartingWithChord Creators ?ChordSeq ?HarmonisedScore}
      DefaultCreators = unit(chord:Chord
			     sim:Score.simultaneous
			     seq:Score.sequential)
      MyCreators = {Adjoin DefaultCreators Creators}
      ChordNumber = {Length ItemsStartingWithChord}
   in
      ChordSeq = {Score.makeScore2
		  seq(info:chordSeq
		      items:{LUtils.collectN ChordNumber fun {$} chord end}
		      %% temporal parameters of ActualScore are unified
		      %% with temporal parameters of ChordSeq
		      offsetTime:{ActualScore getOffsetTime($)}
		      startTime:{ActualScore getStartTime($)}
		      endTime:{ActualScore getEndTime($)})
		  MyCreators}
      HarmonisedScore = {Score.makeScore2 sim(items:[ActualScore
						     ChordSeq])
			 MyCreators}
      thread
	 %% application delayed until the score is fully initialised
	 {Pattern.equalizeParam ItemsStartingWithChord {ChordSeq getItems($)}
	  getStartTime}
      end
   end

   
   /** %% Constraints the start times of Chords (list of chord objects) to the start times of those items in MyScore (score object) which are marked to start a chord. If the items begin with a rest (offsetTime > 0), then the chord starts with the rest. In addition, the end time of the last chord is constrained to the end time of MyScore. The default chord-start-marker is an info tag 'startChord'. The number of marked score items and the number of chords must be equal.
   %%
   %% Args
   %% 'hasChordStartMarker': a unary Boolean function which tests whether a score object should start with a new chord. The default is
   fun {$ X} {X hasThisInfo($ startChord)} end
   %%
   %% Note: score objects with chord-start-marker must not overlap in time.
   %% */
   proc {HarmonicRhythmFollowsMarkers MyScore Chords Args}
      Default = unit(hasChordStartMarker: fun {$ X} {X hasThisInfo($ startChord)} end)
      As = {Adjoin Default Args}
   in
      thread
	 %% Sorting with reified constraints
	 ChordStartingItems = {Sort {MyScore filter($ As.hasChordStartMarker
						    excludeSelf: false)}
			       fun {$ X Y}
				  ({X getStartTime($)} <: {Y getStartTime($)}) == 1
			       end}
      in
	 %% do warning
	 if {Length ChordStartingItems} \= {Length Chords} then
	    {Browse 'HarmonicRythmsFollowsMarkers: number of chords ('#{Length Chords}#') does not match number of score objects which should start with a chord ('#{Length ChordStartingItems}#').'}
	 end
	 %% Actual constraints
	 {List.forAllInd {LUtils.matTrans [ChordStartingItems Chords]}
	  proc {$ I [MyItem MyChord]}
	     {MyItem getStartTime($)} - {MyItem getOffsetTime($)} =: {MyChord getStartTime($)}
	  end}
	 {MyScore getEndTime($)} = {{List.last Chords} getEndTime($)}
      end
   end


      
   /** %% Returns the script defined internally by ChordsToScore. See there for details. 
   %% */
   fun {ChordsToScore_Script ChordSpecs Args}
      Defaults = unit(voices:4
		      pitchDomain:48#72
		      amp:30
			 % value:mid
		      ignoreSopranoChordDegree:false
		      minIntervalToBass:0
		     % engeLage:false
		     ) 
      As = {Adjoin Defaults Args}
      /** %% Expects C (a chord declaration) and returns a chord object.
      %% NB: the returned chord object is not fully initialised! 
      %% */
      fun {MakeChord C}
%	 {Score.makeScore2 {Adjoin C chord} unit(chord:FullChord)}
	 {Score.makeScore2 {Adjoin C chord} unit(chord:InversionChord)}
      end
      /** %% Expects D (a FD int) and returns a singleton FS which contains only D.
      %% */
      proc {MakeSingletonSet D ?MyFS}
	 MyFS = {FS.var.decl}
	 {FS.include D MyFS}
	 {FS.card MyFS 1}
      end
   in
      proc {$ /* MyScript */ MyScore}
	 Chords = {Map ChordSpecs MakeChord}
	 %% list of list of simultaneous note and chord objects 
	 ChordNotess = {Map Chords
			proc {$ C ?Notes}
			   Dur = {C getDuration($)}
			   %% Pairs of note objects and
			   %% singletons sets with the note's
			   %% PC
			   NotesAndPCs = {LUtils.collectN As.voices
					  fun {$}
					     N PC_FS
					     PC = {DB.makePitchClassFDInt}
					  in
					     N = {Score.makeScore2
						  note(duration:Dur
						       pitchClass:PC
						       pitch:{FD.int As.pitchDomain}
						       amplitude:As.amp)
						  unit(note:Note2)}
					     %% N is chord note
					     {FS.include PC {C getPitchClasses($)}}
					     %% for constraining that all chord PC are expressed
					     {MakeSingletonSet PC PC_FS}
					     %% return result
					     N#PC_FS
					  end}
			   PC_FSs = {Map NotesAndPCs fun {$ _#PC_FS} PC_FS end}
			in
			   Notes = {Map NotesAndPCs fun {$ N#_} N end}
%			     Result = {Append Notes [C]}
			   %% no voice crossing (but unison doublings are OK)
			   {Pattern.continuous
			    {Map Notes fun {$ N} {N getPitch($)} end}
			    '=<:'}
			   %% QUATSCH (diese def fuer enge lage)
% 			  %% sim intervals between neighbouring voices
% 			  %% all > than an octave
% 			  if As.engeLage then
% 			     {Pattern.for2Neighbours
% 			      {Map Notes fun {$ N} {N getPitch($)} end}
% 			      proc {$ P1 P2}
% 				 P1 - P2 <: {HS.db.getPitchesPerOctave}
% 			      end}
% 			  end
			   %% first and last Note PCs are bass and soprano of C
			   if {Not As.ignoreSopranoChordDegree} then 
			      {Notes.1 getPitchClass($)} = {C getSopranoPitchClass($)}
			   end
			   {{List.last Notes} getPitchClass($)} = {C getBassPitchClass($)}
			   %%
			   if As.minIntervalToBass > 0 then 
			      {Notes.1 getPitchClass($)} - {{Nth Notes 2} getPitchClass($)} >=: As.minIntervalToBass
			   end
			   %% The note PCs together express all PCs of C (and no others)
			   {FS.unionN PC_FSs {C getPitchClasses($)}}
			end}
      in
	 MyScore
	 = {Score.makeScore
	    sim(items:[seq(items:{Map ChordNotess
				  fun {$ ChordNotes}
				     sim(items:ChordNotes)
				  end})
		       seq(info:lily('\\set Staff.instrumentName = "Analysis"')
			   items:Chords)]
		startTime:0
		%% implicit
%		timeUnit:{Chords.1 getTimeUnit($)}
	       )
	    unit}
      end	 
   end
      
   /** %% Expects a list of chord objects in textual form (init records for InversionChord), and returns a homophonic score object with notes expressing these chords. The notes (Note2 objects) are constrained to express all chord pitch classes, but chords can contain more notes than chord pitch classes. The CSP defined by ChordsToScore is intentionally relatively simple, as it is intended for listening to isolated chord progressions only (e.g., Bruckner's role of the "shortest path" between notes in a voice is not implemented).
   %% ChordSpecs must be fully determined, but chord attributes can be missing (e.g., the chord root is either determined or missing). 
   %% The created score topology has the following form: sim([seq([note note ...]) seq( note...) ... seq(chord chord ...)])
   %% The function defines the following optional Args. voices: the number of homophonic voices, pitchDomain: the pitch domain for all notes (depends on PitchesPerOctave). amp: the amplitude of all notes. order: the score distribition variable ordering strategy. value: the score distribution value selection strategy. ignoreSopranoChordDegree: if false, the sopranoChordDegrees of the input chords affect the output notes. minIntervalToBass: smallest interval allowed between bass and next lowest pitch. These are the default values
   unit(voices:4
	pitchDomain:48#72
	amp:30
	value:random
	ignoreSopranoChordDegree:false
	minIntervalToBass:0)
   %% 
   %% IMPORTANT: there are a few things to watch out for.
   %%
   %% - The timeUnit must be set in at least one chord spec.
   %% - Chord attributes cannot be undetermined variables -- ChordsToScore blocks in this case (it leads to a script with undetermined variables in the top-level space). 
   %% - ChordsToScore conducts a search and it is possible that no solution can be found. For example, the following cases can lead to no solution: the number of voices is insufficient for expressing all chord tones, the pitchDomain is too small, the number of voices equals the number of chord tones, but the soprano and bass chord degrees are equal so that these voices express the same chord tone and hence one tone is missing etc. 
   %% */
   %%
   %% OLD doc snippets:
   %% engeLage: a boolean specifying whether the interval between simultaneous notes of neighbouring voices must be less than an octave.   
   fun {ChordsToScore ChordSpecs Args}
      Defaults = unit(%voices:4
			 %pitchDomain:48#72
			 %amp:30
		      value:random
		      order:{SDistro.makeSetPreferredOrder
			     %% order: time params, chord params, pitch classes, octaves, pitches
			     [fun {$ X} {X isTimeParameter($)} end
			      fun {$ X} {IsChord {X getItem($)}} end
			      %% NOTE: searching for PCs before octaves can lead to massive increase of search size
			    % fun {$ X} {IsPitchClass X} end
			    % fun {$ X} {X hasThisInfo($ octave)} end
			     ]
			     fun {$ X Y}
				fun {GetDomSize X} {FD.reflect.size {X getValue($)}} end
			     in {GetDomSize X} < {GetDomSize Y}
			     end}
			 %ignoreSopranoChordDegree:false
			 %minIntervalToBass:0
		         % engeLage:false
		     ) 
      As = {Adjoin Defaults Args}
      {System.showInfo "ChordsToScore: start searching..."}
      %% !! TODO: check distro strategy
      Sol = {SDistro.searchOne {ChordsToScore_Script ChordSpecs Args}
	     unit(order:As.order
		 % value:random
		  value:As.value
		 )}
   in
      if Sol == nil then raise noSolution(inProc:ChordsToScore) end
      else Sol.1
      end 
   end
    

  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% !! unfinished below this
%%%
  

%% !! use SDistro.makeSearchScript (and SDistro.exploreOne etc.) instead of this
%%
%    %% !! outdated doc
%    /** %% Creates a constraint script for a score which is constrained by a (silent) harmonic progression. MkScoreWithoutChords and MkChordProgression are null-ary funcs which return both a part of the full score, namely the actual sounding score and the silent chord progression. Each subpart of the score must still be extendable (e.g. use Score.makeScore2 for generation). The start and end times of both ScoreWithoutChords and ChordProgression are unified (!). In the resulting score -- a simultaneous is the top-level -- ScoreWithoutChords is placed before ChordProgression.
%    %% Args is a record of additional arguments. All features optional, for defaults see source:
%    %% score(offsetTime:0 startTime:0 duration:<FDint> endTime:<FDint> includeNote:<binary proc> scoreConstraint:<unary proc> distribution:<dist record> distributionParameterTest:<unary fun>)
%    %% */
%    %%
%    %% !! at least one of MkChordsSilentScore or MkScalesSilentScore but not both obligatory (or both simply optional)
%    %%
%    %% !! distribution: first scale pitches, then chord pitches, then note pitches
%    %%
%    %% !! unfinished distributionParameterTest -- use method hasAlsoThisInfo to check parameter purpose.
%    %%
%    %% !!?? missing relation / constraint between chords and scales: e.g. if a note pitch class is passing note (constraint to be in scale but not necessarily in chord)
%    %%
%    %% !! Linking of note and chord pitch classes was main point of this function? Now I kick that out because it may not be flexible enough..
%    %%
%    %% !! redefine in terms of SDistro.makeSearchScript: make script by combining the score parts in common sim and linking. Then hand this script to SDistro.makeSearchScript and add distribution args later at will..
%    %%
%    fun {MkHarmonisedScoreScript MkActualScore
% 	MkChordsSilentScore MkScalesSilentScore Args}
%       proc {$ MyScore}
% 	 DefaultArgs =
% 	 unit(%% Args may contain arbitrary top-level container args
% 	      startTime:0
% 	      timeUnit:beats(4)
% 	      %% binary proc: applied wih each chord and
% 	      %% ScoreWithoutChords to link score pitches in
% 	      %% (simultaneous) chord in ChordProgression
% 	      % includeNotes:proc {$ MyChord MyScore} skip end
% % 	      includeNotes:{ChordProg.mkIncludeSimultaneous
% % 			    %% use chord PCs (not scale PCs)
% % 			    unit(chordAccessor:getPitchClasses)}
% 	      %% to express additional constraints on whole score
% 	      scoreConstraint: proc {$ MyScore} skip end % proc
% 	      %% !! fix link into ChordProg functor
% 	      distribution:{SDistro.makeFDDistribution
% 			    unit(order:ChordProg.startTimePreferChordParamsOrder 
% 				 value:mid)}
% 	      %% to filter which parameters to distribute. Test always implicitly filters out all nont-parameter objects.
% 	      distributionParameterTest:fun {$ X} skip end
% % 	      distributionParameterTest:fun {$ X}
% 					   %% !! blocks
% % 					   %% Skip start and end times
% % 					   %% (determined if offset and dur is
% % 					   %% known)
% % 					   {Not
% % 					    ({X isTimePoint($)}
% % 					     orelse
% % 					     %% skip chord/scale
% % 					     %% root/untransposedRoot
% % 					     %% and note pitches
% % 					     %% (chord/scale index and
% % 					     %% transposition plus
% % 					     %% note PCs and octaves
% % 					     %% is enough)
% % 					     ({X isPitch($)}
% % 					      andthen
% % 					      ({X hasThisInfo($ root)}
% % 					       orelse
% % 					       {X hasThisInfo($ untransposedRoot)}
% % 					       orelse
% % 					       {X hasThisInfo($ notePitch)}
% % 					      )))}
% % 					end
% 	      sim:Simultaneous)
% 	 ActualArgs = {Adjoin DefaultArgs Args}
% 	 ActualScore = {MkActualScore}
% 	 ChordsSilentScore = {MkChordsSilentScore}
% 	 ScalesSilentScore = {MkScalesSilentScore}    
%       in
% 	 %% ActualArgs.sim specifies the sim container used. Arbitrary
% 	 %% top-level container args can be specified by Args
% 	 MyScore = {Score.makeScore2 % ScoreRecord2Object
% 		    {Adjoin {Record.subtractList ActualArgs
% 			     [scoreConstraint
% 			      distribution distributionParameterTest
% 			      sim]}
% 		     sim}
% 		    unit(sim:ActualArgs.sim)}
% 	 %% link score parts into score
% 	 {MyScore bilinkItems([ActualScore ChordsSilentScore ScalesSilentScore])}
% 	 {Score.initScore MyScore}
% 	 %%
% 	 %% constraints
% 	 %%
% 	 %% all parts of score start and end simultaneously
% 	 {ActualScore getStartTime($)}
% 	   = {ChordsSilentScore getStartTime($)}
% 	   = {ScalesSilentScore getStartTime($)}
% 	 {ActualScore getEndTime($)}
% 	   = {ChordsSilentScore getEndTime($)}
% 	   = {ScalesSilentScore getEndTime($)}
% 	 %%
% 	 %% !! DO I need this linking here -- often I link by more complex constraints/rules and in any case I can always do this in scoreConstraint: I can access the scales, chords and notes there and link them at will
% 	 %% 
% 	 %% Link pitches of ScoreWithoutChords notes into (simultaneous)
% 	 %% chords in ChordProgression
% 	 %%
% 	 %% ?? more simple alternative (if format of ChordProgression is fixed)
% 	 %% {ForAll {ChordProgression getItems($)} proc {$ MyChord} {IncludeNotes MyChord ScoreWithoutChords} end}
% % 	 {ChordsSilentScore
% % 	  forAll(test:IsChord
% % 		 proc {$ MyChord}
% % 		    {ActualArgs.includeNotes MyChord ActualScore}
% % 		 end)}
% % 	 %% !! This must not be same linking proc
% % 	 {ScalesSilentScore
% % 	  forAll(test:IsScale
% % 		 proc {$ MyScale}
% % 		    {ActualArgs.includeNotes MyScale ActualScore}
% % 		 end)}
% 	 %% apply additional score constraints
% 	 {ActualArgs.scoreConstraint MyScore}
% 	 %%
% 	 %% distribution
% 	 %%
% 	 {FD.distribute ActualArgs.distribution
% 	  {MyScore
% 	   collect($ test:fun {$ X}
% 			     {X isParameter($)}
% 			     andthen
% 			     {ActualArgs.distributionParameterTest X}
% 			  end)}}
%       end
%    end


   
%   /** %% Returns a seq of n chords.
%    %% */
%    proc {MkChordProgression Args ?ChordSeq}
%       Defaults = unit(n:1
% 		      info:chordProgression
% 		      durationDomain:1#FD.sup
% 		      indexDomain:0#FD.sup
% 		      transpositionDomain:0#72
% 		      %% rules for whole chord seq
% 		      rules:nil
% 		      %% rules for all individual chords
% 		      chordRules:nil)
%       As = {Adjoin Defaults Args}
%    in
%       ChordSeq
%       = {ScoreRecord2Object
% 	 seq(info:chordProgression
% 	     items:{LUtils.collectN As.n
% 		    fun {$}
% 		       chord(duration:{FD.int As.durationDomain}
% 			     index:{FD.int As.indexDomain}
% 			     transposition:{FD.int
% 					    As.transpositionDomain})
% 		    end}
% 	    )}
%       thread			% unclosed hierarchy
% 	 {{GUtils.procs2Proc As.rules} ChordSeq}
% 	 {ForAll {ChordSeq getItems($)} 
% 	  proc {$ MyChord}
% 	     {{GUtils.procs2Proc As.chordRules} MyChord}
% 	  end}
%       end
%    end
%    fun {IsChordProgression X} {HasThisInfo X chordProgression} end

     
%    /** %% Returns a boolean whether MyItem is either the first or the last element in some TemporalAspect.
%    %% */
%    fun {IsFirstOrLastInTemporalAspect MyItem}
%       C = {MyItem getTemporalAspect($)}
%    in
%       {MyItem isFirstItem($ C)} orelse
%       {MyItem isLastItem($ C)}
%    end

end
