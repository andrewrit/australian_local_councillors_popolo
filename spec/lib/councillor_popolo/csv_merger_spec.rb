require('./lib/councillor_popolo')

describe CouncillorPopolo::CSVMerger do
  let(:master_csv_path) { "./spec/fixtures/local_councillors_master.csv" }
  let(:changes_csv_path) { "./spec/fixtures/local_councillors_changes.csv" }
  let(:csv_headers) { ["name", "start_date", "end_date", "executive", "council", "council website", "id", "email", "image", "party", "source", "ward", "phone_mobile"] }
  let(:pre_existing_councillor_row) { ["Julia Chessell", "", "", "", "Foo City Council", "http://www.foo.nsw.gov.au", "foo_city_council/julia_chessell", "jches@foocity.nsw.gov.au", "http://www.foo.nsw.gov.au/__data/assets/image/0018/11547/julia.jpg", "Independent", "http://www.foo.nsw.gov.au/inside-foo/about-council/councillors", "", ""] }
  let(:henare) { ["Henare Degan", "", "", "", "Foo City Council", "http://www.foo.nsw.gov.au", "foo_city_council/henare_degan", "hdegan@foocity.nsw.gov.au", "http://www.foo.nsw.gov.au/__data/assets/image/0018/11547/henare.jpg", "Party Party Party", "http://www.foo.nsw.gov.au/inside-foo/about-council/councillors", "", ""] }
  let(:hisayo) { ["Hisayo Horie", "", "", "", "Foo City Council", "http://www.foo.nsw.gov.au", "foo_city_council/hisayo_horie", "hhorie@foocity.nsw.gov.au", "http://www.foo.nsw.gov.au/__data/assets/image/0018/11547/hisayo.jpg", "Make Toronto Nice Party", "http://www.foo.nsw.gov.au/inside-foo/about-council/councillors", "", ""] }
  let(:new_councillor_rows) do
    [ henare, hisayo ]
  end

  before do
    CSV.open(master_csv_path, "w") do |csv|
      csv << csv_headers
      csv << pre_existing_councillor_row
    end

    CSV.open(changes_csv_path, "w") do |csv|
      csv << ["name", "start_date", "end_date", "executive", "council", "council website", "id", "email", "image", "party", "source", "ward", "phone_mobile"]
      new_councillor_rows.each do |row|
        csv << row
      end
    end
  end

  after do
    File.delete(master_csv_path)
    File.delete(changes_csv_path)
  end

  it "won't initialize without a master_csv_path" do
    expect { CouncillorPopolo::CSVMerger.new(changes_csv_path: changes_csv_path) }.
      to raise_error(ArgumentError, "missing keyword: master_csv_path")
  end

  it "won't initialize without a changes_csv_path" do
    expect { CouncillorPopolo::CSVMerger.new(master_csv_path: master_csv_path) }.
      to raise_error(ArgumentError, "missing keyword: changes_csv_path")
  end


  describe ".merge" do
    context "when the current CSV does not contain councillors with ids of the councillors to be incorporated" do
      it "doesn't alter the existing councillor rows" do
        CouncillorPopolo::CSVMerger.new(
          master_csv_path: master_csv_path,
          changes_csv_path: changes_csv_path
        ).merge

        expect(CSV.read(master_csv_path, headers: true).first.fields).to eql(
          pre_existing_councillor_row
        )
      end

      it "appends them to the file" do
        CouncillorPopolo::CSVMerger.new(
          master_csv_path: master_csv_path,
          changes_csv_path: changes_csv_path
        ).merge

        expect(CSV.read(master_csv_path, headers: true).to_a).to eql [
          csv_headers,
          pre_existing_councillor_row,
          henare,
          hisayo
        ]
      end
    end

    context "when the current CSV contains councillors with ids of the councillors to be incorporated" do
      let(:pre_existing_henare_row) { ["Henare Degan", "2010-09-01", "", "", "Foo City Council", "http://www.foo.nsw.gov.au", "foo_city_council/henare_degan", "", "", "", "", "", ""] }
      let(:expected_henare_row) { ["Henare Degan", "2010-09-01", "", "", "Foo City Council", "http://www.foo.nsw.gov.au", "foo_city_council/henare_degan", "hdegan@foocity.nsw.gov.au", "http://www.foo.nsw.gov.au/__data/assets/image/0018/11547/henare.jpg", "Party Party Party", "http://www.foo.nsw.gov.au/inside-foo/about-council/councillors", "", ""] }
      let(:row_with_change_to_pre_existing_councillor) { ["Julia Chessell", "", "2017-09-28", "", "Foo City Council", "", "foo_city_council/julia_chessell", "", "", "", "", "", ""] }
      let(:expected_updated_pre_existing_councillor) { ["Julia Chessell", "", "2017-09-28", "", "Foo City Council", "http://www.foo.nsw.gov.au", "foo_city_council/julia_chessell", "jches@foocity.nsw.gov.au", "http://www.foo.nsw.gov.au/__data/assets/image/0018/11547/julia.jpg", "Independent", "http://www.foo.nsw.gov.au/inside-foo/about-council/councillors", "", ""] }

      before do
        CSV.open(master_csv_path, "a+", headers: true) do |master_csv|
          master_csv << pre_existing_henare_row
        end

        CSV.open(changes_csv_path, "a+", headers: true) do |changes_csv|
          changes_csv << row_with_change_to_pre_existing_councillor
        end
      end

      it "incorporates the changes into the existing row for those councillors" do
        CouncillorPopolo::CSVMerger.new(
          master_csv_path: master_csv_path,
          changes_csv_path: changes_csv_path
        ).merge

        expect(CSV.read(master_csv_path, headers: true).to_a).to eql [
          csv_headers,
          expected_updated_pre_existing_councillor,
          expected_henare_row,
          hisayo
        ]
      end
    end

    context "when the changes CSV file's headers don't match the master CSV's" do
      let(:csv_with_bad_headers_path) { "./spec/fixtures/local_councillors_changes_with_bad_headers.csv" }

      before do
        CSV.open(csv_with_bad_headers_path, "w") do |csv|
          csv << ["foo", "bar", "baz", "zapadooo"]
          new_councillor_rows.each do |row|
            csv << row
          end
        end
      end

      after { File.delete(csv_with_bad_headers_path) }

      subject { CouncillorPopolo::CSVMerger.new(master_csv_path: master_csv_path, changes_csv_path: csv_with_bad_headers_path) }

      it { expect{ subject.merge }.to raise_error CouncillorPopolo::HeaderMismatchError }
    end
  end

  describe "#changes_csv_valid?" do
    context "when the changes CSV file's headers don't match the master CSV's" do
      let(:csv_with_bad_headers_path) { "./spec/fixtures/local_councillors_changes_with_bad_headers.csv" }

      before do
        CSV.open(csv_with_bad_headers_path, "w") do |csv|
          csv << ["foo", "bar", "baz", "zapadooo"]
          new_councillor_rows.each do |row|
            csv << row
          end
        end
      end

      after { File.delete(csv_with_bad_headers_path) }

      subject do
        CouncillorPopolo::CSVMerger.new(
          master_csv_path: master_csv_path,
          changes_csv_path: csv_with_bad_headers_path
        ).changes_csv_valid?
      end

      it { is_expected.to be false }
    end

    context "when the changes CSV file's headers match the master CSV's" do
      subject do
        CouncillorPopolo::CSVMerger.new(
          master_csv_path: master_csv_path,
          changes_csv_path: changes_csv_path
        ).changes_csv_valid?
      end

      it { is_expected.to be true }
    end
  end
end