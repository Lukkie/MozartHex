% 11 by 11 board
functor
import
  Application(exit:Exit)
  System

define
  fun {RefereeProc}
    Sin in thread
      for Msg in Sin do
        case Msg
        of printArguments(X Client Cont) then
          { System.showInfo X}
          {Send Client Cont}
        [] addNumbers(N1 N2 Client Cont) then
          {Send Client Cont#(N1 + N2)}
        [] startGame() then
          /* {Send Player1 askToPrintArguments('hello world')}
          {System.showInfo {Send Client askForSum(5 8 $)}} */
          {System.showInfo 'Hello worldddd'}
        end
      end
    end
    {NewPort Sin}
  end

  fun {PlayerProc}
    Sin in thread
      for Msg in Sin do
        case Msg
        of askToPrintArguments(Arguments) then
          {Send Referee printArguments(Arguments Player cont1())}
        [] cont1() then
          { System.showInfo 'Received callback from Server for procedure 1' }
        [] askForSum(N1 N2 ?Result) then
          {Send Referee addNumbers(N1 N2 Player cont2(Result))}
        [] cont2(Result)#CalculatedResult then
          { System.showInfo 'Received callback from Server for procedure 2' }
          % Now assign the calculated result to the result such that the procedure call is completed (not blocked anymore)
          Result = CalculatedResult
        end
      end
    end
    {NewPort Sin}
  end


  Referee = {RefereeProc}
  Player = {PlayerProc}
  {Send Player askToPrintArguments('hello world')}
  {System.showInfo {Send Player askForSum(5 8 $)}}


  { Exit 0 }

end
