class DoubleDeckBusUnit < ReservableBusUnit
  def decks
    %i[lower upper]
  end
end
