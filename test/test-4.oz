% 11 by 11 board
functor
import
  Application(exit:Exit)
  System

define

  A = {List.make 5}
  B = A

  {List.nth A 3} = 'hello'


  {System.printInfo {List.nth A 3}}
  {System.printInfo {List.nth B 3}}


  { Exit 0 }

end
