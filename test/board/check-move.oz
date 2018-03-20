% 11 by 11 board
functor
import
  Application(exit:Exit)
  System
  Browser(browse:Browse)
  /* Array */

define
  /* BOARD_SIZE = 3 */

  % Assuming arrays are stateful and therefore not declarative
  /* Lijst = nil
  proc {DoSomeThings Lijst Iteration ?FinalLijst}
    if Iteration == 0 then
      {System.showInfo 'FINISHED'}
      FinalLijst = Lijst
    else
    {DoSomeThings move(x:Iteration y:Iteration player:'Blue') | Lijst Iteration-1 FinalLijst}
    end
  end

  local FinalLijst in
    {DoSomeThings Lijst 5 FinalLijst}

    for move(x:X y:Y player:C) in FinalLijst do
      {System.showInfo 'Move at x:' # X # ' y:' # Y # ' color:' # C}
    end


  end */


  proc {MoveExists MoveList Move ?Exists}
    case MoveList of M|Mr then
      case M of move(x:X y:Y) then
        case Move of move(x:NewX y:NewY) then
          if X == NewX then
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


  local MoveIsNotValid in
    Lijst = move(x:1 y:1) |  move(x:2 y:2) |  move(x:3 y:3) |  move(x:4 y:4) | nil
    /* {Browse Lijst} */
    NewMove = move(x:5 y:1)
    {MoveExists Lijst NewMove MoveIsNotValid}

    if MoveIsNotValid == true then
      {System.showInfo "Move is NOT valid"}
    elseif MoveIsNotValid == false then
      {System.showInfo "Move is valid"}
    else
      {System.showInfo "This should not happen"}
    end
  end

  /* {Time.delay 5000} */
  /* { Exit 0 } */

end
