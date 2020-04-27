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
   /*Variables and function declaration for the extension to generator a random map */
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

   IsTurnByTurn = false

%%%% Description of the map %%%%

%Return a random integer between 4 and 10
fun {RandomInt}
   Int in
   Int = {OS.rand} mod 10 + 1
   if(Int < 4) then
      {RandomInt}
   else
      Int
   end
end

%Set NRow and NColum to a random integer between 4 and 10
NRow = {RandomInt}
NColumn = NRow

%Create a random a random row 
fun{CreateRow Row}
   if Row == 0 then nil
   else 
      Rand in 
      Rand = {OS.rand} mod 8
      if Rand < 7 then 
         0|{CreateRow Row-1}
      else
         1|{CreateRow Row-1}
      end
   end
end

%Create a map with a set of randow columns 
fun{FinishMap Row Column}
   Map NewRow in
   NewRow={CreateRow Row}
   case Column of 0 then nil
   else 
      Map=NewRow|{FinishMap Row Column-1}
   end
end

%Generate a random map
fun{MapGenerator}
   {FinishMap NRow NColumn}
end

Map = {MapGenerator}

%%%% Players description %%%%

   NbPlayer =4
   Players = [player050random player050escape player050target basic]
   Colors = [blue pink purple red]

%%%% Thinking parameters (only in simultaneous) %%%%

   ThinkMin = 100
   ThinkMax = 200

%%%% Surface time/turns %%%%

   TurnSurface = 2

%%%% Life %%%%

   MaxDamage = 4

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
