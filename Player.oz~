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
    proc{TreatStream Stream PlayerState} %on remplace les parametres <p1> <p2> etc par un etat du joueur dans lequel on place tous les parametres
        case Stream of nil then skip
	    [] initPosition(?ID ?Position)|T then
	        ID=PlayerState.id
	        Position={InitPosition PlayerState.position}
            {Send GUI_Port ID}
            {Send GUI_Port Position}
            {TreatStream T PlayerState}

        [] move(?ID ?Position ?Direction)|T then
            ID=PlayerState.id
            Direction=
            Position=

            {Send GUI_Port ID}
            {Send GUI_Port Position}
            {Send GUI_Port Direction}
            {TreatStream T PlayerState}    
        
        [] dive|T then 
            
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
        Id=id(id:ID color:Color)
        KindItem=kinditem(mine:0 sonar:0 missile:0 drone:0)
        LoadCharges=loadcharges(mine:0 sonar:0 missile:0 drone:0)

        PlayerState = playerstate(
                                id:Id 
                                position:Position 
                                kinditem:KindItem 
                                loadcharges:LoadCharges
                                life:Input.maxDamage
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
    %Returns true if it's an island, false otherwise
    fun{IsIsland Row Column}
       fun{HelpII Row Column Acc1 Acc2 Map}
	  case Map of H|T then
	     if Acc1==Row then
		if Acc2==Column then
		   if H==1 then true
		   else false
		   end
		else {HelpII Row Column Acc1 Acc2+1 H.2}
		end
	     else {HelpII Row Column Acc1+1 Acc2 T}
	     end
	  end
       end   
    in
       {HelpII Row Column 1 1 Input.Map}    
    end

    fun{Move ?ID ?Position ?Direction}
        %TODO
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
