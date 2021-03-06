module CouncillorPopolo
  class Processor
    attr_reader :state

    def initialize(state:)
      @state = state
    end

    def update_popolo_for_state
      if state_csv_valid?
        json = JSON.pretty_generate(Popolo::CSV.new(csv_path_for_state).data)

        File.open(json_path_for_state, "w") { |f| f << json }
      end
    end

    def state_csv_valid?
      CouncillorPopolo::CSVValidator.new(csv_path_for_state).validate
    end

    def duplicate_councillor_ids_in_state_csv
      CouncillorPopolo::CSVValidator.new(csv_path_for_state).duplicate_councillor_ids
    end

    def json_path_for_state
      "data/#{state.upcase}/local_councillor_popolo.json"
    end

    def csv_path_for_state
      "data/#{state.upcase}/local_councillors.csv"
    end
  end
end
