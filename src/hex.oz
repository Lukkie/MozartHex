functor
import
  Application(exit:Exit)
  System
  OS
  Browser(browse:Browse)
define
/** 11 by 11 board
                      RED
     (x, y):    (0,0) (1,0) (2,0) ...
              BLUE (0,1) (1,1) (2,1) ...
                      (0,2) (1,2) (2,2) ...
                         ...   ...   ...
    Blue direction: X
    Red direction: Y

**/
  BOARD_SIZE = 11
  {OS.srand 0}



  /** Functor Referee **/
  fun {AndThen BP1 BP2}
    if BP1 then BP2
    else false end
  end

  fun {IsNeighbour Move1 Move2}
    case Move1 of move(x:X1 y:Y1 color:C1) then
      case Move2 of move(x:X2 y:Y2 color:C2) then
        if C1 == C2 then
          if {Number.abs X1-X2} + {Number.abs Y1-Y2} < 2 then true
          elseif {AndThen X1-X2==1 Y2-Y1==1} then true
          elseif {AndThen X2-X1==1 Y1-Y2==1} then true
          else false end
        else false end
      end
    end
  end

  proc {MoveBelongsToSet Move Set ?IsInSet}
    case Set of SetMove|Sr then

      if {IsNeighbour Move SetMove} then
        IsInSet = true
      else
        {MoveBelongsToSet Move Sr ?IsInSet}
      end
      /* case Move of move(x:XValue1 y:YValue1 color:_) then
        case SetMove of move(x:XValue2 y:YValue2 color:_) then
          if {Number.abs XValue1-XValue2} + {Number.abs YValue1-YValue2} < 2 then
            IsInSet = true
          else
            {MoveBelongsToSet Move Sr ?IsInSet}
          end
        end
      end */
    [] nil then
      IsInSet = false
    end
  end

  proc {AddMoveToDisjointSets Move RemainingSetsToCheck CurrentMoveSet UnmodifiedSets ?DisjointSets}
    /**
      Move: Move to add to the disjoint sets
      RemainingSetsToCheck: Sets of which to check whether move belongs in it
      CurrentMoveSet: Accumulator to keep track of the set in which the Move will eventually belong. INITIALIZE TO Move|nil !
      UnmodifiedSets: Accumulator to keep track of all the sets that remain unchanged

      ?DisjointSets: List of disjoint sets (which are lists as well)
    **/
    case RemainingSetsToCheck of Set|Sr then
      local InSet in
        % Check if move belongs in set
        {MoveBelongsToSet Move Set InSet}

        if InSet then
          % If so, append Set to CurrentMoveSet
          {AddMoveToDisjointSets Move Sr {List.flatten Set|CurrentMoveSet} UnmodifiedSets DisjointSets}
        else
          % If not, add Set to UnmodifiedSets
          {AddMoveToDisjointSets Move Sr CurrentMoveSet Set|UnmodifiedSets DisjointSets}
        end
      end
    [] nil then
      DisjointSets = CurrentMoveSet | UnmodifiedSets
    end
  end

  proc {MoveExists MoveList Move ?Exists}
    /** Checks if a tile was already placed where the new move wants to place a tile
      MoveList: a list of moves (excl. Move)
      Move: The move fopr which to check for duplicates
    **/
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

  /* proc {CheckSetVictory Set StartPresent EndPresent ?Victory}
    case Set of Move|Sr then
      case Move of move(x:X y:Y color:Color) then
        if Color = 'Blue' then
          if X == 0 then
            if (EndPresent == true) Victory = true
            else {CheckSetVictory Sr true EndPresent Victory}
            end
          elseif X == BOARD_SIZE-1 then
            if (StartPresent == true) Victory = true
            else {CheckSetVictory Sr StartPresent true Victory}
            end
          else
            {CheckSetVictory Sr StartPresent EndPresent Victory}
          end
        else
          if Y == 0 then
            if (EndPresent == true) Victory = true
            else {CheckSetVictory Sr true EndPresent Victory}
            end
          elseif Y == BOARD_SIZE-1 then
            if (StartPresent == true) Victory = true
            else {CheckSetVictory Sr StartPresent true Victory}
            end
          else
            {CheckSetVictory Sr StartPresent EndPresent Victory}
          end
        end
      end
    [] nil then
      Victory = false
    end */

  proc {CheckSetVictory Set StartPresent EndPresent ?Victory}
    if {AndThen StartPresent EndPresent} then Victory = true
    else
      case Set of Move|Sr then
        case Move of move(x:X y:Y color:Color) then
          if Color == 'Blue' then
            {CheckSetVictory Sr X==0 X==BOARD_SIZE-1 Victory}
          else % Color = 'Red'
            {CheckSetVictory Sr Y==0 Y==BOARD_SIZE-1 Victory}
          end
        end
      [] nil then
        Victory = false
      end
    end
  end

  proc {DetermineWinner DisjointSets ?Winner}
    case DisjointSets of Set|DSr then
      % Check if set has point at start and at end
      local Victory in
        {CheckSetVictory Set false false Victory}
        if Victory == false then
          { DetermineWinner DSr Winner }
        else
          Winner = true
        end
      end
    [] nil then Winner = false
    end
  end

  proc {PlayGame Board DisjointSets CurrentPlayerColor CurrentPlayerPort NextPlayerColor NextPlayerPort ?FinalBoard ?Winner}
    /**
      Board: List of move(x y color)  (will be sent to user)
      DisjointSets: List of disjoint sets (same info as Board, but a little more complex)
      CurrentPlayerColor: Color of player that has turn
      CurrentPlayerPort: Port of player that has turn
      NextPlayerColor: Color of player that will have turn after this player
      NextPlayerPort: Port of player that will have turn after this player
      ?FinalBoard: Return the final state of the board, i.e. list of moves
      ?Winner: Return the color of the Winner
    **/
    % Ask next player for move
    local Move InvalidMove NewDisjointSets LocalWinner in
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
          % Check if any user has won the game
          {AddMoveToDisjointSets Move DisjointSets Move|nil nil NewDisjointSets}
          /* {Browse NewDisjointSets} */

          {DetermineWinner NewDisjointSets ?LocalWinner}
          if LocalWinner == false then
            {PlayGame Move|Board NewDisjointSets NextPlayerColor NextPlayerPort CurrentPlayerColor CurrentPlayerPort ?FinalBoard ?Winner}
          else
            Winner = CurrentPlayerColor
            FinalBoard = Board
          end
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
          {PlayGame nil nil 'Red' Player1 'Blue' Player2 FinalBoard Winner}
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



  /* {Delay 500}
  { Exit 0 } */

end
