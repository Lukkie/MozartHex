% 11 by 11 board
functor
import
  Application(exit:Exit)
  System
  OS
  Browser(browse:Browse)
define
  BOARD_SIZE = 11
  {OS.srand 0}


  /** Functor Referee **/
  fun {AndThen BP1 BP2}
    if BP1 then BP2
    else false end
  end

  proc {MoveExists MoveList Move ?Exists}
    case MoveList of M|Mr then
      case M of move(x:X y:Y color:C) then
        case Move of move(x:NewX y:NewY color:NewC) then
          if {AndThen X==NewX Y==NewY} then
            Exists = true
          else
            {MoveExists Mr Move Exists}
          end
        end
      end
    [] nil then
      Exists = false
    end
  end

  proc {PlayGame Board CurrentPlayerColor CurrentPlayerPort NextPlayerColor NextPlayerPort ?FinalBoard ?Winner}
    /**
      Board: List of move(x: y: color:)
      CurrentPlayerColor: Color of player that has turn
      CurrentPlayerPort: Port of player that has turn
      NextPlayerColor: Color of player that will have turn after this player
      NextPlayerPort: Port of player that will have turn after this player
      ?FinalBoard: Return the final state of the board, i.e. list of moves
      ?Winner: Return the color of the Winner
    **/
    % Ask next player for move
    local Move InvalidMove in
      {Send CurrentPlayerPort generateMove(Board CurrentPlayerColor Move)}
      % Check validity of move
      case Move of move(x:X y:Y color:C) then
        {System.showInfo 'Move at x:' # X # ' y:' # Y # ' color:' # C}
        % Iterate over list to see if x, y combo already exists
        {MoveExists Board Move InvalidMove}
        if InvalidMove == true then
          {System.showInfo 'Move is invalid'}
          FinalBoard = Board
          Winner = NextPlayerColor
        else
          {PlayGame Move|Board NextPlayerColor NextPlayerPort CurrentPlayerColor CurrentPlayerPort ?FinalBoard ?Winner}
        end

      end
    end
    % Assign values of FinalBoard and Winner if game is over
    /* FinalBoard = Board
    Winner = 'Blue' */
  end

  fun {RefereeProc Player1 Player2}
    Sin in thread
      for Msg in Sin do
        case Msg
        of testGame(?Winner) then
          for I in 0..5 do
            {System.showInfo {Send Player2 addNumbers(I I $)}}
            {Delay 500}
          end
          Winner = "Player 1"

        [] startGame(?FinalBoard ?Winner) then
          {PlayGame nil 'Blue' Player1 'Red' Player2 FinalBoard Winner}
        end
      end
    end
    {NewPort Sin}
  end


  /** End of functor Referee **/


  /** Functor Player **/
  fun {PlayerProc}
    Sin in thread
      for Msg in Sin do
        /* {Browse Msg} */
        case Msg of addNumbers(N1 N2 ?Result) then
          Result = N1 + N2
        [] generateMove(MoveList Color Move) then
          % Initial version: Generate random move on position that is not yet occupied
            Move = move(x:{OS.rand} mod BOARD_SIZE y:{OS.rand} mod BOARD_SIZE color:Color)
          skip
        end
      end
    end
    {NewPort Sin}
  end

  /** End of functor Player **/

  /** Main thread **/

  Player1 = {PlayerProc} % Get this from functor
  Player2 = {PlayerProc} % Get this from functor

  % Assume Referee is also a thread
  Referee = {RefereeProc Player1 Player2} % Get this from functor

  /* local Winner in
    {Send Referee testGame(Winner)} % Could also assign players here.
    {System.showInfo "Winner is " # Winner }
  end */

  local FinalBoard Winner in
    {Send Referee startGame(FinalBoard Winner)} % Could also assign players here.
    {System.showInfo "Winner is " # Winner }
    {Browse FinalBoard}
  end

  /* local Move in
    {Send Player1 generateMove(nil 'Blue' Move)}
    {Browse Move}
  end */


  /* {Delay 500}
  { Exit 0 } */

end
