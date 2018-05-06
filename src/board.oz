functor
import
  Application(getArgs:GetArgs)
  System
  /* Browser(browse:Browse) */
export
  transformTheirMoveToMine:TransformTheirMoveToMine
  transformMyMoveToTheirs:TransformMyMoveToTheirs
  transformTheirBoardToMine:TransformTheirBoardToMine
  transformMyBoardToTheirs:TransformMyBoardToTheirs
  getListOfMoves:GetListOfMoves
  getListOfLists:GetListOfLists
  printBoard:PrintBoard
  isNeighbour:IsNeighbour
  moveBelongsToSet:MoveBelongsToSet
  addMoveToDisjointSets:AddMoveToDisjointSets
  moveExists:MoveExists
  checkSetVictory:CheckSetVictory
  determineWinner:DetermineWinner
  moveOutOfBounds:MoveOutOfBounds
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
  NONE_TAG = empty /** Used by others **/
  DEFAULT_SEARCH_DEPTH = 3
  DEFAULT_SWAP_TURN_VALUE = 6


  local BOARD_SIZE SEARCH_DEPTH DEBUG SWAP_TURN_VALUE in

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

    if {Value.hasFeature Args 'swap'} then
      SWAP_TURN_VALUE = Args.swap
    else
      SWAP_TURN_VALUE = DEFAULT_SWAP_TURN_VALUE
    end



    /** Code to transform board and move **/
    fun {TransformTheirMoveToMine TheirMove}
      /* My moves have range between 0 and BOARD_LENGTH - 1
      Other people's moves start at 1 and end at BOARD_LENGTH */
      case TheirMove of move(x:X y:Y color:C) then
        move(x:X-1 y:Y-1 color:C)
      end
    end

    fun {TransformMyMoveToTheirs MyMove}
      /* My moves have range between 0 and BOARD_LENGTH - 1
      Other people's moves start at 1 and end at BOARD_LENGTH */
      case MyMove of move(x:X y:Y color:C) then
        move(x:X+1 y:Y+1 color:C)
      end
    end

    fun {TransformTheirBoardToMine Board}
      case Board of move(x:X y:Y color:C)|BoardRest then
        {TransformTheirMoveToMine move(x:X y:Y color:C)} | {TransformTheirBoardToMine BoardRest}
      [] nil then
        nil
      end
    end

    fun {TransformMyBoardToTheirs Board}
      case Board of move(x:X y:Y color:C)|BoardRest then
        {TransformMyMoveToTheirs move(x:X y:Y color:C)} | {TransformMyBoardToTheirs BoardRest}
      [] nil then
        nil
      end
    end


    /** Old convention, not used anymore, keeping it here just in case **/
    fun {GetListOfMoves Board X Y}
      /* Transform (their) list of lists into (my) list of moves */
      /* Initialize with X = 1 and Y = 1 */
      /* Go over Board step by step, see if position contains something,
      and add this to the list of moves procedurally */
      /* Row-column notation for Y-X */
      local NewX NewY in

        if X == BOARD_SIZE then
          NewX = 1
          NewY = Y+1
        else
          NewX = X+1
          NewY = Y
        end

        if Y == BOARD_SIZE+1 then
          nil
        elseif {List.nth {List.nth Board Y} X} == NONE_TAG then
          {GetListOfMoves Board NewX NewY}
        else
          move(x:X-1 y:Y-1 color:{List.nth {List.nth Board Y} X}) | {GetListOfMoves Board NewX NewY}
        end
      end
    end

    /** Old convention, not used anymore, keeping it here just in case **/
    fun {GetListOfLists BoardList}
      local ListOfLists in
        {List.make BOARD_SIZE ListOfLists}
        for Y in 1..BOARD_SIZE do
          local XList in
            {List.make BOARD_SIZE XList}
            for X in 1..BOARD_SIZE do
              {List.nth XList X} = {DoesBoardListContain BoardList X Y}
            end
            {List.nth ListOfLists Y} = XList
          end
        end
        ListOfLists
      end
    end

    /** Old convention, not used anymore, keeping it here just in case **/
    fun {DoesBoardListContain BoardList X Y}
    /** X and Y are offset by one in my code! **/
      case BoardList of move(x:MoveX y:MoveY color:MoveColor)|BoardListRest then
        if X == MoveX+1 andthen Y == MoveY+1 then
          MoveColor
        else
          {DoesBoardListContain BoardListRest X Y}
        end
      [] nil then
        NONE_TAG
      end
    end

    /** Original code **/
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
                if {Value.isFree CurrentChar} then
                  {System.printInfo ' -  '}
                else
                  {System.printInfo CurrentChar # ' '}
                end
              end
            end
            {System.printInfo '\n'}
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

    proc {CheckSetVictory Set StartPresent EndPresent LastColor ?Victory ?VictoryColor}  % Can this be simplified?
      if StartPresent andthen EndPresent then
        Victory = true
        VictoryColor = LastColor
      else
        case Set of move(x:X y:Y color:Color)|Sr then
          if Color == BLUE_TAG then
            {CheckSetVictory Sr StartPresent orelse X==0 EndPresent orelse X==BOARD_SIZE-1 Color Victory VictoryColor}
          else % Color = 'Red'
            {CheckSetVictory Sr StartPresent orelse Y==0 EndPresent orelse Y==BOARD_SIZE-1 Color Victory VictoryColor}
          end
        [] nil then
          Victory = false
          VictoryColor = false
        end
      end
    end

    proc {DetermineWinner DisjointSets ?GameOver ?Winner}
      case DisjointSets of Set|DSr then
        % Check if set has point at start and at end
        local Victory VictoryColor in
          {CheckSetVictory Set false false nil Victory VictoryColor}
          if Victory == false then
            { DetermineWinner DSr GameOver Winner }
          else
            GameOver = true
            Winner = VictoryColor
          end
        end
      [] nil then
        GameOver = false
        Winner = false
      end
    end
  end
end
