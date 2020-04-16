%Main.Oz
functor
import
    GUI
    Input
    PlayerManager
   OS
   System(showInfo:Print)
define
    GUI_Port
    RecordPlayers 

   GeneratePlayers
   CanMove
   CreateGameState
   SimulateThinking
   UpdateTtw
   Move
   CreateNewList
   ChargeItem
   FireItem
   MineExplode
   RemoveList
   UpdateListOfPlayers
   LaunchTurnByTurn
   LaunchSimultaneous
   InitialPosition
   BroadCastMessage

   GameState
in
   
    %Function to generate players at the beginning of the game
    %Returns a list of records with label player and three fields (port, turnToWait and alive)
   fun {GeneratePlayers}
      fun {GP Players Colors Number}
	 if Number > Input.nbPlayer then nil %There is no more player in Players
	 else 
	    case Players#Colors of (H|T)#(X|Xr) then 
         if (Input.isTurnByTurn) then player(port:{PlayerManager.playerGenerator H X Number} turnToWait:0)|{GP T Xr Number+1}
         else 
            player(port:{PlayerManager.playerGenerator H X Number})|{GP T Xr Number+1}
         end
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
			    alive:Input.nbPlayer
			    firstRound:true
			   )
       GameState
    end
    

    proc {SimulateThinking}
        {Delay ({OS.rand} mod (Input.thinkMax-Input.thinkMin+1))+Input.thinkMin}
    end

    
    %Function that updates the turnToWait of the player, and then updates the playerslist of GameState.
    %Thanks to this function, the player is updated for the next round with turnToWait smaller 
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

    %Sends to the port of the player the message move
    %ID Position and Direction are binds
    %Check if Direction is Surface or not and sends to GUI some informations
    %Return the new state of the game
   fun{Move Player GameState GUI}
      ID Position Direction NewGameState in
      {Send Player.port move(?ID ?Position ?Direction)}
      {Wait ID} {Wait Position} {Wait Direction}
      if Direction=='Surface' then
	      NewPlayer NewList in
	      {Send GUI surface(ID)} %the submarine has made surface
	      NewPlayer={AdjoinList Player [turnToWait#Input.turnSurface]}
         {Print Player.turnToWait}
	      NewList={CreateNewList NewPlayer GameState.playerslist}
	      NewGameState={AdjoinList GameState [playerslist#NewList]}
	      NewGameState
      else
	      {Send GUI movePlayer(ID Position)} %the submarine moves
	      NewGameState=GameState
	      NewGameState
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

    %Send to the port of the player the message chargeItem
    %ID and Item are binds as follow :
    %Id::=<id>
    %Item::=null|mine|missile|sonar|drone
    %Return the state of the game
    fun{ChargeItem Player GameState GUI}
       ID KindItem in
       {Send Player.port chargeItem(?ID ?KindItem)}
       {Wait ID}
       {Wait KindItem}
        %{BroadCastMessage GameState.playerslist sayCharge(ID Item)}
       GameState
    end
    
    %Sends to the port of the player fireItem
    %ID and Mine are binds as follow :
    %ID::=<id> the id of the player who fired the item
    %KindFire ::= <fireitem>
    %If KindFire is a missile, calls the function FireMissileOrMine
    %Returns the new state of the game
    fun{FireItem Player GameState GUI}
       ID KindFire in
       {Send Player.port fireItem(?ID ?KindFire)}
       {Wait ID}
       {Wait KindFire}
       if {Label KindFire}==missile then
	  {BroadCastMessage GUI GameState.playerslist sayMissileExplode(ID KindFire.1)}
       elseif {Label KindFire}==mine then
	  {Send GUI putMine(ID KindFire.1)} %Sends to GUI to draw a mine at the position KindFire.1 because of mine(<Position>)
       end
       GameState
    end

    %Sends to the port of the player fireMine
    %ID and Mine are binds as follow :
    %ID::=<id> the id of the player who exploded the mine
    %Mine ::= mine(<Position>)
    %If the player has a mine, the mine explodes, and calls the function FireMissileOrMine
    %Returns the new state of the game
    fun{MineExplode Player GameState GUI}
       ID Mine Position in 
       {Send Player.port fireMine(?ID ?Mine)}
       {Wait ID}
       {Wait Mine}
       if Mine==null then
	  {Print 'Le joueur n a pas de mine'}
	  GameState
       else
	  {Print 'Le joueur a une mine et va l exploser'}
	  Position=Mine
	  {BroadCastMessage GUI GameState.playerslist sayMineExplode(ID Position)}
	  {Send GUI removeMine(ID Mine)} %GUI removes the mine at the position Mine.1
	  GameState
       end
    end

    %Removes Player of PlayerList because he is dead
    %Returns the updated list of players 
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
    %NewList::=[<player1> <player2> ... <playerN>]
    %PlayerN::=player(port:integer turnToWait:0|1|...|Input.nbSurface
    %Returns the new state of the game
    fun{UpdateListOfPlayers Player GameState}
       NewList
       NewGameState in
       NewList={RemoveList Player GameState.playerslist}
       NewGameState={AdjoinList GameState [playerslist#NewList alive#GameState.alive-1]}
       NewGameState
    end

   proc{LaunchTurnByTurn Players GameState GUI}
      if GameState.alive==1 then skip %it is the end of the game
	   {Print 'Partie finie'}
      else
	      case Players of nil then {LaunchTurnByTurn GameState.playerslist GameState GUI}
	      [] H|T then
	         Answer GS1 GS2 GS3 GS4 GS5 in
            {Print 'ttw avant de jouer'}
            {Print H.turnToWait}
            {Send H.port dive}
	         {Send H.port isDead(?Answer)}
	         {Wait Answer}
	         if Answer==1 then %Step one of the loop. Check if the player is dead.
		         GS1={UpdateListOfPlayers H GameState} % GameState is updated with the player H removed of playerslist because player H is dead
		         {LaunchTurnByTurn T GS1 GUI} %it is the turn of the next player 
	         else
		         if {CanMove H}==false then %Step one of the loop. Check if the player can move, if he cannot, GS1 is the udated version of GameState for the next loop with turnToWait-1
		            GS1={UpdateTtw H GameState}
		            {Print 'Le joueur ne peut pas jouer car il est en surface pendant encore :'}
		            {Print H.turnToWait}
                  
		            {LaunchTurnByTurn T GS1 GUI}

		         else
		            {Print '#########################################################'}
                  {Delay 2000}
		            {Print 'CanMove est true'}
		            {Send H.port dive} %If he can move, the player dives BON DU COUP IL VA IDVE A CHAQUE FOIS MM SI IL EST PAS A LA SURFACE AU DEPART
		            GS2={Move H GameState GUI} %Step two of the loop. The player moves and GS2 is a new version updated of GameState
		            {Print 'GS2 est ok, le player a bouge'}
		            GS3={ChargeItem H GS2 GUI} %Step three
		            {Print 'GS3 est ok, le player a charge un item'}
		            GS4={FireItem H GS3 GUI} %Step four
		            {Print 'GS4 est ok, le player a fire un item'}
		            GS5={MineExplode H GS4 GUI} %Step five
		            {Print 'GS5 est ok, la mine a explose si il y en avait une'}
		            {LaunchTurnByTurn T GS5 GUI}
		         end
	         end
	      end
      end
   end
    

   proc {LaunchSimultaneous Players GameState GUI}
      proc {Turn Player}
         {Print 'dedans'}
	      Answer ID Position Direction Item KindFire Mine GS2 %GS1 
         in 
	      %if (GameState.firstRound==true) then
	         {Send Player.port dive}
            {Print 'C est dive'}
	      %end
	      {Send Player.port isDead(?Answer)}
	      {Wait Answer}
         {Print Answer}
	      if (Answer == 0) then
            {Print 'En vie et pret a move'}
	         {SimulateThinking}
	         {Send Player.port move(?ID ?Position ?Direction)}
            {Print 'j ai move'}
	         {Wait ID} {Wait Position} {Wait Direction} 
	         if (Direction=='Surface' ) then
		         {Delay Input.turnSurface}
		         {Send GUI surface(Player.id)}
		         {Turn Player}
	         else 
               GS2={Move Player GameState GUI}
		         {Send Player.port isDead(?Answer)}
		         {Wait Answer}
		         if (Answer == 0) then
		            {SimulateThinking}
		            {Send Player.port chargeItem(?ID ?Item)}
		            {Wait ID} {Wait Item}
		            %{Broadcast}
		            {Send Player.port isDead(?Answer)}
		            {Wait Answer}
		            if (Answer == 0) then
		               {SimulateThinking}
		               {Send Player.port fireItem(?ID ?KindFire)}
		               {Wait ID} {Wait KindFire}
                     %{Broadcast}
		               {Send Player.port isDead(?Answer)}
		               {Wait Answer}
		               if (Answer == 0) then
			               {SimulateThinking}
			               {Send Player.port fireMine(?ID ?Mine)}
			               {Wait ID} {Wait Mine}
                        %{Broadcast}
			               %if(GameState.firstRound==true) then
			                  %GS1={AdjoinList GameState [firstRound#false]}
			               %end
			               if(GameState.alive > 1) then %parametre que je pense interessant
			                  {Delay 2000}
                           {Turn Player}
			               else
			                  skip
			               end
		               end
		            end
		         end    
	         end
	      end
      end
   in
      {List.forAll Players (proc {$ Player} thread {Turn Player} end end)} 
   end

    %Send Say to all players
    %Return the state of the game
    proc{BroadCastMessage GUI_port PlayersList Say}
       Message in
       case Say
       of sayMineExplode(ID Position) then
	  {List.forAll PlayersList 
	   proc {$ Player} 
	      {Send Player.port sayMineExplode(ID Position ?Message)} 
	      {Wait Message}
	      if (Message \= null) then								
		 case Message of sayDamageTaken(ID Damage Life) then 
		    {BroadCastMessage GUI_port PlayersList sayDamageTaken(ID Damage Life)} % Broadcast
		    {Send GUI_port lifeUpdate(ID Life)}
		 [] sayDeath(ID) then 
		    {BroadCastMessage GUI_port PlayersList sayDeath(ID)} % Broadcast
		    {Send GUI_port removePlayer(ID)}
		 end
	      end
	   end
	  }
       [] sayMissileExplode(ID Position) then
	  {List.forAll PlayersList 
	   proc {$ Player} 
	      {Send Player.port sayMissileExplode(ID Position ?Message)} 
	      {Wait Message}
	      if (Message \= null) then								
		 case Message 
		 of sayDamageTaken(ID Damage Life) then 
		    {BroadCastMessage GUI_port PlayersList sayDamageTaken(ID Damage Life)} % Broadcast
		    {Send GUI_port lifeUpdate(ID Life)}
		 [] sayDeath(ID) then 
		    {BroadCastMessage GUI_port PlayersList sayDeath(ID)} % Broadcast
		    {Send GUI_port removePlayer(ID)}
		 end
	      end
	   end
	  }
       else
	  {List.forAll PlayersList (proc {$ Player} {Send Player.port Message} end)}
       end							
    end
    
     
    proc{InitialPosition RecordPlayers GUI}
       ID
       Position
    in
       case RecordPlayers of nil then skip
       [] H|T then
	  {Send H.port dive}
	  {Send H.port initPosition(?ID ?Position)}
	  {Wait ID}
	  {Wait Position}
	  {Send GUI initPlayer(ID Position)}
	  {InitialPosition T GUI}
       end
    end

    %Lancement du GUI
    GUI_Port = {GUI.portWindow}
    {Send GUI_Port buildWindow}
   {Print 'Lancement GUI'}

    %Creates players
    %RecordPlayers has a port, a turnToWait and a alive field
    RecordPlayers = {GeneratePlayers}
   {Print 'Generation des joueurs '}

    %Ask players to choose an initial position and send to GUI
    {InitialPosition RecordPlayers GUI_Port}
    {Print 'Position initiale'}
    
    %Creation de l'etat de la partie
    GameState={CreateGameState RecordPlayers}
    {Print 'Creation GameState'}

   {Delay 5000}
   {Print 'GO'}
    %Lancement de la partie 
    if(Input.isTurnByTurn) then
       {LaunchTurnByTurn RecordPlayers GameState GUI_Port}
    else 
      {LaunchSimultaneous RecordPlayers GameState GUI_Port}
    end
end