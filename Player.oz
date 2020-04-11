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
    proc{TreatStream Stream PlayerState} %ne devrait on pas ajouter un argument GUI_port?
        case Stream of nil then skip
	[] initPosition(?ID ?Position)|T then
	   ID=PlayerState.id
	   Position={InitPosition PlayerState.position}
	   %{Send GUI_Port ID} %je pense que ca sert a rien pcq dans le GUI.oz il traite pas ca 
	   %{Send GUI_Port Position}%pareil du coup
	   {TreatStream T PlayerState}

	[] move(?ID ?Position ?Direction)|T then %on doit faire le send dans la main mais jsp trop commment donc je lai ecris ici en attendant
	   OldPosition in
           OldPosition=Position
	   ID=PlayerState.id
           Direction= %jsp exactement mais en lien avec saymove
	   Position={Move PlayerState.position PlayerState.visited} %new position
	   if Position==OldPosition then
	      PlayerState.surface=true %he is on surface now
	      PlayerState.visited=nil %visited is nil now because is on surface
	   else PlayerState.visited={Append Visited [pt(x:PlayerState.position.x y:PlayerState.position.y)]}
	   end

           %{Send GUI_Port ID}
           %{Send GUI_Port Position}
	   %{Send GUI_Port Direction}
	   {Send GUI_Port movePlayer(ID Position)} %pas sure que ce soit la je pense pas d ailleur que c la
           {TreatStream T PlayerState}    
        
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
    %Returns the new position of the player 
    fun{InitPosition Position}
       Row Column
    in
       Row = {OS.rand} mod {Input.NRow} %choose a random row between 0 and NRow
       Column = {OS.rand} mod {Input.NColumn} %choose a random column between 0 and NColumn
       if {IsIsland Row Column} then {InitPosition}
       else {AdjoinList Position [x#Row y#Column]}
       end
    end

    %To check if the position is an island or not
    %Returns true if it's an island or the limit of the map, false otherwise
    fun{IsIsland Row Column}
       if Row>3 then true
       else
	  if Column>4 then true
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
	     {HelpII Row Column 1 1 [[0 0 1 0] [0 0 0 0] [0 1 0 1]]}
	  end
       end 
    end

    %Check if the submarine has already vistied the position given by X and Y
    %Return true or false 
    fun{IsVisited X Y List}
       case List of nil then false %{Append Visited [pt(x:X y:Y)]}%on ajoute a la liste visitee je pense qu on lajoute a la procedure dans player
       [] H|T then
	  if H.x==X then
	     if H.y==Y then true
	     else false
	     end
	  else false
	  end
       end
    end

    fun{Move Position Visited}
       Direction Dir X Y in
       Direction= ['East' 'North' 'South' 'West' 'Surface'] %jsp trop comment faire donc j ai fais ocmme ca faudra juste chipoter piur qu ece soit conforme
       Dir={OS.rand} mod 5+1 %choix d une direction
       X=Position.x
       Y=Position.y
       if Dir==2 then %Si c est nord
	  if {IsIsland X-1 Y} then %si c est une ile
	     {Move Position Visited} %on recommence
	  else %si ce n est pas une ile
	     if {IsVisited X-1 Y Visited} then {Move Position Visited} %si ca a ete visite on recommence
	     else {AdjoinList Position [x#X-1]}
	     end
	  end
       elseif Dir==3 then
	  if {IsIsland X+1 Y} then %si c est une ile
	     {Move Position Visited} %on recommence
	  else %si ce n est pas une ile
	     if {IsVisited X+1 Y Visited} then {Move Position Visited} %si ca a ete visite on recommence
	     else {AdjoinList Position [x#X+1]}
	     end
	  end
       elseif Dir==1 then
	  if {IsIsland X Y+1} then %si c est une ile
	     {Move Position Visited} %on recommence
	  else %si ce n est pas une ile
	     if {IsVisited X Y+1 Visited} then {Move Position Visited} %si ca a ete visite on recommence
	     else {AdjoinList Position [y#Y+1]}
	     end
	  end
       elseif Dir==4 then
	  if {IsIsland X Y-1} then %si c est une ile
	     {Move Position Visited} %on recommence
	  else %si ce n est pas une ile
	     if {IsVisited X Y-1 Visited} then {Move Position Visited} %si ca a ete visite on recommence
	     else {AdjoinList Position [y#Y-1]}
	     end
	  end
       else
	  Position %si c surface
	  
       end
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
