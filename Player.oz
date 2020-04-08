%Player.Oz
functor
import
    Input
export
    portPlayer:StartPlayer
define
    StartPlayer
    TreatStream
in
    proc{TreatStream Stream <p1> <p2> ...} % as as many parameters as you want
        % ... proc{TreatStream Stream <p1> <p2> ...} % as as many parameters as you want
      %si j ai bien capte cette procedure traite tt les procedures possibles donc jsp si ca di-oit etre ecrit dedans ou a part mais alz a se change vite
      proc{InitPosition ?ID ?Position}
	 %TO DO
      end
      proc{Move ?ID ?Position ?Direction}
	 %TO DO
      end
      proc{ChargeItem ?ID ?KindItem}
	 %TO DO
      end
      proc{FireItem ?ID ?KindFire}
	 %TO DO
      end
      proc{FireMine ?ID ?Mine}
	 %TO DO
      end
      proc{IsDead ?Answer} 
	 %TO DO
      end
      proc{SayMove ID Direction}
	 %TO DO
      end
      proc{SaySurface ID}
	 %TO DO
      end
      proc{SayCharge ID KindItem}
	 %TO DO
      end
      proc{SayMinePlaced ID}
	 %TO DO
      end
      proc{SayMissileExplode ID Position ?Message}
	 %TO DO
      end
      proc{SayMineExplode ID Position ?Message}
	 %TO DO
      end
      proc{SayPassingDrone Drone ?ID ?Answer}
	 %TO DO
      end
      proc{SayAnswerDrone Drone ID Answer}
	 %TO DO
      end
      proc{SayPassingSonar ?ID ?Answer}
	 %TO DO
      end
      proc{SayAnswerSonar ID Answer}
	 %TO DO
      end
      proc{SayDeath ID}
	 %TO DO
      end
      proc{SayDamageTaken ID Damage LifeLeft}
	 %TO DO
      end
      
      
    end
    fun{StartPlayer Color ID}
        Stream
        Port
    in
        {NewPort Stream Port}
        thread
            {TreatStream Stream <p1> <p2> ...}
        end
        Port
    end
end
