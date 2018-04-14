functor
import
  Application(exit:Exit getArgs:GetArgs)
  System
  OS
  Browser(browse:Browse)
define
  DEFAULT_SIZE = 5

  fun {GenerateLinearMoves BoardSize X Y}

    if X < BoardSize-1 then
      move(x:X y:Y) | {GenerateLinearMoves BoardSize X+1 Y}
    elseif Y < BoardSize-1 then
      move(x:X y:Y) | {GenerateLinearMoves BoardSize 0 Y+1}
    else
      move(x:X y:Y) | nil
    end
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
        {System.showInfo NewX # ", " # NewY}
        if Step == 2*CurrentSize-1 then
          move(x:NewX y:NewY) | {GenerateSpiral CurrentSize 0 1 BoardSize}
        else
          move(x:NewX y:NewY) | {GenerateSpiral CurrentSize Step+1 0 BoardSize}
        end
      elseif Direction == 1 then
        NewX = CenterX + CurrentSize
        NewY = CenterY - CurrentSize + Step
        {System.showInfo NewX # ", " # NewY}
        if Step == 2*CurrentSize-1 then
          move(x:NewX y:NewY) | {GenerateSpiral CurrentSize 0 2 BoardSize}
        else
          move(x:NewX y:NewY) | {GenerateSpiral CurrentSize Step+1 1 BoardSize}
        end
      elseif Direction == 2 then
        NewX = CenterX + CurrentSize - Step
        NewY = CenterY + CurrentSize
        {System.showInfo NewX # ", " # NewY}
        if Step == 2*CurrentSize-1 then
          move(x:NewX y:NewY) | {GenerateSpiral CurrentSize 0 3 BoardSize}
        else
          move(x:NewX y:NewY) | {GenerateSpiral CurrentSize Step+1 2 BoardSize}
        end
      elseif Direction == 3 then
        NewX = CenterX - CurrentSize
        NewY = CenterY + CurrentSize - Step
        {System.showInfo NewX # ", " # NewY}
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








  local BoardSize MoveList in
    Args = {GetArgs record('board_size'(single type:int))}

    if {Value.hasFeature Args 'board_size'} then
      BoardSize = Args.board_size
    else
      BoardSize = DEFAULT_SIZE
    end

    /* {GenerateMoves BoardSize nil MoveList} */
    MoveList = {GenerateSpiral 0 0 0 BoardSize}
    {Browse MoveList}

  end


  /* { Application.exit 0 } */

end
