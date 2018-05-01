/**
  TODO: Safely connected
  TODO: Although we assume the opponent will always play in such way that it will stop your victories
          it will not always do this. Maybe don't assume a perfect opponent.
  TODO: Initialize with a great starting position
  TODO: Optimize for larger search depth
*/

functor
import
  Application(exit:Exit getArgs:GetArgs)
  System
  OS
  Browser(browse:Browse)
export
  referee:RefereeProc
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
  DEFAULT_BOARD_SIZE = 11
  BLUE_TAG = 'Blu'
  RED_TAG = 'Red'
  DEFAULT_SEARCH_DEPTH = 3


  local BOARD_SIZE SEARCH_DEPTH DEBUG in

    Args = {GetArgs record('search_depth'(single type:int)
                           'board_size'(single type:int)
                           'debug'(single)
                           'random_opponent'(single)
                           'swap'(single type:int)
                            )}

    if {Value.hasFeature Args 'search_depth'} then
      SEARCH_DEPTH = Args.search_depth
    else
      SEARCH_DEPTH = DEFAULT_SEARCH_DEPTH
    end

    if {Value.hasFeature Args 'board_size'} then
      BOARD_SIZE = Args.board_size
    else
      BOARD_SIZE = DEFAULT_BOARD_SIZE
    end

    if {Value.hasFeature Args 'debug'} then
      DEBUG = true
    else
      DEBUG = false
    end




    /** Functor Referee **/

    fun {GetOtherColor Color}
      if Color == BLUE_TAG then RED_TAG
      else BLUE_TAG end
    end

    proc {PrintBoard Board BoardList}
      if BoardList == nil then
        local NewBoard in
          {List.make BOARD_SIZE NewBoard}
          for I in 1..BOARD_SIZE do
            {List.make BOARD_SIZE {List.nth NewBoard I $}}
          end
          {PrintBoard Board NewBoard}
        end
      else
        case Board of move(x:X y:Y color:C)|Br then
          {List.nth {List.nth BoardList X+1} Y+1} = C
          {PrintBoard Br BoardList}
        [] nil then
          % Generate output
          for Y in 1..BOARD_SIZE do
            for I in 0..Y-1 do
              {System.printInfo '  '}
            end
            for X in 1..BOARD_SIZE do
              local CurrentChar in
                CurrentChar = {List.nth {List.nth BoardList X} Y}
                /* {Browse CurrentChar} */
                if {Value.isFree CurrentChar} then
                  {System.printInfo ' -  '}
                else
                  {System.printInfo CurrentChar # ' '}
                end
              end
            end
            {System.showInfo '\n'}
          end
        end
      end
    end

    fun {IsNeighbour Move1 Move2}
      case Move1 of move(x:X1 y:Y1 color:C1) then
        case Move2 of move(x:X2 y:Y2 color:C2) then
          if C1 == C2 then
            if {Number.abs X1-X2} + {Number.abs Y1-Y2} < 2 then true
            elseif X1-X2==1 andthen Y2-Y1==1 then true
            elseif X2-X1==1 andthen Y1-Y2==1 then true
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
        Move: The move for which to check for duplicates
      **/
      case MoveList of M|Mr then
        case M of move(x:X y:Y color:_) then
          case Move of move(x:NewX y:NewY color:_) then
            if X==NewX andthen Y==NewY then
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

    proc {MoveOutOfBounds Move ?OutOfBounds}
      /** Checks if a tile was already placed where the new move wants to place a tile
        MoveList: a list of moves (excl. Move)
        Move: The move for which to check for duplicates
      **/
      case Move of move(x:X y:Y color:_) then
        if X < 0 orelse X > BOARD_SIZE-1 orelse Y < 0 orelse Y > BOARD_SIZE-1 then
          OutOfBounds = true
        else
          OutOfBounds = false
        end
      end
    end

    proc {CheckSetVictory Set StartPresent EndPresent ?Victory}
      if StartPresent andthen EndPresent then Victory = true
      else
        case Set of move(x:X y:Y color:Color)|Sr then
          if Color == BLUE_TAG then
            {CheckSetVictory Sr StartPresent orelse X==0 EndPresent orelse X==BOARD_SIZE-1 Victory}
          else % Color = 'Red'
            {CheckSetVictory Sr StartPresent orelse Y==0 EndPresent orelse Y==BOARD_SIZE-1 Victory}
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

    proc {PlayGame Board DisjointSets CurrentPlayerColor CurrentPlayerPort NextPlayerColor NextPlayerPort Attempt TurnsUntilSwap ?FinalBoard ?Winner ?Swapped}
      /**
        Board: List of move(x y color)  (will be sent to user)
        DisjointSets: List of disjoint sets (same info as Board, but a little more complex)
        CurrentPlayerColor: Color of player that has turn
        CurrentPlayerPort: Port of player that has turn
        NextPlayerColor: Color of player that will have turn after this player
        NextPlayerPort: Port of player that will have turn after this player
        Attempt: Int stating which attempt the player is on, starting at 0
        TurnsUntilSwap: Selfexplanatory, initialize as -1
        ?FinalBoard: Return the final state of the board, i.e. list of moves
        ?Winner: Return the color of the Winner
        ?Swapped: Returns true if the colors were swapped during the game, false otherwise
      **/
      if TurnsUntilSwap == 0 then
        /** Turns have to be swapped right now **/
        /** This means that ports are swapped, and the following player object can now play (again, but with different color) **/
        {System.showInfo ' ---- COLORS SWAPPED -----'}
        ?Swapped = true
        {PlayGame Board DisjointSets CurrentPlayerColor NextPlayerPort NextPlayerColor CurrentPlayerPort Attempt ~2 ?FinalBoard ?Winner ?Swapped}
      else
        % Ask next player for move
        local Move NewDisjointSets LocalWinner in
          {Send CurrentPlayerPort generateMove(Board CurrentPlayerColor TurnsUntilSwap Move)}
          % Check validity of move
          case Move of move(x:X y:Y color:C) then
            {System.showInfo 'Move at x:' # X # ' y:' # Y # ' color:' # C}
            % Iterate over list to see if x, y combo already exists
            /* {MoveExists Board Move ExistingMove} */
            if {MoveExists Board Move $} orelse {MoveOutOfBounds Move $} then
              if Attempt == 0 then
                {System.showInfo 'Move is invalid, allowing one more try'}
                {PlayGame Board DisjointSets CurrentPlayerColor CurrentPlayerPort NextPlayerColor NextPlayerPort Attempt+1 TurnsUntilSwap ?FinalBoard ?Winner ?Swapped}
              else
                {System.showInfo 'Move is invalid for the second time -- Disqualified.'}
                FinalBoard = Board
                Winner = NextPlayerColor
              end
            else
              % Print Board
              {PrintBoard Move|Board nil}

              % Update Disjoint Sets
              {AddMoveToDisjointSets Move DisjointSets Move|nil nil NewDisjointSets}

              if TurnsUntilSwap == ~1 then /** Only happens when red has played its first move **/
                /* Ask swap information to blue player */
                local NumberOfTurns in
                  {Send NextPlayerPort swapRequest(Move ?NumberOfTurns)}
                  %if NumberOfTurns == 1 then /** Swap immediately **/
                  %  /** Switch colors and set TurnsUntilSwap to -2 **/
                  %  {System.showInfo ' ---- COLORS SWAPPED -----'}
                  %  {PlayGame Move|Board NewDisjointSets CurrentPlayerColor NextPlayerPort NextPlayerColor CurrentPlayerPort 0 ~2 ?FinalBoard ?Winner}
                  % elseif NumberOfTurns > 1 andthen NumberOfTurns < 7 then /** Swap sometime soon **/
                  if NumberOfTurns > 0 andthen NumberOfTurns < 7 then /** Swap sometime soon **/
                    /** Keep colors for now, and set TurnsUntilSwap to NumberOfTurns-1 **/
                    {PlayGame Move|Board NewDisjointSets NextPlayerColor NextPlayerPort CurrentPlayerColor CurrentPlayerPort 0 NumberOfTurns-1 ?FinalBoard ?Winner ?Swapped}
                  else /** NumberOfTurns is negative or very large, in either case, the turn will never be swapped **/
                    /** Keep colors (for ever) and set TurnsUntilSwap to BOARD_SIZE * BOARD_SIZE **/
                    ?Swapped = false
                    {PlayGame Move|Board NewDisjointSets NextPlayerColor NextPlayerPort CurrentPlayerColor CurrentPlayerPort 0 BOARD_SIZE*BOARD_SIZE ?FinalBoard ?Winner ?Swapped}
                  end
                end
              else
                % Check if any user has won the game
                {DetermineWinner NewDisjointSets ?LocalWinner}
                if LocalWinner == false then
                  {PlayGame Move|Board NewDisjointSets NextPlayerColor NextPlayerPort CurrentPlayerColor CurrentPlayerPort 0 TurnsUntilSwap-1 ?FinalBoard ?Winner ?Swapped}
                else
                  /* {Browse NewDisjointSets} */
                  Winner = CurrentPlayerColor
                  FinalBoard = Board
                end
              end
            end

          end
        end
      end
    end

    fun {RefereeProc Player1 Player2}
      Sin in thread
        for Msg in Sin do
          case Msg
          of startGame() then
            local FinalBoard Winner Swapped in
              {PlayGame nil nil RED_TAG Player1 BLUE_TAG Player2 0 ~1 FinalBoard Winner Swapped}
              if Swapped then
                {System.showInfo 'Winner is ' # Winner # ' after having swapped. Starting color was ' # {GetOtherColor Winner}}
              else
                {System.showInfo 'Winner is ' # Winner # ' which was also his original color'}
              end
              { Exit 0 }
            end
          end
        end
      end
      {NewPort Sin}
    end

    /** End of functor Referee **/


  end % End of local variables SEARCH_DEPTH and BOARD_SIZE


end
