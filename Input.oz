%Input.Oz
%Don't change any names, change only the values
functor
export
   isTurnByTurn:IsTurnByTurn
   nRow:NRow
   nColumn:NColumn
   map:Map
   nbPlayer:NbPlayer
   players:Players
   colors:Colors
   thinkMin:ThinkMin
   thinkMax:ThinkMax
   turnSurface:TurnSurface
   maxDamage:MaxDamage
   missile:Missile
   mine:Mine
   sonar:Sonar
   drone:Drone
   minDistanceMine:MinDistanceMine
   maxDistanceMine:MaxDistanceMine
   minDistanceMissile:MinDistanceMissile
   maxDistanceMissile:MaxDistanceMissile
   guiDelay:GUIDelay
define
   IsTurnByTurn
   NRow
   NColumn
   Map
   NbPlayer
   Players
   Colors
   ThinkMin
   ThinkMax
   TurnSurface
   MaxDamage
   Missile
   Mine
   Sonar
   Drone
   MinDistanceMine
   MaxDistanceMine
   MinDistanceMissile
   MaxDistanceMissile
   GUIDelay
in

%%%% Style of game %%%%

   IsTurnByTurn = true

%%%% Description of the map %%%%

   NRow = 5
   NColumn = 6

   Map = [[0 0 0 0 0 0]
	  [0 0 0 0 0 0]
	  [0 0 0 1 1 0]
	  [0 0 1 1 0 0]
	  [0 0 0 0 0 0]]

%%%% Players description %%%%

   NbPlayer = 2
   Players = [player1 player2]
   Colors = [yellow green]

%%%% Thinking parameters (only in simultaneous) %%%%

   ThinkMin = 500
   ThinkMax = 3000

%%%% Surface time/turns %%%%

   TurnSurface = 2

%%%% Life %%%%

   MaxDamage = 4

%%%% Number of load for each item %%%%

   Missile = 2
   Mine = 1
   Sonar = 3
   Drone = 2

%%%% Distances of placement %%%%

   MinDistanceMine = 1
   MaxDistanceMine = 2
   MinDistanceMissile = 1
   MaxDistanceMissile = 4

%%%% Waiting time for the GUI between each effect %%%%

   GUIDelay = 500 % ms

end
