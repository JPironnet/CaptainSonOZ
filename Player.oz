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
	[] initPosition(ID Position)|T then
	   NewPlayerState in
	   NewPlayerState={InitPosition ID Position PlayerState}
	   {TreatStream T NewPlayerState}

	[] move(?ID ?Position ?Direction)|T then
	   NewPlayerState in
           NewPlayerState={Move ID Position Direction PlayerState} 
           {TreatStream T NewPlayerState}    
        
	[] dive|T then %quand turntowait=0 alors il peut
            {AdjoinList PlayerState [surface#false]} %he is not on surface anymore
        [] chargeItem(?ID ?KindItem)|T then 

        [] fireItem(?ID ?KindFire)|T then 
        
        [] fireMine(?ID ?Mine)|T then 
        
        [] isDead(?Answer)|T then 
        
        [] sayMove(ID Direction)|T then
        
        [] saySurface(ID)|T then
        
        [] sayCharge(ID KindItem) then
        
        [] sayMinePlaced(ID) then
        
        [] sayMissileExplode(ID Position ?Message) then
        
        [] sayMineExplode(ID Position ?Message) then
        
        [] sayPassingDrone(Drone ?ID ?Answer) then
        
        [] sayAnswerDrone(Drone ID Answer) then
        
        [] sayPassingSonar(?ID ?Answer)then
        
        [] sayAnswerSonar(ID Answer) then
        
        [] sayDeath(ID) then
        
        [] sayDamageTaken(ID Damage LifeLeft) then
    
	end

    end


    %Creation de l'etat du joueur
    fun {CreateStatePlayer Player}
        PlayerState

        Position
        Id
        KindItem
        LoadCharges
    in
        Position=pt(x:0 y:0)
        Id=id(id:ID color:Color name:_)
        KindItem=kinditem(mine:0 sonar:0 missile:0 drone:0)
        LoadCharges=loadcharges(mine:0 sonar:0 missile:0 drone:0)

       PlayerState = playerstate(
			id:Id 
			position:Position 
			kinditem:KindItem 
			loadcharges:LoadCharges
			life:Input.maxDamage
			surface:true
			visited:nil %liste des positions entre 2 surfaces
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
    fun{InitPosition ID Position PlayerState}
       Row Column NewState
    in
       ID=PlayerState.id
       Row = {OS.rand} mod {Input.NRow} %choose a random row between 0 and NRow
       Column = {OS.rand} mod {Input.NColumn} %choose a random column between 0 and NColumn
       Position=pt(x:Row y:Column)
       if {IsIsland Row Column} then {InitPosition}
       else
	  NewState={AdjoinList PlayerState [position#Position]}
	  NewState
       end
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
		NewPlayerState={AdjoinList PlayerState [position#Position]}
	     end
	  end
       elseif Dir==3 then
	  if {IsIsland  PlayerState.position.x+1 PlayerState.position.y} then
	     {Move ID Position Direction PlayerState} 
	  else
	     if {IsVisited PlayerState.position.x+1 PlayerState.position.y PlayerState.visited} then {Move ID Position Direction PlayerState} 
	     else
		Position=pt(x:PlayerState.position.x+1 y:PlayerState.position.y)
		NewPlayerState={AdjoinList PlayerState [position#Position]}
	     end
	  end
       elseif Dir==1 then
	   if {IsIsland  PlayerState.position.x PlayerState.y+1} then
	     {Move ID Position Direction PlayerState} 
	  else
	     if {IsVisited PlayerState.position.x PlayerState.y+1 PlayerState.visited} then {Move ID Position Direction PlayerState} 
	     else
		Position=pt(x:PlayerState.position.x y:PlayerState.position.y+1)
		NewPlayerState={AdjoinList PlayerState [position#Position]}
	     end
	  end
       elseif Dir==4 then
	  if {IsIsland  PlayerState.position.x PlayerState.y-1} then
	     {Move ID Position Direction PlayerState} 
	  else
	     if {IsVisited PlayerState.position.x PlayerState.y-1 PlayerState.visited} then {Move ID Position Direction PlayerState} 
	     else
		Position=pt(x:PlayerState.position.x y:PlayerState.position.y-1)
		NewPlayerState={AdjoinList PlayerState [position#Position]}
	     end
	  end
       else
	  Position=PlayerState.position
	  NewPlayerState={AdjoinList PlayerState [visited#Position]}
       end
       NewPlayerState
    end

    fun{Dive}
        %TODO
    end

    fun{ChargeItem ?ID ?KindItem}
        %TODO
    end

    fun{FireItem ?ID ?KindFire}
        %TODO
    end

    fun{FireMine ?ID ?Mine}
        %TODO
    end

    fun{IsDead ?Answer}
        %TODO
    end

    fun{SayMove ID Direction}
        %TODO
    end

    fun{SaySurface ID}
        %TODO
    end

    fun{SayCharge ID KindItem}
        %TODO
    end

    fun{SayMinePlaced ID}
        %TODO
    end

    fun{SayMissileExplode ID Position ?Message}
        %TODO
    end

    fun{SayMineExplode ID Position ?Message}
        %TODO
    end

    fun{SayPassingDrone Drone ?ID ?Answer}
        %TODO
    end

    fun{SayAnswerDrone Drone ID Answer}
        %TODO
    end

    fun{SayPassingSonar ?ID ?Answer}
        %TODO
    end

    fun{SayAnswerSonar ID Answer}
        %TODO
    end

    fun{SayDeath ID}
        %TODO
    end

    fun{SayDamageTaken ID Damage LifeLeft}
        %TODO
    end
end
