% 11 by 11 board
functor
import
  Application(exit:Exit)
  System
  Browser(browse:Browse)
  /* Array */

define
  BOARD_SIZE = 3

  % Assuming arrays are stateful and therefore not declarative
  Lijst = nil
  proc {DoSomeThings Lijst Iteration ?FinalLijst}
    if Iteration == 0 then
      {System.showInfo 'FINISHED'}
      FinalLijst = Lijst
    else
    {Browse Lijst}
    {DoSomeThings move(x:Iteration y:Iteration player:'Blue') | Lijst Iteration-1 FinalLijst}
    end
  end

  local FinalLijst in
    {DoSomeThings Lijst 5 FinalLijst}
    {Browse 'Test:'}
    {Browse FinalLijst}
  end


  /* {Time.delay 5000} */
  /* { Exit 0 } */

end
