% 11 by 11 board
functor
import
  Application(exit:Exit)
  System
  /* Browser(browse:Browse) */
define

  /** Functor 1 **/
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

  /** Functor 2 **/
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


  Player1 = {PlayerProc} % Get this from functor
  Player2 = {PlayerProc} % Get this from functor

  % Assume Referee is also a thread
  Referee = {RefereeProc Player1 Player2} % Get this from functor

  local Winner in
    {Send Referee startGame(Winner)} % Could also assign players here.
    {System.showInfo "Winner is " # Winner }
  end


  {Delay 500}
  { Exit 0 }

end
