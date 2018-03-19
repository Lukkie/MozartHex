functor
import
  Application(exit:Exit)
  System
  /* QTk at 'x-oz://system/wp/QTk.ozf' */
define
  A = [1 2 3 4]
  B = [5 6 7 8]
  for X in A Y in B do
    { System.showInfo X#Y }
  end


  % HELEMAAL NIET ZEKER VAN
  proc {Producer Xs} % Xs is shared with the Consumer thread.
    case Xs of X|Xr then % Blocks until Xs gains a value (or Xr??? )
      X = volvo
      {Producer Xr}
    [] nil then {System.showInfo 'end of line'}
    end
  end
  proc {Consumer N Xs}
     if N=<0 then Xs=nil
     else X|Xr = Xs in % Take the first value of Xs and store in X, rest is kept in Xr
                        % Also waits until this value is available, I guess.
        if X == volvo then
           if N mod 1000 == 0 then
              {System.showInfo 'riding a new volvo'}
           end
           {Consumer N-1 Xr}
        else
           {Consumer N Xr}
        end
     end
  end
  {Consumer 10000 thread {Producer $} end} % $ betekent dat het argument van Producer (Xs) als argument voor Consumer meegegeven wordt


  fun {Kaas LIJST B}
    B = 1
    {System.showInfo {Length LIJST}}
    2

  end

  local C D
    D = [4 5 6]
    {System.showInfo {Kaas D C} # C}
  end



  proc {ReturnFifteen ?Fifteen} % Variables start with upper case, atoms with lower case!
    Fifteen = 15
  end
  {System.showInfo 'The number is '#{ReturnFifteen $}}

  { Exit 0 }
end
