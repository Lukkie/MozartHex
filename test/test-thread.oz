functor
import
   Browser(browse:Browse) %Import Browse form Browser module
   Application
define
   proc {Ping N}
      if N==0 then
        {Browse 'ping terminated'}
      else
        {Delay 500}
        {Browse ping}
        {Ping N-1}
      end
   end
   proc {Pong N}
      {For 1 N 1
         proc {$ I} {Delay 100} {Browse pong} end }
      {Browse 'pong terminated'}
   end
   X1 X2
in
   {Browse 'game started'}
   thread {Ping 5} X1=unit end
   thread {Pong 5} X2=X1 end
   {Wait X2} % Synchronized on 'unit' locks. If Pong is finished earlier, it will wait for assignment of X1. If all are assigned, lock is opened.
              % AKA Thread Termination-Detection
   {Application.exit 0}
end
