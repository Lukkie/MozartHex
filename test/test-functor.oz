functor
import
  System
  /* QTk at 'x-oz://system/wp/QTk.ozf' */
export
  kaas:Test
  max:Max
define
  /* proc {Test X Y Z}
    if X >= Y then Z = X else Z = Y end
  end */
  proc {Test}
    { System.showInfo 'Hi' }
  end

  proc {Max X Y Z}
    if X >= Y then Z = X else Z = Y end
  end
end
