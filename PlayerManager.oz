%PlayerManager.Oz
%Adding players to the list
functor
import
   Player
   Player2
   PlayerSmart
   PlayerBasicAI
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of playerSmart then {PlayerSmart.portPlayer Color ID}
		[] player1 then {Player.portPlayer Color ID}
		[] player2 then {Player2.portPlayer Color ID}
		[] basic then {PlayerBasicAI.portPlayer Color ID}
		end
	end
end
