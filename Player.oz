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
   /*l 
   */
    proc{TreatStream Stream...} 
       case Stream of nil skip
       [] initPosition(?ID ?Position)|T then
       [] Move(?ID ?Position ?Direction)|T then
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

    
    
    fun{StartPlayer Color ID} 
        Stream
        Port
    in
        {NewPort Stream Port}
        thread
            {TreatStream Stream   ...}
        end
        Port
    end
end
