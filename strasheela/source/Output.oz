
%%% *************************************************************
%%% Copyright (C) Torsten Anders (www.torsten-anders.de) 
%%% This program is free software; you can redistribute it and/or
%%% modify it under the terms of the GNU General Public License
%%% as published by the Free Software Foundation; either version 2
%%% of the License, or (at your option) any later version.
%%% This program is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%% GNU General Public License for more details.
%%% *************************************************************

/** %% Functor defines means for output, e.g. means to output a Strasheela score to a csound score and play the result.
% */

%% TODO:
%%
%% * Many formats output nothing at all if some part of the score is undetermined. Instead, output all events etc. which are already determined (and possibly a warning).  
%%
%% OK? * add Fomus output (http://common-lisp.net/project/fomus/)
%%
%% * add GUI for output settings (cf. Common Music GUI CMIO, http://commonmusic.sourceforge.net/doc/dict/cmio-topic.html) 
%%
%% * Refactor: there are some early attempts to prevent
%% code-doublettes by using somewhat more general constructs as
%% MakeHierarchicVSScore. However, code can probably cleaned up more
%% nicely..
%%
%% * Functionality and naming inconsistent: e.g. MakeCsoundScore
%% vs. ToLilypond, and OutputCsoundScore vs. OutputLilypond
%%
%% * Def of lilypond output (ToLilypond) inconsistent: for some classes output is build-in (as for note) and for others the output can be added. More consistent would be a solution which hands all transformers as arg (and supports adding instead of replacing for convenience, similar to Score.makeScore)
%%
%% * GUtils.selectArgs is probably better replaced by a construct
%% using Adjoin: {Adjoin Defaults Args} = EffectiveArgs
%%
%% * ?? unit of measurement not in score parameter but (at least optional) given to output transformer
%%

functor
import
   Open OS Tk System Compiler% Time
   FD FS
   Browser(browse:Browse)
   Inspector(inspect:Inspect)

   %% vars imported to build compiler environment
   CompilerPanel Application Combinator Connection DistributionPanel DPControl DPInit DPStatistics DefaultURL Discovery  Emacs Error ErrorListener ErrorRegistry EvalDialog Explorer Fault Finalize Gump GumpParser GumpScanner Listener Macro Module Narrator OPI OPIEnv OPIServer ObjectSupport OsTime Ozcar OzcarClient Panel Pickle Profiler Property RecordC Remote Resolve Schedule Search Service Space Tix TkTools Type URL VirtualSite
   
   %% !! tmp
   Path at 'x-ozlib://anders/tmp/Path/Path.ozf'
   
   GUtils at 'GeneralUtils.ozf'
   LUtils at 'ListUtils.ozf'
   MUtils at 'MusicUtils.ozf'
   Score at 'ScoreCore.ozf'
   Init at 'Init.ozf'
   Midi at 'MidiOutput.ozf'
%   Score at 'ScoreCore.ozf'
   
export
   WriteToFile ReadFromFile
   RecordToVS ListToVS ListToLines % ListToVS2 ListToVS3 
   MakeEventlist OutputEventlist
   ScoreToEvents
   MakeHierarchicVSScore
   ToScoreConstructor OutputScoreConstructor SaveScore LoadScore
   MakeEvent2CsoundFn MakeCsoundScore
   OutputCsoundScore RenderCsound RenderAndPlayCsound
   CallCsound
   ToLilypond OutputLilypond CallLilypond ViewPDF
   RenderLilypond RenderAndShowLilypond
   %% ?? temp export these ? clean things up once..
   LilyMakePitch LilyMakeFromMidiPitch
   LilyMakeRhythms LilyMakeMicroPitch LilyMakeEt72MarkFromMidiPitch
   MakeNoteToLily
   OutputSCScore MakeSCScore MakeSCEventOutFn
   SendOsc SendSCserver SendSClang
   ToNonmensuralENP OutputNonmensuralENP
   ToFomus OutputFomus RenderFomus
   MakeCMEvent MakeCMScore OutputCMScore
   ToDottedList LispList % LispKeyword
   RecordToLispKeywordList ToLispKeywordList
   OzToLisp
   Note2ClmP MakeClmScoreFn
   PlaySound
   Exec ExecNonQuitting ExecWithOutput
   Shell

   Midi
   
define
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% General stuff
%%%

   /** %% Writes/overwrites Output (a virtual string) to file at Path.
   %% */
   %% TODO: 
   %% !! how to ensure that {File close} is called, ie. how to
   %% 'unwind-protect'
   /*
   try  
      {Process F}
   catch X then {Browse '** '#X#' **'}  
   finally {CloseFile F} end
   */
   proc {WriteToFile Output Path}
      File = {New Open.file  
	      init(name: Path
		   flags: [write create truncate text]
		   mode: mode(owner: [read write]  
			      group: [read write]))}
   in
      {System.showInfo "writing to "#Path}
      {File write(vs:Output)}
      {File close}
   end
   /** %% Reads the content of the text file at Path and returns it as string.
   %% */
   %% !! this should go into some functor Input.oz
   proc {ReadFromFile Path ?Result}
      File = {New Open.file init(name: Path)}
   in
      {System.showInfo "reading from "#Path}
      {File read(list:Result
		 size:all)}
      %% !! how to ensure that {File close} is called, ie. how to
      %% 'unwind-protect'
      {File close}
   end

   local
      fun {Domain2VS X}
	 if {IsList X}
	 then "["#{ListToVS {Map X Domain2VS} ' '}#"]"
	 else case X of A#B
	      then A#"#"#B
	      else X
	      end
	 end
      end
   in
      /** %% Transforms a (possibly nested) record into a single virtual string with Oz record syntax. RecordToVS also transforms the special Oz records with the labels '|' (i.e. lists) and '#' into their shorthand syntax. However, the virtual string output is not indented, every record feature (or list element) starts a new line. As the output is basically a text value (i.e. no 'normal' Oz value anymore), FD and FS variables are transformed into a constructor call (FD.int and FS.var.bounds) which would create these variables when evaluated. 
      %% NB: Value.toVirtualString does something very similar: it transforms nested data into their print representation. Instead, RecordToVS does not expect any max width/depth arguments and attempts to format the output. 
      %% NB: if X (or some value in X) is not of any of the types record (or list or #-pair) or virtual string, Value.toVirtualString is called on this value.
      %%
      %% */
      fun {RecordToVS X}
	 if {IsDet X} then
	    if {IsVirtualString X} then X
	    elseif {IsRecord X} andthen {Arity X} \= nil
	    then L = {Label X}
	    in
	       case L
	       of '|' then '['#{ListToLines {Map X RecordToVS}}#"]"
	       [] '#' then {ListToVS {Map {Record.toList X} RecordToVS} "#"} 
	       else {RecordToVS L}#"("
		  #{ListToLines 
		    {Map {Arity X}
		     fun {$ Feat}
			if {IsNumber Feat}
			then {RecordToVS X.Feat}
			else Feat#":"#{RecordToVS X.Feat}
			end
		     end}}
		  #")"
	       end
	    elseif {GUtils.isFS X}
	    then {VirtualString.toString
		  '{FS.var.bounds '
		  #{Domain2VS {FS.reflect.lowerBound X}}#' '
		  #{Domain2VS {FS.reflect.upperBound X}}#'}'}
	       %% determined other values
	    else {Value.toVirtualString X 10 1000}
	    end
	 elseif {IsFree X} then "_"
	 elseif {FD.is X} then {VirtualString.toString
				  '{FD.int '#{Domain2VS {FD.reflect.dom X}}#'}'}
	 elseif {GUtils.isFS X}
	 then {VirtualString.toString
	       '{FS.var.bounds '
	       #{Domain2VS {FS.reflect.lowerBound X}}#' '
	       #{Domain2VS {FS.reflect.upperBound X}}#'}'}
	    %% undetermined other values
	 else {Value.toVirtualString X 10 1000}
	 end
      end
   end
   
   /** % Transforms Xs, a list of virtual strings, into a single virtual string. Delimiter is the virtual string between all list elements.
   %% */
   fun {ListToVS Xs Delimiter}
      case Xs
      of nil then nil
      [] X|nil then X
      [] X|Tail then X#Delimiter#{ListToVS Tail Delimiter}
      end
   end


   %% old defs kept for reference for a while, just in case 
   %%
%    /** % Transforms a list of virtual strings into a single virtual string without any sign between the list elements.
%    %% */
%    fun {ListToVS2 Xs}
%       {ListToVS Xs ''}
% %       case Xs
% %       of X|nil then X
% %       [] X|Tail then X#{ListToVS2 Tail}
% %       [] nil then nil
% %       end
%    end
%    /** % Transforms a list of virtual strings into a single virtual string with a single whitespace between the list elements.
%    %% */
%    fun {ListToVS3 Xs}
%       {ListToVS Xs " "}
% %       case Xs
% %       of X|nil then X
% %       [] X|Tail then X#" "#{ListToVS Tail}
% %       [] nil then nil
% %       end
%    end
   
   
   /** % Transforms a list of virtual strings into a single virtual string, every list element starts at a new line.
   %% */
   %% !! handle case Xs=nil
   fun {ListToLines Xs}
      {ListToVS Xs "\n"}
%       case Xs
%       of X|nil then X
%       [] X|Tail then X#"\n"#{ListToLines Tail}
%       [] nil then nil
%       end
   end

   /** %% [Temp def? Def. not general enough] MakeEventlist generates a virtual string for output from Score. The unary function EventOut generates the output of a single event. The binary function ScoreOut combines all events to a score.
   %% */
   fun {MakeEventlist Score EventOut ScoreOut}
      % Test is a predicate to filter 
      Test = fun {$ X}
		{X isEvent($)} andthen {X isDet($)} andthen
		({X getDuration($)} > 0)
	     end 		
      Events = {Score collect($ test:Test)}
   in
      %% !! proper call ??
      {ScoreOut Score {Map Events EventOut}}
   end
   /** %% [Temp def -- use WriteToFile directly instead] OutputEventlist transforms Score for output and outputs it at Path. The unary function EventOut generates the output of a single event. The binary function ScoreOut combines all events to a score.
   %% */
   proc {OutputEventlist Score EventOut ScoreOut Path}
      {WriteToFile {MakeEventlist Score EventOut ScoreOut}
       Path}
   end

   /** %% Transforms MyScore (a Strasheela score) into a list of events. Specs is a list of pairs in the form [Test1#Transform1 ...]. Each Test is a unary function (or method) expecting a score object and returning a boolean. Each Transform is a unary function expecting a score object and returning a list of events.
   %% The record Args expects the only optional argument test, a unary boolean function used to filter the set of score objects in MyScore: only  objects for which the test returns true are considered for processing. This test defaults to
   fun {Test X} {X isEvent($)} andthen {X isDet($)} andthen {X getDuration($)} > 0 end
   %%  For every score object in MyScore which passes this Test, the appropriate Test#Transform pair is found out (i.e. the first pair whose test returns true for the score object). If no matching pair is found, the object is skipped. Otherwise, the respective Transform is applied to this score object and the result appended to the full result of ScoreToEvents.
   %% The following example implements a simple Strasheela score -> Csound score transformation. Only the notes in the Strasheela score are considered (everything else is ignored) and these notes are transformed into a csound score event.
   {Out.scoreToEvents MyScore [isNote#fun {$ MyNote}
					 [{Out.listToVS
					   [i1
					    {MyNote getStartTimeInSeconds($)}
					    {MyNote getDurationInSeconds($)}
					    {MyNote getPitchInMidi($)}
					    {MyNote getAmplitudeInVelocity($)}]
					   " "}]
				      end]
    unit}
   
   %% For example, the result returned could look like this:
   ["i1 0.0 1.0 60.0"
    "i1 1.0 2.0 62.0"
    "i1 2.0 4.0 64.0"]
   
   %% */
   fun {ScoreToEvents MyScore Specs Args}
      Defaults = unit(test:fun {$ X}
			      {X isEvent($)} andthen {X isDet($)} andthen
			      ({X getDuration($)} > 0)
			   end)
      As = {Adjoin Defaults Args}
      %% process MyScore as well, if it fits test
      ScoreObjects = {Append if {As.test MyScore} then [MyScore] else nil end
		      {MyScore collect($ test:As.test)}}
   in
      {LUtils.mappend ScoreObjects
       fun {$ X}
	  Matching = {LUtils.find Specs
		      fun {$ Test#_}
			 {{GUtils.toFun Test} X}
		      end}
       in if Matching == nil
	  then nil
	  else 
	     _#Transform = Matching
	  in
	     {{GUtils.toFun Transform} X}
	  end
       end}
%       %%
%       {MyScore mappend($ fun {$ X}
% 			    Matching = {LUtils.find Specs
% 					fun {$ Test#_}
% 					   {{GUtils.toFun Test} X}
% 					end}
% 			 in if Matching == nil
% 			    then nil
% 			    else 
% 			       _#Transform = Matching
% 			    in
% 			       {{GUtils.toFun Transform} X}
% 			    end
% 			 end
% 		       test:As.test)}
   end
   
   
   
   /** %% [Temp def? Def. not general enough] Translates Score into some hierarchic score (a tree, not a graph) for output. EventOut, SimOut, and SeqOut are all functions which output a VS representation of the output format. The functions SimOut and SeqOut return something in the form [BeginVS Delimiter EndVS] -- the representation of their items will be placed between these "tags". FurtherClauses is a list to define additional output alternatives as in the form [testFnOrMeth1#Fn1 ..]. 
   %% */
   %% TODO: redefine using GUtils.cases
   %% this def is used by MakeSCScore but Lily output could use this as well
%    fun {MakeHierarchicVSScore Score EventOut SimOut SeqOut}
%       fun {TransformContainer Score Fn}
% 	 [Begin Delimiter End] = {Fn Score}
% 	 Items = {Map {Score getItems($)}
% 		  fun {$ X}
% 		     {MakeHierarchicVSScore X EventOut SimOut SeqOut}
% 		  end}
% 	 DelimitedItems = {ListToVS2
% 			   Items.1 | {List.map Items.2
% 				      fun {$ X} Delimiter#X end}}
%       in
% 	 Begin#DelimitedItems#End
%       end
%    in
%       if {Score isSimultaneous($)}
%       then {TransformContainer Score SimOut}
%       elseif {Score isSequential($)}
%       then {TransformContainer Score SeqOut}
%       elseif {Score isEvent($)}
%       then
% 	 if {Score isDet($)}
% 	 then {EventOut Score}
% 	    %% [?? general enough] output empty atom for undetermined events
% 	 else ''		
% 	 end
%       else
% 	 %raise unsupportedClass(Score MakeHierarchicVSScore) end
% 	 {Browse warn#unsupportedClass(Score MakeHierarchicVSScore)}
% 	 ''
%       end
%    end
   fun {MakeHierarchicVSScore Score EventOut SimOut SeqOut FurtherClauses}
      fun {TransformContainer Score Fn}
	 [Begin Delimiter End] = {Fn Score}
	 Items = {Map {Score getItems($)}
		  fun {$ X}
		     {MakeHierarchicVSScore X EventOut SimOut SeqOut FurtherClauses}
		  end}
	 DelimitedItems = {ListToVS
			   Items.1 | {List.map Items.2
				      fun {$ X} Delimiter#X end}
			   ""}
      in
	 Begin#DelimitedItems#End
      end
   in
      {GUtils.cases Score
       {Append FurtherClauses
	[%% return empty VS for everything of dur =< 0
	 fun {$ X} ({X getDuration($)} =< 0) end#fun {$ X} {Browse hi} '' end
	 isSimultaneous#fun {$ X} {TransformContainer X SimOut} end
	 isSequential#fun {$ X} {TransformContainer X SeqOut} end
	 isEvent#fun {$ X}
		    if %% !! event must be fully determined 
		       {X isDet($)} 
		    then {EventOut X} 
		       %% [?? general enough] output empty atom for undetermined events
		    else ''		
		    end
		 end
	 fun {$ X} true end
	 #fun {$ X} 
	     %%raise unsupportedClass(Score MakeHierarchicVSScore) end
	     {Browse warn#unsupportedClass(Score MakeHierarchicVSScore)}
	     ''
	  end]}}
   end

   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Oz record output
%%%

   
   /** %% Creates an Oz program (as a VS) which re-constructs MyScore.
   %% */
   fun {ToScoreConstructor MyScore Spec}
      Defaults = unit(prefix:"declare \n MyScore \n = {Score.makeScore\n")
      Args = {Adjoin Defaults Spec}
      StartTime = {MyScore getStartTime($)}
      TimeUnit = {MyScore getTimeUnit($)}   
   in
      if {Not {IsDet StartTime}}
      then {GUtils.warnGUI "warn: undetermined toplevel startTime"}
      end
      if {Not {IsDet TimeUnit}}
      then {GUtils.warnGUI "warn: undetermined timeUnit"}
      end
      %% NB: RecordToVS can handle undetermined variables
      Args.prefix
      #{RecordToVS
	{Adjoin unit(startTime:StartTime
		     timeUnit:TimeUnit)
	 {MyScore toInitRecord($)}}}
      #"\n"#{MyScore getInitClassesVS($)}#"}"
   end
   
   /** %% Stores an Oz program in a file which re-constructs MyScore. For example, this file can also be used for editing purposes. 
   %% */
   %% !! renamed, was: OutputInitRecord
   proc {OutputScoreConstructor MyScore Spec}
      Defaults = unit(file:"test"
		      extension:".ssco"
		      dir:{Init.getStrasheelaEnv defaultSScoDir}
		      %% prefix/postfix defaults defined in ToArchiveInitRecord
		     )
      Args = {Adjoin Defaults Spec}
      Path = Args.dir#Args.file#Args.extension
   in
      {WriteToFile
       '%% -*- mode: oz -*-\n'#
       {ToScoreConstructor MyScore Args}
       Path}
      %% !! BUG: script does not work yet when called from Oz, when called in shell it works fine..
      %%
      %% ksprotte, svn commit r48, Tue, 05 Sep 2006: 
      %%
      %% Init record should now be auto-indented (see below)
      %% Not sure if this works better on linux...
      %%
      %% On osx I get the following error in the OZemulator:
      %%      
      %% writing to /tmp/out3.ssco
      %% > /Users/paul/src/strasheela/scripts/ozindent.sh /tmp/out3.ssco
      %% Formatting /tmp/out3.ssco
      %% Cannot open load file: /Applications/Emacs.app/Contents/MacOS/libexec/fns-21.2.1.el
      %%
      %% The invocation of the script from the shell works, of course :)
      %%
      %% Not sure, what to do here, will remove it again from the archive
      %% init record function of no success.
      %%
      %%
      %% T Anders (9 August 2007): more info on fns-21.2.1.el
      %%
      %% http://www.interopcommunity.com/tm.aspx?m=10583
      %% http://www.cse.huji.ac.il/support/emacs/elisp-help/elisp-manref/elisp_15.html#SEC199
      %%
      %% still, no idea how to fix this
      %%
      %% the file fns-21.2.1.el is loaded by emacs function symbol-file 
      %%
      %% Plainly doing emacs --batch already shows the problem
      {Exec {Init.getStrasheelaEnv strasheelaDir}#'/scripts/ozindent.sh' [Path]}
   end

   /** %% Saves MyScore into a text file which can be compiled and loaded again later with LoadScore.
   %% NB: SaveScore internally uses toInitRecord (because a stateful data structure like an object can not be pickled). Therefore, all present restrictions of toInitRecord apply:  getInitInfo must be defined correctly for all classes and only tree-form score topologys are supported.

%   %% Saves MyScore into a pickle which can be loaded again later with LoadScore.
%   %% NB: Only a fully determiend score can be pickled, otherwise an exception is raised.
   %% */
   %% A pickle is not used, because undetermined variables can not be pickled.
   proc {SaveScore MyScore Args}
      {OutputScoreConstructor MyScore
       {Adjoin Args unit(prefix:"{Score.makeScore\n")}}
   end

   local
      %% full Oz environemnt (copied from contributions/anders/OzServer/source/Compilter.oz)
      %% plus Strasheela core environment
      % Browse and Inspect were already defined above
      ExploreAll = Explorer.all
      ExploreBest = Explorer.best
      ExploreOne = Explorer.one
      SearchAll = Search.base.all
      SearchBest = Search.base.best
      SearchOne = Search.base.one
      Print = System.print
      Show = System.show
      Load = Pickle.load
      Save = Pickle.save
      Apply = Module.apply
      Link = Module.link
      BaseObject = Object.base 
      %% 
      CompilerEnvironment = env('Abs': Abs
				'Access': Access
				'Acos': Acos
				'Adjoin': Adjoin
				'AdjoinAt': AdjoinAt
				'AdjoinList': AdjoinList
				'Alarm': Alarm
				'All': All
				'AllTail': AllTail
				'And': And
				'Append': Append
				'Application': Application
				'Apply': Apply
				'Arity': Arity
				'Array': Array
				'Asin': Asin
				'Assign': Assign
				'Atan': Atan
				'Atan2': Atan2
				'Atom': Atom
				'AtomToString': AtomToString
				'BaseObject': BaseObject
				'BitArray': BitArray
				'BitString': BitString
				'Bool': Bool
				'Browse': Browse
				% 'Browser': Browser
				'ByNeed': ByNeed
				'ByNeedFuture': ByNeedFuture
				'ByteString': ByteString
				'Ceil': Ceil
				'Cell': Cell
				'Char': Char
				'Chunk': Chunk
				'Class': Class
				'Combinator': Combinator
				'Compiler': Compiler
				'CompilerPanel': CompilerPanel
				'CondSelect': CondSelect
				'Connection': Connection
				'Cos': Cos
				'DPControl': DPControl
				'DPInit': DPInit
				'DPStatistics': DPStatistics
				'DefaultURL': DefaultURL
				'Delay': Delay
				'Dictionary': Dictionary
				'Discovery': Discovery
				'DistributionPanel': DistributionPanel
				'Emacs': Emacs
				'Error': Error
				'ErrorListener': ErrorListener
				'ErrorRegistry': ErrorRegistry
				'EvalDialog': EvalDialog
				'Exception': Exception
				'Exchange': Exchange
				'Exp': Exp
				'ExploreAll': ExploreAll
				'ExploreBest': ExploreBest
				'ExploreOne': ExploreOne
				'Explorer': Explorer
				'FD': FD
				'FS': FS
				'Fault': Fault
				'Filter': Filter
				'Finalize': Finalize
				'Flatten': Flatten
				'Float': Float
				'FloatToInt': FloatToInt
				'FloatToString': FloatToString
				'Floor': Floor
				'FoldL': FoldL
				'FoldLTail': FoldLTail
				'FoldR': FoldR
				'FoldRTail': FoldRTail
				'For': For
				'ForAll': ForAll
				'ForAllTail': ForAllTail
				'ForThread': ForThread
				'ForeignPointer': ForeignPointer
				'Functor': Functor
				'Get': Get
				'Gump': Gump
				'GumpParser': GumpParser
				'GumpScanner': GumpScanner
				'HasFeature': HasFeature
				'Inspect': Inspect
				% 'Inspector': Inspector
				'Int': Int
				'IntToFloat': IntToFloat
				'IntToString': IntToString
				'IsArray': IsArray
				'IsAtom': IsAtom
				'IsBitArray': IsBitArray
				'IsBitString': IsBitString
				'IsBool': IsBool
				'IsByteString': IsByteString
				'IsCell': IsCell
				'IsChar': IsChar
				'IsChunk': IsChunk
				'IsClass': IsClass
				'IsDet': IsDet
				'IsDictionary': IsDictionary
				'IsEven': IsEven
				'IsFailed': IsFailed
				'IsFloat': IsFloat
				'IsForeignPointer': IsForeignPointer
				'IsFree': IsFree
				'IsFuture': IsFuture
				'IsInt': IsInt
				'IsKinded': IsKinded
				'IsList': IsList
				'IsLiteral': IsLiteral
				'IsLock': IsLock
				'IsName': IsName
				'IsNat': IsNat
				'IsNeeded': IsNeeded
				'IsNumber': IsNumber
				'IsObject': IsObject
				'IsOdd': IsOdd
				'IsPort': IsPort
				'IsProcedure': IsProcedure
				'IsRecord': IsRecord
				'IsString': IsString
				'IsThread': IsThread
				'IsTuple': IsTuple
				'IsUnit': IsUnit
				'IsVirtualString': IsVirtualString
				'IsWeakDictionary': IsWeakDictionary
				'Label': Label
				'Length': Length
				'Link': Link
				'List': List
				'Listener': Listener
				'Literal': Literal
				'Load': Load
				'Lock': Lock
				'Log': Log
				'Loop': Loop
				'Macro': Macro
				'MakeList': MakeList
				'MakeRecord': MakeRecord
				'MakeTuple': MakeTuple
				'Map': Map
				'Max': Max
				'Member': Member
				'Merge': Merge
				'Min': Min
				'Module': Module
				'Name': Name
				'Narrator': Narrator
				'New': New
				'NewArray': NewArray
				'NewCell': NewCell
				'NewChunk': NewChunk
				'NewDictionary': NewDictionary
				'NewLock': NewLock
				'NewName': NewName
				'NewPort': NewPort
				'NewWeakDictionary': NewWeakDictionary
				'Not': Not
				'Nth': Nth
				'Number': Number
				'OPI': OPI
				'OPIEnv': OPIEnv
				'OPIServer': OPIServer
				'OS': OS
				'Object': Object
				'ObjectSupport': ObjectSupport
				'Open': Open
				'Or': Or
				'OsTime': OsTime
				'Ozcar': Ozcar
				'OzcarClient': OzcarClient
				'Panel': Panel
				'Pickle': Pickle
				'Port': Port
				'Pow': Pow
				'Print': Print
				'Procedure': Procedure
				'ProcedureArity': ProcedureArity
				'Profiler': Profiler
				'Property': Property
				'Put': Put
				'Raise': Raise
				'Record': Record
				'RecordC': RecordC
				'Remote': Remote
				'Resolve': Resolve
				'Reverse': Reverse
				'Round': Round
				'Save': Save
				'Schedule': Schedule
				'Search': Search
				'SearchAll': SearchAll
				'SearchBest': SearchBest
				'SearchOne': SearchOne
				'Send': Send
				'Service': Service
				'Show': Show
				'Sin': Sin
				'SiteProperty': SiteProperty
				'Some': Some
				'Sort': Sort
				'Space': Space
				'Sqrt': Sqrt
				'String': String
				'StringToAtom': StringToAtom
				'StringToFloat': StringToFloat
				'StringToInt': StringToInt
				'System': System
				'Tan': Tan
				'Thread': Thread
				'Time': Time
				'Tix': Tix
				'Tk': Tk
				'TkTools': TkTools
				'Tuple': Tuple
				'Type': Type
				'URL': URL
				'Unit': Unit
				'Value': Value
				'VirtualSite': VirtualSite
				'VirtualString': VirtualString
				'Wait': Wait
				'WaitNeeded': WaitNeeded
				'WaitOr': WaitOr
				'WeakDictionary': WeakDictionary
				'Width': Width
				%%	   
				%% Strasheela stuff
				%%'StrasheelaDemos':StrasheelaDemos
				'Init':Init 'GUtils':GUtils 'LUtils':LUtils 'MUtils':MUtils
				'Score':Score
				% 'SDistro':SDistro
				% 'Out':Out % .. would be recursive?
			       )
   in
      /** %% Loads a pickeled score from path.
      %% NB: If the class definitions for the classes used in the score will have changed meanwhile, the loaded score will still use the new class definitions (it is re-created from the textual specification). 
      %% */
      fun {LoadScore Args}
	 Defaults = unit(file:"test"
			 extension:".ssco"
			 dir:{Init.getStrasheelaEnv defaultSScoDir})
	 As = {Adjoin Defaults Args}
	 Path = As.dir#As.file#As.extension
	 VS = {ReadFromFile Path}
	 %% !!?? this environment may not be sufficient..
	 Env = {Adjoin CompilerEnvironment
		{Init.getStrasheelaEnv strasheelaFunctors}}
      in
	 {Compiler.evalExpression VS Env _}
      end
   end
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Csound output related stuff
%%%

   /** % Outputs unary function which transforms an Score.event into a csound note virtual string. 
   %% Spec is a list of accessor functions/methods. However, for every accessor function/method a transformation function/method for the accessed data can be specified using the syntax Accessor#Transformator. All accessors mmust return a parameters (e.g. use getPitchParameter instead of getPitch).
   %% */
   %%
   %% !! not general enough, e.g., parameter units are ignored. Idea
   %% Spec is either some method (e.g. an accessor) or some unary
   %% function which gets object as arg.
   fun {MakeEvent2CsoundFn Instrument Spec}
      fun {$ X}
	 {ListToVS
	  {Append
	   [i#Instrument]
	   {Map Spec
	    fun {$ Y}
	       case Y of ParamAccessor#Transformator
	       then {{GUtils.toFun Transformator}
		     {{GUtils.toFun ParamAccessor} X}}
	       else
		  ParamAccessor = Y
	       in
		  {{{GUtils.toFun ParamAccessor} X} getValue($)}
	       end
	    end}}
	  " "}
      end
   end
   /** % Returns a Csound score as a virtual string. EventVSs is a note list. Each note is a virtual string. Header is the Csound header, e.g. f statements.
   %% */
   fun {MakeCsoundScore EventVSs Header}
      Header#"\n\n"#{ListToLines EventVSs}
   end

   
%       fun {TimeToSeconds Param}
% 	 {Param getValueInSeconds($)}
%       end
   
   /** % Create a csound score file of MyScore, but only include fully determined events. The defaults for Spec are:
   unit(file:"test" % without extension
	scoDir:{Init.getStrasheelaEnv defaultCsoundScoDir}
	header:nil
	event2CsoundFn:&lt;see source&gt;
	test:&lt;see source&gt;)
   %% header is the csound header VS (e.g. for f-tables).
   %% The default event2CsoundFn of OutputCsoundScore supports parameter unit specifications for the transformation process (see the Parameter documentation). Without determined Parameter unit the unit defaults to seconds for TimeParameters and midi for Pitches. The event2CsoundFn always returns seconds and midi pitches. 
   always transforms timing parameters into seconds and 
   %% */
   proc {OutputCsoundScore MyScore Spec}
      Defaults = unit(file:"test"
		      scoDir:{Init.getStrasheelaEnv defaultCsoundScoDir}
		      header:nil
		      event2CsoundFn:{MakeEvent2CsoundFn 1
				      [getStartTimeParameter#getValueInSeconds
				       getDurationParameter#getValueInSeconds
				       getAmplitudeParameter#getValueInNormalized
				       getPitchParameter#getValueInMidi]}
		      test:fun {$ X}
			      {X isEvent($)} andthen {X isDet($)} andthen
			      ({X getDuration($)} > 0)
			   end)
      Args = {Adjoin Defaults Spec}
      Tempo = "\n\nt 0 "#{Init.getTempo}
      Header = if Args.header == nil
	       then nil
	       else "\n\n"#Args.header
	       end
   in
      {WriteToFile
       {MakeCsoundScore
	{Map {MyScore collect($ test:Args.test)} Args.event2CsoundFn}
	";;; created by Strasheela at "#{GUtils.timeVString}#Header#Tempo}
       Args.scoDir#Args.file#".sco"}
   end
   
   /** % Calls Csound with args in Spec and writes Csound messages on standard output (Oz emulator). Spec is a record with optional arguments. The defaults are:
   unit(orc:{Init.getStrasheelaEnv defaultOrcFile} % with extension!, e.g. "pluck.orc"
	file:"test" % without extension!
	soundExtension:{Init.getStrasheelaEnv defaultCsoundSoundExtension} % ".aiff"
	orcDir:{Init.getStrasheelaEnv defaultCsoundOrcDir}
	scoDir:{Init.getStrasheelaEnv defaultCsoundScoDir}
	soundDir:{Init.getStrasheelaEnv defaultSoundDir}
	csound:{Init.getStrasheelaEnv csound}
	flags:{Init.getStrasheelaEnv defaultCsoundFlags})
   %% */
   proc {CallCsound Spec}
      Defaults = unit(orc:{Init.getStrasheelaEnv defaultOrcFile} %"pluck.orc"
		      file:"test"
		      soundExtension:{Init.getStrasheelaEnv defaultCsoundSoundExtension} % ".aiff"
		      orcDir:{Init.getStrasheelaEnv defaultCsoundOrcDir}
		      scoDir:{Init.getStrasheelaEnv defaultCsoundScoDir}
		      soundDir:{Init.getStrasheelaEnv defaultSoundDir}
		      csound:{Init.getStrasheelaEnv csound}
		      flags:{Init.getStrasheelaEnv defaultCsoundFlags})
      MySpecs = {Adjoin Defaults Spec}
      OrcPath = MySpecs.orcDir#MySpecs.orc
      ScoPath = MySpecs.scoDir#MySpecs.file#".sco"
      SoundPath = MySpecs.soundDir#MySpecs.file#MySpecs.soundExtension
      Flags = {GUtils.selectArg flags Spec Defaults}
      %% !! Open.pipe is very picky with input format: no
      %% additional whitespace and separate flags either as
      %% separate atoms or without any hyphen between them -- try
      %% later to generalise Flags arg
	 % Pipe 
   in
% 	 %% output command
% 	 {System.showInfo
% 	  {ListToVS
% 	   ['>' CSoundApp Flags '-o '#SoundPath OrcPath ScoPath]}}
% 	 Pipe = {New Open.pipe
% 		      init(cmd:CSoundApp
% 			   args:[Flags "-o "#SoundPath OrcPath ScoPath])}
% 	 {System.showInfo
% 	  {Pipe read(list:$ size:all)}}
%       %{Pipe flush}		% wait until csound is finished
% 	 {Pipe close}      
      {Exec MySpecs.csound {Append Flags ['-o' SoundPath OrcPath ScoPath]}}
   end

   /** % Creates a csound score of all (determined) events in MyScore, and renders the score. See the documentation of OutputCsoundScore, CallCsound, and PlaySound for arguments in Spec (the PlaySound argument extension is substituted by the argument soundExtension).
   %% */
   proc {RenderCsound MyScore Spec}	 
      Defaults = unit(test:fun {$ X}
			      {X isEvent($)} andthen {X isDet($)}
			   end
		      soundExtension:{Init.getStrasheelaEnv defaultCsoundSoundExtension})
      MySpec = {Adjoin Defaults Spec}
      Events = {MyScore collect($ test:MySpec.test)}
   in
      if Events \= nil then
	 {OutputCsoundScore MyScore MySpec}
	 {CallCsound MySpec}
      end
   end

     /** % Creates a csound score of all (determined) events in MyScore, renders the score and plays the resulting sound. See the documentation of OutputCsoundScore, CallCsound, and PlaySound for arguments in Spec (the PlaySound argument extension is substituted by the argument soundExtension).
   %% */
   proc {RenderAndPlayCsound MyScore Spec}
      Defaults = unit(test:fun {$ X}
			      {X isEvent($)} andthen {X isDet($)}
			   end
		      soundExtension:{Init.getStrasheelaEnv defaultCsoundSoundExtension})
      MySpec = {Adjoin Defaults Spec}
      Events = {MyScore collect($ test:MySpec.test)}
   in
      if Events \= nil then
	 {RenderCsound MyScore MySpec}
	 {PlaySound {Adjoin MySpec unit(extension: MySpec.soundExtension)}}
      else {System.showInfo "Warning: no events in Csound score. Are events fully determined?"}
      end
   end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Lilypond output related stuff
%%%

   
   %% !! important TODO:
   %%
   %% * OK? pos. offset in Sim and Seq
   %%
   %% * microtonal notation
   %%
   %% * calc clef def by average of contained pitches
   %%
   %%
   %% clean up, generalise (some funcs as args) and enter into SDL
   %% source
   
   BeatsPerQuarterNote = 1.0		% !! arg
   IdxFactor = 64.0
   %%
   %%
   %% !! I may easily add quarternote accidentials 
   LilyPCs = pcs(c cis d 'dis' e f fis g gis a ais b)
   LilyOctaves = octs(",,,," ",,," ",," "," "" "'" "''" "'''" "''''")
   fun {BeatsToIdx Beats}		% Beats is float
      {FloatToInt Beats * BeatsPerQuarterNote * IdxFactor}
   end
   fun {BeatSpecToIdx BeatSpec}
      {FloatToInt BeatSpec * IdxFactor}
   end
   proc {MakeLilyRhythm Result}
      %% this determines IdxFactor (IdxFactor * 0.109375 = 7.0,
      %% i.e. can be integer)
      Spec = [[16.0 " \\longa "]
	      [8.0 " \\breve "]
	      [4.0 1] [6.0 "1."] [7.0 "1.."]
	      [2.0 2] [3.0 "2."] [3.5 "2.."]
	      [1.0 4] [1.5 "4."] [1.75 "4.."]
	      [0.5 8] [0.75 "8."] [0.825 "8.."]
	      [0.25 16] [0.375 "16."] [0.4375 "16.."]
	      [0.125 32] [0.1875 "32."] [0.21875 "32.."]
	      [0.0625 64] [0.09375 "64."] [0.109375 "64.."]]
      Feats = {Map Spec fun {$ [Feat _]} {BeatSpecToIdx Feat} end}
   in
      Result = {MakeRecord rhythms Feats}
      {ForAll Spec proc {$ [Feat Val]} Result.{BeatSpecToIdx Feat} = Val  end}
   end
   LilyRhythms = {MakeLilyRhythm}
   %% all un-punctuated BeatIndices 
   LilyRhythmIdxs = {Map [16.0 8.0 4.0 2.0 1.0 0.5 0.25 0.125] BeatSpecToIdx}
   SmallesRhythmIdxs = {BeatSpecToIdx 0.125}
   fun {LilyMakeRhythms DurationParam}
      %% returns a list of Lilypond rhythm values, which are tied together 
      {MakeRhythmsAux {BeatsToIdx {DurationParam getValueInBeats($)}}}
   end
   fun {MakeRhythmsAux BeatIdx}
      %% create a list of note durations, dots and ties
      if BeatIdx < SmallesRhythmIdxs % stop condition 
      then nil
      elseif {HasFeature LilyRhythms BeatIdx}
      then [ LilyRhythms.BeatIdx ]
      else				% tied notes: 
	 %% find biggest LilyRhythms index smaller IdxBeat
	 BiggestSubRhythm = {LUtils.find LilyRhythmIdxs
			     fun {$ X} BeatIdx > X end}
      in
	 LilyRhythms.BiggestSubRhythm | {MakeRhythmsAux BeatIdx-BiggestSubRhythm}
      end
   end
   %% !!?? temp fix
   fun {LilyMakeMicroPitch PitchParam}
      %% et72: represent 12th notes by fingering marks
      if {PitchParam getUnit($)} == et72
      then {LilyMakeEt72MarkFromMidiPitch {PitchParam getValueInMidi($)}}
      else ''
      end
   end
%    /** %% Returns a Lily fingering mark (a virtual string) which represents a micro-tonal tuning deviation in 72ET temperament.
%    %% */
%    fun {LilyMakeEt72MarkFromMidiPitch MidiPitch}
%       Marks = unit("-0" "-1" "-2" "-3" "-4" "-5" "-6")
%       %Pitch = {PitchParam getValueInMidi($)}
%       Micro = {FloatToInt ((MidiPitch - {Round MidiPitch}) * 6.0)} + 4
%    in
%       Marks.Micro
%    end
   /** %% Returns a Lily fingering mark (a virtual string) which represents a micro-tonal tuning deviation in 72ET temperament.
   %% */
   fun {LilyMakeEt72MarkFromMidiPitch MidiPitch}
      Marks = unit(%% !!?? alternative sign for quarter note flat?
		   %% combination of + and - as advocated by Hans Zender
		   "^\\markup{\\override #\'(baseline-skip . 1) \\column <-- -- -->}"
		   "^\\markup{\\override #\'(baseline-skip . 1) \\column <-- -->}"
		   "^\\markup{--}"
		   ""
		   "^\\markup{+}"
		   "^\\markup{\\override #\'(baseline-skip . 1) \\column <+ +>}"
		   "^\\markup{\\override #\'(baseline-skip . 1) \\column <+ + +>}"
		   %% Manuel Op de Coul's version of HEWM (www.tonalsoft.com/enc/h/hewm.aspx)
% 		   "^\\markup{v}"
% 		   "^\\markup{L}"
% 		   "^\\markup{"\\"}" % this causes Lily problems
% 		   ""
% 		   "^\\markup{/}"
% 		   "^\\markup{7}"
% 		   "^\\markup{^}"
		   %%  edited version of Manuel Op de Coul's HEWM (because of Lily problems with \)
% 		   "^\\markup{v}"
% 		   "^\\markup{L}"
% 		   "^\\markup{-}" 
% 		   ""
% 		   "^\\markup{+}"
% 		   "^\\markup{7}"
% 		   "^\\markup{"\^"}"
		  )
      %Pitch = {PitchParam getValueInMidi($)}
      Micro = {FloatToInt ((MidiPitch - {Round MidiPitch}) * 6.0)} + 4
   in
      Marks.Micro
   end
   fun {LilyMakePitch PitchParam}
      %% create pitchClass and octave expression
      %% !! unit must be bound
      MidiPitch = {FloatToInt {PitchParam getValueInMidi($)}}
   in
      {LilyMakeFromMidiPitch MidiPitch}
   end
   fun {LilyMakeFromMidiPitch MidiPitch}
      PC = {Int.'mod' MidiPitch 12} + 1
      Oct = {Int.'div' MidiPitch 12} + 1
   in
      LilyPCs.PC#LilyOctaves.Oct
   end
   %% !! What about notating Events (e.g. percussion notation)
   %% !! Notate explicite Pauses.
   %% !! TODO: angleichen die verschiedenen Funs
   /** %% Returns unary function expecting note. MakeAddedSigns is unary fun expecting the note and returning VS of arbitrary added signs (e.g. fingering marks, articulation marks etc.)
   %% */
   fun {MakeNoteToLily MakeAddedSigns}
      fun {$ Note}
	 Rhythms = {LilyMakeRhythms {Note getDurationParameter($)}}
      in
	 if Rhythms == nil
	 then ''
	 else  
	    Pitch = {LilyMakePitch {Note getPitchParameter($)}}
	    AddedSigns = {MakeAddedSigns Note}
	    FirstNote = Pitch#Rhythms.1#AddedSigns
	    % MicroPitch = {LilyMakeMicroPitch {Note getPitchParameter($)}}  % ?? temp fix?
	    % FirstNote = Pitch#Rhythms.1#MicroPitch
	 in
	    %% !! ?? generalise (needed elsewhere)
	    if {Length Rhythms} == 1
	    then FirstNote
	       %% all values in Rhythm.2 are tied to predecessor
	    else FirstNote#{ListToVS
			    {Map Rhythms.2
			     fun {$ R}
				" ~ "#Pitch#R#AddedSigns
				%" ~ "#Pitch#R#MicroPitch
			     end}
			    " "}
	    end
	 end
      end
   end
%    fun {NoteToLily Note}
%       Rhythms = {LilyMakeRhythms {Note getDurationParameter($)}}
%    in
%       if Rhythms == nil
%       then ''
%       else  
% 	 Pitch = {LilyMakePitch {Note getPitchParameter($)}}
% 	 MicroPitch = {LilyMakeMicroPitch {Note getPitchParameter($)}}  % ?? temp fix?
% 	 FirstNote = Pitch#Rhythms.1#MicroPitch
%       in
% 	 %% !! ?? generalise (needed elsewhere)
% 	 if {Length Rhythms} == 1
% 	 then FirstNote
% 	    %% all values in Rhythm.2 are tied to predecessor
% 	 else FirstNote#{ListToVS3
% 			 {Map Rhythms.2
% 			  fun {$ R} " ~ "#Pitch#R#MicroPitch end}}
% 	 end
%       end
%    end
   %% appends pauses before X to express offsetTime
   fun {OffsetToPauses X FurtherClauses}
      Offset = {X getOffsetTimeParameter($)} 
      LilyX = {ToLilypondAux X FurtherClauses}
   in
      if {Offset getValueInBeats($)} == 0.0
      then
	 LilyX
      else
	 %% !! ?? generalise (needed elsewhere)
	 %% !! offset must be positive (currently)
	 Rhythms = {LilyMakeRhythms Offset}
	 FirstRest = r#Rhythms.1
      in
	 if {Length Rhythms} == 1
	 then FirstRest#LilyX
	 else FirstRest#{ListToVS {Map Rhythms.2
				   fun {$ R} r#R end}
			 " "}#LilyX
	 end
      end
   end
   %% only for inner Sims
   %% !! I don't differ between general Sims and chords
   %% !! offsets are currently ignored: only positive offsets are currently possible in SDL -- express them by rests or invisible rests (i.e. \skip <duration> )
   fun {SimToLily Sim FurtherClauses}
      Items = {Sim getItems($)}
   in
      %% chord: sim contains only events of same duration
      if {All Items {GUtils.toFun isEvent}}
	 andthen
	 {All Items.2
	  fun {$ X}
	     {X getDuration($)} == {Items.1 getDuration($)}
	  end}
      then
	 Pitches = {ListToVS
		    {Map Items fun {$ X}
				  %% ?? micro pitch tmp fix?
				  {LilyMakePitch {X getPitchParameter($)}}
				  #{LilyMakeMicroPitch {X getPitchParameter($)}} 
			       end}
		    " "}
	 Rhythms = {LilyMakeRhythms
		    {Items.1 getDurationParameter($)}}
	 FirstChord = "\n <"#Pitches#">"#Rhythms.1
      in
	 if {Length Rhythms} == 1
	 then FirstChord
	 else FirstChord#{ListToVS
			  {Map Rhythms.2
			   fun {$ R} " ~ <"#Pitches#">"#R end}
			  " "}
	 end
	 %% 'normal' sim
      else
	 {ListToVS
	  "\n <<" |
	  {Append {Map {Sim getItems($)}
		   fun {$ X} {OffsetToPauses X FurtherClauses} end} [">>"]}
	  " "}
      end
   end
   %% !! offsets are currently ignored: only positive offsets are currently possible in SDL -- express them by rests
   fun {SeqToLily Seq FurtherClauses}
      {ListToVS
       "\n {" |
       {Append {Map {Seq getItems($)}
		fun {$ X} {OffsetToPauses X FurtherClauses} end}
	["}"]}
       " "}
   end
   %% average pitch decides clef
   % LilyClefs = clef(bass_8 bass violin "violin^8")
   fun {DecideClef X}
      %% simple check avarage pitch got confused with pitch classes
      %% (note pitch class and chord root are also pitches)
      Pitches = {X map($ getValueInMidi test:fun {$ X}
						{X isPitch($)} andthen
						{Not {X hasThisInfo($ pitchClass)}}
						% {{X getItem($)} isNote($)}
					     end)}
      AveragePitch = {FoldL Pitches Number.'+' 0.0} / {IntToFloat
						       {Length Pitches}}
   in
      % {Browse decideClef(X Pitches AveragePitch)}
      if AveragePitch < 12.0 then "\"bass_29\""
      elseif AveragePitch < 24.0 then "\"bass_22\""
      elseif AveragePitch < 36.0 then "\"bass_15\""
      elseif AveragePitch < 48.0 then "\"bass_8\""
      elseif AveragePitch < 60.0 then bass
      elseif AveragePitch < 72.0 then violin
      elseif AveragePitch < 84.0 then "\"violin^8\""
      elseif AveragePitch < 96.0 then "\"violin^15\""
      elseif AveragePitch < 108.0 then  "\"violin^22\""
      else "\"violin^29\""
      end
   end
   OuterSimBound = {Cell.new false}
   %% !! no clef defs yet
   %% !! no time signature def yet
   %%
   %% !! in outmost sims contained in surrounding seqs I cause new
   %% staff creation. Refering to the old staff may be better (depends
   %% on context). So for now just always put a Sim around your score
   %% aeussere seqs funktionieren nicht (keine staff def fuer spaetere
   %% outmost sims)
   proc {OutmostSimToLily Sim FurtherClauses ?Result}
      %% set OuterSimBound to true for all processing within Sim and
      %% reset it to false at the end. This only works in a purely
      %% sequential program!
      {Cell.assign OuterSimBound true}	    
      Result = "<<"#{ListToVS
		     {Map {Sim getItems($)}
		      fun {$ X}
			 "\n \\new Staff { \\clef "#{DecideClef X}#" "
			 #{OffsetToPauses X FurtherClauses}#" }"
		      end}
		     " "}#"\n"#">>"
      {Cell.assign OuterSimBound false}
   end

   %% Do type checking and call appropriate function,
   %% FurtherClauses: additional types can be added as a list of the form [TypeCheck1#ProcessingFun1 ...]
   %% !! todo: generalise/refactor: all types and their processing is defined in a single form -- this could be some general processing fun for ScoreMapping...
%       fun {ToLilypondAux MyScore FurtherTypes}
% 	 if {MyScore isSequential($)}
% 	 then {SeqToLily MyScore}
% 	 elseif {MyScore isSimultaneous($)}
% 	 then
% 	    %% distinguish between outmost and inner Sims 
% 	    if {Cell.access OuterSimBound}
% 	    then {SimToLily MyScore}
% 	    else
% 	       %% outmost sims are staffs
% 	       {OutmostSimToLily MyScore}
% 	    end
% 	 elseif {MyScore isNote($)}
% 	 then {NoteToLily MyScore}
% 	 %elseif {LUtils.find FurtherTypes}
% 	 else
% 	    % raise unsupportedClass(MyScore ToLilypondAux) end
% 	    {Browse warn#unsupportedClass(MyScore ToLilypondAux)}
% 	    ''
% 	 end
%       end
   %%
   fun {ToLilypondAux MyScore FurtherClauses}
      {GUtils.cases MyScore
       {Append
	FurtherClauses
	[isSequential#fun {$ X} {SeqToLily X FurtherClauses} end
	 isSimultaneous#fun {$ X}
			   %% distinguish between outmost and inner Sims 
			   if {Cell.access OuterSimBound}
			   then {SimToLily X FurtherClauses}
			   else
			      %% outmost sims are staffs
			      {OutmostSimToLily X FurtherClauses}
			   end
			end
	 isNote#{MakeNoteToLily
		 fun {$ Note}
		    {LilyMakeMicroPitch {Note getPitchParameter($)}} 
		 end}
	   % Otherwise
	 fun {$ X} true end
	 #fun {$ X}
	     {Browse warn#unsupportedClass(X ToLilypondAux)}
	     ''
	  end]}}
   end
   /** %% Transforms a score object into a Lilypond score virtual string. The score layout is hardwired: the Items in the outmost Simultaneous container are put in their own staff. [currently, if outmost Simultaneous containers are contained in surround Sequentials, new staffs will be draw for each Item contained in each Simultaneous.]
   %% The argument FurtherClauses allows for specifying what Lilypond shows for specific score objects. FurtherClauses expects a list of the form [TypeCheck1#ProcessingFun1 ...].  TypeCheckN is a boolean function or method (e.g. isNote) and ProcessingFunN is a function which expects score objects for which TypeCheckN returns true as argument. ProcessingFunN returns a Lilypond VS. For example, the user may define a subclass of Score.note with an additional articulation attribute (e.g. values may be staccato, tenuto etc.) and the user then defines a clause which causes Lilypond to show the articulation by its common sign in the sheetmusic score.
   %% */
   %%
   %% !! TODO: further arg to extend/modify wrapper Lily code (e.g. to add "\header {tagline = \"\"})" for an empty tagline)
   fun {ToLilypond MyScore FurtherClauses}
      {Cell.assign OuterSimBound false}
      "\\version \"2.4.1\"\n\n"#
      %% empty paper def
      "\\paper { \n}\n\n"#
      %% for analysis brackets
      "\\layout {\n\\context {\n\\Staff \\consists \"Horizontal_bracket_engraver\"}}"#
      %% Lilypond 2.4.1: wide horizontal spacing
%       "\\layout{ "
%       #"\n\\context { \n\\Score \\override SpacingSpanner #\'spacing-increment = #6.0 \n}" 
%       #"\n\\context { \n\\Voice \\remove "Note_heads_engraver" \\consists \"Completion_heads_engraver\" \n}\n}\n\n"#
      %% the actual score
      "{\n"#
      {ToLilypondAux MyScore FurtherClauses}#
      "\n}"
   end
%       fun {ToLilypond MyScore FurtherClauses}
%       {Cell.assign OuterSimBound false}
%       "\\score { \n \\notes{\n"#
%       {ToLilypondAux MyScore FurtherClauses}#
%       "\n}"#
%       %% !! quick hack: layout control in \paper should be argument
%       %%
%       %% BTW: Lilypond has problems to automatically break notes correctly in a complex rhythmic situation
%       %%
%       %% Lilypond 2.0 (on my iBook)
%       %"\\paper { \n \\translator { \\ThreadContext \\remove "Note_heads_engraver" \\consists \"Completion_heads_engraver\" } \n}"#
%       %% Lilypond 2.2 (on my LinuxBox)
%       %"\\paper{ \n\\context { \n\\VoiceContext \\remove "Note_heads_engraver" \\consists \"Completion_heads_engraver\" \n} \n}"#
%       %"\n}"
%       %% Lilypond 2.2: wide horizontal spacing
%       "\\paper{ "
%       #"\n\\context { \n\\ScoreContext \\override SpacingSpanner #\'spacing-increment = #6.0 \n}" 
%       #"\n\\context { \n\\VoiceContext \\remove "Note_heads_engraver" \\consists \"Completion_heads_engraver\" \n} \n}"
%       #"\n}"
%    end

   
%    fun {MkDefaultSpec}
%       %% ?? this is function because otherwise
%       %% OutputLilypond calls Init.getStrasheelaEnv
%       %% only once at compile time (?)
%       {Browse mkDefaultSpec#{Init.getStrasheelaEnv defaultLilypondDir}}
%       unit(dir: {Init.getStrasheelaEnv defaultLilypondDir}
% 	   file: test % !! file name without extention
% 	   clauses:nil)
%    end
   /** %% Transforms MyScore into a Lilypond score. See the documentation of ToLilypond for an explanation of the argument clauses in Spec. 
   The defaults of Spec are
   unit(dir: {Init.getStrasheelaEnv defaultLilypondDir}
	file: "test" % !! file name without extention
	clauses:nil)
   %% */
   proc {OutputLilypond MyScore Spec}
      DefaultSpec =  unit(dir: {Init.getStrasheelaEnv defaultLilypondDir}
			  file: "test" % !! file name without extention
			  clauses:nil)
      MySpec = {Adjoin DefaultSpec Spec}
      Path = MySpec.dir#MySpec.file#".ly"
      FurtherClauses = MySpec.clauses
   in
      %{Browse Path#Spec#{MkDefaultSpec}}
      {WriteToFile {ToLilypond MyScore FurtherClauses} Path}
   end

   /** %% Calls lilypond on a lilypond file specified by Spec. The defaults of Spec are:
   unit(dir: {Init.getStrasheelaEnv defaultLilypondDir}
	file: test) % !! file name without extention
   %% */
   %% !! I need to cd into dir of *.ly file to get results into
   %% that dir as well : {OS.chDir DIR}
   %%
   %% !! ?? Path part of some Spec? e.g. default dir (see CallCsound)
   %% !! I could generalise this into CallApp -- move into GUtils
   proc {CallLilypond Spec}
      DefaultSpec = unit(dir: {Init.getStrasheelaEnv defaultLilypondDir}
			 file: test % !! file name without extention
			 'convert-ly':{Init.getStrasheelaEnv 'convert-ly'}
			 lilypond:{Init.getStrasheelaEnv lilypond}
			 flags:{Init.getStrasheelaEnv defaultLilypondFlags})
      MySpec = {Adjoin DefaultSpec Spec}
      %% MySpec.dir may be nil but Dir is not (full path given to file)
      MyPath = {{Path.make MySpec.dir} resolve(MySpec.file#".ly" $)}
      Dir = {Path.dirname MyPath}
      LyFile = {Path.basename MyPath}
   in
      {System.showInfo "> cd "#Dir}
      {OS.chDir Dir}
      {Exec MySpec.'convert-ly' ["-e" LyFile]}
      {Exec MySpec.lilypond {Append  MySpec.flags [LyFile]}}
   end

   /** %% Calls ghostview on a postscript file specified by Spec. The name of the lilypond file is given without extension. The defaults of Spec are:
   unit(dir: {Init.getStrasheelaEnv defaultLilypondDir}
	file: test)
   %% */
   %% !! I could generalise this into CallApp -- move into GUtils
   proc {ViewPDF Spec}
      DefaultSpec = unit(dir: {Init.getStrasheelaEnv defaultLilypondDir}
			 file: test % !! file name without extention
			)
      MySpec = {Adjoin DefaultSpec Spec}
      App = {Init.getStrasheelaEnv pdfViewer}
      Path = MySpec.dir#MySpec.file#".pdf"
	 %Pipe = {New Open.pipe init(cmd:App args:[Path])}
   in
% 	 {System.showInfo ">"#" "#App#" "#Path}
% 	 {System.showInfo {Pipe read(list:$ size:all)}}
% 	 %% block closing (quitting gv closes Pipe as well)
% 	 {Pipe flush(how: [send])}
% 	 {Pipe close}
      {ExecNonQuitting App [Path]}
   end

   /** %% Outputs a Lilypond file for MyScore, calls Lilypond to process it, and calls the PDF viewer with the result. See OutputLilypond, CallLilypond, and ViewPDF for details on Spec.
   %% */ 
   %% !! ?? this does not necessarily work for partly undetermined score
   proc {RenderAndShowLilypond MyScore Spec}
      DefaultSpec = unit
      MySpec = {Adjoin DefaultSpec Spec}
   in
      %% !! unefficient: transformation of Specs is done several times
      {OutputLilypond MyScore MySpec}
      {CallLilypond  MySpec}
      {ViewPDF MySpec}
   end

   /** %% Outputs a Lilypond file for MyScore and calls Lilypond to process it. See OutputLilypond and CallLilypond for details on Spec.
   %% */ 
   proc {RenderLilypond MyScore Spec}
      DefaultSpec = unit
      MySpec = {Adjoin DefaultSpec Spec}
   in
      %% !! unefficient: transformation of Specs is done several times
      {OutputLilypond MyScore MySpec}
      {CallLilypond  MySpec}
      % {ViewPDF MySpec}
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% SuperCollider output related stuff
%%%

   /** %% [aux means for MakeSCScore] Outputs a unary function which transforms a SDL event into a SC event (a VS). PlayerOut is a unary function with the event a argument which returns a SC player call (a VS). The TimeParameter units must be determined.
   %% */
   fun {MakeSCEventOutFn PlayerOut}
      fun {$ X}
	 Player = {PlayerOut X}
	 Dur = {X getDurationInBeats($)}
	 Offset = {X getOffsetTimeInBeats($)}
      in
	 "SEvent("#Player#", "#Dur#", "#Offset#")"
      end
   end
   /** %% Generate a SuperCollider score in hierarchic score format (a VS). SCEventOut is a unary function transforming a single SDL event into a SC event (a VS). The TimeParameter units must be determined.
   %% */
   fun {MakeSCScore Score SCEventOut MkContainerOut FurtherClauses}
      {MakeHierarchicVSScore Score
       SCEventOut {MkContainerOut "SSim"} {MkContainerOut "SSeq"}
       FurtherClauses}
   end
   proc {OutputSCScore Score SCEventOut Spec}
      DefaultSpec =
      unit(dir: {Init.getStrasheelaEnv defaultSuperColliderDir}
	   file: test % !! file name without extension
	   extension:".sc"
	   %% Resulting fun transforms container X in SC VS token of
	   %% form [BeginVS Delimiter EndVS]. Arg OutType is VS of
	   %% container type.
	   mkContainerOut:fun {$ OutType}
			     fun {$ X}
				Start = {X getStartTimeInBeats($)}
				Offset = {X getOffsetTimeInBeats($)}
			     in
				%% !! tmp
				{Browse test#OutputSCScore}
				[OutType#"(["
				 ",\n"
				 "], "#Start#", "#Offset#")"]
			     end
			  end
	   furtherClauses:nil
	   %% postProcess transforms final VS score 
	   postProcess:fun {$ ScoreVS}
			  "(\nTempo.bpm = "
			  #{Init.getTempo}#";\nx="#ScoreVS
			  #";\nx.prepareForPlay;\n)\n\nx.spawn;" 
		       end)
      MySpec = {Adjoin DefaultSpec Spec}
      Path = MySpec.dir#MySpec.file#MySpec.extension
   in
      {WriteToFile
       {MySpec.postProcess
	{MakeSCScore Score SCEventOut MySpec.mkContainerOut
	 MySpec.furtherClauses}}
       Path}
   end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% OSC related stuff
%%%

   /** %%
   %% NB: the network address must be set by setting the environment var REMOTE_ADDR (defaults to '127.0.0.1').
   %% */
   proc {SendOsc Host Port OSCcmd}
      {Exec {Init.getStrasheelaEnv sendOSC} ["-h" Host Port OSCcmd]}
   end
   /** [tmp restricted def?] */
   proc {SendSCserver OSCcmd}
      Host = "127.0.0.1"
      Port = 57110
   in
      {SendOsc Host Port OSCcmd}
   end
   /** [tmp restricted def?] */
   proc {SendSClang OSCcmd}
      Host = "127.0.0.1"
      Port = 57120 
   in
      {SendOsc Host Port OSCcmd}
   end
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Lisp output related stuff
%%%
   
   /** % Recursively transform X into virtual string representing a Lisp list (a dotted list). X is a (possibly nested) list of virtual strings or a virtual string.
   %% */
   %% !! Todo: X is list or record of VS: transform non-numerical record features into keywords
   fun {ToDottedList X}
      case X
      of nil then "nil"
      [] H|T then "("#{ToDottedList H}#" . "#{ToDottedList T}#")"
      else X
      end
   end
   
   /** % Outputs virtual string with round paranthesis wrapped around X. X is either a virtual string or an Oz list of virtual strings
   %% */
   fun {LispList X}
      if X==nil
      then nil
      elseif {IsList X}
      then "("#{ListToVS X " "}#")"
      else "("#X#")"
      end
   end
   /** % Outputs a virtual string denoting a Lisp keyword, i.e puts a colon before X. X is a virtual string.
   %% */
   fun {LispKeyword X}
      ":"#X
   end  

   /** %% This functions transforms a 'literal' Oz value (i.e. a value with a textual representation) into a corresponding literal Lisp value. It transforms an Oz record or list (possibly nested) into a virtual strings representing a Lisp keyword list. Each Oz record feature is transformed into a Lisp keyword (i.e. there is a colon in front of it) and the Oz value into a the corresponding Lisp value. Any record label is omitted (except the whole record is a plain Oz atom). In case a feature is an integer the keyword is omitted.
   %% !! NB: Currently, a value must be either (i) a literal which can be used directly in a VS and doesn't need to be further translated into a Lisp value (e.g. an atom, number, or string), (ii) an Oz list of supported values, or (iii) a record of supported values. 
   %% 
   %% A record feature can only be an integer or a symbol
   %%
   %% NB: The list is output without any line breaks. Use the pprint Lisp function for a more human-readable format.
   %% NB: Oz strings are lists of integers between 0 and 255, i.e. it can not be distinguished from a plain list of integers (e.g. denoting an all-interval series). Therefore, strings are not transformed into Lisp syntax!
   %% NB: Oz atoms can contain whitespace list 'Hi there' which result into two Lisp values!
   %% */
   fun {RecordToLispKeywordList X}
      %% an atom is also a record, but handled special here
      if {IsAtom X}		
      then X
	 %% a list is also a record, but handled special here
      elseif {IsList X}
      then {LispList {Map X RecordToLispKeywordList}}
      elseif {IsRecord X}
      then {LispList
	    {Map {Record.toListInd X}
	     fun {$ Feat#Val}
% 		ValVS = if {IsList Val}
% 			then {LispList {Map Val RecordToLispKeywordList}}
% 			elseif {IsRecord Val}
% 			then {RecordToLispKeywordList Val}
% 			else Val
% 			end
		ValVS = {RecordToLispKeywordList Val}
	     in
		if {IsInt Feat}
		then ValVS
%	   then ValVS#"\n"
		else {LispKeyword Feat}#" "#ValVS
		end
	     end}}
	 % Syntax transformation for negative numbers and exponential notation already buildin in Oz.
      elseif {IsNumber X}
      then X
      else
	 {Exception.raiseError
	  kernel(type
		 'Out.recordToLispKeywordList'
		 [X _]		% args
		 'atom, list, record or number' % type
		 1 % arg position
		 "Transformation only defined for an atom, list, record or a number."
		)}
	 unit % never returned
      end
   end
   
   /** %% Returns a lisp keyword list (a VS). X is a Strasheela score object (e.g. a note) and Spec is a record of the form unit(keyword1: accessor1 ..). The returned keyword list contains the record features as keywords and at these keywords the values of returned by the accessor (a unary function or method expecting X), i.e. ToLispKeywordList returns a VS of the form '(:keyword1'#{accessor1 X}# .. #')'
   %% */
   fun {ToLispKeywordList X Spec}
      {RecordToLispKeywordList
       {Record.map Spec
	fun {$ Accessor}
	   {{GUtils.toFun Accessor} X} 
	end}}
   end

   
   local
      %% NB: Lisp2Oz: nil can also be empty list..
      fun {Bool2LispBool X}
	 if X
	 then 'T'
	 else nil
	 end
      end
      %%
      fun {Atom2LispSymbol X}	
	 if {Some {AtomToString X} Char.isSpace}
	 then '|'#X#'|'
	 elseif  X==nil then
	    "nil"
	 else
	    X
	 end
      end
      fun {String2LispString X}
	 "\""#X#"\"" 
      end
      %% only works for Lisp implementations implementing character code ISO 8859-1, cf. oz/doc/base/char.html#section.text.characters
      fun {Char2LispChar X}
	 "(code-char \""#X#"\")"
      end
      fun {List2LispList X Args}
	 %% X==nil should never occur. List tails are 'filtered out'
	 %% by Map below and plain empty lists are processed by
	 %% Atom2LispSymbol instead (recursive call to OzToLisp..)
	 if X==nil		
	 then nil
	 else "("#{ListToVS {Map X fun {$ X} {OzToLisp X Args} end} " "}#")"
	 end
      end
      fun {Record2Lisp X Args}
	 "("#{ListToVS
	      %% all integer features must come first (Record.toListInd is defined that way).
	      {Append {Map {Record.toListInd X}
		       fun {$ Feat#Val}
			  ValVS = {OzToLisp Val Args}
		       in
			  if {IsInt Feat}
			  then ValVS
			  else {LispKeyword Feat}#" "#ValVS
			  end
		       end}	      
	       %% Record label is stored in last keyword/value pair in returned list. It is not suitable to put :label MyLabel at the beginning of the list: after the first keyword there should be only keywork value pairs, but Record2Lisp omits feature-keywords for number-keywords (e.g. for a tuple there are no feature-keywords at all). 
	       %% Disadvantage for performance: checking for the label requires traversing the whole list
	       %% NB: in case the list contains more than one :label, the first such pair determines the property. 
	       [{LispKeyword 'record-label'} {OzToLisp {Label X} Args}]}
	     " "}#")"
      end
   in
      /** %% OzToLisp transforms a literal Oz value (i.e. a value with a textual representation) into a corresponding literal Lisp value expressed by a VS. 
      %% Supported Oz values are integers, floats, atoms, records/tuples, lists and virtual strings. These values can be freely nested. In principle, characters and strings are supported as well, see below. Not supported are Oz values without a textual representation (e.g. names, procedures, and chunks).
      %% Oz characters are equivalent to integers and Oz strings are equivalent to lists of integers. Therefore, the users must decide for either integer or character/string transformation. For this purpose, Arg expects the optional arguments charTransform and stringTransform (both default to false, i.e. characters and strings are per default transformed into Lisp integers / integers lists).
      %% The following list details how values are transformed:  
      %%
      %% boolean -> boolean: true -> T, false -> nil [NB: Lisp2Oz: nil can also be empty list..]
      %% integer -> integer: 1 -> 1 [only decimal notation supported, NB: tilde ~ as unary minus for int and float supported]
      %% float -> float: 1.0 -> 1.0  [exponential notation supported]
      %% atom -> symbol: abc -> abc 
      %% record -> keyword list: unit(a:1 b:2) -> (:a 1 :b 2 :record-label unit)
      %% tuple -> keyword list: unit(a b) -> (a b :record-label unit)
      %% list -> list: [a b c] -> (a b c)
      %% VS -> unaltered VS: "("#'some Test'#")" -> (some Test)
      %%
      %% character -> character: &a -> (code-char 97) equivalent to 97 -> #\a
      %% string -> string: "Hi there" -> "Hi there"
      %%
      %% NB: Virtual strings are passed unaltered: the user is responsible that any (composite) VS results in a valid Lisp value.
      %% 
      %% NB: OzToLisp is very similar to RecordToLispKeywordList. The main difference is that OzToLisp can handle more cases truely in Lisp syntax (e.g. outputs something as 'Hi there' as |Hi there|). Moreover, the values are transformed in such a way that no information is lost and backtransformation (LispToOz) would be possible as well (e.g. the label of a record is preserved and the presence of the label marks a difference to a plain list).
      %%
      %% TODO:
      %% 
      %% * Lisp does not distinguish between cases, but for back-transformation of symbols etc in CamelCase I should possibly use symbols like |CamelCase|.
      %% */
      %%
      %% * shall I add support for the following values? 
      %%
      %% ?? FD int
      %% ?? FS
      fun {OzToLisp X Args}
	 Default = unit(charTransform:false
			stringTransform:false)
	 As = {Adjoin Default Args}
      in	 
	 if {IsBool X} then {Bool2LispBool X}    
	 elseif {IsUnit X} then 'unit'
	 elseif {IsAtom X} then {Atom2LispSymbol X}
	 elseif As.charTransform andthen {IsChar X} 
	 then {Char2LispChar X}	    
	    %% Syntax transformation for negative numbers and exponential notation already buildin in Oz.
	 elseif {IsNumber X} then X
	    %% unit is no VS 
	 elseif As.stringTransform andthen {IsString X} 
	 then {String2LispString X}
	 elseif {IsList X} then {List2LispList X Args}
	    %% 
	 elseif {IsVirtualString X} then X  
	 elseif {IsRecord X} then {Record2Lisp X Args}
	 else
	    {Exception.raiseError
	     kernel(type
		    'Out.ozToLisp'
		    [X Args _]		% args
		    'bool, unit, atom, number, list, VS, nor record' % type
		    1 % arg position
		    "Transformation only defined for an boolean, unit, atom, number (including chars), list (including strings), VS, nor a record."
		   )}
	    unit % never returned
	 end
      end
   end

   
   %%
   %% CLM output related stuff
   %%

   %% FIXME: [unfinished definition -- not general enough]
   %%
   %% generalisation: argument with list of matching clm::p argument
   %% keywords and SDL note accessors
%    local
%       Defaults = ["clm::p"#getStartTime
% 		  ":duration"#getDuration
% 		  ":keynum"#getPitch
% 		  ":strike-velocity"#getAmplitude]
%    in
   fun {Note2ClmP Note}
      {LispList ["clm::p" {Note getStartTime($)}
		 ":duration" {Note getDuration($)}
		 ":keynum" {Note getPitch($)}
		 ":strike-velocity" {Note getAmplitude($)}]}
   end
%   end
   /** %% [a quick and probably temp. hack]
   %% */
   fun {MakeClmScoreFn WithSoundArgs} 
      fun {$ _ EventVSs}
	 "(in-package :clm) \n\n"#{LispList ["with-sound"
					     {LispList WithSoundArgs} "\n"
					     {ListToLines EventVSs}
					     "\n"]}
      end
   end

   
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% PWGL output
%%%

   /** %% Exports TheScore (a Strasheela score) into a non-mensural ENP score (a VS). The ENP format is rather fixed, whereas the information contained in the Strasheela score format is highly user-customisable. Therefore, the export-process is also highly user-customisable. 
   %% An ENP score has a fixed topology. The non-mensural ENP has the following nesting: <code>score(part(voice(chord(note+)+)+)+)</code>. See the PWGL documentation for details. 
   %% Strasheela, on the other hand, supports various topologies. However, ToNonmensuralENP does not automatically perform a score topology transformation into the ENP topology. Instead, ToNonmensuralENP expects a number of optional accessor functions as arguments (e.g. getScore, getParts, getVoices) which allow for a user-defined topology transformation. These functions expect a (subpart of the) score and return the contained objects according to the ENP topology. For instance, the function getVoices expects a Strasheela object corresponding to an ENP part and returns a list of Strasheela object corresponding to ENP voices. The default values for these accessor functions require that the topology of TheScore fully corresponds with the ENP score topology. That is, for the default accessor functions, TheScore must have the following topology: <code>sim(sim(seq(sim(note+)+)+)+)</code>. The set of all supported accessor functions (together with their default values) is given below.
   %% Any ENP attribute of a score object can be specified by the user. For this purpose, ToNonmensuralENP expects a number of optional attribute accessor functions (e.g. getScoreKeywords, getPartKeywords). These functions expect a Strasheela object corresponding to an ENP part and returns an Oz record whose features are the ENP keywords for this objects and the feature values are the values for these ENP keywords. See the default of getNoteKeywords for an example. 
   %%
   %% Default arguments: 
   unit(getScore:fun {$ X} X end
	getParts:fun {$ MyScore} {MyScore getItems($)} end
	getVoices:fun {$ MyPart} {MyPart getItems($)} end
	getChords:fun {$ MyVoice} {MyVoice getItems($)} end
	getNotes:fun {$ MyChord} {MyChord getItems($)} end
	getScoreKeywords:fun {$ MyScore}
			    unit % put further ENP score keywords here
			 end
	getPartKeywords:fun {$ MyPart}
			   unit % put further ENP part keywords here
			end
	getVoiceKeywords:fun {$ MyVoice}
			    unit % put further ENP voice keywords here
			 end
	getChordKeywords:fun {$ MyChord}
			    unit % put further ENP chord keywords here
			 end
	getNoteKeywords:fun {$ MyNote}
			   %% put further ENP note keywords here
			   unit('offset-time': {MyNote getOffsetTimeInSeconds($)})
			end)
   %% */
   %%
   %% NB: output unit of measurement of chord start times and note offset times hard-wired to seconds
   fun {ToNonmensuralENP TheScore Args}
      Defaults
      = unit(getScore:fun {$ X} X end
	     getParts:fun {$ MyScore} {MyScore getItems($)} end
	     getVoices:fun {$ MyPart} {MyPart getItems($)} end
	     getChords:fun {$ MyVoice} {MyVoice getItems($)} end
	     getNotes:fun {$ MyChord} {MyChord getItems($)} end
	     getScoreKeywords:fun {$ MyScore}
				 %% put further ENP score keywords here
				 unit
			      end
	     getPartKeywords:fun {$ MyPart}
				%% put further ENP part keywords here
				unit
			     end
	     getVoiceKeywords:fun {$ MyVoice}
				 %% put further ENP voice keywords here
				 unit
			      end
	     getChordKeywords:fun {$ MyChord}
				 %% put further ENP chord keywords here
				 unit
			      end
	     getNoteKeywords:fun {$ MyNote}
				%% put further ENP note keywords here
				unit('offset-time': {MyNote getOffsetTimeInSeconds($)})
			     end)
      As = {Adjoin Defaults Args}
      fun {Object2Record MyObject
	   GetSubObjects MakeSubObjectRecord GetKeywords}
	 {Adjoin {GetKeywords MyObject}
	  {List.toTuple unit {Map {GetSubObjects MyObject}
			      MakeSubObjectRecord}}}
      end
      fun {MakeScoreRecord MyScore}
	 {Object2Record MyScore
	  As.getParts MakePartRecord As.getScoreKeywords}
      end
      fun {MakePartRecord MyPart}
	 {Object2Record MyPart
	  As.getVoices MakeVoiceRecord As.getPartKeywords}
      end
      fun {MakeVoiceRecord MyVoice}
	 {Object2Record MyVoice
	  As.getChords MakeChordRecord As.getVoiceKeywords}
      end
      fun {MakeChordRecord MyChord}
	 {Adjoin
	  {As.getChordKeywords MyChord}
	  unit(1:{MyChord getStartTimeInSeconds($)}
	       notes:{Map {As.getNotes MyChord}
		      fun {$ MyNote}
			 {Adjoin {As.getNoteKeywords MyNote}
			  unit(1:{MyNote getPitchInMidi($)})}
		      end})}
      end
   in      
      {RecordToLispKeywordList {MakeScoreRecord TheScore}}
   end
   
   /** %%  Exports MyScore (a Strasheela score) into a text file with a non-mensural ENP score. The file path is specified with the arguments file, extension and dir. For further arguments see the ToNonmensuralENP documentation.
   %% */
   proc {OutputNonmensuralENP MyScore Args}
      Defaults = unit(file:"test"
		      extension:".enp"
		      dir:{Init.getStrasheelaEnv defaultENPDir})
      As = {Adjoin Defaults Args}
   in
      {WriteToFile
       {ToNonmensuralENP MyScore As}
       As.dir#As.file#As.extension}
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Fomus
%%%

   /** %% Exports MyScore into Fomus format (as a VS). The Fomus format is rather fixed, whereas the information contained in the Strasheela score format is highly user-customisable. Therefore, the export-process is also highly user-customisable.
   %% A Fomus score has a fixed topology: <code>score(part(event+)+)</code> (see the Fomus documentation at http://common-lisp.net/project/fomus/doc/). Strasheela, on the other hand, supports various topologies. However, ToFomus does not automatically perform a score topology transformation into the Fomus topology. Instead, ToFomus expects two optional accessor functions as arguments which allow for a user-defined topology transformation: getParts and getEvents. The function given to the argument getParts expects MyScore and returns a list of values corresponding to the Fomus parts. The function given to the argument getEvents expects a part and returns a list of values corresponding to the Fomus events. The default values for these accessor functions require that the topology of MyScore corresponds with the Fomus score topology. That is, for the default accessor functions, MyScore must have the following topology: <code>sim(seq(&lt;arbitrarily nested note&gt;+)+)</code>.
   %% Any Fomus setting for the score, a part, or event can be specified by the user as well. For this purpose, ToFomus expects three optional attribute accessor functions: getScoreKeywords, getPartKeywords, and getEventKeywords. These functions expect a Strasheela object corresponding to a Fomus score/part/event and return an Oz record whose features are the Fomus keywords for this objects and the feature values are the values for these keywords. For example, getEventKeywords may be set to the following function.
   fun {$ MyEvent}
      unit(off:{MyEvent getStartTimeInBeats($)}
	   dur:{MyEvent getDurationInBeats($)}
	   note:{MyEvent getPitchInMidi($)})
   end
   %%
   %% Please inspect the implementation code to see the default values for the arguments. 
   %% */
   %%
   %% !! default args file, extension, and dir are given explicitly thrice in ToFomus, OutputFomus, and CallFomus
   %%
   %% The Oz-created .fms file gets overwritten by fomus, which is kind of fun :) -
   %%
   %%   it also enables you -- for the time being -- to edit the richer settings by hand...
   fun {ToFomus MyScore Args}
      Defaults
      = unit(getParts:fun {$ MyScore} {MyScore getItems($)} end
	     getEvents:fun {$ MyPart} {MyPart collect($ test: isNote)} end
	     /** %% Outputs a record where the features are later Fomus keywords and the values are the corresponding Fomus values for these keywords.
	     %% */
	     getScoreKeywords:fun {$ MyScore}
				 %% :midi will generate an error message, if fomus has not been installed with cm
				 %% however, this will not hurt other processing
				 unit(output: "((:lilypond :view t) (:midi))"
				      %% filename keyword now hard-wired (see below) to keep interface for all three get*Keywords functions consistent.
				      quartertones: "t"
				      %% midi playback will be program 1 - piano
				      instruments: "#.(list (fm:make-instr :treble-bass :clefs '(:treble :bass) :midiprgch-ex 1))")
			      end
	     getPartKeywords:fun {$ MyPart}
				unit(instr:":treble-bass")
			     end
	     getEventKeywords:fun {$ MyEvent}
				unit(off:{MyEvent getStartTimeInBeats($)}
				     dur:{MyEvent getDurationInBeats($)}
				     note:{MyEvent getPitchInMidi($)})
			     end
	     file:"test"
	     extension:".fms"
	     dir:{Init.getStrasheelaEnv defaultFomusDir})
      As = {Adjoin Defaults Args}
      Path = As.dir#As.file#As.extension
      /** %% [Aux] Transforms a record into a VS, where the record features are lisp keywords and the record values remain as is.
      %% */
      fun {Record2KeyValPairs X}
	 {ListToVS {Map {Record.toListInd X}
		    fun {$ Feat#Val} {LispKeyword Feat}#" "#Val end}
	  " "}
      end
   in
      %% score creation
      {ListToLines
       "init "#{Record2KeyValPairs {Adjoin {As.getScoreKeywords MyScore}
				    unit(filename: "\""#Path#"\"")}}|
       {List.mapInd {As.getParts MyScore}
	fun {$ PartId MyPart}
	   %% part creation
	   {ListToLines
	    {ListToVS ["part" PartId {Record2KeyValPairs {As.getPartKeywords MyPart}}]
	     " "}|
	    {Map {As.getEvents MyPart}
	     fun {$ MyEvent}
		%% event creation
		{ListToVS ["note" PartId {Record2KeyValPairs {As.getEventKeywords MyEvent}}]
		 " "}
	     end}}
	end}}
   end
   
   /** %% Outputs a fomus file with optional Args. The defaults are
   unit(file:"test"
	extension:".fms"
	dir:{Init.getStrasheelaEnv defaultFomusDir}
	...)
   %% See the doc of ToFomus for further optional arguments.
   %% */
   %% !! default args file, extension, and dir are given explicitly thrice in ToFomus, OutputFomus, and CallFomus
   proc {OutputFomus MyScore Args}      
      Defaults = unit(file:"test"
		      extension:".fms"
		      dir:{Init.getStrasheelaEnv defaultFomusDir})
      As = {Adjoin Defaults Args}
      Path = As.dir#As.file#As.extension
   in
      {WriteToFile {ToFomus MyScore As} Path}
   end
   
   /** %% Creates a fomus file from MyScore and calls the fomus command-line application on this file. The argument flags expects a list of fomus flags (default is nil). See the doc of OutputFomus for further arguments.
   %% */
   %% !! default args file, extension, and dir are given explicitly thrice in ToFomus, OutputFomus, and CallFomus
   proc {RenderFomus MyScore Args}   
      Defaults = unit(file:"test"
		      extension:".fms"
		      dir:{Init.getStrasheelaEnv defaultFomusDir}
		      flags:nil)
      As = {Adjoin Defaults Args}
      Path = As.dir#As.file#As.extension
      App = {Init.getStrasheelaEnv fomus}
   in
      {OutputFomus MyScore Args}
      {Exec App {Append As.flags [Path]}}
   end

   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Common Music output
%%%

   /** %% Returns CM note VS. Spec is a record of the form class(keywordSymbol1: noteAccessor1 ..). class is an atom, each keywordSymbol are an atom and each noteAccessor is funtions or method.
   %% */
   %% !! code doublication with ToLispKeywordList (aber das kann ich nicht verwenden: habe fuer liste in VS kein cons..)
   fun {MakeCMEvent Note Spec}
      {RecordToLispKeywordList
       {Adjoin
	%% put 'new <class>' in front
	unit(new {Label Spec})
	%% replace each Spec accessor by {Acessor Note} 
	{Record.map Spec
	 fun {$ Accessor}
	    {{GUtils.toFun Accessor} Note} 
	 end}}}
   end
   local
      fun {EventOut MyNote}
	 {MakeCMEvent MyNote
	  midi(time:getStartTimeInSeconds
	       duration:getDurationInSeconds
	       keynum:getPitchInMidi
	       amplitude:getAmplitudeInNormalized)} 
      end
      fun {ContainerOut X}
	 BeginVS = "(new seq subobjects \n(list\n"
	 Delimiter = "\n"
	 EndVS = "\n))"
      in
	 [BeginVS Delimiter EndVS]
      end
   in
      /** %% Transforms Score to Common Music score (VS). Common Music in turn can be used to output to various formats (e.g. MIDI, SuperCollider, Csound, music notation formats via FOMUS) or used to edit the score (e.g. with the CM Plotter). Optional Args features are containerOut (unary function, expecting a container and outputting a list of VS in the form [BeginVS Delimiter EndVS]), eventOut (unary function, expecting an event and outputting a VS), and furtherClauses (list of declarations, see MakeHierarchicVSScore for further details). The default eventOut outputs a CM 'midi' (i.e. events must be notes), the default containerOut outputs a CM 'seq' with the contained items as 'subobjects'.
      %% */
      fun {MakeCMScore Score Args}
	 Defaults = unit(containerOut:ContainerOut	% out for sim and seq
			 eventOut:EventOut
			 furtherClauses:nil)
	 As = {Adjoin Defaults Args}
      in
	 {MakeHierarchicVSScore Score As.eventOut
	  As.containerOut		
	  As.containerOut		
	  As.furtherClauses}
      end
   end

   /** %% Outputs Score into a CM score file. Optional Args features are dir (a VS, defaults to default CM dir in Strasheela env), file (VS, defaults to test), extension (VS, defaults to '.cm'), wrapper (a list of two VS as [WrapperHeader WrapperFooter]) and ioExtension (a VS). The Args feature wrapper specifies a Lisp expression surrounding the CM score in the output, it defaults to a var binding and an 'events' call for output with the same file name as specified by Args or Defaults and an extension as specified by ioExtension.
   %% Additionally, Args features are the Args supported by MakeCMScore (see there).
   %% */
   proc {OutputCMScore Score Args}
      Defaults = unit(dir:{Init.getStrasheelaEnv defaultCommonMusicDir}
		      file:test
		      extension:".cm"
		      ioExtension:".midi"
		      %% io out: file name in Args or Defaults
		      %% and extension Defaults.ioExtension
		      wrapper:["(in-package :cm)\n\n(define my-score \n" %% here goes the score
			       "\n)\n\n"#
			       "(events my-score "#
			       "\n(io \""
			       #{Init.getStrasheelaEnv defaultCommonMusicDir}
			       #{CondSelect Args file Defaults.file}
			       #{CondSelect Args ioExtension
				 Defaults.ioExtension}
			       #"\"))\n"])
      As = {Adjoin Defaults Args}
      [WrapperHeader WrapperFooter] = As.wrapper
      Path = As.dir#As.file#As.extension
   in
      {WriteToFile WrapperHeader#{MakeCMScore Score As}#WrapperFooter
       Path}
   end
   
%    /* %% for MacOS
%    '(defun macosx-midi (file) ; &rest args\n
%   ;; set file creator and type \n
%   (ccl:set-mac-file-creator file :TVOD)\n
%   (ccl:set-mac-file-type file "Midi"))\n
% (Set-midi-output-hook! #\'macosx-midi)n\n\'
% */

%    %% !!??
%    fun {RenderCMScore Score}


% %       ;; initialise MIDI output such that MacOS X recognises the output as
% % ;; MIDI file. [don't worry, you do not need to understand this ;-) ]
% % ;; BTW: I configured Common Music on the iMacs such that this is
% % ;; evaluated at init time.
% % (defun macosx-midi (file) ; &rest args
% %   ;; set file creator and type 
% %   (ccl:set-mac-file-creator file :TVOD)
% %   (ccl:set-mac-file-type file "Midi"))
% % (Set-midi-output-hook! #'macosx-midi)

%    end
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Sound playback related stuff
%%%
   
   local
      proc {Start X File CmdlineSndPlayer}
	 if {Value.isFree {Cell.access X}}
	 then
	    {Cell.access X} =
	    {New Open.pipe init(cmd:CmdlineSndPlayer args:[File])}
	 end
      end
      proc {Stop X}
	 if {Value.isDet {Cell.access X}}
	 then
	    {{Cell.access X} close}
	    {{Cell.assign X} _}	% !! suspends, why ??
	 end
      end
      
      /** % Start sound file sound playback and opens control window that allows stopping and restarting payback. 
      %%*/
      %%
      %% !! Add test whether file exists and do warning in case
      %%
      %% !! Hitting Play to replay (i.e. before hitting stop first)
      %% has no effect. {Stop Sound} suspends, I don't know
      %% why. Otherwise I could just always stop sound playback first
      proc {SoundPlayerWithGui CmdlineSndPlayer File Spec}
	 Sound = {Cell.new _}
	 W={New Tk.toplevel tkInit(title:Spec.title)}
	 B1={New Tk.button
	     tkInit(parent: W text: "Play" 
		    action: proc {$}
			       %{Stop Sound} % suspends
			       {Start Sound File CmdlineSndPlayer}
			    end)}
	 B2={New Tk.button
	     tkInit(parent: W text: "Stop" 
		    action: proc {$} {Stop Sound} end)}
	 B3={New Tk.button
	     tkInit(parent: W text: "Quit" 
		    action: proc {$}
			       thread {Stop Sound} end
			       {W tkClose}
			    end)}
      in
	 {Tk.send pack(B1 B2 B3 fill:x padx:4 pady:4)}
	 {Start Sound File CmdlineSndPlayer}
      end
   in
      /** %% If a sndPlayer is specified, Strasheela assumes it has an own GUI and just calls it with the sound file. If a cmdlineSndPlayer is specified, Strasheela provides a minimal GUI for the cmdline soundPlayer. Spec is a record with optional arguments, the defaults are:
      unit(file:"test" % without extension
	   extension:".aiff"
	   soundDir:{Init.getStrasheelaEnv defaultSoundDir}
	   title:"Play Sound")
      %% */
      proc {PlaySound Spec}
	 Defaults = unit(file:"test"
			 extension:".aiff"
			 soundDir:{Init.getStrasheelaEnv defaultSoundDir}
			 title:"Play Sound")
	 MySpecs = {Adjoin Defaults Spec}
	 SoundPlayer = {Init.getStrasheelaEnv sndPlayer}
	 CmdlineSndPlayer = {Init.getStrasheelaEnv cmdlineSndPlayer}
	 File = MySpecs.soundDir#MySpecs.file#MySpecs.extension
      in
	 if SoundPlayer \= nil
	 then {Exec SoundPlayer [File]}
	    %{New Open.pipe init(cmd:SoundPlayer args:[File])}
	 elseif CmdlineSndPlayer \= nil
	 then {SoundPlayerWithGui CmdlineSndPlayer File MySpecs}
	 else
	    {Exception.raiseError
	     strasheela(initError 'No sound player specified. Please set either the environment variable sndPlayer or cmdlineSndPlayer.')}
	 end
      end
   end


   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Shell interface
%%%
%%%
%%% !! consider the new Shell of the standard library als an alternative: http://www.mozart-oz.org/documentation/mozart-stdlib/os/shell.html
%%%

      
   /** %% Execute shell Cmd with Args, show standard out/error in the emulator and exit.
   %% */
   proc {Exec Cmd Args}
      Pipe = {New Open.pipe init(cmd:Cmd args:Args)}
   in
      {System.showInfo "> "#Cmd#" "#{ListToVS Args " "}}
      {System.showInfo {Pipe read(list:$ size:all)}}
      {Pipe flush}
      {Pipe close}
   end

   /** %% Execute shell Cmd with Args, show standard out/error in the emulator and exit. This is very similar to Exec, however the application Cmd does not automatically quit after finishing.
   %% */
   proc {ExecNonQuitting Cmd Args}
      Pipe = {New Open.pipe init(cmd:Cmd args:Args)}
   in
      {System.showInfo "> "#Cmd#" "#{ListToVS Args " "}}
      {System.showInfo {Pipe read(list:$ size:all)}}
      %% block closing (quitting application closes Pipe as well)
      {Pipe flush(how: [send])}
      {Pipe close}
   end

   /** %% Execute shell Cmd with Args, bind standard out/error to Output and exit.
   %% */
   proc {ExecWithOutput Cmd Args ?Output}
      Pipe = {New Open.pipe init(cmd:Cmd args:Args)}
   in
      {System.showInfo "> "#Cmd#" "#{ListToVS Args " "}}
      Output = {Pipe read(list:$ size:all)}
      {Pipe flush}
      {Pipe close}
   end
 
   /** %% Provides an interface to interactive commandline programs like a shell or an interpreter. Start interactive program with the method init (see below), close it with the method close.
   %% More specialised classes (e.g. an interface to Common Lisp) may be obtained by subclasses..
   %% */
   %% Transformation of def by Christian Schulte in "Open Programming in Mozart"
   class Shell from Open.pipe Open.text
      /** %% Start interactive program Cmd (VS) with Args (list of VSs). The default is the shell "sh" with args ["-s"] for reading from standard input. See the test file for examples for other interactive commands (e.g., the interactive ruby shell or a Common Lisp compiler). 
      %% */
      meth init(cmd:Cmd<="sh" args:Args<=["-s"]) 
	 Open.pipe,init(cmd:Cmd args:Args)  
      end
      /** %% Feed Cmd (a VS) to the interactive program. Use one of the output/show methods to retrieve results.
      %% Please note that the output/show methods are exclusive (i.e., once some result is output one way, it is output again.). 
      %% */
      meth cmd(Cmd)  
	 Open.text,putS(Cmd)  
      end 
      /** %% Show any results and output of each command fed to the shell at stdout. 
      %% */
      %% !! does this only show stdout, but not stderror?
      meth showAll
	 Line = Open.text,getS($)
      in
	 {Wait Line}
	 case Line of false then
	    {System.showInfo "Process has died."} {self close}
	 else {System.showInfo Line}
	    {self showAll}
	 end
      end
      /** %% Return the next line (a string) of any result. In case the shell has died, nil is returned.
      %% */
      meth outputLine($)
	 case Open.text,getS($) of false then 
	    {self close}
	    nil
	 elseof S then S
	 end 
      end
%   /** %% Return any results . In case the shell has died, nil is returned.
%   %% */
%   meth outputAll($)
%   end
   end
   
end

