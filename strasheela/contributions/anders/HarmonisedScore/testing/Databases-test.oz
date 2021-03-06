
%%
HS.dbs.default.db

%%
HS.dbs.scala.db

HS.dbs.scala.db.chordDB


{HS.db.setDB HS.dbs.scala.db}

%% extract selected chords (after setting DB!)
{Map
 % ['Major Triad' 'Minor Triad' 'Dominant Seventh' 'Diminished' 'Semitone Trichord']
 ['Overtone' 'Tristan Chord']
 % ['Undertone']
 fun {$ ChordLabel}
   HS.dbs.scala.db.chordDB.{HS.db.getChordIndex ChordLabel}
 end}

{HS.db.getChordIndex 'Tristan Chord'}
%% !! missing
{HS.db.getChordIndex 'Undertone'}


% %% for more convenient eye-balling of data..
% {Out.writeToFile {Out.recordToVS HS.dbs.scala.db.chordDB}
%  unit(path: '~/tmp/chords.oz')}
% {VirtualString.is {Out.recordToVS HS.dbs.scala.db.chordDB.1.comment}}

{Width HS.dbs.scala.db.chordDB}

%% after starting Oz -- computing of of chord sonance values takes only a few msecs
{GUtils.timeSpend proc {$} _ = HS.dbs.scala.db.chordDB end}


%%
HS.dbs.jazz.burbatVierklaenge


%%
{HS.dbs.partch.getIntervals 12}

{HS.dbs.partch.getIntervals 12}

%% onle a single error almost 6 cent, all other less then 5 cent
{HS.dbs.partch.getIntervals 72}


{HS.dbs.partch.get11LimitDiamondChords 72}


%%

%% errors up to almost 8 cents
{HS.dbs.johnston.getIntervals 72}

{HS.dbs.johnston.getIntervals 1200}

%% onle a single error slighly more than 6 cent, all other less then 5 cent
{HS.dbs.chalmers.getIntervals 72}

%% multiple errors around 7 cent
{HS.dbs.catler.getIntervals 72}

{HS.dbs.catler.getIntervals 1200}

%% all errors less than 5 cent
{HS.dbs.harrison.getIntervals 72}



%%
{HS.dbs.arithmeticalSeriesChords.getSelectedChords 12}

{HS.dbs.arithmeticalSeriesChords.getSelectedChords 72}

{GUtils.timeSpend proc {$} _ = {HS.dbs.arithmeticalSeriesChords.getChords 72} end}

