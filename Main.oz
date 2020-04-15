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
   FireMissileOrMine
   SendMessage
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
	    case Players#Colors of (H|T)#(X|Xr) then player(port:{PlayerManager.playerGenerator H X Number} turnToWait:0)|{GP T Xr Number+1}
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
<<<<<<< HEAD
   fun{Move Player GameState GUI}
      ID Position Direction NewGameState in
      {Send Player.port move(?ID ?Position ?Direction)}
      {Wait ID} {Wait Position} {Wait Direction}
      if Direction=='Surface' then
	      NewPlayer NewList in
	      {Send GUI surface(ID)} %the submarine has made surface
	      NewPlayer={AdjoinList Player turnToWait#Input.turnSurface}
	      NewList={CreateNewList NewPlayer GameState.playerslist}
	      NewGameState={AdjoinList GameState [playerslist#NewList]}
	      NewGameState
      else
	      {Send GUI movePlayer(ID Position)} %the submarine moves
	      NewGameState=GameState
	      NewGameState
      end
   end
=======
    fun{Move Player GameState GUI}
       ID Position Direction NewGameState in
       {Send Player.port move(?ID ?Position ?Direction)}
       {Wait ID} {Wait Position} {Wait Direction}
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
>>>>>>> master

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

    fun{SendMessage Player ID KindFire}
       Message in
       if {Record.label KindFire}==missile then
	  {Send Player.port sayMissileExplode(ID KindFire.1 ?Message)} %Send to the port of the player sayMissileExplode with the ID of the player, with Position KindFire.1
	  {Wait Message}
	  Message
       else
	  {Send Player.port sayMineExplode(ID KindFire.1 ?Message)}
	  {Wait Message}
	  Message
       end
    end
    
    %Sends sayMissileExplode or sayMineExplode and waits until Message is bind.
    %Message ::= message(id:<id> damage:0|1|2 lifeleft:<life>)
    %Returns the new state of the game
    fun{FireMissileOrMine ID KindFire PlayersList GameState GUI}
       Message in
       case PlayersList of nil then GameState
       [] H|T then
	  {Print 'Je suis dans FireMissileOrMine de Main.oz'}
	  Message={SendMessage H ID KindFire}
	  {Print 'Jai recu le message dans FireMissileOrMine dans Main.oz'}
	  if Message.lifeleft==0 then
	     NewGameState in
             %{BroadCastMessage GameState.playerslist sayDeath(Message.id)} 
	     NewGameState={UpdateListOfPlayers H GameState} %removes H of GameState.playerslist because H is dead
	     {Send GUI lifeUpdate(Message.id Message.lifeleft)}
	     {Send GUI removePlayer(Message.id)} 
	     {FireMissileOrMine ID KindFire T NewGameState GUI}
	  else
	     {Print 'Il reste de la vie au joueur'}
	     %{BroadCastMessage GameState.playerslist sayDamageTaken(Message.id Message.damage Message.lifeleft)}
	     {Send GUI lifeUpdate(Message.id Message.lifeleft)}
	     {FireMissileOrMine ID KindFire T GameState GUI}
	  end
       end
    end
       
    %Sends to the port of the player fireItem
    %ID and Mine are binds as follow :
    %ID::=<id> the id of the player who fired the item
    %KindFire ::= <fireitem>
    %If KindFire is a missile, calls the function FireMissileOrMine
    %Returns the new state of the game
<<<<<<< HEAD
   fun{FireItem Player GameState GUI}
      ID KindFire in
      {Send Player.port fireItem(?ID ?KindFire)}
      {Wait ID}
      {Wait KindFire}
      if {Label KindFire}==missile then
	      NewGameState in
	      NewGameState={FireMissileOrMine ID KindFire GameState.playerslist GameState GUI}
	      NewGameState
      else 
      if {Label KindFire}==mine then
	      {Send GUI putMine(ID KindFire.1)} %Sends to GUI to draw a mine at the position KindFire.1 because of mine(<Position>)
	   GameState
      end
   end
   end
=======
    fun{FireItem Player GameState GUI}
       ID KindFire in
       {Send Player.port fireItem(?ID ?KindFire)}
       {Wait ID}
       {Wait KindFire}
       if {Label KindFire}==missile then
	  NewGameState in
	  NewGameState={FireMissileOrMine ID KindFire GameState.playerslist GameState GUI}
	  NewGameState
       elseif {Label KindFire}==mine then
	  {Send GUI putMine(ID KindFire.1)} %Sends to GUI to draw a mine at the position KindFire.1 because of mine(<Position>)
	  GameState
       else
	  GameState
       end
    end
>>>>>>> master

    %Sends to the port of the player fireMine
    %ID and Mine are binds as follow :
    %ID::=<id> the id of the player who exploded the mine
    %Mine ::= mine(<Position>)
    %If the player has a mine, the mine explodes, and calls the function FireMissileOrMine
    %Returns the new state of the game
    fun{MineExplode Player GameState GUI}
       ID Mine NewGameState in 
       {Send Player.port fireMine(?ID ?Mine)}
       {Wait ID}
       {Wait Mine}
       if Mine==null then
	  {Print 'Le joueur n a pas de mine'}
	  NewGameState=GameState
	  NewGameState
       else
	  {Print 'Le joueur a une mine et l explose'}
	  NewGameState={FireMissileOrMine ID Mine GameState.playerslist GameState GUI}
	  {Send GUI removeMine(ID Mine.1)} %GUI removes the mine at the position Mine.1
	  NewGameState
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

<<<<<<< HEAD
   proc{LaunchTurnByTurn Players GameState GUI}
      if GameState.alive==1 then 
         {Print 'Partie finie'}
         skip %it is the end of the game
      
      else
         case Players of nil then {LaunchTurnByTurn GameState.playerslist GameState GUI}
	      [] H|T then
	         Answer GS1 GS2 GS3 GS4 GS5 in
            {Send H.port isDead(?Answer)}
            {Wait Answer}
	         if Answer==1 then %Step one of the loop. Check if the player is dead.
	         GS1={UpdateListOfPlayers H GameState} % GameState is updated with the player H removed of playerslist because player H is dead
		         {LaunchTurnByTurn T GS1 GUI} %it is the turn of the next player 
	         else
		         {Print 'Je suis vivant'}
		         if {CanMove H}==false then %Step one of the loop. Check if the player can move, if he cannot, GS1 is the udated version of GameState for the next loop with turnToWait-1
		            GS1={UpdateTtw H GameState}
		            {Print 'CanMove est false'}
		            {LaunchTurnByTurn T GS1 GUI}
		         else
		            {Print 'CanMove est true'}
		            {Send H.port dive} %If he can move, the player dives BON DU COUP IL VA IDVE A CHAQUE FOIS MM SI IL EST PAS A LA SURFACE AU DEPART
		            GS2={Move H GameState GUI} %Step two of the loop. The player moves and GS2 is a new version updated of GameState
		            {Print 'GS2 est ok, le player a bouge'}
		            GS3={ChargeItem H GS2 GUI} %Step three
		            {Print 'GS3 est ok, le player a charge un item'}
		            GS4={FireItem H GS3 GUI} %Step four
		            GS5={MineExplode H GS4 GUI} %Step five
		            {LaunchTurnByTurn T GS5 GUI}
		         end
	         end
	      end
      end
   end
=======
    proc{LaunchTurnByTurn Players GameState GUI}
       if GameState.alive==1 then skip %it is the end of the game
	   {Print 'Partie finie'}
       else
	  case Players of nil then {LaunchTurnByTurn GameState.playerslist GameState GUI}
	  [] H|T then
	     Answer GS1 GS2 GS3 GS4 GS5 in
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
>>>>>>> master
    

    proc {LaunchSimultaneous Players GameState GUI}
       proc {Turn Player}
	  Answer ID Position Direction Item KindFire Mine GS1 in 
	  if (GameState.firstRound==true) then
	     {Send Player.port dive}
	  end
	  {Send Player.port isDead(?Answer)}
	  {Wait Answer}
	  if (Answer == false) then
	     {SimulateThinking}
	     {Send Player.port move(?ID ?Position ?Direction)}
	     {Wait ID} {Wait Position} {Wait Direction} 
	     if (Direction=='Surface' ) then
		{Delay Input.turnSurface}
		{Send GUI surface(Player.id)}
		{Turn Player}
	     else 
		{Send Player.port isDead(?Answer)}
		{Wait Answer}
		if (Answer == false) then
		   {SimulateThinking}
		   {Send Player.port chargeItem(?ID ?Item)}
		   {Wait ID} {Wait Item}
		                %{Broadcast}
		   {Send Player.port isDead(?Answer)}
		   {Wait Answer}
		   if (Answer == false) then
		      {SimulateThinking}
		      {Send Player.port fireItem(?ID ?KindFire)}
		      {Wait ID} {Wait KindFire}
                            %{Broadcast}
		      {Send Player.port isDead(?Answer)}
		      {Wait Answer}
		      if (Answer == false) then
			 {SimulateThinking}
			 {Send Player.port fireMine(?ID ?Mine)}
			 {Wait ID} {Wait Mine}
                                %{Broadcast}
			 if(GameState.firstRound==true) then
			    GS1={AdjoinList GameState [firstRound#false]}
			 end
			 if(GameState.alive > 1) then %parametre que je pense interessant
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

    %Send Message to all players 
    proc{BroadCastMessage PlayerList Message}
       case PlayerList of nil then skip
       [] H|T then {Send H.port Message}
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
    %Lancement de la partie 
    if(Input.isTurnByTurn) then
       {LaunchTurnByTurn RecordPlayers GameState GUI_Port}
    else 
       {LaunchSimultaneous RecordPlayers GameState GUI_Port}
    end
end