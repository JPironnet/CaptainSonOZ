%PlayerManager.Oz
%Adding players to the list
functor
import
   Player
   PlayerSmart
   Player2
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player2 then {PlayerSmart.portPlayer Color ID}
		[] player1 then {Player2.portPlayer Color ID}
		[] player3 then {Player.portPlayer Color ID}
		end
	end
end
