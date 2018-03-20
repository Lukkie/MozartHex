% 11 by 11 board
functor
import
  Application(exit:Exit)
  System

define

  A = move(x:5 y:6)

  case A of move(x:X y:_) then
    {System.printInfo X}
  end


  fun {AndThen BP1 BP2}
    if BP1 then BP2
    else false end
  end

  fun {IsNeighbour Move1 Move2}
    case Move1 of move(x:X1 y:Y1 color:_) then
      case Move2 of move(x:X2 y:Y2 color:_) then
        if {Number.abs X1-X2} + {Number.abs Y1-Y2} < 2 then true
        elseif {AndThen X1-X2==1 Y2-Y1==1} then true
        elseif {AndThen X2-X1==1 Y1-Y2==1} then true
        else false end
      end
    end
  end

  if {IsNeighbour move(x:2 y:2 color:1) move(x:1 y:3 color:'kaas')} then
    {System.printInfo 'Neighbours 1'}
  end

  if {IsNeighbour move(x:2 y:2 color:1) move(x:3 y:1 color:'kaas')} then
    {System.printInfo 'Neighbours 2'}
  end

  if {IsNeighbour move(x:2 y:2 color:1) move(x:1 y:1 color:'kaas')} then
    {System.printInfo 'Neighbours 3'}
  end

  if {IsNeighbour move(x:2 y:2 color:1) move(x:3 y:3 color:'kaas')} then
    {System.printInfo 'Neighbours 4'}
  end

  { Exit 0 }

end
