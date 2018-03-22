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
  BOARD_SIZE = 3
  BLUE_TAG = 'Blu'
  RED_TAG = 'Red'
  SEARCH_DEPTH = 2

% 5, 12
  local Seed in
    Seed = {OS.rand} mod 50
    {System.showInfo Seed}
    {OS.srand Seed}
  end
  /* {OS.srand 12} */


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
    local Move NewDisjointSets LocalWinner in
      {Send CurrentPlayerPort generateMove(Board CurrentPlayerColor Move)}
      % Check validity of move
      case Move of move(x:X y:Y color:C) then
        {System.showInfo 'Move at x:' # X # ' y:' # Y # ' color:' # C}
        % Iterate over list to see if x, y combo already exists
        /* {MoveExists Board Move ExistingMove} */
        if {MoveExists Board Move $} orelse {MoveOutOfBounds Move $} then
          {System.showInfo 'Move is invalid'}
          FinalBoard = Board
          Winner = NextPlayerColor
        else
          % Print Board
          {PrintBoard Move|Board nil}

          % Check if any user has won the game
          {AddMoveToDisjointSets Move DisjointSets Move|nil nil NewDisjointSets}
          /* {Browse NewDisjointSets} */
          {DetermineWinner NewDisjointSets ?LocalWinner}
          if LocalWinner == false then
            {PlayGame Move|Board NewDisjointSets NextPlayerColor NextPlayerPort CurrentPlayerColor CurrentPlayerPort ?FinalBoard ?Winner}
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
          {PlayGame nil nil RED_TAG Player1 BLUE_TAG Player2 FinalBoard Winner}
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
              {MaximizePlayer MoveList SEARCH_DEPTH ~1000000 1000000 {List.length MoveList} Color {GetOtherColor Color} ~1000000 V nil 0 0}
              {System.showInfo V}
            end
            {GenerateRandomMove MoveList Color Move}
          skip
        end
      end
    end
    {NewPort Sin}
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
      {AddMoveToDisjointSets Move DisjointSets Move|nil nil NewDisjointSets}
    end
  end

  proc {CheckSetVictoryPlayer Set StartPresent EndPresent LastColor ?Victory ?VictoryColor}  % Can this be simplified?
    if StartPresent then
      { System.showInfo 'StartPresent' }
    end
    if EndPresent then
      { System.showInfo 'EndPresent' }
    end

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

  proc {CalculateScore MoveList Board Color Score}
    % TODO
    % Add points for: Victory (many points), safe connections, length of path

    % Deduct points for the same things but on opposite side
    /* V = 1 */

    % Check if any user has won the game

    local DisjointSets GameOver Winner in
      {GenerateDisjointSets MoveList nil DisjointSets}
      {DetermineWinnerPlayer DisjointSets GameOver Winner}
      if GameOver then
        if Winner == Color then
          {System.showInfo 'test'}
          Score = 100
        else
          {System.showInfo 'test2'}

          Score = ~100
        end
      else
        Score = 0
      end
    end

  end

  proc {MaximizePlayer MoveList Depth Alpha Beta TilesPlaced TurnColor OtherColor CurrentV V AccumulatedTwoDList X Y}
    {System.showInfo CurrentV}
    local TwoDList NewV MaxV NewAlpha in
      if AccumulatedTwoDList == nil then
        {MakeBoard MoveList TwoDList}
      else
        TwoDList = AccumulatedTwoDList % For efficiency
      end

      if Depth == 0 orelse TilesPlaced == BOARD_SIZE * BOARD_SIZE then
        % CALCULATE SCORE TODO
        % V = ...
        /* {System.showInfo 'Calculating score for MoveList of size ' # {List.length MoveList}} */
        {CalculateScore MoveList AccumulatedTwoDList TurnColor V}
      else
        /** Determine score when move at X, Y is added **/
        if {Value.isFree {List.nth {List.nth TwoDList X+1} Y+1}} then
          {MinimizePlayer move(x:X y:Y color:TurnColor)|MoveList Depth-1 Alpha Beta TilesPlaced+1 TurnColor OtherColor 1000000 NewV nil 0 0}
          MaxV = {Max CurrentV NewV}
          NewAlpha = {Max Alpha MaxV}
        else
          NewAlpha = Alpha
          NewV = CurrentV
          MaxV = CurrentV
        end

        /** Check next position, i.e. go to same level in search tree, but other move will be generated (if not pruned) **/
        if Beta > NewAlpha then
          if X < BOARD_SIZE-1 then
            {MaximizePlayer MoveList Depth NewAlpha Beta TilesPlaced TurnColor OtherColor MaxV V TwoDList X+1 Y}
          elseif X == BOARD_SIZE-1 andthen Y < BOARD_SIZE-1 then
            {MaximizePlayer MoveList Depth NewAlpha Beta TilesPlaced TurnColor OtherColor MaxV V TwoDList 0 Y+1}
          else
            V = MaxV  % If whole board has been checked
          end
        else
          V = MaxV  % If tree was pruned
        end
      end
    end
  end


  proc {MinimizePlayer MoveList Depth Alpha Beta TilesPlaced TurnColor OtherColor CurrentV V AccumulatedTwoDList X Y}
    local TwoDList NewV MaxV NewBeta in
      if AccumulatedTwoDList == nil then
        {MakeBoard MoveList TwoDList}
      else
        TwoDList = AccumulatedTwoDList % For efficiency
      end

      if Depth == 0 orelse TilesPlaced == BOARD_SIZE * BOARD_SIZE then
        % CALCULATE SCORE TODO
        % V = ...
        {System.showInfo 'Calculating score for MoveList of size ' # {List.length MoveList}}
        {CalculateScore MoveList AccumulatedTwoDList TurnColor V}
      else
        /** Determine score when move at X, Y is added **/
        if {Value.isFree {List.nth {List.nth TwoDList X+1} Y+1}} then
          {MaximizePlayer move(x:X y:Y color:OtherColor)|MoveList Depth-1 Alpha Beta TilesPlaced+1 TurnColor OtherColor ~1000000 NewV nil 0 0}
          MaxV = {Min CurrentV NewV}
          NewBeta = {Max Alpha MaxV}
        else
          NewBeta = Beta
          NewV = CurrentV
          MaxV = CurrentV
        end

        /** Check next position, i.e. go to same level in search tree, but other move will be generated (if not pruned) **/
        if NewBeta > Alpha then
          if X < BOARD_SIZE-1 then
            {MinimizePlayer MoveList Depth Alpha NewBeta TilesPlaced TurnColor OtherColor MaxV V TwoDList X+1 Y}
          elseif X == BOARD_SIZE-1 andthen Y < BOARD_SIZE-1 then
            {MinimizePlayer MoveList Depth Alpha NewBeta TilesPlaced TurnColor OtherColor MaxV V TwoDList 0 Y+1}
          else
            V = MaxV  % If whole board has been checked
          end
        else
          V = MaxV  % If tree was pruned
        end
      end
    end
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
    /* {Browse FinalBoard} */
      /* { Exit 0 } */
  end



  /* {Delay 500}
  { Exit 0 } */

end
