require 'fileutils'

namespace :dojos do
  desc 'Git履歴からinactivated_at日付を抽出してYAMLファイルに反映（引数でDojo IDを指定可能）'
  task :extract_inactivated_at_from_git, [:dojo_id] => :environment do |t, args|
    yaml_path = Rails.root.join('db', 'dojos.yaml')
    
    # YAMLファイルの内容を行番号付きで読み込む
    yaml_lines = File.readlines(yaml_path)
    
    # 対象Dojoを決定（引数があれば特定のDojo、なければ全ての非アクティブDojo）
    target_dojos = if args[:dojo_id]
      dojo = Dojo.find(args[:dojo_id])
      puts "=== 特定のDojoのinactivated_at を抽出 ==="
      puts "対象Dojo: #{dojo.name} (ID: #{dojo.id})"
      [dojo]
    else
      inactive_dojos = Dojo.inactive.where(inactivated_at: nil)
      puts "=== Git履歴から inactivated_at を抽出 ==="
      puts "対象となる非アクティブDojo数: #{inactive_dojos.count}"
      inactive_dojos
    end
    
    puts ""
    updated_count = 0
    updates_to_apply = []  # 更新情報を保存する配列
    
    # Phase 1: 全てのDojoの情報を収集（YAMLを変更せずに）
    target_dojos.each do |dojo|
      puts "処理中: #{dojo.name} (ID: #{dojo.id})"
      
      # is_active: false が記載されている行を探す
      target_line_number = nil
      in_dojo_block = false
      
      yaml_lines.each_with_index do |line, index|
        # Dojoブロックの開始を検出
        if line.match?(/^- id: #{dojo.id}$/)
          in_dojo_block = true
        elsif line.match?(/^- id: \d+$/)
          in_dojo_block = false
        end
        
        # 該当Dojoブロック内で is_active: false を見つける
        if in_dojo_block && line.match?(/^\s*is_active: false/)
          target_line_number = index + 1  # git blameは1-indexedなので+1
          # デバッグ: 重要なDojoの行番号を確認
          if [203, 201, 125, 222, 25, 20].include?(dojo.id)
            puts "  [DEBUG] ID #{dojo.id}: is_active:false は #{target_line_number} 行目"
          end
          break
        end
      end
      
      if target_line_number
        # ファイルの行数チェック
        total_lines = yaml_lines.length
        if target_line_number > total_lines
          puts "  ✗ エラー: 行番号 #{target_line_number} が範囲外です（ファイル行数: #{total_lines}）"
          next
        end
        
        # git blame を使って該当行の最新コミット情報を取得
        # --porcelain で解析しやすい形式で出力
        blame_cmd = "git blame #{yaml_path} -L #{target_line_number},+1 --porcelain 2>&1"
        blame_output = `#{blame_cmd}`.strip
        
        # エラーチェック
        if blame_output.include?("fatal:") || blame_output.empty?
          puts "  ✗ Git blameエラー: #{blame_output}"
          next
        end
        
        # コミットIDを抽出（最初の行の最初の要素）
        commit_id = blame_output.lines[0]&.split&.first
        
        if commit_id && commit_id.match?(/^[0-9a-f]{40}$/)
          # コミット情報を取得
          commit_info = `git show --no-patch --format='%at%n%an%n%s' #{commit_id}`.strip.lines
          timestamp = commit_info[0].to_i
          author_name = commit_info[1]
          commit_message = commit_info[2]
          inactivated_date = Time.at(timestamp)
          
          # 特定Dojoモードの場合は情報表示のみ
          if args[:dojo_id]
            puts "✓ is_active: false に設定された日時: #{inactivated_date.strftime('%Y-%m-%d %H:%M:%S')}"
            puts "  コミット: #{commit_id[0..7]}"
            puts "  作者: #{author_name}"
            puts "  メッセージ: #{commit_message}"
            next
          end
          
          # 更新情報を保存（実際の更新は後で一括実行）
          updates_to_apply << {
            dojo_id: dojo.id,
            dojo_name: dojo.name,
            date: inactivated_date,
            commit_id: commit_id,
            author_name: author_name
          }
          
          puts "  ✓ inactivated_at の日付を取得: #{inactivated_date.strftime('%Y-%m-%d %H:%M:%S')}"
          puts "    コミット: #{commit_id[0..7]} by #{author_name}"
        else
          puts "  ✗ コミット情報の取得に失敗"
        end
      else
        puts "  ✗ YAMLファイル内で 'is_active: false' 行が見つかりません"
      end
      
      puts ""
    end
    
    # Phase 2: 収集した情報を元にYAMLファイルを一括更新
    if !args[:dojo_id] && updates_to_apply.any?
      puts "\n=== Phase 2: YAMLファイルを更新 ==="
      puts "#{updates_to_apply.count} 個のDojoを更新します\n\n"
      
      # 更新情報を日付順（ID順）にソート
      updates_to_apply.sort_by! { |u| u[:dojo_id] }
      
      updates_to_apply.each do |update|
        puts "更新中: #{update[:dojo_name]} (ID: #{update[:dojo_id]})"
        
        # YAMLファイルのDojoブロックを見つけて更新
        yaml_lines.each_with_index do |line, index|
          if line.match?(/^- id: #{update[:dojo_id]}$/)
            # 該当Dojoブロックの最後に inactivated_at を追加
            insert_index = index + 1
            while insert_index < yaml_lines.length && !yaml_lines[insert_index].match?(/^- id:/)
              # is_active: false の次の行に挿入したい
              if yaml_lines[insert_index - 1].match?(/is_active: false/)
                # 既に inactivated_at がある場合はスキップ（冪等性）
                if yaml_lines[insert_index].match?(/^\s*inactivated_at:/)
                  puts "  - inactivated_at は既に設定されています"
                  break
                end
                
                yaml_lines.insert(insert_index, 
                  "  inactivated_at: '#{update[:date].strftime('%Y-%m-%d %H:%M:%S')}'\n")
                updated_count += 1
                puts "  ✓ inactivated_at を追加: #{update[:date].strftime('%Y-%m-%d %H:%M:%S')}"
                break
              end
              insert_index += 1
            end
            break
          end
        end
      end
    end
    
    # 全Dojoモードで更新があった場合のみYAMLファイルを書き戻す
    if !args[:dojo_id] && updated_count > 0
      begin
        # バックアップを作成（tmpディレクトリに）
        backup_path = Rails.root.join('tmp', "dojos.yaml.backup.#{Time.now.strftime('%Y%m%d_%H%M%S')}")
        FileUtils.cp(yaml_path, backup_path)
        puts "\n📦 バックアップ作成: #{backup_path}"
        
        # YAMLファイルを更新
        File.write(yaml_path, yaml_lines.join)
        
        # YAML構文チェック（DateとTimeクラスを許可）
        YAML.load_file(yaml_path, permitted_classes: [Date, Time])
        
        puts "\n=== 完了 ==="
        puts "合計 #{updated_count} 個のDojoに inactivated_at を追加しました"
        puts ""
        puts "次のステップ:"
        puts "1. db/dojos.yaml の変更内容を確認"
        puts "2. rails dojos:update_db_by_yaml を実行してDBに反映"
        puts "3. 変更をコミット"
      rescue => e
        puts "\n❌ エラー: YAMLファイルの更新に失敗しました"
        puts "  #{e.message}"
        puts "\n🔙 バックアップから復元中..."
        FileUtils.cp(backup_path, yaml_path) if File.exist?(backup_path)
        puts "  復元完了"
        raise e
      end
    elsif !args[:dojo_id]
      puts "=== 完了 ==="
      puts "更新対象のDojoはありませんでした（または既に設定済み）"
    end
  end
end