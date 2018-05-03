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
  DEFAULT_BOARD_SIZE = 5
  BLUE_TAG = blue
  RED_TAG = red
  NONE_TAG = empty /** Used by others **/
  DEFAULT_SEARCH_DEPTH = 3
  DEFAULT_SWAP_TURN_VALUE = 6


  local BOARD_SIZE TheirBoard in

    BOARD_SIZE = DEFAULT_BOARD_SIZE

    /** Code to transform board and move **/
    fun {TransformMove Move}
      /* My moves have range between 0 and BOARD_LENGTH - 1
      Other people's moves start at 1 and end at BOARD_LENGTH */
      case Move of move(x:X y:Y color:C) then
        move(x:X+1 y:Y+1 color:C)
      end
    end

    /** For use in player.oz **/
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

    /** For use in referee.oz **/
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


    TheirBoard = [
      [BLUE_TAG NONE_TAG NONE_TAG NONE_TAG NONE_TAG]
      [NONE_TAG NONE_TAG NONE_TAG NONE_TAG NONE_TAG]
      [NONE_TAG RED_TAG NONE_TAG BLUE_TAG NONE_TAG]
      [NONE_TAG NONE_TAG NONE_TAG NONE_TAG NONE_TAG]
      [NONE_TAG NONE_TAG NONE_TAG RED_TAG NONE_TAG]
    ]

    {Browse {List.is TheirBoard}}
    {Browse TheirBoard}
    local BoardList in
      BoardList = {GetListOfMoves TheirBoard 1 1}
      {Browse BoardList}
      {Browse {DoesBoardListContain BoardList 2 3}}
      {Browse {GetListOfLists BoardList}}
    end




  end % End of local variables SEARCH_DEPTH and BOARD_SIZE


end
