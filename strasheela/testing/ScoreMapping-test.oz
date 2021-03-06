
declare 
[S] = {ModuleLink ['x-ozlib://anders/music/sdl/ScoreCore.ozf']}
{Inspector.configure widgetTreeDisplayMode false}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Important testing
%% mapping etc.
%%

declare 
[S] = {ModuleLink ['x-ozlib://anders/music/sdl/ScoreCore.ozf']}
{Inspector.configure widgetTreeDisplayMode false}

declare
N1 = {New S.note init(info: n1)}
N2 = {New S.note init(info: n2)}
P1 = {New S.pause init(info: p1)}
P2 = {New S.pause init(info: p2)}
A1 = {New S.aspect init(items: [N1 P1] info:a1)}
A2 = {New S.aspect init(items: [N1 N2] info:a2)}
Sim = {New S.simultaneous init(items: [N2 P2]
			       info: sim)}
Seq = {New S.sequential init(items:[P1 N1 Sim]
			     info: seq)}
fun {GetInfo X} {X getInfo($)} end
% only tree mode implemented yet, therefore three explicite calls 
{Seq closeScoreHierarchy(mode:tree)}
{A1 closeScoreHierarchy(mode:tree)}
{A2 closeScoreHierarchy(mode:tree)}

{N1 getContainers($)}

{Seq toPPrintRecord($)}
{A1 toPPrintRecord($)}

%%
%% The tests below only test the returned items, additionally all
%% parameters of the items are returned
%%

%% tree mode

% single level tree
{Map {A1 collect($ mode:tree test:isItem)} GetInfo} == [n1 p1]

% recursive call (level:all)
{Map {Seq collect($ mode:tree test:isItem level:all)} GetInfo} 
== [p1 n1 sim n2 p2]

% level:1
{Map {Seq collect($ mode:tree level:1 test:isItem)} GetInfo} 
== [p1 n1 sim]

% arg test
{Map {A1 collect($ mode:tree test:fun {$ X} {X isPause($)} end)} 
 GetInfo}
== [p1]

% arg test
{Map {Seq collect($ mode:tree level:all test:fun {$ X} {X isPause($)} end)}
 GetInfo}
== [p1 p2]

%% graph mode (how to check order independent?)

% level:all
{Map {Seq collect($ mode:graph level:all test:isItem)} GetInfo}
== [p1 n1 sim a1 a2 n2 p2]

%% (how to check order independent?)
{Map {P1 collect($ mode:graph test:isItem)} GetInfo}
== [a1 seq n1  a2 n2 sim p2]

% !! untested: level arg in mode:graph (how containers are limited)


%% method map
{Seq map($ GetInfo mode:graph level:all test:isItem)} == [p1 n1 sim a1 a2 n2 p2]

%% method forAll
{Seq forAll(proc {$ X} {Browse {GetInfo X}} end 
	    mode:graph level:all test:isItem)}

{Seq count($ mode:graph level:all test:isItem)} == 7

% I may configure Inspector for distict records with equal content... 
%{Inspector.configure widgetRelationList
% ['RelationName'(fun {$ X Y} X==Y end)]}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% order of items returned by collect etc.
%%

declare
MyScore = {Score.makeScore
	   seq(items:{LUtils.collectN 3
		      fun {$}
			 seq(items:{LUtils.collectN 3
				    fun {$}
				       note(% offsetTime:0
					    duration:1
					    %% undetermined pitch and amp
					    % pitch:60
					    % amplitude:1
					   )
				    end}
			     offsetTime:0)
		      end}
	       startTime:0
	       offsetTime:0)
	   unit}

%% collect startTimes: strictly increasing order? OK
{MyScore map($ getStartTime test:isNote)}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Testing SMapping.applyToContext
%%

declare
MyNote = {Score.makeScore2 note(info:note1 duration:2 pitch:60) unit}
MyScore = {Score.makeScore
	   sim(items:[seq(items:[MyNote])
		      seq(items:[note(info:note2 duration:2 pitch:64)])
		      seq(items:[note(info:note3 duration:2 pitch:64)])]
	       startTime:0
	       timeUnit:beats(4))
	   unit}


{SMapping.applyToContext
 %% context
 {Map MyNote | {MyNote getSimultaneousItems($ test:isNote)}
  fun {$ X} {X getInfo($)} end}
 %% 'rule' 
 Browse}


%% skip application 
{SMapping.applyToContext 
 %% context is nil
 nil
 Browse}


%% method application
{SMapping.applyToContext 
 %% context accessor is method
 {MyNote getSimultaneousItems($)}
 Browse}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Testing SMapping.applyToContextR
%%

declare
proc {IsConsonantR N1 N2 B}
   Consonance = {FD.int [3 4 7 8 9 12 15 16]}
in
   B = {FD.reified.distance {N1 getPitch($)} {N2 getPitch($)}
	'=:' Consonance}
end
fun {MakeNote Args}
   {Adjoin
    note(duration:{FD.int 1#2}
	 pitch:{FD.int 60#72}
	 amplitude:1)
    Args}
end

{SDistro.exploreOne
 proc {$ MyScore}
    %% rhythmic structure not predetermined
    Voice1 = {Score.makeScore2 seq(items:{Map [note(info:note1_1)
					       note(info:note2_2)]
					  MakeNote})
	      unit}
    Voice2 = {Score.makeScore2 seq(items:{Map [note(info:note2_1)
					       note(info:note2_2)
					       note(info:note2_3)
					       note(info:note2_4)]
					  MakeNote})
	      unit}
    % IsContextBs RuleBs
 in
    MyScore = {Score.makeScore
	       sim(items:[Voice1 Voice2]
		   startTime:0
		   timeUnit:beats(4))
	       unit}
    {ForAll {Voice1 getItems($)}
     proc {$ MyNote}
	{SMapping.applyToContextR
	 unit(%% context candidates are notes of other voice
	      candidates:{Voice2 getItems($)}
	      %% context test
	      isContext:fun {$ X} {MyNote isSimultaneousItemR($ X)} end
	      %% rule: applied to all context candidates. Rule must hold (i.e. return 1) for all X for which context test holds. 
	      rule:proc {$ X B} {IsConsonantR MyNote X B} end
	      %% how many true: there are 2 consonant sim notes for each note in Voice1 (in effect, this constraints the rhythmic structure)
	      n:2
	      b:1
	     % isContextBs:IsContextBs
	     % ruleBs:RuleBs
	     )}
     end}
    %{FD.distribute ff {Append IsContextBs RuleBs}}
    %{Browse IsContextBs#RuleBs}
 end
 unit(value:random)}



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% SMapping.mapContexts and friends
%%

declare
MyScore = {Score.makeScore
	   sim(items:[seq(items:[note(info:a duration:1) note(info:b duration:2)])
		      seq(items:[note(info:c duration:2) note(info:d duration:1)])]
	       startTime:0)
	   unit}
MyVoice1Notes = {{MyScore getItems($)}.1 getItems($)}


{SMapping.mapContexts MyVoice1Notes
 fun {$ X} X | {X getSimultaneousItems($ test:isNote)} end
 fun {$ Xs}
    myConstraint({Map Xs fun {$ X} note(info:{X getInfo($)}) end})
 end}

{SMapping.forContexts MyVoice1Notes
 fun {$ X} X | {X getSimultaneousItems($ test:isNote)} end
 proc {$ Xs} {Browse myConstraint({Map Xs fun {$ X} note({X getInfo($)}) end})} end}


%%%%%
%%
%% {SMapping.forContexts MyVoice1Notes GetSimultaneousNotes AllConsonant}
%%

{SDistro.exploreOne
 proc {$ MyScore}
    fun {GetSimultaneousNotes X} X | {X getSimultaneousItems($ test:isNote)} end
    proc {IsConsonantR Note1 Note2 B}
       Pitch1 = {Note1 getPitch($)}
       Pitch2 = {Note2 getPitch($)}
       %% no unisono
       Interval = {FD.int [3 4 7 8 9 12 15 16]} % 0
    in
       B = {FD.int 0#1}
       B = {FD.reified.distance Pitch1 Pitch2 '=:' Interval}
    end
    proc {AllConsonant Xs}
       {Pattern.allTrue {Pattern.mapPairwise Xs IsConsonantR}}
    end
    MyVoice1Notes
 in
    MyScore = {Score.makeScore
	       sim(items:[seq(items:[note2(duration:1
					   pitch:{FD.int 60#72})
				     note2(duration:2
					   pitch:{FD.int 60#72})])
			  seq(items:[note2(duration:1
					   pitch:{FD.int 60#72})
				     note2(duration:2
					   pitch:{FD.int 60#72})])
			  seq(items:[note2(duration:2
					   pitch:{FD.int 60#72})
				     note2(duration:1
					   pitch:{FD.int 60#72})])]
		   startTime:0
		   timeUnit:beats(2))
	       unit}
    MyVoice1Notes = {{MyScore getItems($)}.1 getItems($)}
    %%
    {SMapping.forContexts MyVoice1Notes GetSimultaneousNotes AllConsonant}
 end
 unit}



%%%%%
%%
%% SMapping.forContextsR
%%


declare
proc {IsConsonantR N1 N2 B}
   Consonance = {FD.int [3 4 7 8 9 12 15 16]}
in
   B = {FD.reified.distance {N1 getPitch($)} {N2 getPitch($)}
	'=:' Consonance}
end
fun {MakeNote Args}
   {Adjoin
    note(duration:{FD.int 1#2}
	 pitch:{FD.int 60#72}
	 amplitude:1)
    Args}
end

{SDistro.exploreOne
 proc {$ MyScore}
    %% rhythmic structure not predetermined
    Voice1 = {Score.makeScore2 seq(items:{Map [note(info:note1_1)
					       note(info:note2_2)]
					  MakeNote})
	      unit}
    Voice2 = {Score.makeScore2 seq(items:{Map [note(info:note2_1)
					       note(info:note2_2)
					       note(info:note2_3)
					       note(info:note2_4)]
					  MakeNote})
	      unit}
 in
    MyScore = {Score.makeScore
	       sim(items:[Voice1 Voice2]
		   startTime:0
		   timeUnit:beats(4))
	       unit}
    {SMapping.forContextsR
     unit(xs:{Voice1 getItems($)}
	  %% context candidates are pairs of notes of both voices  
	  getCandidates:fun {$ Note1} 
			   {Map {Voice2 getItems($)}
			    fun {$ Note2} Note1#Note2 end}
			end
	  %% context test
	  isContext:proc {$ Note1#Note2 B} B={Note1 isSimultaneousItemR($ Note2)} end
	  %% rule: applied to all context candidates. Rule must hold (i.e. return 1) for all X for which context test holds. 
	  rule:proc {$ Note1#Note2 B} {IsConsonantR Note1 Note2 B} end
	  %% for how many (notes of voice 1) shall rule hold?
	  n:every)}
 end
 unit(value:random)}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% SMapping.forNumericRange
%%

%% b c d f
{SMapping.forNumericRange [a b c d e f g] [2#4 6] proc {$ X} {Browse X} end}

%% exception
{SMapping.forNumericRange [a b c d e f g] [2#4 9] proc {$ X} {Browse X} end}

%% exception
{SMapping.forNumericRange [a b c d e f g] [2#4 blau] proc {$ X} {Browse X} end}

%% elseCase#a b c d elseCase#e f elseCase#g
{SMapping.forNumericRange2 [a b c d e f g] [2#4 6] proc {$ X} {Browse X} end
proc {$ X} {Browse elseCase#X} end}


%% a#[hi] noMatch#b c#[there] d#[there] noMatch#e
{SMapping.forNumericRangeArgs [a b c d e]
 [1#[hi]
  (3#4)#[there]]
 proc {$ X Args} {Browse X#Args} end
 proc {$ X} {Browse noMatch#X} end}



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% SMapping.patternMatchingApply
%% 

%% [b c d]
{SMapping.patternMatchingApply c [a b c d e] [o x o] proc {$ Xs} {Browse Xs} end}

%% [a b]
{SMapping.patternMatchingApply b [a b c d e] [o x] proc {$ Xs} {Browse Xs} end}

%% [b c]
{SMapping.patternMatchingApply b [a b c d e] [x o] proc {$ Xs} {Browse Xs} end}

%% skip
{SMapping.patternMatchingApply a [a b c d e] [o x o] proc {$ Xs} {Browse Xs} end}

%% skip
{SMapping.patternMatchingApply e [a b c d e] [o x o] proc {$ Xs} {Browse Xs} end}

%% exception
{SMapping.patternMatchingApply c [a b c d e] [o y o] proc {$ Xs} {Browse Xs} end}

%% exception
{SMapping.patternMatchingApply bla [a b c d e] [o x o] proc {$ Xs} {Browse Xs} end}


%% [b c d]
{SMapping.patternMatchingApply2 c [a b c d e] [o x o] proc {$ Xs} {Browse Xs} end
 proc {$} {Browse elseCase} end}

%% else case
{SMapping.patternMatchingApply2 e [a b c d e] [o x o] proc {$ Xs} {Browse Xs} end
 proc {$} {Browse elseCase} end}

%% else case
{SMapping.patternMatchingApply2 a [a b c d e] [o x o] proc {$ Xs} {Browse Xs} end
 proc {$} {Browse elseCase} end}



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% SMapping.mapTimeslices, SMapping.forTimeslices
%% 

declare
MyScore = {Score.make sim([seq([note(offsetTime: {FD.int 0#1}
				     duration: 1
				     pitch: 1)
				note(duration: 1
				     pitch: 2)
				note(duration: 2
				     pitch: 3)
				note(duration: 2  % has start time 5 or 6
				     pitch: 4)
				note(duration: 2
				     pitch: 5)
				note(duration: 2
				     pitch: 6)])
			   seq([note(duration: 2
				     pitch: 11)
				note(duration: 2
				     pitch: 12)
				note(offsetTime: 1
				     duration: 1
				     pitch: 13)
				%% The note pairs up to here should be processed by SMapping.mapTimeslices below, but the fourth note pair is delayed until this offset time is determined
				%% BUG: all are delayed
				note(offsetTime: {FD.int 0#1} % has start time 6 or later
				     duration: 2
				     pitch: 14)
				note(offsetTime: {FD.int 0#1}
				     duration: 2
				     pitch: 15)
				note(offsetTime: {FD.int 0#3}
				     duration: 2
				     pitch: 16)])
			   seq([note(duration: 2
				     pitch: 21)
				note(duration: 1
				     pitch: 22)
				note(duration: 2
				     pitch: 23)
				note(duration: 2  % has start time 6
				     pitch: 24)
				note(duration: 2
				     pitch: 25)
				note(duration: 2
				     pitch: 26)])]
			  startTime:0
			  timeUnit: beats)
	   unit}


%% Now bind undetermined offset time
{{Nth {{Nth {MyScore getItems($)} 1} getItems($)} 1} getOffsetTime($)} = 1

%% BUG ? undetermined offset time of note with pitch 1 causes blocking of time slice start=1 end=2 and others
%% Problem occurs, because program does not know in which time slice the first notes of all parts will occur together
%% Is that OK, because these time slices are after this note and will not cause problems with left-to-right variable ordering?

{SMapping.forTimeslices {MyScore collect($ test:isNote)}
 proc {$ Xs}
    {Browse {Map Xs fun {$ X}
		       {Adjoin unit(start: {X getStartTime($)} 'end': {X getEndTime($)})
			{X toInitRecord($)}}
		    end}}
 end
 unit(endTime: {FD.reflect.max {MyScore getEndTime($)}})}


{Browse
 {SMapping.mapTimeslices {MyScore collect($ test:isNote)}
  fun {$ Xs}
     {Map Xs fun {$ X}
		{Adjoin unit(start: {X getStartTime($)} 'end': {X getEndTime($)})
		 {X toInitRecord($)}}
	     end}
  end
  unit(endTime: {FD.reflect.max {MyScore getEndTime($)}})}}

% 




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% SMapping.forSimultaneousPairs / SMapping.mapSimultaneousPairs
%% 

declare
N1 N2 
MyScore = {Score.makeScore sim(items:[seq(items:[note(handle:N1
						      info:n1
						      duration:2)])
				      seq(items:[note(handle:N2
						      info:n2
						      duration:2)])]
			       startTime:0
			       timeUnit:beats)
	   unit}


{MyScore toInitRecord($)}


{SMapping.mapSimultaneousPairs [N1]
 fun {$ X Y} {X getInfo($)}#{Y getInfo($)} end
 unit(test: isNote)}

%% -> nil

{SMapping.mapSimultaneousPairs [N2]
 fun {$ X Y} {X getInfo($)}#{Y getInfo($)} end
 unit(test: isNote)}

%% -> [[n2]#[n1]]


{SMapping.forSimultaneousPairs [N2]
 proc {$ X Y} {Browse {X getInfo($)}#{Y getInfo($)}} end
 unit(test: isNote)}

%% browses [n2]#[n1]





%%%%%%%%%%%%%%%%%%%%%%

declare
MyScore = {Score.make sim([seq([note(offsetTime: {FD.int 0#1}
				     duration: 1
				     pitch: 1)
				note(duration: 1
				     pitch: 2)
				note(duration: 2
				     pitch: 3)
				note(duration: 2  % has start time 5
				     pitch: 4)
				note(duration: 2
				     pitch: 5)
				note(duration: 2
				     pitch: 6)])
			   seq([note(duration: 1
				     pitch: 11)
				note(duration: 2
				     pitch: 12)
				note(offsetTime: 1
				     duration: 1
				     pitch: 13)
				%% The note pairs up to here should be processed by SMapping.mapTimeslices below, but the fourth note pair is delayed until this offset time is determined
				note(offsetTime: {FD.int 0#1} % has start time 5 or later
				     duration: 1
				     pitch: 14)
				note(offsetTime: {FD.int 0#1}
				     duration: 2
				     pitch: 15)
				note(offsetTime: {FD.int 0#3}
				     duration: 2
				     pitch: 16)])
			   seq([note(duration: 2
				     pitch: 21)
				note(duration: 1
				     pitch: 22)
				note(duration: 2
				     pitch: 23)
				note(duration: 2  % has start time 5
				     pitch: 24)
				note(duration: 2
				     pitch: 25)
				note(duration: 2
				     pitch: 26)])]
			  startTime:0
			  timeUnit: beats)
	   unit}


{SMapping.forSimultaneousPairs {MyScore collect($ test:isNote)}
 proc {$ X Y}
    {Browse {Adjoin unit(start: {X getStartTime($)} 'end': {X getEndTime($)}) {X toInitRecord($)}}
     #{Adjoin unit(start: {Y getStartTime($)} 'end': {Y getEndTime($)}) {Y toInitRecord($)}}}
 end
 unit(test: isNote)}


%% BUG: blocks -- should return what it can so far, i.e. a list with unbound end?
{SMapping.mapSimultaneousPairs {MyScore collect($ test:isNote)}
 fun {$ X Y}
    {Adjoin unit(start: {X getStartTime($)} 'end': {X getEndTime($)}) {X toInitRecord($)}}
    #{Adjoin unit(start: {Y getStartTime($)} 'end': {X getEndTime($)}) {Y toInitRecord($)}}
 end
 unit(test: isNote)}




%% Now bind undetermined offset time
{{Nth {{Nth {MyScore getItems($)} 1} getItems($)} 4} getOffsetTime($)} = 1

{{Nth {{Nth {MyScore getItems($)} 1} getItems($)} 5} getOffsetTime($)} = 0
 
{{Nth {{Nth {MyScore getItems($)} 1} getItems($)} 6} getOffsetTime($)} = 0


{{Nth {{Nth {MyScore getItems($)} 1} getItems($)} 4} getOffsetTime($)} = 3




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% SMapping.forSimultaneousPairs -- with partially determined score
%%

declare
N1 N2 N3
N11 N12 N13
MyScore = {Score.make sim([seq([note(handle:N1
				     duration: 2
				     pitch: 1)
				note(handle:N2
				     duration: 1
				     pitch: 2)
				note(handle:N3
				     duration: 2
				     pitch: 3)])
			   seq([note(handle:N11
				     duration: 2
				     pitch: 11)
				%% This note is already known to be in time window 1-4
				note(handle:N12
				     offsetTime: {FD.int 0#1}
				     % duration: 1
				     pitch: 12)
				note(handle:N13
				     pitch: 13)])]
			  startTime:0
			 timeUnit:beats)
	   unit}

%% BUG: does not work if sim notes are not contained in given list
{SMapping.forSimultaneousPairs [N1 N2 N3]
 proc {$ N_1 N_2}
    {Browse {Pattern.mapItems [N_1 N_2] toInitRecord}}
 end
 unit(test: isNote)}

{SMapping.forSimultaneousPairs {MyScore collect($ test:isNote)}
 proc {$ N_1 N_2}
    {Browse {Pattern.mapItems [N_1 N_2] toInitRecord}}
 end
 unit(test: isNote)}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% MapScore
%%

declare
MyScore = seq(info:test
	      items:[note(duration:4
			  pitch:60)
		    note(duration:4
			 pitch:62)
		    note(duration:4
			  pitch:64)]
	      startTime:0
	      timeUnit:beats(4)
	     )

%% no processing
{Browse {SMapping.mapScore MyScore
	 fun {$ X} X end}}

%% add feat bla
%% Note: all score objects get it added, but not beats(4) 
{Browse {SMapping.mapScore MyScore
	 fun {$ X} {Adjoin unit(bla:hallo) X} end}}

