%Main.Oz
functor
import
    GUI
    Input
    PlayerManager
define
    GUI_Port
    RecordPlayers 

    GameState %Etat de la partie TODO

      %Function to generate players at the beginning of the game
   %Returns a list of records with label player and three fields (port, turnToWait and alive)
    fun {GeneratePlayers}
        fun {GP Players Colors Number}
            if Number > Input.nbPlayer then nil %There is no more player in Players
            else 
                case Players#Colors of (H|T)#(X|Xr) then player(port:{PlayerManager.playerGenerator H X Number} turnToWait:1)|{GP T Xr Number+1} %turntowait initialise a 1 pcq plus ez
                end
            end
        end
    in
        {GP Input.players Input.colors 1} %Number is initialized to 1
    end

    %Check if the player can move
    %Returns true if he can, false otherwise
    fun{CanMove Player}
       if Player.turnToWait==0 then true
       else false
       end
    end
    
    %creation de l'etat de la partie 
    fun{CreateGameState RecordPlayers} %je suis vraiment en hess pour coder etat de la partie, genre comment recuperer les differents playerstat
    %si on arrive a recuperer la liste des playerstate, apres il suffit d'en faire une liste et de rajouter les eventuelles param de partie
    %faudra demander a Maxime lol
        GameState in
        fun {CreateBasicGameState ListPlayers}
            case ListPlayers of nil then skip
            [] H|T then {CreatePlayerState H}|{CreateBasicGameState T}
            end
        in
            {CreateBasicGameState RecordPlayers}
        end

        GameState = gamestate(player1state: ... player2state : ... isfirstround : true )
    end

    proc {SimulateThinking}
        {Delay ({OS.rand} mod (Input.thinkMax-Input.thinkMin+1))+Input.thinkMin}
    end

    
    proc{LaunchTurnByTurn Players GameState GUI}
       %faire une condition si la liste est vide ou non si oui skip car jeu fini
       case Players of nil then %jsp
       [] H|T then
	  {Send isDead(?Answer)}
	  {Wait Answer}
	  if Answer==false then %if the player is alive
	     if {CanMove H} then %if the player can move
		{Send H.port dive} %the player dives
		{Send H.port move(?ID ?Position ?Direction)}
		{Wait ID} {Wait Position} {Wait Direction} 
		if Direction==Surface then %changer le state et continuer
		   {Send GUI surface(ID)}
		else
		   {Send GUI movePlayer(ID Position)}
		   %{BroadCast...} osef
		end
		{Send H.port chargeItem(?ID ?Item)}
		{Wait ID} {Wait Item}
		%{Broadcast...} osef
		
		{Send H.port fireItem(?ID ?KindFire)}
		{Wait ID} {Wait KindFire}
		if {Label KindFire}==missile then
		   {BroadCastMessage GameState.playerList sayMissileExplode(ID Position ?Message)} %send to every player that a missile exploded
		elseif {Label KindFire}==mine then
		   {Send GUI putMine(ID KindFire.pt)} %je pense que dans <position> le label c est pt
		end
		{Send H.port fireMine(?ID ?Mine)}
		{Wait ID} {Wait Mine}
		if Mine /= nil then
		   {BroadCastMessage GameState.playerList sayMineExplode(ID Mine.pt ?Message)} %traiter le msg et send des trucs au gui et remove la mine et Mine.pt = position normalement
		   
		{LaunchTurnByTurn T GameState GUI} 
	     else % si il ne peut pas bouger on doit diminuer son turntowait et actualiser player.turntowait
		
	     end
	  else
	     {LaunchTurnByTurn {DeletePlayerList} {GameStateUpdate} GUI}  %ca va retirer le joueur de la liste, mettre a jour la liste dans GameState faire les fonctions
	  end
	  
       end

    fun {LaunchSimultaneous Players GUI}
        %TODO
    end

    %Send Message to all players 
    fun{BroadCastMessage PlayerList Message}
       case PlayerList of nil then skip
       [] H|T then {Send H.port Message}
       end
    end
    
in

    %Lancement du GUI
    GUI_Port = {GUI.portWindow}
    {Send GUI_Port buildWindow}

    %Creates players
    %RecordPlayers has a port, a turnToWait and a alive field
    RecordPlayers = {GeneratePlayers}



    %Ask players ti choos an initial position and send to GUI 
    proc{InitialPosition RecordPlayers}
        ID
        Position
    in
        case RecordsPlayers of nil then skip
        [] H|T then
	    {Send H.port initPosition(?ID ?Position)}
	    {Wait ID}
	    {Wait Position}
	    {Send GUI_Port initPlayer(ID Position)}  
        end
    end
    
    %Creation de l'etat de la partie
    GameState={CreateGameState RecordPlayers}

    %Lancement de la partie 
    if(Input.isTurnByTurn) then
        {LaunchTurnByTurn RecordPlayers GameState GUI_Port}
    else 
        {LaunchSimultaneous RecordPlayers GUI_Port}
    end
end

