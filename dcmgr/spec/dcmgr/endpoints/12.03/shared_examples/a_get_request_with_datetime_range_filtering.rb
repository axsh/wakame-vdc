# -*- coding: utf-8 -*-

shared_examples 'a get request with datetime range filtering' do |param_name, fabricator|
  context "with the '#{param_name}_since' parameter" do
    let(:before_api_call) do
      Fabricate(fabricator, account_id: account.canonical_uuid,
                            "#{param_name}_at".to_sym => time1)

      Fabricate(fabricator, account_id: account.canonical_uuid,
                            "#{param_name}_at".to_sym => time2)

      Fabricate(fabricator, account_id: account.canonical_uuid,
                            "#{param_name}_at".to_sym => time3)
    end

    let(:time1) { Time.now }
    let(:time2) { time1 + 7200 }
    let(:time3) { time2 + 7200 }

    let(:params) { {"#{param_name}_since" => (time2 - 10).iso8601} }

    it "shows only the #{fabricator} #{param_name} since the time passed" do
      expect(body.first["results"].length).to eq 2

      body.first["results"].each do |i|
        expect(Time.iso8601(i["#{param_name}_at"])).to be > (time2 - 10)
      end
    end
  end
end
