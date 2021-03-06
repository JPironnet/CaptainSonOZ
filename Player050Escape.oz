%PlayerEscape.Oz
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
   RandomPositionMine
   RandomPositionMissile
   NewMineLocation
   MineOk
   IsEnnemyIn
   PositionExceptSurface
   MoveIfPossible


in
   %Treat the stream of the port and takes as arguments Stream and PlayerState 
    proc{TreatStream Stream PlayerState} 
      case Stream of nil then skip
      [] initPosition(ID Position)|T then
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
	 NewPlayerState in
	 NewPlayerState={SayMove ID Direction PlayerState}
	 {TreatStream T NewPlayerState}
	 
      [] saySurface(ID)|T then
	 {TreatStream T PlayerState}
	 
      [] sayCharge(ID KindItem)|T then
	 NewPlayerState in
	 NewPlayerState={SayCharge ID KindItem PlayerState}
	 {TreatStream T NewPlayerState}
	 
      [] sayMinePlaced(ID)|T then
	 {TreatStream T PlayerState}
	 
      [] sayMissileExplode(ID Position Message)|T then
	 NewPlayerState in
	 NewPlayerState={SayMissileExplode ID Position PlayerState Message} 
	 {TreatStream T NewPlayerState}
	 
      [] sayMineExplode(ID Position Message)|T then
	 NewPlayerState in
	 NewPlayerState={SayMineExplode ID Position PlayerState Message} 
	 {TreatStream T NewPlayerState}
	 
      [] sayPassingDrone(Drone ID Answer)|T then
	 NewPlayerState in
	 NewPlayerState={SayPassingDrone Drone ID Answer PlayerState}
	 {TreatStream T NewPlayerState}
	 
      [] sayAnswerDrone(Drone ID Answer)|T then
	 NewPlayerState in
	 NewPlayerState={SayAnswerDrone Drone ID Answer PlayerState}
	 {TreatStream T NewPlayerState}
	 
      [] sayPassingSonar(ID Answer)|T then
	 NewPlayerState in
	 NewPlayerState={SayPassingSonar ID Answer PlayerState}
	 {TreatStream T NewPlayerState}
	 
      [] sayAnswerSonar(ID Answer)|T then
	 NewPlayerState in
	 NewPlayerState={SayAnswerSonar ID Answer PlayerState}
	 {TreatStream T NewPlayerState}
	 
      [] sayDeath(ID)|T then
	 NewPlayerState in
	 NewPlayerState={SayDeath ID PlayerState}
	 {TreatStream T NewPlayerState}
	 
      [] sayDamageTaken(ID Damage LifeLeft)|T then
	 NewPlayerState in
	 NewPlayerState={SayDamageTaken ID Damage LifeLeft PlayerState}
	 {TreatStream T NewPlayerState}
	 
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
      Target
   in
      Position=pt(x:0 y:0)
      Id=id(id:ID color:Color name:_)
      Target=target(id:0 position:Position isTarget:false stillTarget:0)

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
		       target:Target
		       ennemy:nil %the list of the enemies
		       numberEnnemy:0 %the nulber of enemy that the player has count
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
      NewState={AdjoinList PlayerState [position#Position visited#[Position]]}
      NewState
   end

   %ID, Position and Direction are binds as follow :
   %ID::=<id>, Position::=<Position> and Direction::=<carddirection>|surface
   %Check if the player can move to another direction than surface
   %If not, he moves at the surface, otherwise, he moves where it is possible
   %Returns the new state of the player 
   fun{Move ID Position Direction PlayerState}
      X Y PossibleNewPositions NewPlayerState in
      ID=PlayerState.id
      X=PlayerState.position.x
      Y=PlayerState.position.y
      PossibleNewPositions = [pt(x:X-1 y:Y) pt(x:X+1 y:Y) pt(x:X y:Y+1) pt(x:X y:Y-1)]
      if {PositionExceptSurface PossibleNewPositions PlayerState 0}<4 then
	 NewPlayerState={MoveIfPossible Position Direction PlayerState}
      else
	 Direction='Surface'
	 {Print Direction}
	 Position=PlayerState.position
	 NewPlayerState={AdjoinList PlayerState [visited#[Position] surface#true]}
      end
      NewPlayerState
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
   %If the player does not have a sonar, the player builds one, after he builds a drone, 5 missiles and mines
   %Returns the new state of the player
   fun{ChargeItem ID KindItem PlayerState}
      NewPlayerState Choice in
      ID = PlayerState.id
      if (PlayerState.sonarAmmo<1) then
	  if (PlayerState.sonarCharge+1 == Input.sonar) then
	    KindItem = 'sonar'
	     {Print 'Le Player2 a construit sonar'}
	    NewPlayerState={AdjoinList PlayerState [sonarCharge#0 sonarAmmo#PlayerState.sonarAmmo+1]}
	    NewPlayerState
	 else
	    KindItem = nil
	    {Print 'Le Player2 a augmente ses charges de sonar'}
	    NewPlayerState={AdjoinList PlayerState [sonarCharge#PlayerState.sonarCharge+1]}
	    NewPlayerState
	  end
      elseif (PlayerState.droneAmmo<1) then
	  if (PlayerState.droneCharge+1 == Input.drone) then
	    KindItem = 'drone'
	     {Print 'Le Player2 a construit un drone'}
	    NewPlayerState={AdjoinList PlayerState [droneCharge#0 droneAmmo#PlayerState.droneAmmo+1]}
	    NewPlayerState
	 else
	    KindItem = nil
	    {Print 'Le Player2 a augmente ses charges de drone'}
	    NewPlayerState={AdjoinList PlayerState [droneCharge#PlayerState.droneCharge+1]}
	    NewPlayerState
	  end
      elseif (PlayerState.missileAmmo<5) then
	  if (PlayerState.missileCharge+1 == Input.missile) then
	    KindItem = 'missile'
	    {Print 'Le Player2 a construit un missile'}
	    NewPlayerState={AdjoinList PlayerState [missileCharge#0 missileAmmo#PlayerState.missileAmmo+1]}
	    NewPlayerState
	 else 
	    KindItem = nil
	    {Print 'Le Player2 a augmente ses charges de missiles'}
	    NewPlayerState={AdjoinList PlayerState [missileCharge#PlayerState.missileCharge+1]}
	    NewPlayerState
	 end
      else
	 if (PlayerState.mineCharge+1 == Input.mine) then
	    KindItem ='mine'
	     {Print 'Le Player2 a construit une  mine'}
	    NewPlayerState={AdjoinList PlayerState [mineCharge#0 mineAmmo#PlayerState.mineAmmo+1]}
	    NewPlayerState
	 else 
	    KindItem = nil
	    {Print 'Le Player2 a augmente ses charges de mines'}
	    NewPlayerState={AdjoinList PlayerState [mineCharge#PlayerState.mineCharge+1]}
	    NewPlayerState
	 end
      end
   end

   %ID and KindFire are binds as follow :
   %ID::=<id> and KindFire::=<fireitem>|null
   %KindFire=nil if the player does not have enough charge to fire an item
   %if the number of ennemies is 2, the player launches a sonar and a drone to have a target
   %Returns the new state of the player
   fun{FireItem ID KindFire PlayerState}
      NewPlayerState Manhattan in
      ID=PlayerState.id
      if PlayerState.numberEnnemy==2 then %if there is just 1 other player than him
	 if PlayerState.target.id==0 then %if the player does not have a target
	    if(PlayerState.sonarAmmo > 0) then
	       {Print 'Le joueur smart a lance un sonar'}
	       KindFire=sonar
	       NewPlayerState={AdjoinList PlayerState [sonarAmmo#PlayerState.sonarAmmo-1]}
	       NewPlayerState
	    else
	       KindFire=nil 
	       NewPlayerState=PlayerState
	       NewPlayerState
	    end
	 else %if the player has a target
	    if (PlayerState.target.isTarget==false) then %if the player has a target but does not have launched his drone
	       if PlayerState.droneAmmo>0 then
		  {Print 'Le joueur smart a lancer un drone'}
		  KindFire=drone(row PlayerState.target.position.x)
		  NewPlayerState={AdjoinList PlayerState [droneAmmo#PlayerState.droneAmmo-1]}
		  NewPlayerState
	       else
		  KindFire=nil
		  NewPlayerState=PlayerState
		  NewPlayerState
	       end
	    else
	       Manhattan in
	       Manhattan={Abs (PlayerState.position.x - PlayerState.target.position.x)}+ {Abs (PlayerState.position.y - PlayerState.target.position.y)}
	       if Manhattan>=2 andthen Manhattan =< Input.maxDistanceMissile then 
		  if PlayerState.missileAmmo>0 then
		     KindFire = missile(PlayerState.target.position)%the missile is fired at the possible position of the target
		     {Print 'Le joueur smart a deploye un missile'}
		     NewPlayerState={AdjoinList PlayerState [missileAmmo#PlayerState.missileAmmo-1]}
		     NewPlayerState
		  else
		     KindFire=nil
		     NewPlayerState=PlayerState
		     NewPlayerState
		  end
	       elseif  Manhattan =< Input.maxDistanceMine andthen  Manhattan >= Input.minDistanceMine then
		  if(PlayerState.mineAmmo>0) andthen {IsPositionOk PlayerState.target.position.x PlayerState.target.position.y}==1 then
		     KindFire=mine(PlayerState.target.position)
		     {Print 'Le joueur smart a pose une mine'}
		     NewPlayerState={AdjoinList PlayerState [mineAmmo#PlayerState.mineAmmo-1 minePlanted#PlayerState.minePlanted+1 mineLocation#(KindFire.1|PlayerState.mineLocation)]}
		     NewPlayerState
		  else
		     KindFire=nil
		     NewPlayerState=PlayerState
		     NewPlayerState
		  end
	       else
		  KindFire=nil
		  NewPlayerState=PlayerState
		  NewPlayerState
	       end
	    end
	 end
      else
	 if (PlayerState.mineAmmo > 0) then
	    KindFire = mine({RandomPositionMine PlayerState})
	    {Print 'Le Player2 a pose une mine'}
	    NewPlayerState={AdjoinList PlayerState [mineAmmo#PlayerState.mineAmmo-1 minePlanted#PlayerState.minePlanted+1 mineLocation#(KindFire.1|PlayerState.mineLocation)]}
	    NewPlayerState
	 else 
	    KindFire = nil
	    NewPlayerState=PlayerState
	    NewPlayerState
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
      if PlayerState.numberEnnemy==2 then
	 NewPlayerState={MineOk Mine PlayerState PlayerState.mineLocation}
	 NewPlayerState
      else
	 Mine=null
	 PlayerState
      end
   end

   %Check if the player is dead or not
   %Binds Anwser as follow : Answer::=true(1)|false(0)
   %Returns the state of the player
   fun{IsDead Answer PlayerState}
      NewPlayerState in
      if PlayerState.life==0 then
	 Answer=true
      else
	 Answer=false
      end
      NewPlayerState=PlayerState
      NewPlayerState
   end

   %If the player does not have a target, if the ID is not in the ennemy list, the add it to the list PlayerState.ennemy
   %If the player has a target, it upadate the position of his target thanks to Direction
   %Return the new state of the player
   fun{SayMove ID Direction PlayerState}
      NewPlayerState NewEnnemy NewPosition NewTarget in
      if PlayerState.target.id==0 then
	 if {IsEnnemyIn ID PlayerState.ennemy} then
	    PlayerState
	 else
	    NewEnnemy=ID|PlayerState.ennemy
	    NewPlayerState={AdjoinList PlayerState [ennemy#NewEnnemy numberEnnemy#PlayerState.numberEnnemy+1]}
	    NewPlayerState
	 end
      else
	  if ID==PlayerState.target.id then
	    if Direction=='North' then
	       if {IsPositionOk PlayerState.target.position.x-1 PlayerState.target.position.y}==1 then
		  NewPosition=pt(x:PlayerState.target.position.x-1 y:PlayerState.target.position.y)
		  NewTarget={AdjoinList PlayerState.target [position#NewPosition]}
		  NewPlayerState={AdjoinList PlayerState [target#NewTarget]}
		  NewPlayerState
	       else
		  PlayerState
	       end
	    elseif Direction=='South' then
	       if {IsPositionOk PlayerState.target.position.x+1 PlayerState.target.position.y}==1 then
		  NewPosition=pt(x:PlayerState.target.position.x+1 y:PlayerState.target.position.y)
		  NewTarget={AdjoinList PlayerState.target [position#NewPosition]}
		  NewPlayerState={AdjoinList PlayerState [target#NewTarget]}
		  NewPlayerState
	       else
		  PlayerState
	       end
	    elseif Direction=='West' then
	       if {IsPositionOk PlayerState.target.position.x PlayerState.target.position.y-1}==1 then
		  NewPosition=pt(x:PlayerState.target.position.x y:PlayerState.target.position.y-1)
		  NewTarget={AdjoinList PlayerState.target [position#NewPosition]}
		  NewPlayerState={AdjoinList PlayerState [target#NewTarget]}
		  NewPlayerState
	       else
		  PlayerState
	       end
	    elseif Direction=='East' then
	       if {IsPositionOk PlayerState.target.position.x PlayerState.target.position.y+1}==1 then
		  NewPosition=pt(x:PlayerState.target.position.x y:PlayerState.target.position.y+1)
		  NewTarget={AdjoinList PlayerState.target [position#NewPosition]}
		  NewPlayerState={AdjoinList PlayerState [target#NewTarget]}
		  NewPlayerState
	       else
		  PlayerState
	       end
	    else
	       PlayerState
	    end
	 else
	    PlayerState
	 end
      end
   end 	    
   
   fun{SaySurface ID PlayerState}
      PlayerState
   end

   fun{SayCharge ID KindItem PlayerState}
      PlayerState
   end

   fun{SayMinePlaced ID PlayerState}
      PlayerState
   end

   %Checks the distance thanks to Manhattan distance
   %Binds <Message> ::=message(id:<id> damage:0|1|2 lifeleft:<life>)
   %Returns the new state of the player
   fun{SayMissileExplode ID Position PlayerState Message}
      NewPlayerState Manhattan Damage in
      Manhattan = {Abs (Position.x-PlayerState.position.x)} + {Abs (Position.y - PlayerState.position.y)}
      {Print 'La distance Manhattan du Player2 est de :'}
      {Print Manhattan}
      if Manhattan >= 2 then
	 NewPlayerState=PlayerState
	 Damage=0
	 Message=null %there is no damage
      elseif Manhattan==1 then
	 if PlayerState.life=<1 then
	    NewPlayerState={AdjoinList PlayerState [life#0 alive#false]}
	    Message=sayDeath(NewPlayerState.id) %there is no life anymore
	 else
	    NewPlayerState={AdjoinList PlayerState [life#PlayerState.life-1]}
	    Damage=1
	    Message=sayDamageTaken(NewPlayerState.id Damage NewPlayerState.life)  %there is one damage
	 end
      else
	 if PlayerState.life=<2 then
	    NewPlayerState={AdjoinList PlayerState [life#0 alive#false]}
	    Message=sayDeath(NewPlayerState.id) %there is no life anymore
	 else
	    NewPlayerState={AdjoinList PlayerState [life#PlayerState.life-2]}
	    Damage=2
	    Message=sayDamageTaken(NewPlayerState.id Damage NewPlayerState.life)  %there is one damage
	 end
      end
      NewPlayerState
   end

    %Checks the distance thanks to Manhattan distance
   %Binds <Message> ::=message(id:<id> damage:0|1|2 lifeleft:<life>)
   %Returns the new state of the player
  fun{SayMineExplode ID Position PlayerState Message}
     {SayMissileExplode ID Position PlayerState Message}
   end

   %Check the Drone argument and answer by true if tje position is true, false otherwise
  %Return the state of the player
  fun{SayPassingDrone Drone ID Answer PlayerState}
     if PlayerState.alive==false then
	ID=null
	Answer=null
	PlayerState
     else
	ID=PlayerState.id
	if Drone.1==row then
	   if PlayerState.position.x==Drone.2 then
	      Answer=true
	   else
	      Answer=false
	   end
	else
	   if PlayerState.position.y==Drone.2 then
	      Answer=true
	   else
	      Answer=false
	   end
	end
	PlayerState
     end
  end

    %If Answer is true, then the position is updated. Otherwise, the position is the same then the previsous
   %Returns the new state of the player with the target updated
  fun{SayAnswerDrone Drone ID Answer PlayerState}
     if ID==null orelse ID.id==PlayerState.id.id orelse PlayerState.target.id==0 then %if it is the position of the player who launched the sonar
	PlayerState
     else
	NewTarget NewPlayerState in
	if PlayerState.target.id==ID then
	   if Answer==true then
	      if Drone.1==row then
		 NewTarget={AdjoinList PlayerState.target [position#pt(x:Drone.2 y:PlayerState.target.position.y) isTarget#true]}
		 NewPlayerState={AdjoinList PlayerState [target#NewTarget]}
	      else
		 NewTarget={AdjoinList PlayerState.target [position#pt(x:PlayerState.target.position.x y:Drone.2) isTarget#true]}
		 NewPlayerState={AdjoinList PlayerState [target#NewTarget]}
	      end
	   else
	      NewTarget={AdjoinList PlayerState.target [isTarget#true]}
	      NewPlayerState={AdjoinList PlayerState [target#NewTarget]}
	   end
	else
	   NewPlayerState=PlayerState
	end
	NewPlayerState
     end
  end

  %The player answer to the sonar with a random column or row and the other is the true position
  %Return the state of the player 
   fun{SayPassingSonar ID Answer PlayerState}
      if PlayerState.alive==false then
	 ID=null
	 Answer=null
	 PlayerState
      else
	 Choice Random in
	 ID=PlayerState.id
	 Choice={OS.rand} mod 2
	 if Choice==0 then
	    Random={OS.rand} mod (1+Input.nColumn)
	    if {IsPositionOk PlayerState.position.x Random}==1 then %if the position is possible
	       Answer=pt(x:PlayerState.position.x y:Random)
	       PlayerState
	    else
	       {SayPassingSonar ID Answer PlayerState}
	    end
	 else
	    Random={OS.rand} mod (1+Input.nRow)
	    if {IsPositionOk Random PlayerState.position.y}==1 then
	       Answer=pt(x:Random y:PlayerState.position.y)
	       PlayerState
	    else
	       {SayPassingSonar ID Answer PlayerState}
	    end
	 end
      end
   end

   %If the ID is null or if the ID is the id of the player, it does nothing
   %Else the player has his target
   %Return the new state of the player 
   fun{SayAnswerSonar ID Answer PlayerState}
      if ID==null orelse ID.id==PlayerState.id.id then %if it is the position of the player who launched the sonar
	 PlayerState
      else
	 NewPlayerState NewTarget in
	 NewTarget={AdjoinList PlayerState.target [id#ID position#Answer]}
	 NewPlayerState={AdjoinList PlayerState [target#NewTarget]}
	 {Print 'Le player smart a une cible'}
	 NewPlayerState
      end
   end

   %The number of enemis is decremented by one when a enemy is dead
   %Return the new state of the player
   fun{SayDeath ID PlayerState}
      NewPlayerState in
      NewPlayerState={AdjoinList PlayerState [numberEnnemy#PlayerState.numberEnnemy-1]}
      NewPlayerState
   end

   fun{SayDamageTaken ID Damage LifeLeft PlayerState}
      PlayerState
   end

%%%%%%%%%%% Useful functions %%%%%%%%%%%%%%%%%%%

   %If the player can move to a direction except surface, moveIfPossible is called
   %It chooses a random number between 1 and 4 and check if the player can move to this position
   %Return the new state of the player
   fun{MoveIfPossible Position Direction PlayerState}
      NewPlayerState Poles Dir in
      Poles= ['East' 'North' 'South' 'West']
      {Print 'Je suis la'}
      Dir={OS.rand} mod 4+1
      {Print Dir}
      if Dir==2 then
	 if {IsPositionOk PlayerState.position.x-1 PlayerState.position.y}==0 then
	    {MoveIfPossible Position Direction PlayerState} 
	 else
	    if {IsVisited PlayerState.position.x-1 PlayerState.position.y PlayerState.visited}==1 then
	       {MoveIfPossible Position Direction PlayerState} 
	    else
	       Direction={Nth Poles Dir}
	       {Print Direction}
	       Position=pt(x:PlayerState.position.x-1 y:PlayerState.position.y)
	       NewPlayerState={AdjoinList PlayerState [position#Position visited#(Position|PlayerState.visited)]}
	       NewPlayerState
	    end
	 end
      elseif Dir==3 then
	 if {IsPositionOk PlayerState.position.x+1 PlayerState.position.y}==0 then
	    {MoveIfPossible Position Direction PlayerState} 
	 else
	    if {IsVisited PlayerState.position.x+1 PlayerState.position.y PlayerState.visited}==1 then
	       {MoveIfPossible Position Direction PlayerState} 
	    else
	       Direction={Nth Poles Dir}
	       {Print Direction}
	       Position=pt(x:PlayerState.position.x+1 y:PlayerState.position.y)
	       NewPlayerState={AdjoinList PlayerState [position#Position visited#(Position|PlayerState.visited)]}
	       NewPlayerState
	    end
	 end
      elseif Dir==1 then
	 if {IsPositionOk PlayerState.position.x PlayerState.position.y+1}==0 then
	    {MoveIfPossible Position Direction PlayerState} 
	 else
	    if {IsVisited PlayerState.position.x PlayerState.position.y+1 PlayerState.visited}==1 then
	       {MoveIfPossible Position Direction PlayerState} 
	    else
	       Direction={Nth Poles Dir}
	       {Print Direction}
	       Position=pt(x:PlayerState.position.x y:PlayerState.position.y+1)
	       NewPlayerState={AdjoinList PlayerState [position#Position visited#(Position|PlayerState.visited)]}
	       NewPlayerState
	    end
	 end
      else
	 if {IsPositionOk PlayerState.position.x PlayerState.position.y-1}==0 then
	    {MoveIfPossible Position Direction PlayerState} 
	 else
	    if {IsVisited PlayerState.position.x PlayerState.position.y-1 PlayerState.visited}==1 then
	       {MoveIfPossible Position Direction PlayerState} 
	    else
	       Direction={Nth Poles Dir}
	       {Print Direction}
	       Position=pt(x:PlayerState.position.x y:PlayerState.position.y-1)
	       NewPlayerState={AdjoinList PlayerState [position#Position visited#(Position|PlayerState.visited)]}
	       NewPlayerState
	    end
	 end
      end
   end

   %Check if the player can move to a direction except surface
   %If the player can move into a direction, Acc=Acc+1
   %Return Acc
   fun{PositionExceptSurface List PlayerState Acc}
      case List of nil then Acc
      [] H|T then
	 if {IsPositionOk H.x H.y}==1 andthen {IsVisited H.x H.y PlayerState.visited}==0 then
	    {PositionExceptSurface T PlayerState Acc}
	 else
	    {PositionExceptSurface T PlayerState Acc+1}
	 end
      end
   end

   %Check if the ID of the ennemy is already in the list
   %Return true if the ID is already in, false otherwise
   fun{IsEnnemyIn ID List}
      case List of nil then false
      [] H|T then
	 if ID==H then true
	 else {IsEnnemyIn ID T}
	 end
      end
   end

   %Check if the mine can explode without damaging the player
   %Returns the new state of the player
   fun{MineOk Mine PlayerState List}
      Manhattan NewPlayerState in
      case List of nil then
	 Mine=null
	 NewPlayerState=PlayerState
	 NewPlayerState
      [] H|T then
	 Manhattan={Abs H.x-PlayerState.position.x} + {Abs H.y-PlayerState.position.y}
	 if Manhattan < 2 then
	    {MineOk Mine PlayerState T}
	 else
	    Mine=H
	    NewPlayerState={AdjoinList PlayerState [minePlanted#PlayerState.minePlanted-1 mineLocation#{NewMineLocation H PlayerState.mineLocation}]}
	    {Print 'Le joueur smart a explose une mine'}
	    NewPlayerState
	 end
      end
   end

   %Updates PlayerState.mineLocation without the exploding mine
   %Returns the new list of mine's location
   fun{NewMineLocation Mine List}
      case List of nil then nil
      [] H|T then
	 if H==Mine then {NewMineLocation Mine T}
	 else
	    H|{NewMineLocation Mine T}
	 end
      end
   end

   %Choose a random position
   %<Row>::= 1|2|...|Input.nRow and <Column>::=1|2|...|Input.nColumn
   %Returns a position and Position::=pt(x:<Row> y:<Column>)
   fun {RandomPosition}
      Row Column Position in
      Row = {OS.rand} mod (Input.nRow+1)
      Column = {OS.rand} mod (Input.nColumn+1)
      if {IsPositionOk Row Column}==1 then
	 Position=pt(x:Row y:Column)
	 Position
      else
	 {RandomPosition}
      end
   end

   %Choose a random position to place the mine
   %Return the position
   fun{RandomPositionMine PlayerState}
      Row Column Position Manhattan in
      Row = {OS.rand} mod (Input.nRow+1)
      Column = {OS.rand} mod (Input.nColumn+1)
      Manhattan={Abs PlayerState.position.x-Row}+{Abs PlayerState.position.y-Column}
      if Manhattan >= Input.minDistanceMine andthen Manhattan =< Input.maxDistanceMine then
	 if {IsPositionOk Row Column}==1 then
	    Position=pt(x:Row y:Column)
	    Position
	 else
	    {RandomPositionMine PlayerState}
	 end
      else
	 {RandomPositionMine PlayerState}
      end
   end

    %Choose a random position to launch the missile
   %Return the position
    fun{RandomPositionMissile PlayerState}
      Row Column Position Manhattan in
      Row = {OS.rand} mod (Input.nRow+1)
      Column = {OS.rand} mod (Input.nColumn+1)
      Manhattan={Abs PlayerState.position.x-Row}+{Abs PlayerState.position.y-Column}
      if Manhattan >= Input.minDistanceMissile andthen Manhattan =< Input.maxDistanceMissile then
	 if {IsPositionOk Row Column}==1 then
	    Position=pt(x:Row y:Column)
	    Position
	 else
	    {RandomPositionMissile PlayerState}
	 end
      else
	 {RandomPositionMine PlayerState}
      end
   end
      
   fun {RandomRowOrColumn}
      Choice Drone Result in  
      Choice = {OS.rand} mod 2
      if (Choice==0) then
	 Result = {OS.rand} mod (1+Input.nRow)
	 Drone = drone(row Result)
	 Drone 
      else 
	 Result = {OS.rand} mod (1+Input.nColumn)
	 Drone = drone(column Result)
	 Drone 
      end
   end

   %Check if it is the limit of the map
   %Reutrn true if it is, false otherwise
   fun{IsLimitOfMap Row Column}
      if  Row >= 1 andthen Row =< Input.nRow andthen Column >= 1 andthen Column =< Input.nColumn then false
      else true 
      end
   end
   
    %Check if the position is ok (if the position is not out of the map and if it is not an island) 
    %Returns true if it is water and in the map, false otherwise
   fun{IsPositionOk Row Column}
      if {IsLimitOfMap Row Column}==true then 0
      else
	 if {Nth {Nth Input.map Row} Column}==1 then 0
	 else 1
	 end
      end 
   end

   %Check if the player has already visited the position between 2 surfaces
   %Return 0 if not, 1 otherwise
   fun{IsVisited X Y List}
      case List of nil then 0
      [] H|T then
	 if H.x==X then
	    if H.y==Y then 1
	    else {IsVisited X Y T}
	    end
	 else {IsVisited X Y T}
	 end
      end
   end

end