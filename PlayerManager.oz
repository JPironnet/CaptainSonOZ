%PlayerManager.Oz
%Adding players to the list
functor
import
   Player050Random
   Player050Escape
   Player050Target
   PlayerBasicAI
export
	playerGenerator:PlayerGenerator
define
	PlayerGenerator
in
	fun{PlayerGenerator Kind Color ID}
		case Kind
		of player050target then {Player050Target.portPlayer Color ID}
		[] player050random then {Player050Random.portPlayer Color ID}
		[] player050escape then {Player050Escape.portPlayer Color ID}
		[] basic then {PlayerBasicAI.portPlayer Color ID}
		end
	end
end
