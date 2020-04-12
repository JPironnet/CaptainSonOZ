%Player.Oz
functor
import
    Input
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

in
   proc{TreatStream Stream PlayerState} 
      case Stream of nil then skip
      [] initPosition(?ID ?Position)|T then
	 NewPlayerState in
	 NewPlayerState={InitPosition ID Position PlayerState}
	 {TreatStream T NewPlayerState}

      [] move(?ID ?Position ?Direction)|T then
	 NewPlayerState in
	 NewPlayerState={Move ID Position Direction PlayerState} 
	 {TreatStream T NewPlayerState}    
	 
      [] dive|T then
	 NewPlayerState in
	 NewPlayerState={Dive PlayerState} 
	 {TreatStream T NewPlayerState}
	 
      [] chargeItem(?ID ?KindItem)|T then
	 NewPlayerState in
	 NewPlayerState={ChargeItem ID KindItem PlayerState} 
	 {TreatStream T NewPlayerState}

      [] fireItem(?ID ?KindFire)|T then
	 NewPlayerState in
	 NewPlayerState={FireItem ID KindFire PlayerState} 
	 {TreatStream T NewPlayerState}
	 
      [] fireMine(?ID ?Mine)|T then
	 NewPlayerState in
	 NewPlayerState={FireMine ID Mine PlayerState} 
	 {TreatStream T NewPlayerState}
	 
      [] isDead(?Answer)|T then
	 NewPlayerState in
	 NewPlayerState={IsDead Answer PlayerState} 
	 {TreatStream T NewPlayerState}
	 
      [] sayMove(ID Direction)|T then
	 NewPlayerState in
	 NewPlayerState={SayMove ID Direction PlayerState}
	 {TreatStream T PlayerState}
	 
      [] saySurface(ID)|T then
	  NewPlayerState in
	 NewPlayerState={SaySurface ID PlayerState}
	 {TreatStream T PlayerState}
	 
      [] sayCharge(ID KindItem) then
	 {TreatStream T PlayerState}
	 
      [] sayMinePlaced(ID) then
	 
      [] sayMissileExplode(ID Position ?Message) then
	 
      [] sayMineExplode(ID Position ?Message) then
	 
      [] sayPassingDrone(Drone ?ID ?Answer) then
	 {TreatStream T PlayerState}
	 
      [] sayAnswerDrone(Drone ID Answer) then
	 {TreatStream T PlayerState}
	 
      [] sayPassingSonar(?ID ?Answer)then
	 {TreatStream T PlayerState}
	 
      [] sayAnswerSonar(ID Answer) then
	 {TreatStream T PlayerState}
	 
      [] sayDeath(ID) then
	 {TreatStream T PlayerState}
	 
      [] sayDamageTaken(ID Damage LifeLeft) then
	 {TreatStream T PlayerState}
	 
      end
   end


    %Creation de l'etat du joueur
   fun {CreateStatePlayer Player}
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
        PlayerState={CreateStatePlayer}
        {NewPort Stream Port}
        thread {TreatStream Stream PlayerState} end
        Port
    end


    %Initialize the position of the player
    %Returns the new state of the player 
    fun{InitPosition ?ID ?Position PlayerState}
       Row Column NewPlayerState
    in
       ID=PlayerState.id
       Position={RandomPosition}
       NewPlayerState={AdjoinList PlayerState [position#Position]}
       NewPlayerState  
    end

    %To check if the position is an island or not
    %Returns true if it's an island or the limit of the map, false otherwise
    %ptdr on l optimisera mais trql pour le moment
    fun{IsIsland Row Column}
       if Row>Input.NRow then true
       else
	  if Column>Input.Ncolumn then true
	  else
	     fun{HelpII Row Column Acc1 Acc2 Map}
		case Map of H|T then
		   if Acc1==Row then
		      if Acc2==Column then
			 if H==1 then true
			 else false
			 end
		      else
			 if Acc2==1 then {HelpII Row Column Acc1 Acc2+1 H.2}
			 else {HelpII Row Column Acc1 Acc2+1 T}
			 end
		      end
		   else {HelpII Row Column Acc1+1 Acc2 T}
		   end
		end
	     end
	  in
	     {HelpII Row Column 1 1 Input.Map}
	  end
       end 
    end

    %Check if the submarine has already vistied the position given by X and Y
    %Return true or false 
    fun{IsVisited X Y List}
        case List of nil then false
        [] H|T then
	    if H.x==X then
	        if H.y==Y then true
	        else false
	        end
	    else false
	    end
        end
    end

    %Change the position of the player. Check what's the direction, and verify if the new position is an island or out of the map
    %Return the new state of the player 
    fun{Move ID Position Direction PlayerState}
       Poles Dir NewPlayerState in
       Poles= ['East' 'North' 'South' 'West' 'Surface']
       Dir={OS.rand} mod 5+1
       ID=PlayerState.id
       Direction={Nth Poles Dir}
       if Dir==2 then %If it's North
	  if {IsIsland PlayerState.position.x-1 Y} then %if it's an island
	     {Move Position Visited} 
	  else 
	     if {IsVisited Position.x-1 Y PlayerState.visited} then {Move ID Position Direction PlayerState} 
	     else
		Position=pt(x:PlayerState.position.x-1 y:PlayerState.position.y)
		NewPlayerState={AdjoinList PlayerState [position#Position visited#visited|Position]}
	     end
	  end
       elseif Dir==3 then
	  if {IsIsland  PlayerState.position.x+1 PlayerState.position.y} then
	     {Move ID Position Direction PlayerState} 
	  else
	     if {IsVisited PlayerState.position.x+1 PlayerState.position.y PlayerState.visited} then {Move ID Position Direction PlayerState} 
	     else
		Position=pt(x:PlayerState.position.x+1 y:PlayerState.position.y)
		NewPlayerState={AdjoinList PlayerState [position#Position visited#visited|Position]}
	     end
	  end
       elseif Dir==1 then
	   if {IsIsland  PlayerState.position.x PlayerState.y+1} then
	     {Move ID Position Direction PlayerState} 
	  else
	     if {IsVisited PlayerState.position.x PlayerState.y+1 PlayerState.visited} then {Move ID Position Direction PlayerState} 
	     else
		Position=pt(x:PlayerState.position.x y:PlayerState.position.y+1)
		NewPlayerState={AdjoinList PlayerState [position#Position visited#visited|Position]}
	     end
	  end
       elseif Dir==4 then
	  if {IsIsland  PlayerState.position.x PlayerState.y-1} then
	     {Move ID Position Direction PlayerState} 
	  else
	     if {IsVisited PlayerState.position.x PlayerState.y-1 PlayerState.visited} then {Move ID Position Direction PlayerState} 
	     else
		Position=pt(x:PlayerState.position.x y:PlayerState.position.y-1)
		NewPlayerState={AdjoinList PlayerState [position#Position visited#visited|Position]}
	     end
	  end
       else
	  Position=PlayerState.position
	  NewPlayerState={AdjoinList PlayerState [visited#Position]}
       end
       NewPlayerState
    end

    %The player is granted to dive
    %Return the new player state
    fun{Dive PlayerState}
       NewPlayerState in
       NewPlayerState={AdjointList PlayerState [surface#false]}
       NewPlayerState
    end

    %Increasing the number of charge of 1 and if the number of charge is the number to create a mine/missile/sonar/drone, it creates one
    %Binds ID, KindItem 
    %Returns the new player state
    fun{ChargeItem ?ID ?KindItem PlayerState}
       NewPlayerState Choice in
       ID = PlayerState.id
       Choice = {OS.rand} mod 4 + 1
       if (Choice==1) then
	  if (PlayerState.mineCharge+1 == Input.mine) then
	     {Print} %il faut créer une fonction qui print sur le jeu la création de l'objet
	     KindItem = mine
	      NewPlayerState={AdjoinList PlayerState [mineCharge#0 mineAmmo#PlayerState.mineAmmo+1]}
	  else 
	     KindItem = nil
	      NewPlayerState={AdjoinList PlayerState [mineCharge#PlayerState.mineCharge+1]}
	  end

       elseif (Choice==2) then
	  if (PlayerState.missileCharge+1 == Input.missile) then
	     {Print} %il faut créer une fonction qui print sur le jeu la création de l'objet
	     KindItem = missile
	      NewPlayerState={AdjoinList PlayerState [missileCharge#0 missileAmmo#PlayerState.missileAmmo+1]}
	  else 
	     KindItem = nil
	      NewPlayerState={AdjoinList PlayerState [missileCharge#PlayerState.missileCharge+1]}
	  end
	  
       elseif (Choice==3) then
	  if (PlayerState.sonarCharge+1 == Input.sonar) then
	      NewPlayerState={AdjoinList PlayerState [sonarCharge#0 sonarAmmo#PlayerState.sonarAmmo+1]}
	     {Print} %il faut créer une fonction qui print sur le jeu la création de l'objet
	     KindItem = sonar
	  else 
	      NewPlayerState={AdjoinList PlayerState [sonarCharge#PlayerState.sonarCharge+1]}
	     KindItem = nil
	  end

       elseif (Choice==4) then
	  if (PlayerState.droneCharge+1 == Input.drone) then
	      NewPlayerState={AdjoinList PlayerState [droneCharge#0 droneAmmo#PlayerState.droneAmmo+1]}
	     {Print} %il faut créer une fonction qui print sur le jeu la création de l'objet
	     KindItem = drone
	  else 
	     NewPlayerState={AdjoinList PlayerState [droneCharge#PlayerState.droneCharge+1]}
	     KindItem = nil
	  end
       end
       NewPlayerState
    end

    %Creates a random position
    %Returns a new player state 
    fun {RandomPosition}
       Row Column Position in
       Row = {OS.rand} mod Input.NRow
       Column = {OS.rand} mod Input.NColumn
       if {IsIsland Row Column} then
	  Position=pt(x:Row y:Column)
       else {RandomPosition}
       end
       Position
    end

    %Returns a random number for a row or a column 
    fun {RandomRowOrColumn}
        Choice Drone Result in  
        Choice = {OS.rand} mod 2
        if (Choice==1) then
            Result = {OS.rand} mod Input.NRow
            Drone = drone(row:Result)
            Drone 
        else 
            Result = {OS.rand} mod Input.NColumn
            Drone = drone(column:Result)
            Drone 
        end
    end

    %Returns the new player state with a new arm (missile, mine, sonar or drone or nothing)
    fun{FireItem ?ID ?KindFire PlayerState}
       NewPlayerState in
       ID=PlayerState.id
       if (PlayerState.mineAmmo > 0) then
	  KindFire = mine({RandomPosition})
	  if (PlayerState.minePlanted==0) then
	     NewPlayerState={AdjoinList PlayerState [mineAmmo#PlayerState.mineAmmo-1 minePlanted#1 mineLocation#KindFire]}
	  else
	     NewPlayerState={AdjoinList PlayerState [mineAmmo#PlayerState.mineAmmo-1 minePlanted#minePlanted+1 mineLocation#mineLocation|KindFire]}
	  end
       else 
	  if (PlayerState.missileAmmo > 0) then
	     KindFire = missile({RandomPosition})
	     NewPlayerState={AdjoinList PlayerState [missileAmmo#PlayerState.missileAmmo-1]}
	  else 
	     if(PlayerState.droneAmmo > 0) then
		KindFire = drone({RandomRowOrColumn})
		NewPlayerState={AdjoinList PlayerState [droneAmmo#PlayerState.droneAmmo-1]}
	     else 
		if(PlayerState.sonarAmmo > 0) then
		   KindFire=sonar
		   NewPlayerState={AdjoinList PlayerState [sonarAmmo#PlayerState.sonarAmmo-1]}
		else 
		   KindFire = nil
		   NewPlayerState=PlayerState
		end
	     end
	  end
       end
       NewPlayerState
    end

    %If a mine was already placed before, the player may decide to make one explode.
    %Binds ID and Mine
    %Returns the new player state
    fun{FireMine ?ID ?Mine PlayerState}
       NewPlayerState in
       ID=PlayerState.id
       case PlayerState.mineLocation of nil then
	  Mine=nil
	  NewPlayerState=PlayerState
       [] H|T then
	  Mine=H
	  NewPlayerState={AdjoinList PlayerState [minePlanted#minePlanted-1 mineLocation#T]}
       end
       NewPlayerState
    end

    %Check if the player is dead or alive
    %Returns the new player state
    fun{IsDead Answer PlayerState}
       NewPlayerState in
       if PlayerState.life==0 then
	  Answer=true
       else
	  Answer=false
       end
       NewPlayerState={AdjoinList PlayerState [alive#Answer]}
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

    %Check if the position where the missile was exploded is in the request distances to decrease life of the player
    %Returns the new player state of the player and binds Message
    fun{SayMissileExplode ID Position PlayerState ?Message}
       NewPlayerState Distance in
       Distance =  Position.x-PlayerState.position.x %fonction valeur absolue ?
       if Distance >= 2 then
	  NewPlayerState=PlayerState
	  Message=sayDamageTaken(NewPlayerState.id 0 NewPlayerState.life)
       elseif Distance==1 then
	  if PlayerState.life-1<=0 then %if the player has no life anymore
	     NewPlayerState={AdjoinList PlayerState [alive#false]}
	     Message=sayDeath(NewPlayerState.id)
	  else
	     NewPlayerState={AdjoinList PlayerState [life#PlayerState.life-1]}
	     Message=sayDamageTaken(NewPlayerState.id 1 NewPlayerState.life)
	  end
       else
	  if PlayerState.life-2<=0 then
	     NewPlayerState={AdjoinList PlayerState [alive#false]}
	     Message=sayDeath(NewPlayerState.id)
	  else
	     NewPlayerState={AdjoinList PlayerState [life#PlayerState.life-2]}
	     Message=sayDamageTaken(NewPlayerState.id 2 NewPlayerState.life)
	  end
       end
       NewPlayerState
    end

    fun{SayMineExplode ID Position PlayerState ?Message}
        
    end

    fun{SayPassingDrone Drone ?ID ?Answer}
        nil
    end

    fun{SayAnswerDrone Drone ID Answer}
        nil
    end

    fun{SayPassingSonar ?ID ?Answer}
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
end
