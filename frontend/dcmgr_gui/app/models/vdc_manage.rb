# -*- coding: utf-8 -*-
require 'logger'

#　VDC manage 実行ベースクラス
class VdcManage
  # 操作対象取得（継承クラスでオーバライド）
  def self.get_name
  end

  # UUIDに付くプレフィクス（継承クラスでオーバライド）
  def self.get_prefix
  end

  # ノード名に付くプレフィクス（継承クラスでオーバライド）
  def self.get_nodeid_prefix
  end

  # 固定部分（必須指定）のコマンド記述
  def self.head_desc(subcom,required) 
    @commands = [];
    # 対象(host,storage,...)
    @commands.push(get_name())
    # 動作(add,del,...)
    @commands.push(subcom)
    # 必須パラメータ（コマンド依存）
    if required != "" then
      if subcom == "add" then 
        prefix = get_nodeid_prefix()
        if prefix != "" then
          regex = /^#{prefix}/
          if required !~ regex then
            required = "%s.%s" % [prefix,required]
          end
        end
      end

      # 引数の必須パラメータ
      @commands.push(required)
      # -force指定 環境設定シェルでは付いているので
      @commands.push(get_force_param())
    end
  end

  # 登録系コマンドの実行
  def self.exec(cmd,d_options,i_options,required)
    # 固定部配列セット
    head_desc(cmd,required)
    # 任意部を配列に追加
    if cmd != "del" then
      connect_options(d_options,i_options)
    end
    # コマンド文字列を組み立て
    command_str = make_str()
    # 実行
    r = issue(command_str,cmd) 
  end

  # 情報取得系コマンド実行
  def self.info(cmd)
    # 固定部配列セット
    head_desc(cmd,"")
    # コマンド文字列を組み立て
    command_str = make_str()
    # 実行
    r = issue(command_str,cmd)
  end

  # 任意パラメータ
  def self.connect_options(d_options,i_options)
    @pattern = "";
    
    # 指定されたパラメータが、そのコマンドで定義されていればオプション形式で配列格納
    i_options.each {         
      |k,v| if d_options.rindex(k) && v != "" then 
              @commands.push("--" + k + "=\"" + v + "\"")
           end
    }
  end

  # 配列内容を文字列につなぐ。cdコマンドを付加
  def self.make_str()
    s = @commands.join(" ")
    s = "%s 2>&1" % [s]
  end

  # コマンドを実行
  def self.issue(command_str,cmd)
    dcmgr_path = DcmgrGui::Application.config.dcmgr_path
    ssh = 'ssh root@`hostname`'
    ruby_path = "#{dcmgr_path}/ruby/bin"
    gem_home = "GEM_HOME=#{dcmgr_path}/.vender/bundle/ruby/1.9.1"
    bundle_gem_file = "BUNDLE_GEMFILE=#{dcmgr_path}/Gemfile"
    export = "export PATH=$PATH:#{ruby_path};#{gem_home};#{bundle_gem_file};cd #{dcmgr_path};"
    exec_cmd = "#{ssh} #{export} ./bin/vdc-manage #{command_str}"
    Rails.logger.info("REMOTE COMMAND[#{exec_cmd}]")
    r = `#{exec_cmd}`
    if $?.exitstatus != 0
      # コマンドステータスが0以外
      ret = { "message" => "errmsg_%s_%s_failure" % [get_prefix(),cmd] ,
              "exitcode" => $?.exitstatus,
              "detail" => r }
    else
      # add時は成功のときにはUUIDが返却される
      if cmd == "add" then
        prefix = get_prefix()
        regex = /^#{prefix}-[\w]+$/
        if r =~ regex then
          ret = { "message" => "msg_%s_%s_success" % [get_prefix(),cmd] ,
              "exitcode" => $?.exitstatus,
              "detail" => r }
        else
          # ノードIDでないときは何かエラー
          ret = { "message" => "errmsg_%s_%s_failure" % [get_prefix(),cmd] ,
              "exitcode" => 9999,
              "detail" => r }
        end
      else
          # add以外は０返却なら成功
          ret = { "message" => "msg_%s_%s_success" % [get_prefix(),cmd] ,
              "exitcode" => 0,
              "detail" => r }
      end
    end
  end
end
