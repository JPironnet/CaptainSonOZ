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
                case Players#Colors of (H|T)#(X|Xr) then player(port:{PlayerManager.playerGenerator H X Number} turnToWait:Input.nbPlayer-1|{GP T Xr Number+1} %turntowait initialise a 1 pcq plus ez
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
    fun{CreateGameState RecordPlayers}
       GameState in
       GameState= gamestate(playerslist:RecordPlayers
			    playersalive:Input.nbPlayer
			   )
       GameState
    end
    

    proc {SimulateThinking}
        {Delay ({OS.rand} mod (Input.thinkMax-Input.thinkMin+1))+Input.thinkMin}
    end

    
    %Function that updates the turnToWait of the player, and then updates the playerslist of GameState. Thanks to this function, the player is updated for the next round
    %Returns NewGameState
    fun{UpdateTtw Player GameState}
       NewPlayer
       NewList
       NewGameState in
       NewPlayer={AdjoinList Player turnToWait#Player.turnToWait-1}
       NewList={CreateNewList NewPlayer GameState.playerslist}
       NewGameState={AdjoinList GameState [playerslist#NewList]}
       NewGameState
    end

    fun{Move Player GameState GUI}
       {Send Player.port move(?ID ?Position ?Direction)}
       {Wait ID} {Wait Position} {Wait Direction}
       if Direction=='Surface' then
	  NewPlayer NewList NewGameState in
	  {Send GUI surface(ID)} %the submarine has made surface
	  NewPlayer={AdjoinList Player turnToWait#Input.turnSurface}
	  NewList={CreateNewList NewPlayer GameState.playerslist}
	  NewGameState={AdjoinList GameState [playerslist#NewList]}
	  NewGameState
       else
	  {Send GUI movePlayer(ID Position)} %the submarine moves
	  GameState
       end
    end

%Create a new list to update GameState.playerslist
%Returns the updated list
    fun{CreateNewList Player PlayersList}
       case PlayersList of nil then nil
       [] H|T then
	  if Player.port==H.port then Player|{CreateNewList Player T}
	  else
	     H|{CreateNewList Player T}
	  end
       end
    end

    fun{ChargeItem Player GameState GUI}
       {Send Player.port chargeItem(?ID ?Item)}
       {Wait ID}
       {Wait Item}
       GameState
    end

    fun{FireItem Player GameState GUI}
       {Send Player.port fireItem(?ID ?KindFire)}
       {Wait ID}
       {Wait KindFire}
       if {Label KindFire}==missile then
	  {BroadCastMessage GameState.playerList sayMissileExplode(ID Position ?Message)} %Sends to every player that a missile exploded
	  {Wait Message}
      %ptet check si c est saydeath alors remove de la liste
	  GameState
       elseif {Label KindFire}==mine then
	  {Send GUI putMine(ID KindFire.1)} %Sends to GUI to draw a mine at the position KindFire.1 because of mine(<Position>)
	  GameState
       end
    end

    fun{MineExplode Player GameState GUI}
       {Send H.port fireMine(?ID ?Mine)}
       {Wait ID}
       {Wait Mine}
       if Mine /= nil then
	  {BroadCastMessage GameState.playerList sayMineExplode(ID Mine.1 ?Message)} %traiter le msg Message si il est dead
	  {Send GUI removeMine(ID Mine.1)} %GUI removes the mine at the position Mine.1 
       end
    end

%Removes Player of PlayerList because he is dead
%Returns the updated list of player 
    fun{RemoveList Player PlayersList}
       case PlayersList of nil then nil
       [] H|T then
	  if Player.port==H.port then {RemoveList Player T}
	  else
	     H|{RemoveList Player T}
	  end
       end
    end

%Updates the list of player if one player is dead
%Returns the new state of the game
    fun{UpdateList Player GameState}
       NewList
       NewGameState in
       NewList={RemoveList Player GameState.playerslist}
       NewGameState={AdjoinList GameState [playerslist#NewList]}
       NewGameState
    end

%par contre jsp pour removePlayer
    proc{LaunchTurnByTurn Players GameState GUI}
       if GameState.playeralive==1 then skip %it is the end of the game
       else
	  case Players of nil then {LauchTurnByTurn GameState.playerslist GameState GUI}
	  [] H|T then
	     GS1 GS2 GS3 GS4 GS5 in
	     {Send isDead(?Answer)}
	     {Wait Answer}
	     if Answer==true then %Step one of the loop. Check if the player is dead.
		GS1={UpdateList H GameState} % GameState is updated with the player H removed of playerslist because player H is dead
		{LaunchTurnByTurn T GS1 GUI} %it is the turn of the next player 
	     else
		if {CanMove H}==false then %Step one of the loop. Check if the player can move, if he cannot, GS1 is the udated version of GameState for the next loop with turnToWait-1
		   GS1={UpdateTtw H GameState}
		   {LaunchTurnByTurn T GS1 GUI}
		else 
		   {Send H.port dive} %If he can move, the player dives BON DU COUP IL VA IDVE A CHAQUE FOIS MM SI IL EST PAS A LA SURFACE AU DEPART
		   GS2={Move H GameState GUI} %Step two of the loop. The player moves and GS2 is a new version updated of GameState
		   GS3={ChargeItem H GS2 GUI}
		   GS4={FireItem H GS3 GUI}
		   GS5={MineExplode H GS4 GUI}
		   {LaunchTurnByTurn T GS5 GUI}
		end
	     end
	  end
       end
    end

    

    proc {LaunchSimultaneous Players GameState GUI}
        proc {Turn Player}
            if (GameState.firstRound==true) then
                {Send Player.port dive}
            end
            {Send isDead(?Answer)}
	        {Wait Answer}
            if (Answer == false) then
                {SimulateThinking}
                {Send Player.port move(?ID ?Position ?Direction)}
                {Wait ID} {Wait Position} {Wait Direction} 
                if (Direction==Surface) then
                    {Delay Input.turnSurface}
                    {Send GUI_Port surface(Player.id)}
                    {Turn Player}
                else 
                    {Send isDead(?Answer)}
	                {Wait Answer}
                    if (Answer == false) then
                        {SimulateThinking}
                        {Send Player.port chargeItem(?ID ?Item)}
		                {Wait ID} {Wait Item}
		                %{Broadcast}
                        {Send isDead(?Answer)}
	                    {Wait Answer}
                        if (Answer == false) then
                            {SimulateThinking}
                            {Send Player.port fireItem(?ID ?KindFire)}
		                    {Wait ID} {Wait KindFire}
                            %{Broadcast}
                            {Send isDead(?Answer)}
	                        {Wait Answer}
                            if (Answer == false) then
                                {SimulateThinking}
                                {Send Player.port fireMine(?ID ?Mine)}
		                        {Wait ID} {Wait Mine}
                                %{Broadcast}
                                if(GameState.firstRound==true) then
                                    {AdjoinList GameState [firstRound#false]}
                                end
                                if(GameState.alive > 1) %parametre que je pense interessant a ajouter dans GameState qu'il faudra vrmt coder demain
                                    {Turn Player}
                                end
                            end
                        end
                    end    
                end
            end
        end
    in
        {List.forAll PlayerList (proc {$ Player} thread {Turn Player} end end)} 
    end

    %Send Message to all players 
    proc{BroadCastMessage PlayerList Message}
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
        {LaunchSimultaneous RecordPlayers GameState GUI_Port}
    end
end

