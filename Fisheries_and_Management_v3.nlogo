breed [fishers fisher]
breed [herrings herring]

globals [
    starvations
    kills 
    boat-deaths
    drag-factor
    safe
    mean-energy
    ]
    
patches-own [
    plankton
    zone
    ]
    
turtles-own [
    energy 
    cruise-speed
    wiggle-angle
    turn-angle 
    metabolism
    birth-energy
    age
   ]
    
fishers-own [
    fisher-field-of-view 
    fisher-sight-range 
    ]



to setup
    ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  set safe 1
    create-herrings herring-population [
        setxy random-xcor random-ycor
        set color grey
        set cruise-speed 1
        set shape "fish"
        set wiggle-angle 5
        set turn-angle 10 ;herring-turn-angle 
        set birth-energy 25 ;herring-birth-energy
        set energy random-float 100 
        set age random 200
        grow
    ]
    repeat fisher-population [make-fishers random-xcor random-ycor]
    ask patches [ set plankton random 3 ]
;; smooth out the plankton so the distribution is more homeogenous 
    repeat 5 [diffuse plankton 1 ]
    ask n-of zone_no patches [ set zone safe
                                      let targets patches in-radius zone_size
                                      ask targets [set zone safe]
                                      ]
    
;; scale the color of the patches to reflect the quantity of plankton on each patch
    ask patches [ set pcolor scale-color turquoise plankton 0 5 ]
    ;set fisher-deaths 0
    ;set starvations 0
    set drag-factor 0.5
    set kills 0
    set mean-energy 0
    
end
        
to go ;; main procedure
;;  plankton growth. If there is less than the threshold amount of plankton on a patch regrow it with a particular probability determined 
;; by the growth rate. We also diffuse the plankton to allow for the fact that plankton drift.
   ask patches [
       if (plankton < 5) [
           ;if ((random-float 100) < plankton-growth-rate) [ 
           ;   set plankton plankton  + 1  ] 
           set plankton plankton  + 1 ;plankton-growth-rate   ;growth rate on slider between 0 and 2 maybe
           ]  
       ]
   diffuse plankton 1        
;; scale the color of the patches to reflect the quantity of plankton on each patch
   ask patches [ ifelse (zone = safe) [
       set pcolor green
   ]
   [
     set pcolor scale-color turquoise plankton 6 0
   ]
     ] 

;; main minnow procedures   
    ask herrings [
        swim
        feed   ]
    ;if (herring-dynamics?) [
      ask herrings [ birth ] ;death ]
    ;]
    
 ;; main boat procedures
    ask fishers [ hunt ]
    ;if fisher-dynamics? [ ask fishers [ birth death ]]
    do-plots
    if kills > 2000 [stop]
    tick
end


;; create boats with the following paramter values. These values could be set with sliders
;; but it would make for crowded interface
to make-fishers [x y]
        create-fishers 1 [
            set heading random 360
            setxy x y
            set size 4
            set shape "boat"
            set wiggle-angle 5
            set turn-angle 10
            set fisher-sight-range 10
            set fisher-field-of-view 120
            set cruise-speed 1.5
            set energy 100
            set metabolism 0.3
            set birth-energy 25 ;fisher-birth-energy
            set color red
       ] 
end

;; main minnow procedure governing movement and loss of energy
to swim 
        set energy energy - metabolism
        let danger fishers in-cone sight-range field-of-view 
        ifelse ((any? danger) and escaping?)
          [set turn-angle herring-turn-angle * 3  ;; the turn angle for escaping is larger than normal by a factor of 3
           avoid min-one-of danger [distance myself ]
            fd escape-speed 
            set energy energy - escape-speed * drag-factor ]
          [ifelse schooling? [school][cruise]
      ]
end 


;; minnow or boat procedure which determines random motion when no predators or prey are near.
to cruise
   rt random wiggle-angle 
   lt random wiggle-angle
   fd cruise-speed
   set energy energy - cruise-speed * drag-factor
end


to hunt 
    set energy energy - metabolism
    let prey herrings in-cone fisher-sight-range fisher-field-of-view
    
    ifelse (([zone] of patch-here) = safe) 
    [
      
      
     
      cruise ]
    [
    ifelse ( any? prey )
        [ let targets prey in-radius 2 ;; minnows are eaten if they are with a radius of 2
          ifelse any? targets
          
              [ let totcatch sum [energy] of targets
                
                set kills kills + count targets 
                ask n-of (count targets) targets [die]
                set energy energy + totcatch  * 0.5 
                set mean-energy mean-energy + sum [energy] of fishers]
              [ ifelse hunting?  ;; if minnows are not close enough head towards them
                  [ approach min-one-of prey [distance myself] 
                    fd hunt-speed
                    set energy energy - hunt-speed * 4 ]
                  [ cruise ]  ;; if you are not hunting cruise around
               ] 
        ]  
        [ cruise ] ;; if you can't see any minnows just cruise around
    ]
end


;; minnow procedure governing schooling behaviour
to school
    let schoolmates herrings in-cone sight-range field-of-view with [distance myself > 0.1 ]
    ifelse any? schoolmates                                   ;; minnows you can see
        [let buddy min-one-of schoolmates [distance myself]   ;; closest minnow you can see
         ifelse distance buddy  < safety-range 
             [ set turn-angle herring-turn-angle           ;; avoid minnow if it is too slose
               avoid buddy  
             ]
 ;; if nobody is too close then turn towards each of the schoolmates in turn, by an angle that exponentially
 ;; decrease with distance. This ensures that the minnow is more influenced by closer minnows. After making these turns 
 ;; then try to align to the headings of each of the schoolmates in turn by an angle that exponentially 
 ;; decreases with distance.

             [ foreach sort schoolmates [  
                  set turn-angle herring-turn-angle * exp( ((distance buddy) - (distance ?) ) )
                  approach ?
                  align ? 
                  ]
             ]
          fd cruise-speed
          set energy energy - cruise-speed * drag-factor ] ;; after making adjustements in heading move
        [cruise]   ;; if you can't see any other minnows just cruise around
end

;; boat or minnow procedure to turn in the direction of a target turtle by at most the specified turn angle
to approach [target]
   let angle subtract-headings towards target heading
              ifelse (abs (angle) > turn-angle)
                  [ ifelse angle > 0 [right turn-angle ][left turn-angle] ]
                  [ right angle ] 
end

;; minnow procedure to turn in the direction of the heading of a target turtle by at most the specified turn angle
to align [target]
   let angle subtract-headings [heading] of target heading
              ifelse (abs (angle) > turn-angle)
                  [ ifelse (angle > 0) [right turn-angle ][left turn-angle] ]
                  [ right angle ] 
end

;; minnow procedure to turn in the direction away from a target turtle by at most the specified turn angle
to avoid [target]
   let angle subtract-headings ((towards target) + 180) heading
              ifelse (abs(angle) > turn-angle)
                  [ ifelse (angle > 0) [right turn-angle ][left turn-angle] ]
                  [ right angle ] 
end


;; minnow procedure. If there is plankton on the patch eat it to gain energy and reduce the plankton count on the patch.
to feed
    if (plankton > 1) [
        set energy energy + 1 ; herring-food-energy
        set plankton plankton - 3 ]
end

;; minnow and boat procedure if your enery exceeds a threshold hatch an offspring with energy = birth energy and
;; reduce your energy accordingly
to birth
    if (energy > 2 * birth-energy) [
        set energy energy - birth-energy
        hatch 1 [ 
           set energy birth-energy 
           set heading random 360
           fd cruise-speed ] ]
end


;; minnow and boat procedure for removing turtles with energy below zero
to death
    ;; first check for random deaths
    let mort_rate 0.0
    let mort_check random-float 1
        ifelse (breed = herrings)
            [set mort_rate herrings_mort_rate]
            [set mort_rate herrings_mort_rate]
        if (mort_rate > mort_check) [ die ]
    
    ;; now check for metabolic death
    if energy < 0 [ 
        if (breed = herrings)
            [set starvations starvations + 1]
        ;    [set fisher-deaths boat-deaths + 1]
        die ]
end

;; minnow procedure to color and size the minnows so that their age and energy are visually apparant
to grow
        ifelse (age > 300 )
           [set size 2 ]
           [set size 1 + age * 0.003 ]
       set color scale-color color (energy ) 0  (200 + birth-energy)
end

to do-plots
  set-current-plot "Population"
    set-current-plot-pen "herrings"
    plot count herrings
    set-current-plot-pen "fishers"
    plot count fishers
    ;set-current-plot-pen "plankton"
    ;plot sum [plankton] of patches
    
    set-current-plot "energy"
    set-current-plot-pen "energy"
    plot sum [energy] of fishers
    set-current-plot-pen "kill"
    plot sum [energy] of herrings
    set-current-plot-pen "pen-1"
    plot 0
end
@#$#@#$#@
GRAPHICS-WINDOW
309
10
729
451
20
20
10.0
1
10
1
1
1
0
1
1
1
-20
20
-20
20
0
0
1
ticks
30.0

BUTTON
737
10
817
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
5
33
146
66
herring-population
herring-population
0
100
84
1
1
NIL
HORIZONTAL

BUTTON
824
10
880
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
883
10
950
55
Herrings
count herrings
3
1
11

SLIDER
5
68
146
101
herring-food-energy
herring-food-energy
0
10
10
1
1
NIL
HORIZONTAL

MONITOR
951
10
1009
55
Fishers
count fishers
3
1
11

SLIDER
171
67
296
100
fisher-food-energy
fisher-food-energy
0
50
8
1
1
NIL
HORIZONTAL

SLIDER
169
256
298
289
field-of-view
field-of-view
0
360
360
1
1
NIL
HORIZONTAL

SWITCH
172
181
296
214
schooling?
schooling?
0
1
-1000

SLIDER
172
32
296
65
fisher-population
fisher-population
0
20
5
1
1
NIL
HORIZONTAL

PLOT
741
56
1008
232
Population
time
population
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"herrings" 1.0 0 -7500403 true "" ""
"fishers" 1.0 0 -2674135 true "" ""

SWITCH
5
178
146
211
hunting?
hunting?
0
1
-1000

SWITCH
6
140
147
173
escaping?
escaping?
0
1
-1000

SLIDER
5
104
146
137
herring-birth-energy
herring-birth-energy
0
50
8
1
1
NIL
HORIZONTAL

SLIDER
170
103
296
136
fisher-birth-energy
fisher-birth-energy
0
50
11
1
1
NIL
HORIZONTAL

SLIDER
172
140
297
173
escape-speed
escape-speed
0
4
0.8
0.1
1
NIL
HORIZONTAL

SLIDER
170
217
297
250
hunt-speed
hunt-speed
0
10
1.8
0.1
1
NIL
HORIZONTAL

SLIDER
168
296
296
329
herring-turn-angle
herring-turn-angle
0
20
14
1
1
NIL
HORIZONTAL

SLIDER
5
217
145
250
sight-range
sight-range
0
20
4
1
1
NIL
HORIZONTAL

SLIDER
4
255
146
288
safety-range
safety-range
0
5
0.6
0.1
1
NIL
HORIZONTAL

MONITOR
778
445
874
490
NIL
mean-energy
3
1
11

MONITOR
917
446
974
491
NIL
kills
3
1
11

SLIDER
5
296
146
329
herrings_mort_rate
herrings_mort_rate
0
1.0
0.29
0.01
1
NIL
HORIZONTAL

SLIDER
5
332
296
365
fishers_mort_rate
fishers_mort_rate
0
1.0
0.115
0.001
1
NIL
HORIZONTAL

PLOT
740
244
1005
434
energy
NIL
NIL
0.0
20.0
0.0
10.0
true
true
"" ""
PENS
"energy" 1.0 0 -16777216 true "" ""
"pen-1" 1.0 0 -7500403 true "" ""
"kill" 1.0 0 -2674135 true "" ""

SLIDER
336
455
508
488
zone_no
zone_no
0
20
4
1
1
NIL
HORIZONTAL

SLIDER
546
455
718
488
zone_size
zone_size
0
10
7
1
1
NIL
HORIZONTAL

TEXTBOX
20
12
289
46
Fishers, fish and plankton interaction
14
0.0
1

TEXTBOX
7
367
310
549
In this model the green plankton grow, the swarming fish move around and eat the plankton while growing and breeding and the fishing boats use fuel to  chase the fish collecting energy. Increase the number of boats to say 6 and watch the fish population collapse. Try adding some no-fishing reserves (zone_no) to help stabilise the fish population. What settings make the fishers energy increase while the fish numbers remain stable?
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This is a predator-prey model, with fishing boats as predators and minnows as prey and plankton as food source. The minnows also feed on plankton, which is continuously regenerated. The difference between this and other predator prey models is that there are options to (a) have the fishing boats hunt minnows (b) have the minnows try to escape from the boats and (c) let the minnows school. Plus there is the option of modifying the behaviour of the fishing boats by adding in no-fish reserves. There is quantitatively different population dynamics when each of these options is selected. This model therefore serves to show the versatility of agent based modeling in complex population dynamics.

## HOW IT WORKS

Without hunting, evading or schooling, the predator-prey part of the model works as follows.  Fishing boats and minnows move about at random, when a boat finds itself on the same patch as a minnow it consumes it and gains some food-energy. Minnows are constantly grazing on available plankton and gaining energy if they find some. Plankton is replenished at a particular rate.  Boats and minnows also lose energy at a rate determined by their fuel consumption/metabolism and at a rate proportional to their speed. In this way a faster speed is more costly. If minnows gain enough energy they produce one offspring, giving it losing an amount of energy called birth-energy, and giving it to their offspring. If the energy of a minnow falls below 0 they die.

Hunting Option: If boats are allowed to hunt they swim at random unless they sense at least one minnow in a cone determined by their field of view and sight range. Then they try to turn towards the nearest of these minnows and move forward at a hunting speed, which is set by a slider. Their ability to turn is limited by a maximum turn angle.  

Escaping Option: If minnows are allowed to escape, they swim at random unless they sense one or more boats in a cone determined by their field of view and sight range. In this case they turn away from the nearest of these boats and move forward at an escaping speed which is set by a slider. Their ability to turn is limited by a maximum turn angle called the escaping angle

Schooling Option: If minnows are allowed to school then they will try to do so provided they sense no boats. Schooling is governed by three behaviors: avoiding, approaching and aligning. First, if there is a fellow minnow that is too close (as determined by a safety range which is set by a slider), a minnow will avoid it by turning away from it and moving forward. If there is no minnow that is too close, then a minnow will look at all the minnows in its cone of view and attempt to change its heading towards each of them in turn. The angle that it can turn is weighted by how close the minnow is to it. It makes more of an effort to turn towards closer minnows. After doing this it will try to align itself with the same heading as all the minnows in its cone of view, again turning by at most an angle, which is weighted by how close the minnow is to it. This procedure is slightly different from other methods of mimicking flocking and schooling in that there is nothing probabilistic and there is no averaging of headings (see the flocking module in the NetLogo models library, for example). 

## HOW TO USE IT

Choose the initial populations, food energy, metabolism and birth-energy for the vessels and minnows, and choose a growth rate for the plankton. Then click setup and go. You may choose any of the options, hunting, escaping or schooling at anytime that it Is running. Each of these options has its own sliders that govern the behavior. You can set speeds for escaping and hunting, and you can set the parameters that govern schooling, including the turn angle, which determines the maximum amount a minnow can turn, the sight-range which is the distance a minnow can see, the field of view, and the safety range, which is the closest a minnow will approach an other minnow before trying to avoid it.  You can also turn the minnow dynamics off if you want to study some behavior, such as schooling, without worrying about minnows dying or being born.

At anytime you can add a boat by clicking on the world view. You can remove boat or harvest minnows by clicking on the relevant buttons.

## THINGS TO NOTICE

The dynamics can be quite complicated, and the survival of the boats and minnows can be quite sensitive to the parameter choices. As with most predator prey models, wild oscillations in population size occur quite often, and typically precede an extinction of one or both species. It should be possible to find parameter choices where the populations are relatively stable. 

The escaping, hunting and schooling options can change the dynamics dramatically, but not always in the way expected. With escaping and hunting both on there are typically fewer wild oscillations in population, and minnow population tends to increase. With schooling turned on, there is only a noticeable difference in dynamics for cases where there are relatively few boats. When there are a lot of boats the minnows do not have much time to school.

## THINGS TO TRY

Try finding parameter choices that lead to relatively stable populations of boats and minnows with the hunting, escaping and schooling options off. Now try adding each of these options in turn to see what happens. Try the same thing with different combinations of these options.

In particular try adding some no-fishing reserves. The boats can cross the reserves but no fishing is allowed. So it costs fuel to go into reserves, the more reserves the more energy is expended. the fish can however breed up in these spaces and you can find a set of parameters that allow the most fish numbers with the most boats given a number of reserves.

If you have oscillating population dynamics, try harvesting minnows and different times to see if you can stabilize the population.



## EXTENDING THE MODEL

There are a lot of parameters in this model, not all of which are shown on the sliders. One might ask the question � what values of these parameters optimize the total numbers of minnows, what values optimize the total number of boats? One possible way to answer these questions would be to allow the parameters to change dynamically, by having new minnows and boats have slightly modified values of these parameters. Over time the values would change, and the �fittest� minnows and boats would emerge. This may or may not result in more minnows and boats.


## RELATED MODELS

This model is adapted from David McAvity  (Evergreen State College) model on shark-minnow population dynamics. 

## COPYRIGHT NOTICE

   Copyright 2012 Stuart Kininmonth, Eyram Apetcho, Susanna Nurdjamman, Fi Prowe and Anna  Luzenczyk.

This model was created at the IMBER workshop in Ankara, Turkey. 

   
The model may be freely used, modified and redistributed provided this copyright is included and it not used for profit.

Contact Stuart Kininmonth at stuart.kininmonth@stockholmresilience.su.se if you have questions about its use. 
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

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

minnow
true
0
Polygon -7500403 true true 150 15 136 32 118 80 105 90 90 120 105 120 115 145 125 208 131 259 120 285 135 285 165 285 150 261 167 208 177 141 180 120 195 120 195 105 178 80 162 32

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
true
0
Polygon -7500403 true true 150 15 164 32 182 80 204 98 210 113 189 117 185 145 175 208 169 259 200 277 168 276 135 298 150 261 133 208 123 141 123 116 99 123 104 106 122 80 138 32

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
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
