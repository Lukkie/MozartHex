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

  local Seed in
    Seed = {OS.rand} mod 50
    {System.showInfo 'Seed: ' # Seed}
    {OS.srand Seed}
  end
  /* {OS.srand 41} */


  local BOARD_SIZE SEARCH_DEPTH in

    Args = {GetArgs record('search_depth'(single type:int)
                                   'board_size'(single type:int))}

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




    /** Functor Referee **/

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

    proc {PlayGame Board DisjointSets CurrentPlayerColor CurrentPlayerPort NextPlayerColor NextPlayerPort Attempt ?FinalBoard ?Winner}
      /**
        Board: List of move(x y color)  (will be sent to user)
        DisjointSets: List of disjoint sets (same info as Board, but a little more complex)
        CurrentPlayerColor: Color of player that has turn
        CurrentPlayerPort: Port of player that has turn
        NextPlayerColor: Color of player that will have turn after this player
        NextPlayerPort: Port of player that will have turn after this player
        Attempt: Int stating which attempt the player is on, starting at 0
        ?FinalBoard: Return the final state of the board, i.e. list of moves
        ?Winner: Return the color of the Winner
      **/
      % Ask next player for move
      local Move NewDisjointSets LocalWinner in
        {Send CurrentPlayerPort generateMove(Board CurrentPlayerColor Move)}
        % Check validity of move
        case Move of move(x:X y:Y color:C) then
          {System.showInfo 'Move at x:' # X # ' y:' # Y # ' color:' # C}
          % Iterate over list to see if x, y combo already exists
          /* {MoveExists Board Move ExistingMove} */
          if {MoveExists Board Move $} orelse {MoveOutOfBounds Move $} then
            if Attempt == 0 then
              {System.showInfo 'Move is invalid, allowing one more try'}
              {PlayGame Board DisjointSets CurrentPlayerColor CurrentPlayerPort NextPlayerColor NextPlayerPort Attempt+1 ?FinalBoard ?Winner}
            else
              {System.showInfo 'Move is invalid for the second time -- Disqualified.'}
              FinalBoard = Board
              Winner = NextPlayerColor
            end
          else
            % Print Board
            {PrintBoard Move|Board nil}

            % Check if any user has won the game
            {AddMoveToDisjointSets Move DisjointSets Move|nil nil NewDisjointSets}
            /* {Browse NewDisjointSets} */
            {DetermineWinner NewDisjointSets ?LocalWinner}
            if LocalWinner == false then
              {PlayGame Move|Board NewDisjointSets NextPlayerColor NextPlayerPort CurrentPlayerColor CurrentPlayerPort 0 ?FinalBoard ?Winner}
            else
              /* {Browse NewDisjointSets} */
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
          of startGame(?FinalBoard ?Winner) then
            {PlayGame nil nil RED_TAG Player1 BLUE_TAG Player2 0 FinalBoard Winner}
          end
        end
      end
      {NewPort Sin}
    end


    /** End of functor Referee **/


    /** Functor Player **/

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

    fun {PlayerProc}
      Sin in thread
        for Msg in Sin do
          /* {Browse Msg} */
          case Msg of generateMove(MoveList Color Move) then
            % Initial version: Generate random move on position that is not yet occupied
              local V in
                {GenerateAlphaBetaMove MoveList Color ?Move ?V}
                /* {Browse Color}
                {Browse V}
                {Browse Move} */
              end
            skip
          end
        end
      end
      {NewPort Sin}
    end

    fun {RandomPlayerProc}
      Sin in thread
        for Msg in Sin do
          /* {Browse Msg} */
          case Msg of generateMove(MoveList Color Move) then
            % Initial version: Generate random move on position that is not yet occupied
              {GenerateRandomMove MoveList Color Move}
            skip
          end
        end
      end
      {NewPort Sin}
    end

    proc {GenerateAlphaBetaMove MoveList Color ?Move ?V}
      local DisjointSets in
        {GenerateDisjointSets MoveList nil DisjointSets}
        {MaximizePlayer MoveList DisjointSets SEARCH_DEPTH ~1000000 1000000 {List.length MoveList} Color {GetOtherColor Color} ~1000000 V nil 0 0 nil Move}
        {System.showInfo V}
      end
    end

    proc {MakeBoard MoveList /*BoardList*/ ?Board}
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


    proc {CheckSetVictoryPlayer Set StartPresent EndPresent LastColor ?Victory ?VictoryColor}  % Can this be simplified?
      if StartPresent andthen EndPresent then
        Victory = true
        VictoryColor = LastColor
      else
        case Set of move(x:X y:Y color:Color)|Sr then
          if Color == BLUE_TAG then
            {CheckSetVictoryPlayer Sr StartPresent orelse X==0 EndPresent orelse X==BOARD_SIZE-1 Color Victory VictoryColor}
          else % Color = 'Red'
            {CheckSetVictoryPlayer Sr StartPresent orelse Y==0 EndPresent orelse Y==BOARD_SIZE-1 Color Victory VictoryColor}
          end
        [] nil then
          Victory = false
          VictoryColor = false
        end
      end
    end

    proc {DetermineWinnerPlayer DisjointSets ?GameOver ?Winner}
      /* {Browse DisjointSets} */
      case DisjointSets of Set|DSr then
        % Check if set has point at start and at end
        local Victory VictoryColor in
          {CheckSetVictoryPlayer Set false false nil Victory VictoryColor}
          if Victory == false then
            { DetermineWinnerPlayer DSr GameOver Winner }
          else
            /* {System.showInfo VictoryColor} */
            GameOver = true
            Winner = VictoryColor
          end
        end
      [] nil then
        GameOver = false
        Winner = false
      end
    end

    proc {CalculateScore DisjointSets Board Color Depth Score}
      % TODO
      % Add points for: Victory (many points), safe connections, length of path

      % Deduct points for the same things but on opposite side
      % Check if any user has won the game
      local GameOver Winner VictoryScore LengthScore OtherLengthScore in
        {CalculateLengthScore DisjointSets Color 0 LengthScore}
        {CalculateLengthScore DisjointSets {GetOtherColor Color} 0 OtherLengthScore}
        Score = 2 * LengthScore - OtherLengthScore
      end
    end

    proc {CalculateLengthScore DisjointSets Color CurrentBestLengthScoreAcc ?LengthScore}
      case DisjointSets of Set|Sr then
        % Determine highest and lowest value of axis, depending on which color
        local CalculatedScore in
          if Color == BLUE_TAG then
            % Blue goes left to right: X value is important
            {CalculateBlueLengthScore Set Color 1000000 ~1000000 CalculatedScore}
            {CalculateLengthScore Sr Color {Max CalculatedScore CurrentBestLengthScoreAcc} ?LengthScore}

          elseif Color == RED_TAG then
          % Red goes up to down: Y value is important
            {CalculateRedLengthScore Set Color 1000000 ~1000000 CalculatedScore}
            {CalculateLengthScore Sr Color {Max CalculatedScore CurrentBestLengthScoreAcc} ?LengthScore}

          else {System.showInfo 'This should not happen'} end
        end
      [] nil then LengthScore = CurrentBestLengthScoreAcc
      end
    end

    proc {CalculateRedLengthScore DisjointSet Color CurrentMinValue CurrentMaxValue ?LengthScore}
      case DisjointSet of move(x:X y:Y color:C)|Sr then
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
      case DisjointSet of move(x:X y:Y color:C)|Sr then
        if Color == C then
          {CalculateRedLengthScore Sr Color {Min CurrentMinValue X} {Max CurrentMaxValue X} ?LengthScore}
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
        {DetermineWinnerPlayer DisjointSets GameOver Winner}
        if GameOver then
          if Winner == Color then
            Score = (Depth + 1) * 100
          else
            Score = (Depth + 1) * ~100
          end

          /* {System.showInfo Score} */
        else
          Score = 0
        end
      end
    end

    proc {MaximizePlayer MoveList DisjointSets Depth Alpha Beta TilesPlaced TurnColor OtherColor CurrentV ?V AccumulatedTwoDList X Y CurrentMove ?BestMove} % TODO OriginalMoveList for debugging, should remove
      /* {System.showInfo CurrentV} */
      local VictoryScore TurnScore TwoDList NewDisjointSets NewV MaxV NewAlpha NewMove CurrentBestMove NextBestMove in
        if AccumulatedTwoDList == nil then
          {MakeBoard MoveList TwoDList}
        else
          TwoDList = AccumulatedTwoDList % For efficiency
        end

        % Check for victory with current MoveList
        {CheckForVictory DisjointSets TurnColor Depth ?VictoryScore}

        if VictoryScore \= 0 orelse Depth == 0 orelse TilesPlaced == BOARD_SIZE * BOARD_SIZE then
          % CALCULATE SCORE
          {CalculateScore DisjointSets AccumulatedTwoDList TurnColor Depth TurnScore}
          V = VictoryScore + TurnScore
          /* {System.showInfo V} */
        else
          /** Determine score when move at X, Y is added **/
          if {Value.isFree {List.nth {List.nth TwoDList X+1} Y+1}} then  % O(n^2) --> Can be improved by passing partial lists instead of indices
            NewMove = move(x:X y:Y color:TurnColor)
            {AddMoveToDisjointSets NewMove DisjointSets NewMove|nil nil NewDisjointSets}
            {MinimizePlayer NewMove|MoveList NewDisjointSets Depth-1 Alpha Beta TilesPlaced+1 TurnColor OtherColor 1000000 NewV nil 0 0 nil NextBestMove} % NextBestMove is not used.
            /* MaxV = {Max CurrentV NewV} */
            if NewV > CurrentV then
              MaxV = NewV
              CurrentBestMove = NewMove
            else
              MaxV = CurrentV
              CurrentBestMove = CurrentMove
            end
            NewAlpha = {Max Alpha MaxV}
          else
            NewAlpha = Alpha
            NewV = CurrentV
            MaxV = CurrentV
            CurrentBestMove = CurrentMove
          end

          /** Check next position, i.e. go to same level in search tree, but other move will be generated (if not pruned) **/
          if Beta > NewAlpha then
            if X < BOARD_SIZE-1 then
              {MaximizePlayer MoveList DisjointSets Depth NewAlpha Beta TilesPlaced TurnColor OtherColor MaxV V TwoDList X+1 Y CurrentBestMove BestMove}
            elseif X == BOARD_SIZE-1 andthen Y < BOARD_SIZE-1 then
              {MaximizePlayer MoveList DisjointSets Depth NewAlpha Beta TilesPlaced TurnColor OtherColor MaxV V TwoDList 0 Y+1 CurrentBestMove BestMove}
            else
              V = MaxV  % If whole board has been checked
              BestMove = CurrentBestMove
            end
          else
            V = MaxV  % If tree was pruned
            BestMove = CurrentBestMove

            % DEBUG
            if Depth == SEARCH_DEPTH then
              {Browse V}
              {Browse BestMove}
            end
            %%%%%
          end
        end
      end
    end


    proc {MinimizePlayer MoveList DisjointSets Depth Alpha Beta TilesPlaced TurnColor OtherColor CurrentV V AccumulatedTwoDList X Y CurrentMove ?BestMove}
      local VictoryScore TurnScore TwoDList NewDisjointSets NewV MinV NewBeta NewMove CurrentBestMove NextBestMove in
        if AccumulatedTwoDList == nil then
          {MakeBoard MoveList TwoDList}
        else
          TwoDList = AccumulatedTwoDList % For efficiency
        end
        % Check for victory with current MoveList
        {CheckForVictory DisjointSets TurnColor Depth ?VictoryScore}

        if VictoryScore \= 0 orelse Depth == 0 orelse TilesPlaced == BOARD_SIZE * BOARD_SIZE then
          % CALCULATE SCORE
          {CalculateScore DisjointSets AccumulatedTwoDList TurnColor Depth TurnScore}
          V = VictoryScore + TurnScore
          /* {System.showInfo V} */
        else
          /** Determine score when move at X, Y is added **/
          if {Value.isFree {List.nth {List.nth TwoDList X+1} Y+1}} then
            NewMove = move(x:X y:Y color:OtherColor)
            {AddMoveToDisjointSets NewMove DisjointSets NewMove|nil nil NewDisjointSets}
            {MaximizePlayer NewMove|MoveList NewDisjointSets Depth-1 Alpha Beta TilesPlaced+1 TurnColor OtherColor ~1000000 NewV nil 0 0 nil NextBestMove}
            /* MinV = {Min CurrentV NewV} */
            if NewV < CurrentV then
              MinV = NewV
              CurrentBestMove = NewMove
            else
              MinV = CurrentV
              CurrentBestMove = CurrentMove
            end
            NewBeta = {Max Alpha MinV}
          else
            NewBeta = Beta
            NewV = CurrentV
            MinV = CurrentV
            CurrentBestMove = CurrentMove
          end

          /** Check next position, i.e. go to same level in search tree, but other move will be generated (if not pruned) **/
          if NewBeta > Alpha then
            if X < BOARD_SIZE-1 then
              {MinimizePlayer MoveList DisjointSets Depth Alpha NewBeta TilesPlaced TurnColor OtherColor MinV V TwoDList X+1 Y CurrentBestMove BestMove}
            elseif X == BOARD_SIZE-1 andthen Y < BOARD_SIZE-1 then
              {MinimizePlayer MoveList DisjointSets Depth Alpha NewBeta TilesPlaced TurnColor OtherColor MinV V TwoDList 0 Y+1 CurrentBestMove BestMove}
            else
              V = MinV  % If whole board has been checked
              BestMove = CurrentBestMove
            end
          else
            V = MinV  % If tree was pruned
            BestMove = CurrentBestMove

            % DEBUG
            if Depth == SEARCH_DEPTH then
              {Browse V}
              {Browse BestMove}
            end
            %%%%%
          end
        end
      end
    end

    /** End of functor Player **/

    /** Main thread **/

    Player1 = {PlayerProc} % Get this from functor
    Player2 = {PlayerProc} % Get this from functor
    /* Player1 = {RandomPlayerProc} % Get this from functor */
    /* Player2 = {RandomPlayerProc} % Get this from functor */

    % Assume Referee is also a thread
    Referee = {RefereeProc Player1 Player2} % Get this from functor

    /* local Winner in
      {Send Referee testGame(Winner)} % Could also assign players here.
      {System.showInfo "Winner is " # Winner }
    end */

    local FinalBoard Winner in
      {Send Referee startGame(FinalBoard Winner)} % Could also assign players here.
      {System.showInfo "Winner is " # Winner }
      /* {Browse FinalBoard} */
        /* { Exit 0 } */
    end

  end % End of local variables SEARCH_DEPTH and BOARD_SIZE

  /* {Delay 500}
  { Exit 0 } */

end
