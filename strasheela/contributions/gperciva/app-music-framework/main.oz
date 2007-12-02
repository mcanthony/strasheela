%% ozmake -vm Makefile.oz

functor
import
	%% basic Oz stuff
	System Application Property
	%% Strasheela output
	Out at 'x-ozlib://anders/strasheela/source/Output.ozf'

	%% your personal music definitions
	MyMusic

%	LUtils at 'x-ozlib://anders/strasheela/source/ListUtils.ozf'
%	Score at 'x-ozlib://anders/strasheela/source/ScoreCore.ozf'
%	SDistro at 'x-ozlib://anders/strasheela/source/ScoreDistribution.ozf'
define


	%% Show help message
	proc{ShowHelp M}
		{System.printError
		if M==unit then nil else "Command line option error: "#M#"\n" end#
			"Usage: "#{Property.get 'application.url'}#" [OPTIONS]\n"#
			"   --file <FILE>		 Lilypond output filename (basename without extension)\n"#
			"   --dir <DIR>			 Lilypond output directory\n"#
			"   --size <INTEGER>		 Number of notes in created score\n"}
	end

	try
		%% Args is record of parsed commandline arguments 
		Args = {Application.getArgs record(
			file(single type:string default:"foo")
			dir(single type:string default:"/tmp/")
			size(single type:int default:1)
			help(single char:&h type:bool default:false)
		)} 
	in
		%% Ask for help?
		if Args.help==true then
			{ShowHelp unit}
		{Application.exit 0}
		end	   

	%% your actual program
	local
		Score
		Filename
	in
		{MyMusic.myScore Args.size Score}
		Filename = Args.file
		{System.showInfo 'now outputting lilypond to '#Filename}

		{Out.outputLilypond Score
			unit(file:Filename
			dir:Args.dir)}
	end

	{Application.exit 0}

	%% handling of exceptions
	catch X then
		case X of quit then
			{Application.exit 0}
		elseof error(ap(usage M) ...) then
			{ShowHelp M}
			{Application.exit 2}
		elseof E then
			raise E end
		end
	end

end

