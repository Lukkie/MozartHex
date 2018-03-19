% 11 by 11 board
functor
import
  Application(exit:Exit)
  System
  /* Browser(browse:Browse) */
  /* Array */

define

  % Werkt perfect
  /* local UsedPort Xs in
    {Port.new Xs UsedPort}
    thread
      for X in Xs do
        { System.showInfo X }
      end
    end

    for I in 1..5 do
      {Port.send UsedPort "hello"}
      {Delay 500}
    end
  end */


  /***********************************/

  /* fun {NewPortObject2 Proc}
    Sin in thread
      for Msg in Sin do
        {Proc Msg}
      end
    end
    {NewPort Sin}
  end


  proc {ServerProc Msg}
    case Msg
    of printArguments(X Client Cont) then
      { System.showInfo X}
      {Send Client Cont}
    [] addNumbers(N1 N2 Client Cont) then
      {Send Client Cont#(N1 + N2)}
    end
  end

  proc {ClientProc Msg}
    case Msg
    of askToPrintArguments(Arguments) then
      {Send Server printArguments(Arguments Client cont1())}
    [] cont1() then
      { System.showInfo 'Received callback from Server for procedure 1' }
    [] askForSum(N1 N2 ?Result) then
      {Send Server addNumbers(N1 N2 Client cont2(Result))}
    [] cont2(Result)#CalculatedResult then
      { System.showInfo 'Received callback from Server for procedure 2' }
      % Now assign the calculated result to the result such that the procedure call is completed (not blocked anymore)
      Result = CalculatedResult
    end
  end


  Server = {NewPortObject2 ServerProc}
  Client = {NewPortObject2 ClientProc}
  {Send Client askToPrintArguments('hello world')}
  {System.showInfo {Send Client askForSum(5 8 $)}} */

  /***************************************/

  /* fun {RefereeProc Player1 Player2 ?RefPort}
    RefPort = {NewPort Sin}
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
          /* {System.showInfo 'Hello worldddd'}
        end
      end
    end
  end

  proc {PlayerProc Referee ?PlayerPort}
    PlayerPort = {NewPort Sin}
    Sin in thread
      for Msg in Sin do
        case Msg
        of askToPrintArguments(Arguments Server) then
          {Send Server printArguments(Arguments PlayerPort cont1())}
        [] cont1() then
          { System.showInfo 'Received callback from Server for procedure 1' }
        [] askForSum(N1 N2 Server ?Result) then
          {Send Server addNumbers(N1 N2 PlayerPort cont2(Result))}
        [] cont2(Result)#CalculatedResult then
          { System.showInfo 'Received callback from Server for procedure 2' }
          % Now assign the calculated result to the result such that the procedure call is completed (not blocked anymore)
          Result = CalculatedResult
        end
      end
    end
  end

  local Referee Player1 Player2 in
    {RefereeProc Player1 Player2 Referee}
    {PlayerProc Referee Player1}
    {PlayerProc Referee Player2}
    {Send Referee startGame()}
    { System.showInfo 'End' }
  end */
  /* {Send Client askToPrintArguments('hello world')}
  {System.showInfo {Send Client askForSum(5 8 $)}}  */

  /***************************************/


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
        of askToPrintArguments(Arguments Server) then
          {Send Server printArguments(Arguments Player cont1())}
        [] cont1() then
          { System.showInfo 'Received callback from Server for procedure 1' }
        [] askForSum(N1 N2 ?Result) then
          {Send Referee addNumbers(N1 N2 cont2(Result))}
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
