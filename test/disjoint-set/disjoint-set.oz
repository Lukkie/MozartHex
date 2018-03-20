% 11 by 11 board
functor
import
  Application(exit:Exit)
  System
  Browser(browse:Browse)
  /* Array */

define
  /* BOARD_SIZE = 3 */

  MoveList = move(1) | move(2) | move(4) | move(6) | move(7) | move(8) | nil
  % Expected result after generating disjoint sets: [[1 2] [4] [6 7 8]]


  % MoveList = move(1) | move(2) | move(4) | move(6) | move(7) | move(8) | move(3) nil
  % Expected result after generating disjoint sets: [[1 2 3 4] [6 7 8]]

  A = {NewCell 0}
  /* MoveCell = {NewCell}
  SetCell = {NewCell} */

  proc {MoveBelongsToSet Move Set ?IsInSet}

    % DEBUG
    /* {System.showInfo @A}
    A := @A + 1
    {Browse Move}
    {Browse Set}
    {Delay 1000} */
    %%%%

    case Set of SetMove|Sr then
      case Move of move(Value1) then
        case SetMove of move(Value2) then
          if {Number.abs Value1-Value2} < 2 then
            IsInSet = true
          else
            {MoveBelongsToSet Move Sr ?IsInSet}
          end
        end
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


  proc {GetAllDisjointSets Moves DisjointSets ?Results}
    case Moves of Move | Mr then
      {GetAllDisjointSets Mr {AddMoveToDisjointSets Move DisjointSets Move|nil nil $} Results}
    [] nil then
      Results = DisjointSets
    end
  end

  local DS DS1 DS2 DS3 in
    /* {AddMoveToDisjointSets move(3) nil move(3) nil ?Results} */
    /* {AddMoveToDisjointSets move(1) nil move(1)|nil nil DS1}
    {AddMoveToDisjointSets move(2) DS1 move(2)|nil nil DS2}
    {AddMoveToDisjointSets move(3) DS2 move(3)|nil nil DS3}
    {Browse DS3} */
    {GetAllDisjointSets MoveList nil ?DS}
    {Browse DS}
  end

  /* Content1 = 'a' | 'b' | nil
  Content2 = 'c' | 'd' | 'f' | nil
  {Browse set(Content1) | set(Content2) | nil}
  {Browse Content1 | Content2 | nil}
  {Browse { List.flatten Content1 | Content2 } } */


  /* {Time.delay 5000} */
  /* { Exit 0 } */

end
