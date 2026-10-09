# frozen_string_literal: true

# Special Builder's Stimulus controller, loaded with the admin's own: special-builder--board.
pin_all_from SpecialBuilder::Engine.root.join("app/javascript/controllers/special_builder"),
  under: "controllers/special_builder", to: "controllers/special_builder"
