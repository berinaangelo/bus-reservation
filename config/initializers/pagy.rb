# frozen_string_literal: true

# Sitewide default page size. See kos/decisions/rails-pagination-and-batch-export-processing.md
#
# `Pagy::Method#pagy` (included on ApplicationController) covers both pagination styles used in
# this app:
#   pagy(collection)                # page-based (operator admin lists, manifest)
#   pagy(:keyset, collection)       # trip search results — collection pre-ordered
#                                    # (departure_at, id) asc, per the decision doc
Pagy::OPTIONS[:limit] = 20
Pagy::OPTIONS.freeze
