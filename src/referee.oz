functor
import
  Application(exit:Exit getArgs:GetArgs)
  System
  /* Browser(browse:Browse) */
  Board(  transformTheirMoveToMine:TransformTheirMoveToMine
          getListOfLists:GetListOfLists
          printBoard:PrintBoard
          addMoveToDisjointSets:AddMoveToDisjointSets
          moveExists:MoveExists
          determineWinner:DetermineWinner
          moveOutOfBounds:MoveOutOfBounds ) at 'board.ozf'
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
  BLUE_TAG = blue
  RED_TAG = red
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
        local TheirBoard GeneratedMove Move NewDisjointSets GameOver LocalWinner in
          % Transform my board representation to theirs
          TheirBoard = {GetListOfLists Board}

          % Ask for move
          {Send CurrentPlayerPort generateMove(TheirBoard CurrentPlayerColor TurnsUntilSwap GeneratedMove)}

          % Transform their move to my representation
          Move = {TransformTheirMoveToMine GeneratedMove}

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
                  {Send NextPlayerPort swapRequest(GeneratedMove ?NumberOfTurns)} % Use GeneratedMove for their representation
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
                {DetermineWinner NewDisjointSets ?GameOver ?LocalWinner}
                if GameOver == false then
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
            local Winner Swapped in
              {PlayGame nil nil RED_TAG Player1 BLUE_TAG Player2 0 ~1 _ Winner Swapped}
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
