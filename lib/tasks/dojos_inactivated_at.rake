namespace :dojos do
  desc 'Git履歴からinactivated_at日付を抽出してYAMLファイルに反映'
  task extract_inactivated_at_from_git: :environment do
    require 'git'
    
    yaml_path = Rails.root.join('db', 'dojos.yaml')
    git = Git.open(Rails.root)
    
    # YAMLファイルの内容を行番号付きで読み込む
    yaml_lines = File.readlines(yaml_path)
    
    # 非アクティブなDojoを取得
    inactive_dojos = Dojo.inactive.where(inactivated_at: nil)
    
    puts "=== Git履歴から inactivated_at を抽出 ==="
    puts "対象となる非アクティブDojo数: #{inactive_dojos.count}"
    puts ""
    
    updated_count = 0
    
    inactive_dojos.each do |dojo|
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
          break
        end
      end
      
      if target_line_number
        # git blame を使って該当行の最新コミット情報を取得
        # --porcelain で解析しやすい形式で出力
        blame_cmd = "git blame #{yaml_path} -L #{target_line_number},+1 --porcelain"
        blame_output = `#{blame_cmd}`.strip
        
        # コミットIDを抽出（最初の行の最初の要素）
        commit_id = blame_output.lines[0].split.first
        
        if commit_id && commit_id.match?(/^[0-9a-f]{40}$/)
          # コミット情報を取得
          commit = git.gcommit(commit_id)
          inactivated_date = commit.author_date
          
          # YAMLファイルのDojoブロックを見つけて更新
          yaml_updated = false
          yaml_lines.each_with_index do |line, index|
            if line.match?(/^- id: #{dojo.id}$/)
              # 該当Dojoブロックの最後に inactivated_at を追加
              insert_index = index + 1
              while insert_index < yaml_lines.length && !yaml_lines[insert_index].match?(/^- id:/)
                # is_active: false の次の行に挿入したい
                if yaml_lines[insert_index - 1].match?(/is_active: false/)
                  yaml_lines.insert(insert_index, 
                    "  inactivated_at: '#{inactivated_date.strftime('%Y-%m-%d %H:%M:%S')}'\n")
                  yaml_updated = true
                  break
                end
                insert_index += 1
              end
              break if yaml_updated
            end
          end
          
          if yaml_updated
            updated_count += 1
            puts "  ✓ inactivated_at を追加: #{inactivated_date.strftime('%Y-%m-%d %H:%M:%S')}"
            puts "    コミット: #{commit_id[0..7]} by #{commit.author.name}"
          else
            puts "  ✗ YAMLファイルの更新に失敗"
          end
        else
          puts "  ✗ コミット情報の取得に失敗"
        end
      else
        puts "  ✗ YAMLファイル内で 'is_active: false' 行が見つかりません"
      end
      
      puts ""
    end
    
    if updated_count > 0
      # YAMLファイルを書き戻す
      File.write(yaml_path, yaml_lines.join)
      
      puts "=== 完了 ==="
      puts "合計 #{updated_count} 個のDojoに inactivated_at を追加しました"
      puts ""
      puts "次のステップ:"
      puts "1. db/dojos.yaml の変更内容を確認"
      puts "2. rails dojos:update_db_by_yaml を実行してDBに反映"
      puts "3. 変更をコミット"
    else
      puts "=== 完了 ==="
      puts "更新対象のDojoはありませんでした"
    end
  end
  
  desc '特定のDojoのinactivated_at日付をGit履歴から抽出'
  task :extract_inactivated_at_for_dojo, [:dojo_id] => :environment do |t, args|
    require 'git'
    
    dojo = Dojo.find(args[:dojo_id])
    yaml_path = Rails.root.join('db', 'dojos.yaml')
    git = Git.open(Rails.root)
    
    puts "対象Dojo: #{dojo.name} (ID: #{dojo.id})"
    
    # YAMLファイルの内容を読み込む
    yaml_lines = File.readlines(yaml_path)
    
    # is_active: false が記載されている行を探す
    target_line_number = nil
    in_dojo_block = false
    
    yaml_lines.each_with_index do |line, index|
      if line.match?(/^- id: #{dojo.id}$/)
        in_dojo_block = true
      elsif line.match?(/^- id: \d+$/)
        in_dojo_block = false
      end
      
      if in_dojo_block && line.match?(/^\s*is_active: false/)
        target_line_number = index + 1
        break
      end
    end
    
    if target_line_number
      blame_cmd = "git blame #{yaml_path} -L #{target_line_number},+1 --porcelain"
      blame_output = `#{blame_cmd}`.strip
      commit_id = blame_output.lines[0].split.first
      
      if commit_id && commit_id.match?(/^[0-9a-f]{40}$/)
        commit = git.gcommit(commit_id)
        inactivated_date = commit.author_date
        
        puts "✓ is_active: false に設定された日時: #{inactivated_date.strftime('%Y-%m-%d %H:%M:%S')}"
        puts "  コミット: #{commit_id[0..7]}"
        puts "  作者: #{commit.author.name}"
        puts "  メッセージ: #{commit.message.lines.first.strip}"
      else
        puts "✗ コミット情報の取得に失敗しました"
      end
    else
      puts "✗ YAMLファイル内で 'is_active: false' 行が見つかりません"
    end
  end
end