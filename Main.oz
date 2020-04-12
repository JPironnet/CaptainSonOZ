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
                case Players#Colors of (H|T)#(X|Xr) then player(port:{PlayerManager.playerGenerator H X Number})|{GP T Xr Number+1}
                end
            end
        end
    in
        {GP Input.players Input.colors 1} %Number is initialized to 1
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
    
    fun {LaunchTurnByTurn Players GUI}
        %parcourir la liste de Players
       %le player 1 commence, c est son tour, quand il a fini de jouer on le retire de la liste
       %checker si il est alive, si il ne l est pas on le retire de la liste a jamais 
       %quand tous les players ont fini on recommence avec la liste de depart moins ceux qui sont morts
       {Send H.port move(?ID ?Position ?Direction)}
       {Wait ID}
       {Wait Position}
       {Wait Direction}
       {Send GUI movePlayer(ID Position)} %le joueur va bouger 
    end

    fun {LaunchSimultaneous Players GUI}
        %TODO
    end

    proc {BroadCastMessage Message PlayerList}
        %TODO
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
        {LaunchTurnByTurn RecordPlayers GUI_Port}
    else 
        {LaunchSimultaneous RecordPlayers GUI_Port}
    end
end

