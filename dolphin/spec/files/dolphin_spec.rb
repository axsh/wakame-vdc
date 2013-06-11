# -*- coding: utf-8 -*-

require 'rubygems'
require 'spec_helper'
require 'net/http'

require File.join(File.expand_path('../../../', __FILE__), 'lib/dolphin')

describe 'Notification Service' do

  describe Dolphin::RequestHandler do
    context "リクエストパラメータを入力したとき" do
      it "リクエストに成功すること" do
      end

      describe "リクエストに失敗すること" do
      end
    end
  end

  describe Dolphin::Manager do
    it "開始できること" do
    end

    it "停止できること" do
    end

    it "Workerを起動できること" do
    end

    it "Workerを停止できること" do
    end

    it "RequestHandlerを起動できること" do
    end

    it "RequestHandlerを停止できること" do
    end

  end

  describe Dolphin::Worker do

    context "EventObjectを入力したとき" do
      it "Senderにメッセージが送れること" do
      end
    end
  end

  describe Dolphin::QueryProcessor do

    it "宛先情報を取得できること" do
    end

    it "イベントを記録できること" do
    end
  end

  describe Dolphin::Sender do

    context "ファイル出力を選択したとき" do
      it "ファイルに保存できること" do
      end
    end

    context "メールサーバーが設定されているとき", :smtp => true  do
      it "送信できること" do
      end
    end

  end

  describe Dolphin::DataBase do

    context "設定ファイルを入力したとき" do
      it "Cassandraデータベースに接続できること" do
      end
    end

    context "Cassandraデータベースに接続できたとき" do

      it "Eventを保存できること" do
      end

      it "Eventを取得できること" do
      end

      it "Notificationを保存できること" do
      end

      it "Notificationを取得できること" do
      end

    end

  end

  describe Dolphin::Util do
    context "ログタイプにstdoutを選択したとき" do
      it "ログが書き込めること" do
      end
    end

    context "ログタイプにltsvを選択したとき" do
      it "ログが書き込めること" do
      end
    end
  end

end