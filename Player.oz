%Player.Oz
functor
import
   Input
   OS
   System(showInfo:Print)
export
   portPlayer:StartPlayer
define
   StartPlayer
   TreatStream

   InitPosition
   Move
   Dive
   ChargeItem
   FireItem 
   FireMine
   IsDead
   SayMove
   SaySurface
   SayCharge
   SayMinePlaced
   SayMissileExplode
   SayMineExplode
   SayPassingDrone
   SayAnswerDrone
   SayPassingSonar
   SayAnswerSonar
   SayDeath
   SayDamageTaken

   CreateStatePlayer
   IsVisited
   IsPositionOk
   IsLimitOfMap
   RandomPosition   
   RandomRowOrColumn
   HelpII


in
   
   proc{TreatStream Stream PlayerState} 
      case Stream of nil then skip
      [] initPosition(?ID ?Position)|T then
	 NewPlayerState in
	 NewPlayerState={InitPosition ID Position PlayerState}
	 {TreatStream T NewPlayerState}

      [] move(ID Position Direction)|T then
	 NewPlayerState in
	 NewPlayerState={Move ID Position Direction PlayerState} 
	 {TreatStream T NewPlayerState}    
	 
      [] dive|T then
	 NewPlayerState in
	 NewPlayerState={Dive PlayerState} 
	 {TreatStream T NewPlayerState}
	 
      [] chargeItem(ID KindItem)|T then
	 NewPlayerState in
	 {Print 'Je suis dans TreatStream pour chargeItem'}
	 NewPlayerState={ChargeItem ID KindItem PlayerState} 
	 {TreatStream T NewPlayerState}

      [] fireItem(ID KindFire)|T then
	 NewPlayerState in
	 NewPlayerState={FireItem ID KindFire PlayerState} 
	 {TreatStream T NewPlayerState}
	 
      [] fireMine(ID Mine)|T then
	 NewPlayerState in
	 NewPlayerState={FireMine ID Mine PlayerState} 
	 {TreatStream T NewPlayerState}
	 
      [] isDead(Answer)|T then
	 NewPlayerState in
	 NewPlayerState={IsDead Answer PlayerState} 
	 {TreatStream T NewPlayerState}
	 
      [] sayMove(ID Direction)|T then
	 {TreatStream T PlayerState}
	 
      [] saySurface(ID)|T then
	 {TreatStream T PlayerState}
	 
      [] sayCharge(ID KindItem)|T then
	 {TreatStream T PlayerState}
	 
      [] sayMinePlaced(ID)|T then
        {TreatStream T PlayerState}
      [] sayMissileExplode(ID Position Message)|T then
	 NewPlayerState in
	 NewPlayerState={SayMissileExplode ID Position PlayerState Message} 
	 {TreatStream T NewPlayerState}
      [] sayMineExplode(ID Position ?Message)|T then
	 NewPlayerState in
	 NewPlayerState={SayMineExplode ID Position PlayerState Message} 
	 {TreatStream T NewPlayerState}
	 
      [] sayPassingDrone(Drone ID Answer)|T then
	 {TreatStream T PlayerState}
	 
      [] sayAnswerDrone(Drone ID Answer)|T then
	 {TreatStream T PlayerState}
	 
      [] sayPassingSonar(ID Answer)|T then
	 {TreatStream T PlayerState}
	 
      [] sayAnswerSonar(ID Answer)|T then
	 {TreatStream T PlayerState}
	 
      [] sayDeath(ID)|T then
	 {TreatStream T PlayerState}
	 
      [] sayDamageTaken(ID Damage LifeLeft)|T then
	 {TreatStream T PlayerState}
      [] _|T then {TreatStream T PlayerState}
      end
   end


   %Creates the state of the player
   %PlayerState::=playerstate(id: position:<Position> life: visited:<ListVisited> ...)
   %<ListVisited>::=null|[Position1 ... PositionN] and <PositionN>::=<Position>
   %Returns the state of the player
   fun {CreateStatePlayer ID Color}
      PlayerState

      Position
      Id
   in
      Position=pt(x:0 y:0)
      Id=id(id:ID color:Color name:_)

      PlayerState = playerstate(
		       id:Id 
		       position:Position
		       life:Input.maxDamage
		       surface:true
		       visited:nil %liste des positions entre 2 surfaces
		       alive:true
		       mineCharge:0
		       mineAmmo:0
		       missileCharge:0
		       missileAmmo:0
		       sonarCharge:0
		       sonarAmmo:0
		       droneCharge:0
		       droneAmmo:0
		       minePlanted:0
		       mineLocation:nil
		       )
      PlayerState
   end

    %Function to create the player
    %Returns the port of the player
   fun{StartPlayer Color ID}
      Stream
      Port
      PlayerState
   in
      PlayerState={CreateStatePlayer ID Color}
      {NewPort Stream Port}
      thread {TreatStream Stream PlayerState} end
      Port
   end


    %Initialize the position of the player
    %Returns the new state of the player 
   fun{InitPosition ID Position PlayerState}
      NewState
   in
      ID=PlayerState.id
      Position={RandomPosition}
      NewState={AdjoinList PlayerState [position#Position visited#Position]}
      NewState
   end

   %ID, Position and Direction are binds as follow :
   %ID::=<id>, Position::=<Position> and Direction::=<carddirection>|surface
   %Returns the new state of the player
   fun{Move ID Position Direction PlayerState}
      Poles Dir NewPlayerState in
      Poles= ['East' 'North' 'South' 'West' 'Surface']
      Dir={OS.rand} mod 5+1
      ID=PlayerState.id
      Direction={Nth Poles Dir}
      if Dir==2 then
	 {Print 'c nord'}
	 if {IsPositionOk PlayerState.position.x-1 PlayerState.position.y}==0 then %if it's an island
	    {Move ID Position Direction PlayerState} 
	 else 
	    if {IsVisited PlayerState.position.x-1 PlayerState.position.y PlayerState.visited} then {Move ID Position Direction PlayerState} 
	    else
	       {Print 'cc'}
	       Position=pt(x:PlayerState.position.x-1 y:PlayerState.position.y)
	       NewPlayerState={AdjoinList PlayerState [position#Position visited#(Position|PlayerState.visited)]}
	       NewPlayerState
	    end
	 end
      elseif Dir==3 then
	 {Print 'c sud'}
	 if {IsPositionOk PlayerState.position.x+1 PlayerState.position.y}==0 then
	    {Move ID Position Direction PlayerState} 
	 else
	    if {IsVisited PlayerState.position.x+1 PlayerState.position.y PlayerState.visited} then
	       {Move ID Position Direction PlayerState} 
	    else
	       {Print 'cc'}
	       Position=pt(x:PlayerState.position.x+1 y:PlayerState.position.y)
	       NewPlayerState={AdjoinList PlayerState [position#Position visited#(Position|PlayerState.visited)]}
	       NewPlayerState
	    end
	 end
      elseif Dir==1 then
	 {Print 'Cest est'}
	 if {IsPositionOk PlayerState.position.x PlayerState.position.y+1}==0 then
	    {Move ID Position Direction PlayerState} 
	 else
	    if {IsVisited PlayerState.position.x PlayerState.position.y+1 PlayerState.visited} then
	       {Move ID Position Direction PlayerState} 
	    else
	       {Print 'cc'}
	       Position=pt(x:PlayerState.position.x y:PlayerState.position.y+1)
	       NewPlayerState={AdjoinList PlayerState [position#Position visited#(Position|PlayerState.visited)]}
	       NewPlayerState
	    end
	 end
      elseif Dir==4 then
	 if {IsPositionOk PlayerState.position.x PlayerState.position.y-1}==0 then
	    {Move ID Position Direction PlayerState} 
	 else
	    if {IsVisited PlayerState.position.x PlayerState.position.y-1 PlayerState.visited} then
	       {Move ID Position Direction PlayerState} 
	    else
	       Position=pt(x:PlayerState.position.x y:PlayerState.position.y-1)
	       NewPlayerState={AdjoinList PlayerState [position#Position visited#(Position|PlayerState.visited)]}
	       NewPlayerState
	    end
	 end
      else
	 Position=PlayerState.position
	 NewPlayerState={AdjoinList PlayerState [visited#Position surface#true]}
	 NewPlayerState
      end
   end

    %The player is in the water and not at the surface anymore
    %Returns the new state of the player
   fun{Dive PlayerState}
      NewPlayerState in
      NewPlayerState={AdjoinList PlayerState [surface#false]}
      NewPlayerState
   end

   %ID and KindItem are binds as follow :
   %ID::=<id> and KindItem::=null|missile|mine|sonar|drone
   %Returns the new state of the player
   fun{ChargeItem ID KindItem PlayerState}
      NewPlayerState Choice in
      {Print 'suis la'}
      ID = PlayerState.id
      Choice = {OS.rand} mod 4 + 1
      {Print 'Je suis dans la fonction chargeItem Player.oz, Choice a ete choisi'}
      if (Choice==1) then
	 if (PlayerState.mineCharge+1 == Input.mine) then
	    KindItem ='mine'
	    NewPlayerState={AdjoinList PlayerState [mineCharge#0 mineAmmo#PlayerState.mineAmmo+1]}
	    NewPlayerState
	 else 
	    KindItem = nil
	    NewPlayerState={AdjoinList PlayerState [mineCharge#PlayerState.mineCharge+1]}
	    NewPlayerState
	 end
      elseif (Choice==2) then
	 if (PlayerState.missileCharge+1 == Input.missile) then
	    KindItem = 'missile'
	    NewPlayerState={AdjoinList PlayerState [missileCharge#0 missileAmmo#PlayerState.missileAmmo+1]}
	    NewPlayerState
	 else 
	    KindItem = nil
	    NewPlayerState={AdjoinList PlayerState [missileCharge#PlayerState.missileCharge+1]}
	    NewPlayerState
	 end
      elseif (Choice==3) then
	 if (PlayerState.sonarCharge+1 == Input.sonar) then
	    KindItem = 'sonar'
	    NewPlayerState={AdjoinList PlayerState [sonarCharge#0 sonarAmmo#PlayerState.sonarAmmo+1]}
	    NewPlayerState
	 else
	    KindItem = nil
	    NewPlayerState={AdjoinList PlayerState [sonarCharge#PlayerState.sonarCharge+1]}
	    NewPlayerState
	 end
      elseif (Choice==4) then
	 if (PlayerState.droneCharge+1 == Input.drone) then
	    KindItem = 'drone'
	    NewPlayerState={AdjoinList PlayerState [droneCharge#0 droneAmmo#PlayerState.droneAmmo+1]}
	    NewPlayerState
	 else
	    KindItem = nil
	    NewPlayerState={AdjoinList PlayerState [droneCharge#PlayerState.droneCharge+1]}
	    NewPlayerState
	 end
      end
   end

   %ID and KindFire are binds as follow :
   %ID::=<id> and KindFire::=<fireitem>|null
   %KindFire=nil if the player does not hae enough charge to fire an item
   %Returns the new state of the player
   fun{FireItem ID KindFire PlayerState}
      NewPlayerState in
      ID=PlayerState.id
      if (PlayerState.mineAmmo > 0) then
	 KindFire = mine({RandomPosition})
	 NewPlayerState={AdjoinList PlayerState [mineAmmo#PlayerState.mineAmmo-1 minePlanted#PlayerState.minePlanted+1 mineLocation#(KindFire.1|PlayerState.mineLocation)]}
	 NewPlayerState
	 
      else 
	 if (PlayerState.missileAmmo > 0) then
	    KindFire = missile({RandomPosition})
	    NewPlayerState={AdjoinList PlayerState [missileAmmo#PlayerState.missileAmmo-1]}
	    NewPlayerState
	 else 
	    if(PlayerState.droneAmmo > 0) then
	       KindFire = drone({RandomRowOrColumn})
	       NewPlayerState={AdjoinList PlayerState [droneAmmo#PlayerState.droneAmmo-1]}
	       NewPlayerState
	    else 
	       if(PlayerState.sonarAmmo > 0) then
		  NewPlayerState={AdjoinList PlayerState [sonarAmmo#PlayerState.sonarAmmo-1]}
		  NewPlayerState
	       else 
		  KindFire = nil
		  NewPlayerState=PlayerState
		  NewPlayerState
	       end
	    end
	 end
      end        
   end

   %ID and Mine are bind as follow :
   %Id::=<id> and Mine::=mine(<Position>)|null
   %If the player does not have mine, then nil
   %Returns the new state of the player
   fun{FireMine ID Mine PlayerState}
      NewPlayerState in
      ID=PlayerState.id
      case PlayerState.mineLocation of nil then
	 Mine=nil
	 PlayerState
      [] H|T then
	 Mine=H
	 NewPlayerState={AdjoinList PlayerState [minePlanted#minePlanted-1 mineLocation#T]}
	 NewPlayerState
      end
   end

   %Check if the player is dead or not
   %Binds Anwser as follow : Answer::=true(1)|false(0)
   %Returns the state of the player
   fun{IsDead Answer PlayerState}
      NewPlayerState in
      if PlayerState.life==0 then
	 Answer=1
      else
	 Answer=0
      end
      NewPlayerState=PlayerState
      NewPlayerState
   end

   fun{SayMove ID Direction}
      nil
   end

   fun{SaySurface ID}
      nil
   end

   fun{SayCharge ID KindItem}
      nil
   end

   fun{SayMinePlaced ID}
      nil
   end

   %Checks the distance thanks to Manhattan distance
   %Binds <Message> ::=message(id:<id> damage:0|1|2 lifeleft:<life>)
   %Returns the new state of the player
   fun{SayMissileExplode ID Position PlayerState Message}
      NewPlayerState
      Manhattan in
      Manhattan = (Position.x-PlayerState.position.x) + (Position.y - PlayerState.position.y)
      if Manhattan >= 2 then
	 NewPlayerState=PlayerState
	 Message=message(id:NewPlayerState.id damage:0 lifeleft:NewPlayerState.life) %there is no life anymore
	 NewPlayerState
      elseif Manhattan==1 then
	 if PlayerState.life==1 then
	    NewPlayerState={AdjoinList PlayerState [life#0 alive#false]}
	    Message=message(id:NewPlayerState.id damage:1 lifeleft:NewPlayerState.life) %there is no life anymore
	    NewPlayerState
	 else
	    NewPlayerState={AdjoinList PlayerState [life#PlayerState.life-1]}
	    Message=message(id:NewPlayerState.id damage:1 lifeleft:NewPlayerState.life) %there is no life anymore
	    NewPlayerState
	 end
      else
	 if PlayerState.life=<2 then
	    NewPlayerState={AdjoinList PlayerState [life#0 alive#false]}
	    Message=message(id:NewPlayerState.id damage:2 lifeleft:NewPlayerState.life) %there is no life anymore
	    NewPlayerState
	 else
	    NewPlayerState={AdjoinList PlayerState [life#PlayerState.life-2]}
	    Message=message(id:NewPlayerState.id damage:2 lifeleft:NewPlayerState.life) %there is no life anymore
	    NewPlayerState
	 end
      end
   end

    %Checks the distance thanks to Manhattan distance
   %Binds <Message> ::=message(id:<id> damage:0|1|2 lifeleft:<life>)
   %Returns the new state of the player
   fun{SayMineExplode ID Position PlayerState Message}
        {SayMissileExplode ID Position PlayerState ?Message}
   end

   fun{SayPassingDrone Drone ID Answer}
      nil
   end

   fun{SayAnswerDrone Drone ID Answer}
      nil
   end

   fun{SayPassingSonar ID Answer}
      nil
   end

   fun{SayAnswerSonar ID Answer}
      nil
   end

   fun{SayDeath ID}
      nil
   end

   fun{SayDamageTaken ID Damage LifeLeft}
      nil
   end

%%%%%%%%%%% Useful functions %%%%%%%%%%%%%%%%%%%

   %Choose a random position
   %<Row>::= 1|2|...|Input.nRow and <Column>::=1|2|...|Input.nColumn
   %Returns a position and Position::=pt(x:<Row> y:<Column>)
   fun {RandomPosition}
      Row Column Position in
      Row = {OS.rand} mod Input.nRow+1
      Column = {OS.rand} mod Input.nColumn+1
      if {IsPositionOk Row Column}==1 then
	 Position=pt(x:Row y:Column)
	 Position
      else
	 {RandomPosition}
      end
   end

   fun {RandomRowOrColumn}
      Choice Drone Result in  
      Choice = {OS.rand} mod 2
      if (Choice==0) then
	 Result = {OS.rand} mod Input.nRow
	 Drone = drone(row:Result)
	 Drone 
      else 
	 Result = {OS.rand} mod Input.nColumn
	 Drone = drone(column:Result)
	 Drone 
      end
   end

   fun{IsLimitOfMap Row Column}
      if  Row >= 1 andthen Row =< Input.nRow andthen Column >= 1 andthen Column =< Input.nColumn then 0
      else 1
      end
   end
   
    %Check if the position is ok (if the position is not out of the map and if it is not an island) 
    %Returns true if it is water and in the map, false otherwise
   fun{IsPositionOk Row Column}
      %R C in
      %if C==1 then 0
      %else
         if {IsLimitOfMap Row Column}==1 then 0
	      else 
            1
            %R={Nth Input.map Row} 
            %C={Nth R Column}
	   %   end
      end
   end 

    %Checks if the submarine has been already visited the <Position> given by X and Y
    %Returns true or false 
   fun{IsVisited X Y List}
      case List of nil then false
      [] H|T then
	      if H.x==X then
	         if H.y==Y then true
	         else false
	         end
	      else false
	      end
      else 
         false 
      end
   end

end

