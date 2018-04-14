/**
  TODO: Second chance for players after invalid move
  TODO:
*/

functor
import
  Application(exit:Exit)
  System
  OS
  Browser(browse:Browse)
define

  A = move(5) | move(6) | nil
  B = move(6) | nil
  C = nil

  /* for Item in B do
    case Item of move(Value) then
      {System.showInfo Value}
    [] nil then
      {System.showInfo 'nil'}
    end

  end */

  for move(Value) in C do
      {System.showInfo Value}

  end


  { Exit 0 }

end
