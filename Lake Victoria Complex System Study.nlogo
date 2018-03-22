; I initally used Wilensky's Wolf Sheep Predation Model to code this program (please see "Information" section).  However, I 
; ended up reprograming from scratch.

breed [cichlids cichlid] 
breed [other-fish an-other-fish] 
breed [nile-perch a-nile-perch]
breed [fishermen fisherman]
turtles-own [energy]      ; all agents have energy (Chiclids, nile-perch, and other-fishes)
patches-own [countdown]

;start of setup phase
to setup
  clear-all
  ask patches [ set pcolor green ]
  if biomass?
    [ask patches [
      set countdown random biomass-regrowth-time 
      set pcolor one-of [green blue]]]
    
  if staticbiomass? ;this command sets all the biomass to green
  [ask patches 
         [set pcolor green]]
                
  
  set-default-shape other-fish "fish 3"
  create-other-fish initial-number-other-fish  ; these are the "other-fish" in the Lake Victoria example, such as the Daga
  [
    set color white
    set size 1.5 
    set label-color blue - 2
    set energy random (2 * other-fish-gain-from-food)
    setxy random-xcor random-ycor
  ]
  
  set-default-shape cichlids "fish"
  create-cichlids initial-number-cichlids  ;; these are the "chiclids" for the Lake Victoria example
  [
    set color yellow
    set size 1.5
    set label-color blue - 2
    set energy random (2 * cichlid-gain-from-food)
    setxy random-xcor random-ycor
  ]
     
  set-default-shape nile-perch "shark"
  create-nile-perch initial-number-nile-perch  ;; creates the nile-perch, which are the predators in this model
  [
    set color red
    set size 3.0  
    set energy random (other-fish-gain-from-food + cichlid-gain-from-food)
    setxy random-xcor random-ycor
  ]
  
  set-default-shape fishermen "boat"
  create-ordered-fishermen initial-number-fishermen ;;creates fishermen
  [
  set color orange
  set size 6
  facexy -2 0
  setxy random-xcor random-ycor
  ]
     
  display-labels
  update-plot1
  update-plot2
end

;end of setup and start of "go"

to go
  if not any? turtles [ stop ]
  if count patches with [ pcolor = green ] <= 5 [stop]
  if trialrun? and ticks >= 500 [stop]
   ask cichlids [
    move
    if biomass? [
      set energy energy - 1.1  ; this represents an animals energy cost to movement, note that the value differs from the other species
      eat-chiclid
    ]
    reproduce-chiclids
    death
  ]
  ask other-fish [
    move
    if biomass? [
      set energy energy - .9  ; this represents the other fish's energy cost to movement
      eat-other-fish
    ]
    reproduce-other-fish
    death
  ]
  ask-concurrent nile-perch [
    move
    set energy energy - .9  ; this represents an animals energy cost to movement
    if count cichlids >= cichlid-critical [catch-chiclids]
    if count other-fish >= other-fish-critical [catch-other-fish]
    reproduce-nile-perch
    death
  ]
    
  ask-concurrent fishermen [ ;;fishermen behavior may be buggy - not tested
    if troll? 
          [troll]
    if random?
          [move]
    if hunt-cichlids?
          [hunt-chiclids]
    if catch-nile-perch? [catch-nile-perch]]
  ask fishermen
     [if catch-other-fish?
      [catch-other-fishF]]
      
   ask fishermen
     [if catch-cichlids?
    [catch-chiclidsF]
    ]
  ask patches
    [if not staticbiomass? [produce-biomass]]
  tick
  update-plot1
  update-plot2
  update-plot3
  display-labels
end

to move  ;; turtle procedure
  rt random 50
  lt random 50
  fd 1
end

to troll ; fishermen will "troll" rather than move randomly
   rt 0
   fd 1
end

to hunt-chiclids
  if count cichlids > 0
  [
  set heading towards one-of cichlids
  fd 1
  ]
  end
    
to eat-chiclid  ;; chiclid procedure
    if pcolor = green [
    set pcolor blue
    set energy energy + cichlid-gain-from-food]  ;; transformation of biomass into energy
end

to eat-other-fish  ;; other-fish procedure
    if pcolor = green [
    set pcolor blue
    set energy energy + other-fish-gain-from-food]  ;; transformation of biomass into energy
end
    
to reproduce-other-fish  ;; Other Fish Procedure
  if random-float 100 < other-fish-reproduce [  ;; throw "dice" to see if other-fish will reproduce
    set energy (energy / 2)                ;; divide energy between parent and offspring
    hatch 1 [ rt random-float 360 fd 1 ]   ;; spawn an Other Fish and move it forward 1 step
  ]
end

to reproduce-chiclids  ;; Cichlid Procedure
  if random-float 100 < cichlid-reproduce [  ;; throw "dice" to see if a cichlid will reproduce
    set energy (energy / 2)                ;; divide energy between parent and offspring
    hatch 1 [ rt random-float 360 fd 1 ]   ;; spawn a Cichlid and move it forward 1 step
  ]
end

to reproduce-nile-perch  ;; Nile Perch procedure
  if random-float 100 < nile-perch-reproduce [  ;; throw "dice" to see if a nile-perch will reproduce
    set energy (energy / 2)               ;; divide energy between parent and offspring
    hatch 1 [ rt random-float 360 fd 1 ]  ;; spawn a nile perch and move it forward 1 step
  ]
end

to catch-chiclids  ;; Nile Perch catching Cichlids
  ask nile-perch
      [let prey one-of cichlids-here                    ;; tries to locate a chiclid
  if prey != nobody
       [set energy energy + [energy] of prey]                        
  if prey != nobody 
   [ ask prey [ die ]]]                
      ;; gains energy from eating
end

to catch-other-fish  ;; Nile Perch catching other fish agent
   ask nile-perch 
        [let prey one-of other-fish-here             ;; tries to locate an other-fish
  if prey != nobody
  [set energy energy + [energy] of prey]                
  if prey != nobody
   [ ask prey [ die ]]]         
       ;; gains energy from eating
end

to catch-nile-perch
  ask fishermen
    [let prey one-of nile-perch-here
      if prey != nobody 
       [set energy energy + [energy] of prey]
      if prey != nobody
         [ ask prey [die]]]
        end
        
to catch-chiclidsF  ;;Fishermen catching Cichlids
  ask fishermen
      [let prey one-of cichlids-here                    ;; tries to locate a chiclid
  if prey != nobody
       [set energy energy + [energy] of prey]                        
  if prey != nobody 
   [ ask prey [ die ]]]  
        end
to catch-other-fishF  ;; Fishermen catching other fish agent
   ask fishermen
        [let prey one-of other-fish-here             ;; tries to locate an other-fish
  if prey != nobody
  [set energy energy + [energy] of prey]                
  if prey != nobody
   [ ask prey [ die ]]] 
   
   
end
   
to death  ;; procedure for turtles (cichlids, other fish, nile perch)
  ;; when energy dips below zero, die
  if energy < 0 [ die ]
end


to produce-biomass  
  if pcolor = blue 
    [ifelse countdown <= 0
      [ set pcolor green
        set countdown biomass-regrowth-time ]
      [ set countdown countdown - 1 ]]
  end

;plots and graphs

to update-plot1
  set-current-plot "Species-Population"
  set-current-plot-pen "Other Fish"
  plot count other-fish
  set-current-plot-pen "Nile Perch"
  plot count nile-perch
  set-current-plot-pen "Cichlids"
  plot count cichlids
  if biomass?
    [set-current-plot-pen "Biomass"
    plot count patches with [pcolor = green] / 4]  ;; division is so the graph levels are similar
   
end

to update-plot2
  set-current-plot "Ecostystem-Species-Distribution"
  set-current-plot-pen "Other Fish %"
  plot count other-fish / count turtles
  set-current-plot-pen "Cichlid %"
  plot count cichlids / count turtles
  set-current-plot-pen "Nile Perch %"
  plot count nile-perch / count turtles
  end
    
to update-plot3
  set-current-plot "Fishermen"
  set-current-plot-pen "Total Energy Gain"
  plot sum [ energy ] of fishermen
  end

    
to display-labels
  ask turtles [ set label "" ]
  if show-energy? [
    ask nile-perch [ set label round energy ]
    ask fishermen [set label round energy]
    if biomass? [ ask cichlids [ set label round energy ] ]
    if biomass? [ ask other-fish [set label round energy]]]
  end

;;This model was created by Alexander R. F. Marlantes, 2008.  Please reaech me at amarlantes@ucla.edu if you have any questions.  I hope someone finds it useful.
@#$#@#$#@
GRAPHICS-WINDOW
203
10
831
659
25
25
12.12
1
14
1
1
1
0
1
1
1
-25
25
-25
25
1
1
1
ticks

SLIDER
1
126
175
159
initial-number-cichlids
initial-number-cichlids
0
200
180
1
1
NIL
HORIZONTAL

SLIDER
1
163
175
196
cichlid-gain-from-food
cichlid-gain-from-food
0.0
50.0
7
1.0
1
NIL
HORIZONTAL

SLIDER
1
198
175
231
cichlid-reproduce
cichlid-reproduce
1.0
20.0
5
1.0
1
%
HORIZONTAL

SLIDER
3
423
185
456
initial-number-nile-perch
initial-number-nile-perch
0
250
25
1
1
NIL
HORIZONTAL

SLIDER
2
459
185
492
nile-perch-reproduce
nile-perch-reproduce
0.0
20.0
4
1.0
1
%
HORIZONTAL

SWITCH
0
29
90
62
biomass?
biomass?
0
1
-1000

SLIDER
1
64
201
97
biomass-regrowth-time
biomass-regrowth-time
0
100
60
1
1
NIL
HORIZONTAL

BUTTON
834
17
903
50
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
835
56
902
89
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

PLOT
-1
711
315
908
Species-Population
Time (iterations)
Population
0.0
100.0
0.0
100.0
true
true
PENS
"Other Fish" 1.0 0 -13345367 true
"Nile Perch" 1.0 0 -2674135 true
"Biomass" 1.0 0 -10899396 true
"Cichlids" 1.0 0 -16777216 true

MONITOR
5
663
76
708
Chiclids
count cichlids
3
1
11

MONITOR
167
663
249
708
Nile Perch
count nile-perch
3
1
11

MONITOR
253
663
347
708
Biomass Locations
count patches with [ pcolor = green ]
0
1
11

TEXTBOX
6
106
146
125
Cichlid settings
11
0.0
0

TEXTBOX
8
403
121
421
Nile Perch settings
11
0.0
0

TEXTBOX
6
10
158
28
Biomass settings
11
0.0
0

SWITCH
906
55
1021
88
show-energy?
show-energy?
1
1
-1000

MONITOR
81
662
162
707
Other Fish
count other-fish
17
1
11

TEXTBOX
7
246
157
264
Other Fish
11
0.0
1

SLIDER
5
271
187
304
initial-number-other-fish
initial-number-other-fish
0
200
35
1
1
NIL
HORIZONTAL

SLIDER
3
313
188
346
other-fish-gain-from-food
other-fish-gain-from-food
0
50
7
1
1
NIL
HORIZONTAL

SLIDER
5
356
186
389
other-fish-reproduce
other-fish-reproduce
0
20
4
1
1
%
HORIZONTAL

SLIDER
835
92
868
242
cichlid-critical
cichlid-critical
0
400
5
5
1
NIL
VERTICAL

SLIDER
878
93
911
243
other-fish-critical
other-fish-critical
0
400
20
5
1
NIL
VERTICAL

PLOT
323
711
629
908
Ecostystem-Species-Distribution
Time (iterations)
% of Total Pop.
0.0
10.0
0.0
1.0
true
true
PENS
"Cichlid %" 1.0 0 -16777216 true
"Other Fish %" 1.0 0 -13345367 true
"Nile Perch %" 1.0 0 -2674135 true

MONITOR
395
662
497
707
Total Population
count turtles
17
1
11

SLIDER
834
249
867
402
initial-number-fishermen
initial-number-fishermen
0
50
4
1
1
NIL
VERTICAL

MONITOR
949
540
1006
585
Biomass
count patches with [ pcolor = green ] * other-fish-gain-from-food
17
1
11

SLIDER
875
251
908
401
nile-perch-critical
nile-perch-critical
0
50
0
1
1
NIL
VERTICAL

MONITOR
834
413
1004
458
Static Bio-Biomass Extracted
((count patches) - (count patches with [ pcolor = green ])) * other-fish-gain-from-food
17
1
11

PLOT
637
712
881
906
Fishermen
Time
Total Energy Gain
0.0
10.0
0.0
10.0
true
true
PENS
"Total Energy Gain" 1.0 0 -16777216 true

SWITCH
87
29
202
62
staticbiomass?
staticbiomass?
1
1
-1000

SWITCH
508
669
642
702
catch-cichlids?
catch-cichlids?
1
1
-1000

SWITCH
645
669
795
702
catch-other-fish?
catch-other-fish?
1
1
-1000

SWITCH
797
669
947
702
catch-nile-perch?
catch-nile-perch?
0
1
-1000

SWITCH
833
569
936
602
troll?
troll?
0
1
-1000

SWITCH
834
529
937
562
random?
random?
1
1
-1000

SWITCH
906
18
996
51
trialrun?
trialrun?
0
1
-1000

TEXTBOX
837
463
987
481
Fishermen Movement
11
0.0
1

SWITCH
834
493
963
526
hunt-cichlids?
hunt-cichlids?
1
1
-1000

@#$#@#$#@

WHAT IS IT?
This model was created after studying Chu et al's Lake Victoria Story paper and Wilensky's Wolf Sheep Predation model as part of the UCLA Human Complex Systems program.   Although the program was eventually re-written from the bottom up, the Wolf-Sheep Predation model was instrumental to the design and the proper citation can be found at the end.

This simulation models the biological statespace of Lake Victoria, replete with biomass, two different secondary species, and a tertiary predator.  The simulation assigns very basic agent based rules to each agent class and records the ensuing systemic complexity and aggregate behavior via graphs below the viewing area.

Lake Victoria had a stable ecosystem consisting of 80% Cichlid fish by biomass.  Surrounding fisherman desired a more commercially marketable fish and introduced a larger predator, the Nile Perch, in hopes of selling the fish in foreign markets.  Many ecologists believed that because the Nile Perch had no natural predators their population would quickly balloon.  It was hypothesized that this would lead to the decimation of the Cichlid species due to over predation, which in turn would cause the Nile Perch to die off, having exterminated their food source.  However, Lake Victoria’s ecosystem did not implode.  This simulation attempts to shed light on the agent based behavior and mechanisms behind this turn of events.

As a further point of modeling interest a human element has been added.  Considering that the Nile Perch were introduced via human agency, I thought it would be interesting to model the effect of different situations upon fishermen.  One of the questions that might be of interest is determining the most effective method for fishermen to extract biomass from the lake.  The whole system can be seen as a delivery mechanism of the sun's energy to humans.  The initial solar energy is transferred through a layered conversion process in which energy is lost and complexity gained.  The sun’s initial energy is captured by biomass such as algae, then Cichlids and other fish consume the biomass, who are finally consumed once again by the Nile Perch, which are the final repository of this chain (outside of humans).  Holding this view, fishing can be seen as an energy recovery optimization problem.

A  model therefore might lend insight into how tinkering with an ecosystem can provide the best results for humans.  For example, it might be found that establishing hunting laws that specify minimum species levels could lead to an increase commercial profitability.  These minimum levels are represent in the model with the “critical” level slider.

HOW IT WORKS
The eco system is populated depending on slider values.  The agents then move around the lake randomly.  Each agent has an “energy” value which represents how much of the lake system’s energy they have accrued.  Cichlids, Nile Perch, and Other Fish all have to expend a variable energy unit each time they move randomly.  I added Fishermen to enrich the model, but I have not tested it extensively.  They do not reproduce or die, spend no energy moving, and gain cumulative energy from catching fish (hunting only Nile Perch is the current default).

The lake can either have a constant nutritional landscape (all green) or food which when eaten re-grows, in which case a blue patch representing water without any nutrients replaces the consumed biomass until it regrows.  The “Static-Biomass” mode is an experimental mode in which the biomass does not grow back.  Users may find this useful for questions such as, “what is the most efficient way for a fisherman to extract the energy in the lake?”  These are all set by sliders.  In order to gain energy the Cichlid and Other-Fish eat the biomass and gain a set level of energy determined by the sliders.  Nile Perch and Fishermen gain whatever the current energy the prey had.  For example, a Nile Perch caught on the verge of death will give the fishermen much less energy than a health Nile Perch.  All fish populations have a fixed probability of reproducing per iteration, which is determined by sliders on the left.  At the point of reproduction a clone of that fish is spawned and the parent and offspring split the parent’s current energy (half of their current energy goes to the clone).

Please take a look at the code itself to see each individual agent’s instructions.

THINGS TO NOTICE
I think one of the more interesting aspects of this model is that an increase in complexity actually leads to an increase in system stability.  This concept runs contrary to the popular mantra of simplicity leading to stability.  Complexity need not necessarily lead to a collapse in a system. 

For example, the system is unstable when there is no accounting for biomass (unlimited food) and results in the extinction of one or more species involved due to the “boom and bust” phenomenon.  In contrast, the system stabilizes, despite fluctuations in population sizes if a third layer in the ecosystem is added (biomass).
Alfred Lotka and Vito Volterra developed a predator prey model in the early 1920’s that uses differential equations to model the fluctuations between the two populations.

Studying the Lars Volta species predation model lends some insight into this problem. The main cause of species extinction seems to be a large boom in a species due to overfeeding.  This boom causes a predator level to become so high that they in fact devour the entire species they prey on, causing the predator population to quickly self implode.  One interesting question this raises is how an agent based model differs from an equation based model.  What are the strengths and weaknesses of each?  The  Lotka-Volterra expression of half a single predator-prey dyad is expressed as a differential equation, as seen below:
dx / [dt] = Rx x (Kx – x – ?xy Y) / [Kx]
 

Where  rx and ry are the inherent growth rates of the respective species, Kx and Ky are the environmental carrying capacity for each species, and ?xy represents the predation effect that species X has on species Y.   In this simulation, those differential equations are replaced by rule based behavior, which judging by the similar graphs, leads to a similar result.

------------

HOW TO USE IT
The “Trial Run” switch causes the simulation to stop after 500 iterations.  This could be useful for comparative benchmarks or exporting data to Excel.
The “critical level” sliders found on the right cause a species population to never fall under that set level.  This can be useful for people interested in hunting and population control or the effects of species extinction and criticality.
Fishermen can move in different ways.  “Troll” causes the fishermen to move horizontally across the screen as opposed to the default random movement.  Activating “Hunt-Cichlid” will cause the boats to give a slight preference to cichlids, should they be told to harvest that species.
The “biomass-regrowth-time” slider sets how many iterations (the fewer the quicker) before a green food slot reappears.
The graphs can be found below the simulation view space.

THINGS TO TRY
Try using this simulation to explore Rosenzweig’s notion of “The Paradox of Enrichment.”   What happens when there is an abundant food source?  What happens when populations are only allowed to grow so big?  If you were a regulatory agency what sort of policies would you employ?
What systems are stable?  What systems will always crash?   Which systems are the most advantageous to the fishermen?  Can a marginal effectiveness be determined for fishing boats (i.e., does the 5th boat introduced catch less fish per boat than if there were only 1)?

EXTENDING THE MODEL
One possible project could be to create a much larger and dynamic food pyramid eco-system.  Originally I had set levels of food gained when the Nile Perch or fishermen caught a fish.  I thought that implementing a fluid system in which the energy passes up the food chain depending on the specific prey’s energy status would be more realistic and provide greater transparency to the process.  Taking this simulation and using it to make a food pyramid with 5 or 6 layers and many more species could be very interesting.  This could allow one to model system shocks of removing one layer of a pryamid to see if any emergent solutions arise.

CREDITS AND REFERENCES

Fluctuations of the sizes of predatory lynx and prey hare populations in Northern
Canada from 1845 to 1935. From Life: The Science of Biology (3rd ed., Figure 46.7B, p. 1060), by W. Purves, G. Orian, and H. Heller, 1992, Sunderland, MA: Sinauer. Copyright 1992 by Sinauer Associates.

Wilensky, U. (1997).  NetLogo Wolf Sheep Predation model.  http://ccl.northwestern.edu/netlogo/models/WolfSheepPredation.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL. 

Chu, D., R. Strand & R. Fjelland (2003). “Theories of Complexity.” Complexity, 8: 19–30.

This model was created by Alexander R. F. Marlantes, UCLA, 2008.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

boat
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

crab
true
0
Polygon -1184463 true false 216 204 241 233 247 254 229 266 216 252 194 210
Polygon -1184463 true false 195 90 225 75 245 75 255 60 225 45 255 90 240 105 225 105 210 105
Polygon -1184463 true false 105 90 75 75 45 45 75 30 60 60 45 90 60 105 75 105 90 105
Polygon -2674135 true false 130 84 132 63 105 50 106 16 148 1 190 17 190 51 167 64 170 86
Polygon -1184463 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -955883 true false 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99
Circle -16777216 false false 122 24 16
Circle -16777216 false false 151 24 19
Circle -16777216 true false 121 24 17
Circle -16777216 true false 150 23 20

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

fish 3
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1184463 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -1 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -1 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -1 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

shark
false
0
Polygon -7500403 true true 283 153 288 149 271 146 301 145 300 138 247 119 190 107 104 117 54 133 39 134 10 99 9 112 19 142 9 175 10 185 40 158 69 154 64 164 80 161 86 156 132 160 209 164
Polygon -7500403 true true 199 161 152 166 137 164 169 154
Polygon -7500403 true true 188 108 172 83 160 74 156 76 159 97 153 112
Circle -16777216 true false 256 129 12
Line -16777216 false 222 134 222 150
Line -16777216 false 217 134 217 150
Line -16777216 false 212 134 212 150
Polygon -7500403 true true 78 125 62 118 63 130
Polygon -7500403 true true 121 157 105 161 101 156 106 152

sheep
false
0
Rectangle -16777216 true false 166 225 195 285
Rectangle -16777216 true false 62 225 90 285
Rectangle -7500403 true true 30 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 180 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -6459832 true false 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Rectangle -7500403 true true 195 106 285 150
Rectangle -7500403 true true 195 90 255 105
Polygon -7500403 true true 240 90 217 44 196 90
Polygon -16777216 true false 234 89 218 59 203 89
Rectangle -1 true false 240 93 252 105
Rectangle -16777216 true false 242 96 249 104
Rectangle -16777216 true false 241 125 285 139
Polygon -1 true false 285 125 277 138 269 125
Polygon -1 true false 269 140 262 125 256 140
Rectangle -7500403 true true 45 120 195 195
Rectangle -7500403 true true 45 114 185 120
Rectangle -7500403 true true 165 195 180 270
Rectangle -7500403 true true 60 195 75 270
Polygon -7500403 true true 45 105 15 30 15 75 45 150 60 120

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 4.1
@#$#@#$#@
setup
set grass? true
repeat 75 [ go ]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count chiclids</metric>
    <metric>count other-fish</metric>
    <metric>count nile-perch</metric>
    <enumeratedValueSet variable="trialrun?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-other-fish">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="troll?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-nile-perch">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cichlid-reproduce">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-fish-critical">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunt-cichlids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="catch-chiclids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="biomass-regrowth-time">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-fish-gain-from-food">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cichlid-critical">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="staticbiomass?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="biomass?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="catch-other-fish?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-fishermen">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nile-perch-reproduce">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-energy?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-fish-reproduce">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="catch-nile-perch?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nile-perch-critical">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cichlid-gain-from-food">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-cichlids">
      <value value="180"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
