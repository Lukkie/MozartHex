% 11 by 11 board
functor
import
  Application(exit:Exit)
  System
  /* Browser(browse:Browse) */
  /* Array */

define
  BOARD_SIZE = 3

  A = {Cell.new 15}
  {System.showInfo {Cell.access A}}

  {Cell.assign A {Cell.access A}+5}
  {System.showInfo {Cell.access A}}

  A:=@A+5
  {System.showInfo {Cell.access A}}

  Zin = {Cell.new "test"}
  {System.showInfo @Zin}


  Zin := @Zin # " hello \nworld"
  {System.showInfo @Zin}

  /* {Time.delay 5000} */
  { Exit 0 }

end
