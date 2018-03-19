functor
import
  Test at 'test-functor.ozf'
  Application(exit:Exit)
  System
define
  { Test.kaas }
  X = 10
  Y = 13
  { System.showInfo { Test.max X Y } }
  { Exit 0 }
end
