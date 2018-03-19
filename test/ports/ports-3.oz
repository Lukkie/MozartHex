% 11 by 11 board
functor
import
  Application(exit:Exit)
  System
  /* Browser(browse:Browse) */
define
  fun {RefereeProc Player1 Player2}
    Sin in thread
      for Msg in Sin do
        case Msg of startGame(?Winner) then
          for I in 0..5 do
            {System.showInfo {Send Player2 addNumbers(I I $)}}
            {Delay 500}
          end
          Winner = "Player 1"
        end
      end
    end
    {NewPort Sin}
  end

  fun {PlayerProc}
    Sin in thread
      for Msg in Sin do
        /* {Browse Msg} */
        case Msg of addNumbers(N1 N2 ?Result) then
          Result = N1 + N2

        end
      end
    end
    {NewPort Sin}
  end


  Player1 = {PlayerProc}
  Player2 = {PlayerProc}

  Referee = {RefereeProc Player1 Player2}

  local Winner in
    {Send Referee startGame(Winner)} % Could also assign players here.
    {System.showInfo "Winner is " # Winner }
  end


  {Delay 500}
  { Exit 0 }

end
