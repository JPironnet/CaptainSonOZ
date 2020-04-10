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
                case Players#Colors of (H|T)#(X|Xr) then %if Players and Colors have the same length with one color for each player
                    if (Input.isTurnByTurn) then
                        player(port:{PlayerManager.PlayerGenerator H X Number} turnToWait:0 alive:true)|{GP T Xr Number+1} %the player is alive at the beginning of the game
        
                    else 
                        player(port:{PlayerManager.playerGenerator H X Number})|{GP T Xr Number+1} %il prend juste un port si c est en simultaneous ?
                    end
                end
            end
        end
    in
        {GP Input.players Input.colors 1} %Number is initialized to 1
    end

    fun {LaunchTurnByTurn Players GUI}
        %TODO
    end

    fun {LaunchSimultaneous Players GUI}
        %TODO
    end
    
in

    %Lancement du GUI
   GUI_Port = {GUI.portWindow}
   {Send GUI_Port buildWindow}

    %Creation des joueurs
   RecordPlayers = {GeneratePlayers}

   %Demande aux joueurs de choisir une position initiale pour DrawSubmarine 
   proc{InitialPosition RecordPlayers}
      ID
      Position
   in
      case RecordsPlayers of nil then skip
      [] H|T then
	 {Send H.port initPosition(?ID ?Position)}
	 {Wait ID}
	 {Wait Position}
	 {GUI.DrawSubMarine ? ID Position} %ptdr jsp c quoi Grid comme premier argument
      end
   end
    
    %Lancement de la partie 
    if(Input.isTurnByTurn) then
        {LaunchTurnByTurn RecordPlayers GUI_Port}
    else 
        {LaunchSimultaneous RecordPlayers GUI_Port}
    end
end

