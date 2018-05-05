/**
  TODO: Safely connected
  TODO: Although we assume the opponent will always play in such way that it will stop your victories
          it will not always do this. Maybe don't assume a perfect opponent.
  TODO: Optimize for larger search depth
*/
functor
import
  Application(getArgs:GetArgs)
  System
  OS
  /* Browser(browse:Browse) */
  Board( transformTheirMoveToMine:TransformTheirMoveToMine
          transformMyMoveToTheirs:TransformMyMoveToTheirs
          getListOfMoves:GetListOfMoves
          printBoard:PrintBoard
          addMoveToDisjointSets:AddMoveToDisjointSets
          moveExists:MoveExists
          determineWinner:DetermineWinner ) at 'board.ozf'
export
  player:PlayerProc
  randomPlayer:RandomPlayerProc
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

    /** Functor Player **/

    fun {PlayerProc}
      Sin in thread
        for Msg in Sin do
          case Msg of generateMove(Board Color TurnsUntilSwap Move) then
              {System.showInfo 'Turns until swap: ' # TurnsUntilSwap}
              local V GeneratedMove MoveList in
                MoveList = {GetListOfMoves Board 1 1} /* Transforming their board to my representation */

                if TurnsUntilSwap > 0 andthen TurnsUntilSwap < 7 then
                  {GenerateAlphaBetaMove MoveList Color ~1 ?GeneratedMove ?V}
                else
                  {GenerateAlphaBetaMove MoveList Color 1 ?GeneratedMove ?V}
                end

                Move = {TransformMyMoveToTheirs GeneratedMove}
              end
          [] swapRequest(Move ?NumberOfTurns) then
              {SwapRequest {TransformTheirMoveToMine Move} ?NumberOfTurns}
          end
        end
      end
      {NewPort Sin}
    end

    fun {RandomPlayerProc}
      Sin in thread
        for Msg in Sin do
          /* {Browse Msg} */
          case Msg of generateMove(Board Color _ Move) then
            % Initial version: Generate random move on position that is not yet occupied
            local GeneratedMove MoveList in
              MoveList = {GetListOfMoves Board 1 1} /* Transforming their board to my representation */
              {GenerateRandomMove MoveList Color ?GeneratedMove}
              Move = {TransformMyMoveToTheirs GeneratedMove}
            end
          [] swapRequest(Move ?NumberOfTurns) then
              {SwapRequest {TransformTheirMoveToMine Move} ?NumberOfTurns}
          end
        end
      end
      {NewPort Sin}
    end

    % For testing! Not used in final model.
    proc {GenerateRandomMove MoveList Color ?Move}
      local GeneratedMove in
        GeneratedMove = move(x:{OS.rand} mod BOARD_SIZE y:{OS.rand} mod BOARD_SIZE color:Color)
        local Exists in
          {MoveExists MoveList GeneratedMove ?Exists}
          if Exists then {GenerateRandomMove MoveList Color Move}
          else Move = GeneratedMove end
        end
      end
    end

    fun {GetOtherColor Color}
      if Color == BLUE_TAG then RED_TAG
      else BLUE_TAG end
    end

    fun {GenerateSpiral CurrentSize Step Direction BoardSize}
      local CenterX CenterY NewX NewY in
        CenterX = BoardSize div 2
        CenterY = BoardSize div 2

        if CurrentSize == 0 then
          move(x:CenterX y:CenterY) | {GenerateSpiral 1 0 0 BoardSize}
        elseif CurrentSize < CenterX + 1 then

          if Direction == 0 then
            NewX = CenterX - CurrentSize + Step
            NewY = CenterY - CurrentSize
            if Step == 2*CurrentSize-1 then
              move(x:NewX y:NewY) | {GenerateSpiral CurrentSize 0 1 BoardSize}
            else
              move(x:NewX y:NewY) | {GenerateSpiral CurrentSize Step+1 0 BoardSize}
            end
          elseif Direction == 1 then
            NewX = CenterX + CurrentSize
            NewY = CenterY - CurrentSize + Step
            if Step == 2*CurrentSize-1 then
              move(x:NewX y:NewY) | {GenerateSpiral CurrentSize 0 2 BoardSize}
            else
              move(x:NewX y:NewY) | {GenerateSpiral CurrentSize Step+1 1 BoardSize}
            end
          elseif Direction == 2 then
            NewX = CenterX + CurrentSize - Step
            NewY = CenterY + CurrentSize
            if Step == 2*CurrentSize-1 then
              move(x:NewX y:NewY) | {GenerateSpiral CurrentSize 0 3 BoardSize}
            else
              move(x:NewX y:NewY) | {GenerateSpiral CurrentSize Step+1 2 BoardSize}
            end
          elseif Direction == 3 then
            NewX = CenterX - CurrentSize
            NewY = CenterY + CurrentSize - Step
            if Step == 2*CurrentSize-1 then
              move(x:NewX y:NewY) | {GenerateSpiral CurrentSize+1 0 0 BoardSize}
            else
              move(x:NewX y:NewY) | {GenerateSpiral CurrentSize Step+1 3 BoardSize}
            end

          end
        else
          nil
        end
      end
    end

    proc {GenerateAlphaBetaMove MoveList Color Direction ?Move ?V}
    % Direction = 1 if trying to maximize score, else use -1
      local DisjointSets MoveOptions in
        MoveOptions = {GenerateSpiral 0 0 0 BOARD_SIZE}
        {GenerateDisjointSets MoveList nil DisjointSets}
        {MaximizePlayer MoveList DisjointSets SEARCH_DEPTH ~1000000 1000000 {List.length MoveList} Color {GetOtherColor Color} ~1000000 V nil MoveOptions MoveOptions nil Direction Move nil _}
        {System.showInfo V}
      end
    end

    proc {MakeBoard MoveList ?Board}
    /**
      Converts list of moves into a 2-dimensional array of shape BOARD_SIZExBOARD_SIZE
    **/
      local NewBoard in
        {List.make BOARD_SIZE NewBoard}
        for I in 1..BOARD_SIZE do
          {List.make BOARD_SIZE {List.nth NewBoard I $}}
        end
        for move(x:X y:Y color:C) in MoveList do
          {List.nth {List.nth NewBoard X+1} Y+1} = move(x:X y:Y color:C)
        end
        Board = NewBoard
      end
    end

    fun {Max X Y}
      if X >= Y then X else Y end
    end

    fun {Min X Y}
      if X >= Y then Y else X end
    end

    proc {GenerateDisjointSets MoveList DisjointSets ?NewDisjointSets}
      case MoveList of Move|Mr then
        {GenerateDisjointSets Mr {AddMoveToDisjointSets Move DisjointSets Move|nil nil $} NewDisjointSets}
      [] nil then
        NewDisjointSets = DisjointSets
      end
    end

    proc {CalculateScore DisjointSets Board Color Depth Direction ?Score}
      % If Direction = -1, return the opposite score! This is used when trying to do a worthless move, otherwise Direction = 1
      % Add points for: Victory (many points), safe connections, length of path

      % Deduct points for the same things but on opposite side
      % Check if any user has won the game
      local LengthScore OtherLengthScore in
        {CalculateLengthScore DisjointSets Color 0 LengthScore}
        {CalculateLengthScore DisjointSets {GetOtherColor Color} 0 OtherLengthScore}
        Score = Direction * (LengthScore - 2*OtherLengthScore)
      end
    end

    proc {CalculateLengthScore DisjointSets Color CurrentBestLengthScoreAcc ?LengthScore}
      case DisjointSets of Set|Sr then
        % Determine highest and lowest value of axis, depending on which color
        local CalculatedScore in
          if Color == BLUE_TAG then
            % Blue goes left to right: X value is important
            {CalculateBlueLengthScore Set Color 1000000 ~1000000 CalculatedScore}

          elseif Color == RED_TAG then
          % Red goes up to down: Y value is important
            {CalculateRedLengthScore Set Color 1000000 ~1000000 CalculatedScore}
          end

          {CalculateLengthScore Sr Color {Max CalculatedScore CurrentBestLengthScoreAcc} ?LengthScore}

        end
      [] nil then LengthScore = CurrentBestLengthScoreAcc
      end
    end

    proc {CalculateRedLengthScore DisjointSet Color CurrentMinValue CurrentMaxValue ?LengthScore}
      case DisjointSet of move(x:_ y:Y color:C)|Sr then
        if Color == C then
          {CalculateRedLengthScore Sr Color {Min CurrentMinValue Y} {Max CurrentMaxValue Y} ?LengthScore}
        else
          % Looking at disjoint set of wrong color, just return score of 0
          LengthScore = 0
        end
      [] nil then
        LengthScore = CurrentMaxValue - CurrentMinValue + 1
      end
    end

    proc {CalculateBlueLengthScore DisjointSet Color CurrentMinValue CurrentMaxValue ?LengthScore}
      case DisjointSet of move(x:X y:_ color:C)|Sr then
        if Color == C then
          {CalculateBlueLengthScore Sr Color {Min CurrentMinValue X} {Max CurrentMaxValue X} ?LengthScore}
        else
          % Looking at disjoint set of wrong color, just return score of 0
          LengthScore = 0
        end
      [] nil then
        LengthScore = CurrentMaxValue - CurrentMinValue + 1
      end
    end

    proc {CheckForVictory DisjointSets Color Depth ?Score} % Could be more efficient...
      local GameOver Winner in
        {DetermineWinner DisjointSets GameOver Winner}
        if GameOver then
          if Winner == Color then
            Score = (Depth + 1) * 100
          else
            Score = (Depth + 1) * ~100
          end
        else
          Score = 0
        end
      end
    end

    proc {MaximizePlayer MoveList DisjointSets Depth Alpha Beta TilesPlaced TurnColor OtherColor CurrentV ?V AccumulatedTwoDList AvailableMoveOptions MoveOptions CurrentMove Direction ?BestMove CurrentList ?BestList} % TODO OriginalMoveList for debugging, should remove
      local VictoryScore TurnScore TwoDList NewDisjointSets NewV MaxV NewAlpha NewMove CurrentBestMove NextBestMove NewList MaxList in
        if AccumulatedTwoDList == nil then
          {MakeBoard MoveList TwoDList}
        else
          TwoDList = AccumulatedTwoDList % For efficiency
        end

        % Check for victory with current MoveList
        {CheckForVictory DisjointSets TurnColor Depth ?VictoryScore}

        if VictoryScore \= 0 orelse Depth == 0 orelse TilesPlaced == BOARD_SIZE * BOARD_SIZE then
          % CALCULATE SCORE
          {CalculateScore DisjointSets AccumulatedTwoDList TurnColor Depth Direction TurnScore}
          V = VictoryScore + TurnScore
          BestList = MoveList
        else
          case AvailableMoveOptions of move(x:X y:Y)|Mr then



            /** Determine score when move at X, Y is added **/
            if {Value.isFree {List.nth {List.nth TwoDList X+1} Y+1}} then  % O(n^2) --> Can be improved by passing partial lists instead of indices
              NewMove = move(x:X y:Y color:TurnColor)
              {AddMoveToDisjointSets NewMove DisjointSets NewMove|nil nil NewDisjointSets}
              {MinimizePlayer NewMove|MoveList NewDisjointSets Depth-1 Alpha Beta TilesPlaced+1 TurnColor OtherColor 1000000 NewV nil MoveOptions MoveOptions nil Direction NextBestMove nil NewList} % NextBestMove is not used.
              if NewV > CurrentV then
                MaxV = NewV
                CurrentBestMove = NewMove
                MaxList = NewList
              else
                MaxV = CurrentV
                CurrentBestMove = CurrentMove
                MaxList = CurrentList
              end
              NewAlpha = {Max Alpha MaxV}
            else
              NewAlpha = Alpha
              NewV = CurrentV
              MaxV = CurrentV
              CurrentBestMove = CurrentMove
              MaxList = CurrentList
            end

            /** Check next position, i.e. go to same level in search tree, but other move will be generated (if not pruned) **/
            if Beta > NewAlpha then
              if Mr == nil then
                BestList = MaxList

                % DEBUG
                if DEBUG andthen Depth == SEARCH_DEPTH then
                  {System.showInfo "\n\n\n"}
                  {PrintBoard BestList nil}
                end
                %%%%%
                V = MaxV  % If whole board has been checked
                BestMove = CurrentBestMove
              else
                {MaximizePlayer MoveList DisjointSets Depth NewAlpha Beta TilesPlaced TurnColor OtherColor MaxV V TwoDList Mr MoveOptions CurrentBestMove Direction BestMove MaxList BestList}
              end
            else
              V = MaxV  % If tree was pruned
              BestMove = CurrentBestMove
              BestList = MaxList
              % DEBUG
              if DEBUG andthen Depth == SEARCH_DEPTH then
                {PrintBoard BestList nil}
              end
              %%%%%
            end
          end
        end
      end
    end


    proc {MinimizePlayer MoveList DisjointSets Depth Alpha Beta TilesPlaced TurnColor OtherColor CurrentV V AccumulatedTwoDList AvailableMoveOptions MoveOptions CurrentMove Direction ?BestMove CurrentList ?BestList}
      local VictoryScore TurnScore TwoDList NewDisjointSets NewV MinV NewBeta NewMove CurrentBestMove NextBestMove NewList MaxList in
        if AccumulatedTwoDList == nil then
          {MakeBoard MoveList TwoDList}
        else
          TwoDList = AccumulatedTwoDList % For efficiency
        end

        % Check for victory with current MoveList
        {CheckForVictory DisjointSets TurnColor Depth ?VictoryScore}

        if VictoryScore \= 0 orelse Depth == 0 orelse TilesPlaced == BOARD_SIZE * BOARD_SIZE then
          % CALCULATE SCORE
          {CalculateScore DisjointSets AccumulatedTwoDList TurnColor Depth Direction TurnScore}
          V = VictoryScore + TurnScore
          BestList = MoveList
        else
          case AvailableMoveOptions of move(x:X y:Y)|Mr then
            /** Determine score when move at X, Y is added **/
            if {Value.isFree {List.nth {List.nth TwoDList X+1} Y+1}} then
              NewMove = move(x:X y:Y color:OtherColor)
              {AddMoveToDisjointSets NewMove DisjointSets NewMove|nil nil NewDisjointSets}
              {MaximizePlayer NewMove|MoveList NewDisjointSets Depth-1 Alpha Beta TilesPlaced+1 TurnColor OtherColor ~1000000 NewV nil MoveOptions MoveOptions nil Direction NextBestMove nil NewList}
              if NewV < CurrentV then
                MinV = NewV
                CurrentBestMove = NewMove
                MaxList = NewList
              else
                MinV = CurrentV
                CurrentBestMove = CurrentMove
                MaxList = CurrentList
              end
              NewBeta = {Max Alpha MinV}
            else
              NewBeta = Beta
              NewV = CurrentV
              MinV = CurrentV
              CurrentBestMove = CurrentMove
              MaxList = CurrentList
            end

            /** Check next position, i.e. go to same level in search tree, but other move will be generated (if not pruned) **/
            if NewBeta > Alpha then
              if Mr == nil then
                BestList = MaxList

                % DEBUG
                if DEBUG andthen Depth == SEARCH_DEPTH then
                  {System.showInfo "\n\n\n"}
                  {PrintBoard BestList nil}
                end
                %%%%%
                V = MinV  % If whole board has been checked
                BestMove = CurrentBestMove
              else
                {MinimizePlayer MoveList DisjointSets Depth Alpha NewBeta TilesPlaced TurnColor OtherColor MinV V TwoDList Mr MoveOptions CurrentBestMove Direction BestMove MaxList BestList}
              end
            else
              V = MinV  % If tree was pruned
              BestMove = CurrentBestMove
              BestList = MaxList

              % DEBUG
              if DEBUG andthen Depth == SEARCH_DEPTH then
                {PrintBoard BestList nil}
              end
              %%%%%
            end
          end
        end
      end
    end

    proc {SwapRequest Move ?NumberOfTurns}
      NumberOfTurns = SWAP_TURN_VALUE
    end

  end % End of local variables SEARCH_DEPTH and BOARD_SIZE
end
