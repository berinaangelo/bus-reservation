class BusUnit < ApplicationRecord
  belongs_to :operator
  has_many :seats, dependent: :destroy
  has_many :trips, dependent: :restrict_with_error

  validates :plate_number, presence: true, uniqueness: true
  validates :total_seats, presence: true, numericality: { greater_than: 0 }

  # Maps an incoming bus_class param (as used by FareRule.bus_class) to the concrete STI subclass
  # to instantiate/become. There's no bus_class column on bus_units -- the "class" IS the STI
  # subclass (see `type`). Raises ArgumentError on an unknown key, which ApplicationController
  # already rescues globally into a 400.
  #
  # NOT named `sti_class_for` -- that's ActiveRecord::Inheritance's own internal hook
  # (`find_sti_class` calls exactly that method name to resolve a loaded row's `type` column back
  # to a class), and overriding it here broke every load of a BusUnit row from the DB.
  BUS_CLASSES = {
    "ordinary" => "OrdinaryBusUnit",
    "aircon" => "AirconBusUnit",
    "deluxe" => "DeluxeBusUnit",
    "double_deck" => "DoubleDeckBusUnit"
  }.freeze

  def self.class_for_bus_class(bus_class)
    BUS_CLASSES.fetch(bus_class.to_s) { raise ArgumentError, "Unknown bus_class: #{bus_class}" }.constantize
  end

  # Every STI subclass shares one Pundit policy -- without this, Pundit's per-class lookup would
  # need an AirconBusUnitPolicy/DeluxeBusUnitPolicy/etc. for each concrete subtype.
  def self.policy_class
    BusUnitPolicy
  end

  # Whether this bus_class uses a seat map (TripSeat rows) vs. a plain seat-count fallback.
  # Overridden by ReservableBusUnit.
  def reservable?
    false
  end

  # Deck labels seats on this bus are laid out across. Overridden by DoubleDeckBusUnit.
  def decks
    [ nil ]
  end

  # Maps the STI type to the matching FareRule.bus_class enum key, e.g. AirconBusUnit -> :aircon.
  def fare_class
    self.class.name.underscore.delete_suffix("_bus_unit").to_sym
  end
end
