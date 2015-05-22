# -*- coding: utf-8 -*-

shared_examples "malformed vifs" do
  context "with a malformed vifs parameter" do
    let(:vifs_parameter) { "JOSSEFIEN!" }

    it { is_expected.to raise_error Dcmgr::Scheduler::NetworkSchedulingError }
  end
end
