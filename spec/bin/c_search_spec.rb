require 'spec_helper'
require 'open3'
require 'net/http'
require 'connpass_api_v2'

RSpec.describe 'bin/c-search' do
  let(:script_path) { File.expand_path('../../bin/c-search', __dir__) }
  let(:api_key) { 'test_api_key_123' }
  
  before do
    ENV['CONNPASS_API_KEY'] = api_key
  end
  
  after do
    ENV.delete('CONNPASS_API_KEY')
  end
  
  describe '使い方の表示' do
    context '引数なしで実行した場合' do
      it 'Usageメッセージを表示して終了コード1を返す' do
        output, error, status = Open3.capture3({"CONNPASS_API_KEY" => api_key}, "bundle", "exec", "ruby", script_path)
        
        expect(status.exitstatus).to eq(1)
        expect(output).to include('Usage: c-search [CONNPASS_URL | CONNPASS_EVENT_ID]')
        expect(output).to include('例: c-search https://coderdojoaoyama.connpass.com/')
        expect(output).to include('例: c-search https://coderdojoaoyama.connpass.com/event/356972/')
        expect(output).to include('例: c-search 356972')
      end
    end
    
    context 'CONNPASS_API_KEYが設定されていない場合' do
      before { ENV.delete('CONNPASS_API_KEY') }
      
      it 'エラーメッセージを表示して終了コード1を返す' do
        output, error, status = Open3.capture3({}, "bundle", "exec", "ruby", script_path, "123456")
        
        expect(status.exitstatus).to eq(1)
        expect(output).to include('CONNPASS_API_KEY が設定されていません')
      end
    end
  end
  
  describe 'イベントIDでの検索（既存機能）' do
    context '数字のみを指定した場合' do
      it 'イベントAPIを呼び出してgroup_idを表示する' do
        # ConnpassApiV2 gemのモック
        mock_client = double('ConnpassApiV2::Client')
        mock_result = double('result', 
          results_returned: 1,
          events: [{
            'id' => 356972,
            'title' => 'CoderDojo 青山',
            'group' => { 'id' => 1234, 'title' => 'CoderDojo 青山' }
          }]
        )
        
        allow(ConnpassApiV2).to receive(:client).with(api_key).and_return(mock_client)
        allow(mock_client).to receive(:get_events).with(event_id: '356972').and_return(mock_result)
        
        output, error, status = Open3.capture3({"CONNPASS_API_KEY" => api_key}, "bundle", "exec", "ruby", script_path, "356972")
        
        if status.exitstatus != 0
          puts "Error output: #{error}"
          puts "Standard output: #{output}"
        end
        
        expect(status.exitstatus).to eq(0)
        expect(output.strip).to eq('1234')
      end
    end
    
    context 'イベントが見つからない場合' do
      it 'エラーメッセージを表示して終了コード1を返す' do
        mock_client = double('ConnpassApiV2::Client')
        mock_result = double('result', results_returned: 0, events: [])
        
        allow(ConnpassApiV2).to receive(:client).with(api_key).and_return(mock_client)
        allow(mock_client).to receive(:get_events).with(event_id: '999999').and_return(mock_result)
        
        output, error, status = Open3.capture3({"CONNPASS_API_KEY" => api_key}, "bundle", "exec", "ruby", script_path, "999999")
        
        expect(status.exitstatus).to eq(1)
        expect(output).to include('イベントが見つかりませんでした (event_id: 999999)')
      end
    end
  end
  
  describe 'イベントURLでの検索（既存機能）' do
    context 'HTTPSのイベントURLを指定した場合' do
      it 'URLからイベントIDを抽出してAPIを呼び出す' do
        mock_client = double('ConnpassApiV2::Client')
        mock_result = double('result',
          results_returned: 1,
          events: [{
            'id' => 356972,
            'group' => { 'id' => 1234 }
          }]
        )
        
        allow(ConnpassApiV2).to receive(:client).with(api_key).and_return(mock_client)
        allow(mock_client).to receive(:get_events).with(event_id: '356972').and_return(mock_result)
        
        output, error, status = Open3.capture3({"CONNPASS_API_KEY" => api_key}, "bundle", "exec", "ruby", script_path, "https://coderdojoaoyama.connpass.com/event/356972/")
        
        expect(status.exitstatus).to eq(0)
        expect(output.strip).to eq('1234')
      end
    end
  end
  
  describe 'グループURLでの検索（新機能）' do
    context 'HTTPSのグループURLを指定した場合' do
      it 'URLからサブドメインを抽出してグループAPIを呼び出す' do
        # Net::HTTPのモック
        mock_response = double('response',
          code: '200',
          body: {
            total_items: 1,
            groups: [{
              id: 1234,
              title: 'CoderDojo 青山',
              subdomain: 'coderdojoaoyama'
            }]
          }.to_json
        )
        
        allow(Net::HTTP).to receive(:start).and_yield(double('http').tap do |http|
          allow(http).to receive(:request).and_return(mock_response)
        end)
        
        output, error, status = Open3.capture3({"CONNPASS_API_KEY" => api_key}, "bundle", "exec", "ruby", script_path, "https://coderdojoaoyama.connpass.com/")
        
        expect(status.exitstatus).to eq(0)
        expect(output.strip).to eq('1234')
      end
    end
    
    context 'グループが見つからない場合' do
      it 'エラーメッセージを表示して終了コード1を返す' do
        mock_response = double('response',
          code: '200',
          body: { total_items: 0, groups: [] }.to_json
        )
        
        allow(Net::HTTP).to receive(:start).and_yield(double('http').tap do |http|
          allow(http).to receive(:request).and_return(mock_response)
        end)
        
        output, error, status = Open3.capture3({"CONNPASS_API_KEY" => api_key}, "bundle", "exec", "ruby", script_path, "https://nonexistent.connpass.com/")
        
        expect(status.exitstatus).to eq(1)
        expect(output).to include('グループが見つかりませんでした (subdomain: nonexistent)')
      end
    end
    
    context 'APIが404を返す場合' do
      it 'エラーメッセージを表示して終了コード1を返す' do
        mock_response = Net::HTTPNotFound.new('1.1', '404', 'Not Found')
        allow(mock_response).to receive(:body).and_return('')
        
        allow(Net::HTTP).to receive(:start).and_yield(double('http').tap do |http|
          allow(http).to receive(:request).and_return(mock_response)
        end)
        
        output, error, status = Open3.capture3({"CONNPASS_API_KEY" => api_key}, "bundle", "exec", "ruby", script_path, "https://notfound.connpass.com/")
        
        expect(status.exitstatus).to eq(1)
        expect(output).to include('グループが見つかりませんでした (subdomain: notfound)')
      end
    end
    
    context 'APIエラーが発生した場合' do
      it 'エラーメッセージを表示して終了コード1を返す' do
        mock_response = Net::HTTPInternalServerError.new('1.1', '500', 'Internal Server Error')
        allow(mock_response).to receive(:body).and_return('Internal Server Error')
        
        allow(Net::HTTP).to receive(:start).and_yield(double('http').tap do |http|
          allow(http).to receive(:request).and_return(mock_response)
        end)
        
        output, error, status = Open3.capture3({"CONNPASS_API_KEY" => api_key}, "bundle", "exec", "ruby", script_path, "https://error.connpass.com/")
        
        expect(status.exitstatus).to eq(1)
        expect(output).to include('APIエラー: 500')
      end
    end
    
    context 'タイムアウトが発生した場合' do
      it 'タイムアウトメッセージを表示して終了コード1を返す' do
        allow(Net::HTTP).to receive(:start).and_raise(Timeout::Error.new('execution expired'))
        
        output, error, status = Open3.capture3({"CONNPASS_API_KEY" => api_key}, "bundle", "exec", "ruby", script_path, "https://timeout.connpass.com/")
        
        expect(status.exitstatus).to eq(1)
        expect(output).to include('APIへの接続がタイムアウトしました')
      end
    end
  end
  
  describe 'セキュリティバリデーション' do
    context 'HTTPのURLを指定した場合' do
      it 'HTTPSを要求するエラーメッセージを表示する' do
        output, error, status = Open3.capture3({"CONNPASS_API_KEY" => api_key}, "bundle", "exec", "ruby", script_path, "http://coderdojoaoyama.connpass.com/")
        
        expect(status.exitstatus).to eq(1)
        expect(output).to include('HTTPSのURLを指定してください')
      end
    end
    
    context 'Connpass以外のドメインを指定した場合' do
      it 'Connpassドメインを要求するエラーメッセージを表示する' do
        output, error, status = Open3.capture3({"CONNPASS_API_KEY" => api_key}, "bundle", "exec", "ruby", script_path, "https://example.com/")
        
        expect(status.exitstatus).to eq(1)
        expect(output).to include('Connpass のURLを指定してください')
      end
    end
    
    context '無効なURLを指定した場合' do
      it '無効なURLエラーメッセージを表示する' do
        output, error, status = Open3.capture3({"CONNPASS_API_KEY" => api_key}, "bundle", "exec", "ruby", script_path, "https://[invalid")
        
        expect(status.exitstatus).to eq(1)
        expect(output).to include('無効なURLです')
      end
    end
    
    context '認識できないURLパターンの場合' do
      it '認識できないパターンエラーを表示する' do
        output, error, status = Open3.capture3({"CONNPASS_API_KEY" => api_key}, "bundle", "exec", "ruby", script_path, "https://coderdojoaoyama.connpass.com/about/")
        
        expect(status.exitstatus).to eq(1)
        expect(output).to include('認識できないURLパターンです')
      end
    end
  end
end