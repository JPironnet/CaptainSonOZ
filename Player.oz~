%Player.Oz
functor
import
    Input
export
    portPlayer:StartPlayer %when PlayerManager.oz calls playerX.portPlayer, it calls the function StartPlayer
define
    StartPlayer
    TreatStream
in
   %TreatStream
   /*ID the id of the player initalialized with PlayerManager
   * Position is initialized to null 
   */
    proc{TreatStream Stream Id Position ...} 
       case Stream of nil skip
       [] initPosition(?ID ?Position)|T then
	  Position={GetPosition}
	  ID=Id
	  {TreatStream T ID Position ...}
       [] Move(?ID ?Position ?Direction)|T then
	  ID=Id
	  Position= %ptdr ben du coup jsp je beug
	  Direction=%mais la position elle est choisie random? je pige pas
       [] dive|T then %to do
       [] chargeItem(?ID ?KindItem)|T then %to do
       [] fireItem(?ID ?KindFire)|T then %to fo
       [] fireMine(?ID ?Mine)|T then %to do
       [] isDead(?Answer)|T then %to do
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

    fun{GetPosition}%get a random initial position 
       Row Column in
       Row = {Os.rand} mod Input.NRow %between 0 and NRow
       Column = {OS.rand} mod Input.NColumn %between 0 and NColumn
       if {IsIsland Row Column 1 1 Input.Map} then {GetPosition}
       else pt(x:Row y:Column)
       end
    end

    fun{IsIsland Row Column Acc1 Acc2 Map} %check if the initial position is an island
       case Map of H|T then 
	  if Acc1==Row then
	     if Acc2==Column+1 then
		if H==1 then true
		else false
		end
	     else
		if Acc2>1 then {IsIsland Row Column Acc1 Acc2+1 T}
		else {IsIsland Row Column Acc1 Acc2+1 H}
		end
	     end
	  else {IsIsland Row Column Acc1+1 Acc2 T}
	  end
       end
    end

    
    
    fun{StartPlayer Color ID} %Color and ID are bound thanks to PlayerManager 
        Stream
        Port
    in
        {NewPort Stream Port}
        thread
            {TreatStream Stream ID null ...}
        end
        Port
    end
end
