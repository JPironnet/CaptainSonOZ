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
   DeadPort
   StartDeadPort
   TreatStream
   GenerateDeadList

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
         player(port:{PlayerManager.playerGenerator H X Number} turnToWait:0)|{GP T Xr Number+1}
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

    
    %Create the state of the game
    %GameState is a record with 3 fields : playerslist, alive (the number of players alive) and firstRound used for the turn by turn mode
    %Return GameState
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
       NewPlayer={AdjoinList Player [turnToWait#Player.turnToWait-1]}
       {Print 'Le joueur doit encore attendre a la surface pendant :'}
       {Print NewPlayer.turnToWait}
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
      {BroadCastMessage GUI  GameState GameState.playerslist Player sayMove(ID Direction)}
      if Direction=='Surface' then
	      NewPlayer NewList in
	      {Send GUI surface(ID)} %the submarine has made surface
	      NewPlayer={AdjoinList Player [turnToWait#Input.turnSurface]}
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
    proc{ChargeItem Player GameState GUI}
       ID KindItem in
       {Send Player.port chargeItem(?ID ?KindItem)}
       {Wait ID}
       {Wait KindItem}
       {BroadCastMessage GUI GameState GameState.playerslist Player sayCharge(ID KindItem)}
    end
    
    %Sends to the port of the player fireItem
    %ID and Mine are binds as follow :
    %ID::=<id> the id of the player who fired the item
    %KindFire ::= <fireitem>
    proc{FireItem Player GameState GUI}
       ID KindFire in
       {Send Player.port fireItem(?ID ?KindFire)}
       {Wait ID}
       {Wait KindFire}
       if {Label KindFire}==missile then
	  {BroadCastMessage GUI GameState GameState.playerslist Player sayMissileExplode(ID KindFire.1)}
       elseif {Label KindFire}==mine then
	  {Send GUI putMine(ID KindFire.1)} %Sends to GUI to draw a mine at the position KindFire.1 because of mine(<Position>)
       elseif KindFire==sonar then
	  {BroadCastMessage GUI GameState GameState.playerslist Player sayPassingSonar()}
       elseif {Label KindFire}==drone then
	  {BroadCastMessage GUI GameState GameState.playerslist Player sayPassingDrone(KindFire)}
       end
       skip
    end

    %Sends to the port of the player fireMine
    %ID and Mine are binds as follow :
    %ID::=<id> the id of the player who exploded the mine
    %Mine ::= mine(<Position>)
    %If the player has a mine, the mine explodes
    proc{MineExplode Player GameState GUI}
       ID Mine in 
       {Send Player.port fireMine(?ID ?Mine)}
       {Wait ID}
       {Wait Mine}
       if Mine\=null then
	  {BroadCastMessage GUI GameState GameState.playerslist Player sayMineExplode(ID Mine)}
	  {Send GUI removeMine(ID Mine)} %GUI removes the mine at the position Mine.1
       end
       skip
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

    %Updates the list of player if one player is dead. Used for the turn by turn mode 
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

    %If Input.isTurnByTurn is true, then the procedure LaunchTurnByTur is called
    %Check if there is more than one player (if not, the game is finished) and then the player can play
    proc{LaunchTurnByTurn Players GameState GUI}
       if GameState.alive==1 then {Print 'VICTORY'} skip %it is the end of the game
       else
	  case Players of nil then {LaunchTurnByTurn GameState.playerslist GameState GUI}
	  [] H|T then
	     Answer1 Answer2 GS1 GS2 in
	     {Print '#########################################################'}
	     {Delay 200}
	     {Send H.port isDead(?Answer1)}
	     {Wait Answer1}
	     if Answer1==true then %Step one of the loop. Check if the player is dead.
		GS1={UpdateListOfPlayers H GameState} % GameState is updated with the player H removed of playerslist because player H is dead
		{LaunchTurnByTurn T GS1 GUI} %it is the turn of the next player 
	     else
		if {CanMove H}==false then%Step one of the loop. Check if the player can move, if he cannot, GS1 is the udated version of GameState for the next loop with turnToWait-1
		   GS1={UpdateTtw H GameState}
		   {LaunchTurnByTurn T GS1 GUI}

		else
		   {Send H.port dive} %If he can move, the player dives
		   GS1={Move H GameState GUI} %Step two of the loop. The player moves and GS2 is a new version updated of GameState
		   {ChargeItem H GS1 GUI} %Step three
		   {FireItem H GS1 GUI} %Step four
		   {Send H.port isDead(?Answer2)}
		   {Wait Answer2}
		   if Answer2==true then %if the player is dead because of his own missile
		      GS2={UpdateListOfPlayers H GameState} % GameState is updated with the player H removed of playerslist because player H is dead
		      {LaunchTurnByTurn T GS2 GUI} %it is the turn of the next player
		   else
		      {MineExplode H GS1 GUI} %Step five if the player is not dead
		      {LaunchTurnByTurn T GS1 GUI}
		   end
		end
	     end
	  end
       end
    end
    
   proc {LaunchSimultaneous Players GameState GUI DeadPort}
      proc {Turn Player}
	 Number  GS1 Answer  in
	 {Print '#########################################################'}
	 {Send Player.port isDead(?Answer)}
	 {Wait Answer}
	 if Answer==true then skip
	 else
	    {Send DeadPort alive(?Number)}
	    {Wait Number}
	    if Number==1 then
	       {Print 'VICTOIRE'}
	       skip
	    else
	       {Send Player.port dive}
	       {SimulateThinking}
	       GS1={Move Player GameState GUI}
	       if(Player.turnToWait==Input.turnSurface) then
		  NewPlayer in
		  {Delay Input.turnSurface}
		  NewPlayer = {AdjoinList Player [turnToWait#0]}
		  {Turn NewPlayer}
	       else
		  {SimulateThinking}
		  {ChargeItem Player GS1 GUI}
		  {SimulateThinking}
		  {FireItem Player GS1 GUI}
		  if Answer==true then
		     if Number==1 then
			{Print 'LES DERNIERS JOUEURS SONT MORTS EN MEME TEMPS'}
			skip
		     else
			skip
		     end
		  else
		     {SimulateThinking}
		     {MineExplode Player GS1 GUI}
		     {Turn Player}
		  end
	       end
	    end
	 end
      end
   in
      {List.forAll Players (proc {$ Player} thread {Turn Player} end end) }
   end

    %Send Say to all players
    proc{BroadCastMessage GUI_port GameState PlayersList Player Say}
       Message ID Answer in
       case Say
       of sayMineExplode(ID Position) then
	  case PlayersList of nil then skip
	  [] H|T then
	     Ans in
	     {Send H.port isDead(?Ans)}
	     if Ans==true then
		{BroadCastMessage GUI_port GameState T Player Say}
	     else
		{Send H.port sayMineExplode(ID Position ?Message)} 
		{Wait Message}
		if (Message \= null) then								
		   case Message of sayDamageTaken(ID Damage Life) then
		      {Send GUI_port lifeUpdate(ID Life)}
		      {BroadCastMessage GUI_port GameState GameState.playerslist Player sayDamageTaken(ID Damage Life)} % Broadcast
		      {BroadCastMessage GUI_port GameState T Player Say}
		   [] sayDeath(ID) then
		      {Print 'Un joueur est mort a cause dune mine'}
		      if Input.isTurnByTurn==false then
			 {Send DeadPort dead(ID)}
		      end
		      {Send GUI_port removePlayer(ID)}
		      {BroadCastMessage GUI_port GameState GameState.playerslist Player sayDeath(ID)} % Broadcast
		      {BroadCastMessage GUI_port GameState T Player Say}
		   end
		else
		   {BroadCastMessage GUI_port GameState T Player Say}
		end
	     end
	  end
       [] sayMissileExplode(ID Position) then
	  case PlayersList of nil then skip
	  [] H|T then
	     Ans in
	     {Send H.port isDead(?Ans)}
	     if Ans==true then
		{BroadCastMessage GUI_port GameState T Player Say}
	     else
		{Send H.port sayMissileExplode(ID Position ?Message)} 
		{Wait Message}
		if (Message \= null) then								
		   case Message 
		   of sayDamageTaken(ID Damage Life) then
		      {Send GUI_port lifeUpdate(ID Life)}
		      {BroadCastMessage GUI_port GameState GameState.playerslist Player sayDamageTaken(ID Damage Life)} % Broadcast
		      {BroadCastMessage GUI_port GameState T Player Say}
		   [] sayDeath(ID) then
		      {Print 'Un joueur est mort a cause dun missile'}
		      if Input.isTurnByTurn==false then
			 {Send DeadPort dead(ID)}
		      end
		      {Send GUI_port removePlayer(ID)}
		      {BroadCastMessage GUI_port GameState GameState.playerslist Player sayDeath(ID)} % Broadcast
		      {BroadCastMessage GUI_port GameState T Player Say}
		   end
		else
		   {BroadCastMessage GUI_port GameState T Player Say}
		end
	     end
	  end
       [] sayPassingSonar() then
	  case PlayersList of nil then skip
	  [] H|T then
	     Ans in
	     {Send H.port isDead(?Ans)}
	     if Ans==true then
		{BroadCastMessage GUI_port GameState T Player Say}
	     else
		{Send H.port sayPassingSonar(?ID ?Answer)}
		{Wait ID}
		{Wait Answer}
		{Send Player.port sayAnswerSonar(ID Answer)}
		{BroadCastMessage GUI_port GameState T Player Say}
	     end
	  end
       [] sayPassingDrone(Drone) then
	   case PlayersList of nil then skip
	   [] H|T then
	      Ans in
	      {Send H.port isDead(?Ans)}
	      if Ans==true then
		 {BroadCastMessage GUI_port GameState T Player Say}
	      else
		 {Send H.port sayPassingDrone(Drone ?ID ?Answer)}
		 {Wait ID}
		 {Wait Answer}
		 {Send Player.port sayAnswerDrone(Drone ID Answer)}
		 {BroadCastMessage GUI_port GameState T Player Say}
	      end
	   end
       else
	  case PlayersList of nil then skip
	  [] H|T then
	     {Send H.port Say}
	     {BroadCastMessage GUI_port GameState T Player Say}
	  end
       end							
    end
    
    %Places each player on a random position before the game starts.
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
    {Print 'Creation des joueurs '}

    %Ask players to choose an initial position and send to GUI
    {InitialPosition RecordPlayers GUI_Port}
    {Print 'Position initiale'}
    
    %Creation de l'etat de la partie
    GameState={CreateGameState RecordPlayers}
    {Print 'Creation du GameState'}

    %Creates DeadPort which receives information about a new dead player (dead) and the number of players still alive(?Answer))
    %It is only used for simultaneous mode
    %Returns DeadPort
    fun{StartDeadPort}
       DeadStream
       DeadPort
    in
       {NewPort DeadStream DeadPort}
       thread {TreatStream DeadStream Input.nbPlayer nil} end
       DeadPort
    end

    %Treat the stream receives on the port DeadPort
    proc{TreatStream DeadStream NbPlayers DeadList}
       case DeadStream
       of dead(ID)|T then
	  NewDeadList in
	  NewDeadList={GenerateDeadList ID DeadList}
	  if NewDeadList==nil then
	     {TreatStream T NbPlayers DeadList}
	  else
	     {TreatStream T NbPlayers-1 NewDeadList}
	  end
       [] alive(Number)|T then
	  Number=NbPlayers
	  {TreatStream T NbPlayers DeadList} 
       else
	  {TreatStream DeadStream NbPlayers DeadList}
       end
    end

    %Check if the player with his ID is already dead
    %If not, it adds the ID of the player to the list DeadList and returns the new DeadList
    %Otherwise, it returns nil
    fun{GenerateDeadList ID DeadList}
       case DeadList of nil then ID|DeadList
       [] H|T then
	  if H==ID then nil
	  else {GenerateDeadList ID T}
	  end
       end
    end
       
   {Delay 3000}
    %Game launch 
    if(Input.isTurnByTurn) then
       {LaunchTurnByTurn RecordPlayers GameState GUI_Port}
    else
      DeadPort={StartDeadPort}
       {LaunchSimultaneous RecordPlayers GameState GUI_Port DeadPort}
    end
end