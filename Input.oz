%Input.Oz
%Don't change any names, change only the values
functor
import 
   OS
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
   RandomInt
   CreateRow
   FinishMap
   MapGenerator

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

/* 
fun {RandomInt}
   Int in
   Int = {OS.rand} mod 10 + 1
   if(Int < 4) then
      {RandomInt}
   else
      Int
   end
end

NRow = {RandomInt}
NColumn = {RandomInt}

fun{CreateRow Row}
   NewRow Rand in
   case Row of 0 then NewRow
   else 
      Rand = {OS.rand} mod 4
      if(Rand==0) then
         NewRow=1|{CreateRow Row-1}
      else 
         NewRow=0|{CreateRow Row-1}
      end
   end
end

fun{FinishMap Row Column}
   Map NewRow in
   NewRow={CreateRow Row}
   case Column of 0 then Map
   else 
      Map=NewRow|{FinishMap Row Column-1}
   end
end

fun{MapGenerator}
   {FinishMap NRow NColumn}
end

*/

Map = {MapGenerator}

   NRow = 6
   NColumn = 6

   Map = [[0 0 0 0 0 0]
	  [0 1 1 0 0 0]
	  [0 0 1 0 0 0]
	  [0 0 0 0 0 0]
	  [0 0 0 0 0 1]
	  [1 1 0 0 0 0]]

%%%% Players description %%%%

   NbPlayer = 3
   Players = [player1 player2 player3]
   Colors = [black blue red]

%%%% Thinking parameters (only in simultaneous) %%%%

   ThinkMin = 100
   ThinkMax = 200

%%%% Surface time/turns %%%%

   TurnSurface = 2

%%%% Life %%%%

   MaxDamage = 2

%%%% Number of load for each item %%%%

   Missile = 1
   Mine = 2
   Sonar = 3
   Drone = 2

%%%% Distances of placement %%%%

   MinDistanceMine = 0
   MaxDistanceMine = 2
   MinDistanceMissile = 1
   MaxDistanceMissile = 5

%%%% Waiting time for the GUI between each effect %%%%

   GUIDelay = 500 % ms

end
