%%% created by Strasheela at 16:31, 14-6-2008

\version "2.10.0"

\header {
  title = "List of Paul Erlich's decatonic scales"
}

\markuplines {
  \justified-lines {
    Paul Erlich describes a set of 7-limit scales in the following publications.
    }
  \justified-lines {
    Paul Erlich (1998). Tuning, Tonality, and Twenty-Two-Tone Temperament. Xenharmonikon 17. }
  \justified-lines {
    Paul Erlich (2001). The Forms of Tonality. 
  }
  \justified-lines {
    
  }
  \justified-lines {
    Whereas Erlich proposes a new notation for these scales, this file displays them in common five-line staff notation, using special accidentals for 22-tone equal temperament. This notation is explain in the file "./ET22-notation.pdf" (in the same folder as this document). 
  }
}


\layout {
    \context {
      \Score
      \override SpacingSpanner
                #'base-shortest-duration = #(ly:make-moment 1 32)
    }
  }
% \paper {
% }
% \layout {  
% }

% Define 22 ET pitches simply as 1/6 tone alterations...
#(define-public Comma 1/6)
#(define-public SharpMinusComma 1/3)
#(define-public Sharp 1/2)


% Define pitch names: C = c, C/ = cu (comma up), C#\ = cscd (c sharp, comma down),  C# = cs, C\ = ccd, Cb/ = cfcu, Cb = cf

etTwentytwoPitchNames = #`(
  (c . ,(ly:make-pitch -1 0 NATURAL))
  (d . ,(ly:make-pitch -1 1 NATURAL))
  (e . ,(ly:make-pitch -1 2 NATURAL))
  (f . ,(ly:make-pitch -1 3 NATURAL))
  (g . ,(ly:make-pitch -1 4 NATURAL))
  (a . ,(ly:make-pitch -1 5 NATURAL))
  (b . ,(ly:make-pitch -1 6 NATURAL))
  
  (ccu . ,(ly:make-pitch -1 0 Comma))
  (dcu . ,(ly:make-pitch -1 1 Comma))
  (ecu . ,(ly:make-pitch -1 2 Comma))
  (fcu . ,(ly:make-pitch -1 3 Comma))
  (gcu . ,(ly:make-pitch -1 4 Comma))
  (acu . ,(ly:make-pitch -1 5 Comma))
  (bcu . ,(ly:make-pitch -1 6 Comma))

  (cscd . ,(ly:make-pitch -1 0 SharpMinusComma))
  (dscd . ,(ly:make-pitch -1 1 SharpMinusComma))
  (escd . ,(ly:make-pitch -1 2 SharpMinusComma))
  (fscd . ,(ly:make-pitch -1 3 SharpMinusComma))
  (gscd . ,(ly:make-pitch -1 4 SharpMinusComma))
  (ascd . ,(ly:make-pitch -1 5 SharpMinusComma))
  (bscd . ,(ly:make-pitch -1 6 SharpMinusComma))

  (cs . ,(ly:make-pitch -1 0 Sharp))
  (ds . ,(ly:make-pitch -1 1 Sharp))
  (es . ,(ly:make-pitch -1 2 Sharp))
  (fs . ,(ly:make-pitch -1 3 Sharp))
  (gs . ,(ly:make-pitch -1 4 Sharp))
  (as . ,(ly:make-pitch -1 5 Sharp))
  (bs . ,(ly:make-pitch -1 6 Sharp))


  (ccd . ,(ly:make-pitch -1 0 (- Comma)))
  (dcd . ,(ly:make-pitch -1 1 (- Comma)))
  (ecd . ,(ly:make-pitch -1 2 (- Comma)))
  (fcd . ,(ly:make-pitch -1 3 (- Comma)))
  (gcd . ,(ly:make-pitch -1 4 (- Comma)))
  (acd . ,(ly:make-pitch -1 5 (- Comma)))
  (bcd . ,(ly:make-pitch -1 6 (- Comma)))
  
  (cfcu . ,(ly:make-pitch -1 0 (- SharpMinusComma)))
  (dfcu . ,(ly:make-pitch -1 1 (- SharpMinusComma)))
  (efcu . ,(ly:make-pitch -1 2 (- SharpMinusComma)))
  (ffcu . ,(ly:make-pitch -1 3 (- SharpMinusComma)))
  (gfcu . ,(ly:make-pitch -1 4 (- SharpMinusComma)))
  (afcu . ,(ly:make-pitch -1 5 (- SharpMinusComma)))
  (bfcu . ,(ly:make-pitch -1 6 (- SharpMinusComma)))

  (cf . ,(ly:make-pitch -1 0 (- Sharp)))
  (df . ,(ly:make-pitch -1 1 (- Sharp)))
  (ef . ,(ly:make-pitch -1 2 (- Sharp)))
  (ff . ,(ly:make-pitch -1 3 (- Sharp)))
  (gf . ,(ly:make-pitch -1 4 (- Sharp)))
  (af . ,(ly:make-pitch -1 5 (- Sharp)))
  (bf . ,(ly:make-pitch -1 6 (- Sharp)))

)

%% set pitch names.
pitchnames = \etTwentytwoPitchNames 
#(ly:parser-set-note-names parser etTwentytwoPitchNames)


% etTwentytwoGlyphs = #'((1 . "accidentals.doublesharp")
%        (1/2 . "accidentals.sharp")
%        (1/3 . "accidentals.sharp.slashslashslash.stem")
%        (1/6 . "accidentals.rightparen")
%        (0 . "accidentals.natural")
%        (-1/6 . "accidentals.leftparen")
%        (-1/3 . "accidentals.flat.slash")
%        (-1/2 . "accidentals.flat")
%        (-1 . "accidentals.flatflat")
%        )

% etTwentytwoGlyphs = #'((1 . "accidentals.doublesharp")
%        (1/2 . "accidentals.sharp")
%        (1/3 . "accidentals.sharp.slashslashslash.stem")
%        (1/6 . "arrowheads.open.11")
%        (0 . "accidentals.natural")
%        (-1/6 . "arrowheads.open.1M1")
%        (-1/3 . "accidentals.flat.slash")
%        (-1/2 . "accidentals.flat")
%        (-1 . "accidentals.flatflat")
%        )

etTwentytwoGlyphs = #'((1 . "accidentals.doublesharp")
       (1/2 . "accidentals.sharp")
       (1/3 . "accidentals.sharp.slashslash.stem")
       (1/6 . "arrowheads.open.01")
       (0 . "accidentals.natural")
       (-1/6 . "arrowheads.open.0M1")
       (-1/3 . "accidentals.mirroredflat")
       (-1/2 . "accidentals.flat")
       (-1 . "accidentals.flatflat")
       )

{ 
\override Score.Accidental #'glyph-name-alist =  \etTwentytwoGlyphs

\override Score.KeySignature #'glyph-name-alist = \etTwentytwoGlyphs

% test
% \relative { c4 ccu cscd cs d dcd dfcu df c }
% }



 \new Staff { \clef violin  

 {
   
 {
   c'4^\markup{standard pentachordal major}  dfcu'4  d'4  ecd'4  f'4  fscd'4  g'4  acd'4  bf'4  bcd'4  c''4 r4 \bar "||" \break 
}  
 {
   c'4^\markup{static symmetrical major}  dfcu'4  d'4  ecd'4  f'4  fscd'4  g'4  afcu'4  bf'4  bcd'4  c''4 r4 \bar "||" \break 
}  
 {
   c'4^\markup{alternate pentachordal major}  dfcu'4  ef'4  ecd'4  f'4  fscd'4  g'4  afcu'4  bf'4  bcd'4  c''4 r4 \bar "||" \break 
}  
 {
   c'4^\markup{dynamic symmetrical major}  dfcu'4  ef'4  ecd'4  f'4  fscd'4  g'4  acd'4  bf'4  bcd'4  c''4 r4 \bar "||" \break 
}  
 {
   c'4^\markup{standard pentachordal minor}  dfcu'4  d'4  efcu'4  f'4  fscd'4  g'4  afcu'4  a'4  bfcu'4  c''4 r4 \bar "||" \break 
}  
 {
   c'4^\markup{static symmetrical minor}  dfcu'4  d'4  efcu'4  f'4  fscd'4  g'4  afcu'4  a'4  bcd'4  c''4 r4 \bar "||" \break 
}  
 {
   c'4^\markup{alternate pentachordal minor}  dfcu'4  d'4  efcu'4  e'4  fscd'4  g'4  afcu'4  a'4  bcd'4  c''4 r4 \bar "||" \break 
}  
 {
   c'4^\markup{dynamic symmetrical minor}  dfcu'4  d'4  efcu'4  e'4  fscd'4  g'4  afcu'4  a'4  bfcu'4  c''4 r4 \bar "||" \break 
} 
} }

}