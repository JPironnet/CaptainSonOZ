%Main.Oz
functor
import
    GUI
    Input
    PlayerManager
   OS
define
   /* Variables declaration*/
   GUI_Port
   RecordPlayers
   GameState
   
   %Specific for simultaneous mode
   DeadPort
   
   

   /* Functions and procedures declaration*/
   GeneratePlayers
   CreateGameState
   InitialPosition
   BroadCastMessage
   Move
   ChargeItem
   FireItem
   MineExplode

   %Specific for turn by turn mode 
   CanMove
   UpdateTtw
   UpdateListOfPlayers
   CreateNewList
   RemoveList
   LaunchTurnByTurn

   %Specifif for simultaneous mode 
   SimulateThinking
   StartDeadPort
   TreatDeadStream
   LaunchSimultaneous
   
   
in
   
   /*Descriptions of procedures and functions for both game modes*/
    
   %Function to generate players at the beginning of the game
   %Returns a list of records with label player and two fields (port, turnToWait)
   fun {GeneratePlayers}
      fun {GP Players Colors Number}
	 if Number > Input.nbPlayer then nil %There is no more player in Players
	 else 
	    case Players#Colors of (H|T)#(X|Xr) then 
	       player(port:{PlayerManager.playerGenerator H X Number} turnToWait:0)|{GP T Xr Number+1} %Creation of the list of players
	    end
	 end
      end
   in
      {GP Input.players Input.colors 1} %Players and Colors are the ones specified in Input.oz and Number is initialized to 1
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
    

     %Function to place each player on a random position before the game starts.
    proc{InitialPosition RecordPlayers GUI}
       ID
       Position
    in
       case RecordPlayers of nil then skip
       [] H|T then
	  {Send H.port dive}
	  {Send H.port initPosition(?ID ?Position)} %ask the player to choose a position
	  {Wait ID}
	  {Wait Position}
	  {Send GUI initPlayer(ID Position)} %send the position to the GUI
	  {InitialPosition T GUI}
       end
    end
    
   
   %Send a message Say to all players
    proc{BroadCastMessage GUI_port GameState PlayersList Player Say}
   Message ID Answer in
   case Say
   of sayMineExplode(ID Position) then %if the message is sayMineExplode
      case PlayersList of nil then skip
      [] H|T then
	 Ans in
	 {Send H.port isDead(?Ans)}
	 if Ans==true then %checks if the player is alive
	    {BroadCastMessage GUI_port GameState T Player Say} %recursive call
	 else
	    {Send H.port sayMineExplode(ID Position ?Message)} %ask the players their reaction to the message
	    {Wait Message}
	    if (Message \= null) then %if the player answers with a certain message 
	       case Message of sayDamageTaken(ID Damage Life) then %if the player has taken damges
		  {Send GUI_port lifeUpdate(ID Life)} %update the life of the player on the GUI
		  {BroadCastMessage GUI_port GameState GameState.playerslist Player sayDamageTaken(ID Damage Life)} %broadcast the damages taken
		  {BroadCastMessage GUI_port GameState T Player Say} %recursive call
	       [] sayDeath(ID) then %if the player died 
		  if Input.isTurnByTurn==false then %if it's in simultaneous, send the information to DeadPort
		     {Send DeadPort dead(ID)} 
		  end
		  {Send GUI_port removePlayer(ID)} %remove the player from the GUI
		  {BroadCastMessage GUI_port GameState GameState.playerslist Player sayDeath(ID)} %broadcast the death
		  {BroadCastMessage GUI_port GameState T Player Say} %recursive call
	       end
	    else
	       {BroadCastMessage GUI_port GameState T Player Say} %recursive call
	    end
	 end
      end
   [] sayMissileExplode(ID Position) then %if the message is sayMissileExplode
      case PlayersList of nil then skip
      [] H|T then
	 Ans in
	 {Send H.port isDead(?Ans)} %checks if the player is alive
	 if Ans==true then
	    {BroadCastMessage GUI_port GameState T Player Say} %recursive call
	 else
	    {Send H.port sayMissileExplode(ID Position ?Message)} %ask the players their reaction to the message
	    {Wait Message}
	    if (Message \= null) then %if the player answers with a certain message								
	       case Message 
	       of sayDamageTaken(ID Damage Life) then %if the player has taken damages
		  {Send GUI_port lifeUpdate(ID Life)} %update the life of the player on the GUI
		  {BroadCastMessage GUI_port GameState GameState.playerslist Player sayDamageTaken(ID Damage Life)} %broadcast the damages taken
		  {BroadCastMessage GUI_port GameState T Player Say} %recursive call
	       [] sayDeath(ID) then %if the player died
		  if Input.isTurnByTurn==false then %if it's in simultaneous, send the information to DeadPort
		     {Send DeadPort dead(ID)}
		  end
		  {Send GUI_port removePlayer(ID)} %removes the player from the GUI
		  {BroadCastMessage GUI_port GameState GameState.playerslist Player sayDeath(ID)} %broadcast the death
		  {BroadCastMessage GUI_port GameState T Player Say} %recursive call
	       end
	    else
	       {BroadCastMessage GUI_port GameState T Player Say} %recursive call
	    end
	 end
      end
   [] sayPassingSonar() then
      case PlayersList of nil then skip
      [] H|T then
	 Ans in
	 {Send H.port isDead(?Ans)} %checks if the player is alive
	 if Ans==true then
	    {BroadCastMessage GUI_port GameState T Player Say} %recursive call
	 else
	    {Send H.port sayPassingSonar(?ID ?Answer)} %ask the players their reaction to the message
	    {Wait ID}
	    {Wait Answer}
	    {Send Player.port sayAnswerSonar(ID Answer)} %send the answer of the sonar to the player
	    {BroadCastMessage GUI_port GameState T Player Say} %recursive call
	 end
      end
   [] sayPassingDrone(Drone) then
      case PlayersList of nil then skip
      [] H|T then
	 Ans in
	 {Send H.port isDead(?Ans)} %checks if the player is stil alive
	 if Ans==true then
	    {BroadCastMessage GUI_port GameState T Player Say} %recursive call
	 else
	    {Send H.port sayPassingDrone(Drone ?ID ?Answer)} %ask the players their reaction to the message
	    {Wait ID}
	    {Wait Answer}
	    {Send Player.port sayAnswerDrone(Drone ID Answer)} %send the answer of the drone to the player
	    {BroadCastMessage GUI_port GameState T Player Say} %recursive call
	 end
      end
   else
      case PlayersList of nil then skip
      [] H|T then
	 {Send H.port Say} %send the message
	 {BroadCastMessage GUI_port GameState T Player Say} %recursive call
      end
   end							
end


    %Sends to the port of the player the message move
    %ID Position and Direction are binds
    %Check if Direction is Surface or not and sends to GUI some informations
    %Return the new state of the game
   fun{Move Player GameState GUI}
      ID Position Direction NewGameState in
      {Send Player.port move(?ID ?Position ?Direction)} %ask the player where he wants to move
      {Wait ID} {Wait Position} {Wait Direction}
      {BroadCastMessage GUI  GameState GameState.playerslist Player sayMove(ID Direction)} %broadcast the direction of the player
      if Direction=='Surface' then %if the player wants to go surface 
	      NewPlayer NewList in
	      {Send GUI surface(ID)} %the submarine has made surface on the GUI
	      NewPlayer={AdjoinList Player [turnToWait#Input.turnSurface]} %update of the player.turnToWait and GameState
	      NewList={CreateNewList NewPlayer GameState.playerslist}
	      NewGameState={AdjoinList GameState [playerslist#NewList]}
	      NewGameState
      else
	      {Send GUI movePlayer(ID Position)} %the submarine has moved on the GUI
	      NewGameState=GameState
	      NewGameState
      end
    end


     %Send to the port of the player the message chargeItem
    %ID and Item are binds as follow :
    %Id::=<id>
    %Item::=null|mine|missile|sonar|drone
    proc{ChargeItem Player GameState GUI}
       ID KindItem in
       {Send Player.port chargeItem(?ID ?KindItem)} %ask the player what kind of item he wants to charge
       {Wait ID}
       {Wait KindItem}
       {BroadCastMessage GUI GameState GameState.playerslist Player sayCharge(ID KindItem)} %broadcast the charge 
    end

   
   %Sends to the port of the player fireItem
    %ID and Mine are binds as follow :
    %ID::=<id> the id of the player who fired the item
    %KindFire ::= <fireitem>
    proc{FireItem Player GameState GUI}
       ID KindFire in
       {Send Player.port fireItem(?ID ?KindFire)} %ask the player what kind of item he wants to fire 
       {Wait ID}
       {Wait KindFire}
       if {Label KindFire}==missile then %if it's a missile
	  {BroadCastMessage GUI GameState GameState.playerslist Player sayMissileExplode(ID KindFire.1)} %broadcast the explosion
       elseif {Label KindFire}==mine then %if it's a mine
	  {Send GUI putMine(ID KindFire.1)} %Sends to GUI to draw a mine at the position KindFire.1 because of mine(<Position>)
       elseif KindFire==sonar then %if it's a sonar
	  {BroadCastMessage GUI GameState GameState.playerslist Player sayPassingSonar()} %broadcast the passing sonar
       elseif {Label KindFire}==drone then %if it's a drone
	  {BroadCastMessage GUI GameState GameState.playerslist Player sayPassingDrone(KindFire)} %broadcast the passing drone
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
       {Send Player.port fireMine(?ID ?Mine)} %ask the player if he wants to explode a mine 
       {Wait ID}
       {Wait Mine}
       if Mine\=null then 
	  {BroadCastMessage GUI GameState GameState.playerslist Player sayMineExplode(ID Mine)} %broadcast the explose 
	  {Send GUI removeMine(ID Mine)} %GUI removes the mine at the position Mine.1
       end
       skip
    end


    /*Descriptions of procedures and functions specific to turn by turn mode */


    %Check if the player can move
    %Returns true if he can, false otherwise
    fun{CanMove Player}
       if Player.turnToWait==0 then %if its his turn to play
         true 
       else 
         false
       end
    end

    %Function that updates the turnToWait of the player, and then updates the playerslist of GameState
    %Thanks to this function, the player is updated for the next round with turnToWait smaller 
    %Returns NewGameState
    fun{UpdateTtw Player GameState}
       NewPlayer
       NewList
       NewGameState in
       NewPlayer={AdjoinList Player [turnToWait#Player.turnToWait-1]}
       NewList={CreateNewList NewPlayer GameState.playerslist}
       NewGameState={AdjoinList GameState [playerslist#NewList]}
       NewGameState
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

   %Launches the game in turn by turn mode
    %Check if there is more than one player (if not, the game is finished) and then the player can play
    proc{LaunchTurnByTurn Players GameState GUI}
       if GameState.alive==1 then skip %it is the end of the game
       else
	  case Players of nil then {LaunchTurnByTurn GameState.playerslist GameState GUI}
	  [] H|T then
	     Answer1 Answer2 GS1 GS2 in
	     {Send H.port isDead(?Answer1)} %ask the player if he is dead 
	     {Wait Answer1}
	     if Answer1==true then %Step one of the loop. Check if the player is dead.
		GS1={UpdateListOfPlayers H GameState} % GameState is updated with the player H removed of playerslist because player H is dead
		{LaunchTurnByTurn T GS1 GUI} %it is the turn of the next player 
	     else
		if {CanMove H}==false then%Step one of the loop. Check if the player can move, if he cannot, GS1 is the updated version of GameState for the next loop with turnToWait-1
		   GS1={UpdateTtw H GameState}
		   {LaunchTurnByTurn T GS1 GUI} %it is the turn of the next player
		else
		   {Send H.port dive} %If he can move, the player dives
		   GS1={Move H GameState GUI} %Step two of the loop. The player moves and GS2 is a new version updated of GameState
		   {ChargeItem H GS1 GUI} %Step three
		   {FireItem H GS1 GUI} %Step four
		   {Send H.port isDead(?Answer2)} %ask the player if he is dead
		   {Wait Answer2}
		   if Answer2==true then %if the player is dead because of his own missile
		      GS2={UpdateListOfPlayers H GameState} % GameState is updated with the player H removed of playerslist because player H is dead
		      {LaunchTurnByTurn T GS2 GUI} %it is the turn of the next player
		   else
		      {MineExplode H GS1 GUI} %Step five if the player is not dead
		      {LaunchTurnByTurn T GS1 GUI} %it is the turn of the next player
		   end
		end
	     end
	  end
       end
    end


   /*Description of procedures and functions specific to simultaneous mode */
    
   %Simulates the thinking time of a player before his actions
    proc {SimulateThinking}
        {Delay ({OS.rand} mod (Input.thinkMax-Input.thinkMin+1))+Input.thinkMin}
    end

   %Launches the game in simultaneous mode 
     proc {LaunchSimultaneous Players GameState GUI DeadPort}
      proc {Turn Player} %Launch the turn of a player 
	 GS1 Answer Number Answer2 Number2 in
	 {Send Player.port isDead(?Answer)} %ask the player if he is dead
	 {Wait Answer}
	 if Answer==true then skip
	 else
	    {Send DeadPort alive(?Number)} %ask how many players are still alive
	    {Wait Number}
	    if Number==1 then %if the game is finished with 1 player alive
	       skip
	    else
	       {Send Player.port dive}
	       {SimulateThinking}
	       GS1={Move Player GameState GUI} %the player can move
	       if(Player.turnToWait==Input.turnSurface) then %if the direction chose is surface
		  NewPlayer in
		  {Delay Input.turnSurface} %the player has to wait
		  NewPlayer = {AdjoinList Player [turnToWait#0]}
		  {Turn NewPlayer} %recursive call
	       else
		  {SimulateThinking}
		  {ChargeItem Player GS1 GUI} %the player can charge an item
		  {SimulateThinking}
		  {FireItem Player GS1 GUI} %the player can fire an item
		  {Send Player.port isDead(?Answer2)} %ask the player if he is dead 
		  {Wait Answer2}
		  if Answer2==true then skip 
		  else
		     {SimulateThinking}
		     {MineExplode Player GS1 GUI} %the player can explode a mine
		     {Turn Player} %recursive call
		  end
	       end
	    end
	 end
      end
   in
      {List.forAll Players (proc {$ Player} thread {Turn Player} end end) } %create a thread for every players to play their turns 
   end


    %Creates DeadPort which receives information about a new dead player (dead) and the number of players still alive(?Answer))
    %Returns DeadPort
    fun{StartDeadPort}
       DeadStream
       DeadPort
    in
       {NewPort DeadStream DeadPort}
       thread {TreatDeadStream DeadStream Input.nbPlayer} end
       DeadPort
    end
    
   %Treat the stream received on the port DeadPort
    proc{TreatDeadStream DeadStream NbPlayers}
       case DeadStream
       of dead(ID)|T then %if the message is dead, decrement the number of players alive
	  {TreatDeadStream T NbPlayers-1}
       [] alive(Number)|T then %if the message is alive, answer with the number of players alive 
	  Number=NbPlayers
	  {TreatDeadStream T NbPlayers} 
       else
	  {TreatDeadStream DeadStream NbPlayers}
       end
    end

    
   
   /*Execution of the game controller */
   

    %GUI launch
    GUI_Port = {GUI.portWindow}
    {Send GUI_Port buildWindow}

    %Creations of players 
    RecordPlayers = {GeneratePlayers}

    %Ask players to choose an initial position and send to GUI
    {InitialPosition RecordPlayers GUI_Port}

    %Creation de l'etat de la partie
    GameState={CreateGameState RecordPlayers}

    %Game launch depending on the mode
    if(Input.isTurnByTurn) then
       {LaunchTurnByTurn RecordPlayers GameState GUI_Port}
    else
      DeadPort={StartDeadPort} %creation of the port specific to simultaneous mode
       {LaunchSimultaneous RecordPlayers GameState GUI_Port DeadPort}
    end
end