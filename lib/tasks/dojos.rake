#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'json'
require 'yaml'
require 'csv'

namespace :dojos do
  # NOTE: 2020年1月中はコメントアウトで残し、もし必要になる場面が無ければ翌月以降に削除する
  # desc 'Parseから出力したjsonファイルをベースに、yamlファイルを生成します'
  # task generate_yaml: :environment do
  #   dojos = JSON.parse(File.read(Rails.root.join('db', 'parse_backup.json')))['results']
  #   dojos.sort_by! { |hash| hash['order'] }
  #
  #   # Tweak dojo info if needed
  #   dojos.each do |dojo|
  #     dojo['description'].strip!
  #     dojo.delete 'objectId'  # Delete Parse-specific key
  #     dojo.delete 'createdAt' # This is managed by database
  #     dojo.delete 'updatedAt' # This is managed by database
  #   end
  #
  #   Dojo.dump_attributes_to_yaml(dojos)
  # end

  desc '現在のyamlファイルを元にデータベースを更新します'
  task update_db_by_yaml: :environment do
    dojos = Dojo.load_attributes_from_yaml

    # DB 反映する前に YAML データをチェックする
    # https://railsguides.jp/error_reporting.html
    #
    # 全行を検証してから書き始める。1 行でも不正なら、DB を触る前に止まる
    dojos.each { |dojo| raise_if_invalid_dojo(dojo) }

    # YAML と一致しなくなった global_club_id を先に解放する。
    #
    # このタスクは行ごとに save! するだけで、YAML に無い DB 行は消さない。
    # そのため「UUID を道場 A から B へ移す」編集は、YAML 内に重複が生じないので
    # CI をすり抜け、本番 DB の既存行との衝突としてのみ現れる。毎デプロイ走る
    # タスクなので、当たると release ごと止まる。
    #
    # A と B の入れ替えや、DB にだけ残った行が UUID を握っている場合も同じ。
    # 後者はリポジトリのどこにも重複が見えないため、原因にたどり着きにくい。
    # 先に解放しておけば、いずれも 1 回のデプロイで解決する。
    expected_global_club_id = dojos.to_h { |dojo| [dojo['id'], dojo['global_club_id'].presence] }
    Dojo.where.not(global_club_id: nil).find_each do |d|
      d.update_columns(global_club_id: nil) if expected_global_club_id[d.id] != d.global_club_id
    end

    dojos.each do |dojo|
      d = Dojo.find_or_initialize_by(id: dojo['id'])
      d.name           = dojo['name']
      d.counter        = dojo['counter'] || 1
      d.email          = ''
      d.description    = dojo['description']
      d.logo           = dojo['logo']
      d.tags           = dojo['tags']
      d.note           = dojo['note'] || '' # For internal comments for developers
      d.url            = dojo['url']
      d.prefecture_id  = dojo['prefecture_id']
      d.order          = dojo['order'] || search_order_number_by(dojo['name'])
      d.is_private     = dojo['is_private'].nil? ? false : dojo['is_private']
      # 空文字は nil に落とす。DB のユニークインデックスは NULL を重複とみなさないが、
      # 空文字は 2 件目で落ちるため（値を持たない道場が 78 件ある）
      d.global_club_id = dojo['global_club_id'].presence
      d.inactivated_at = dojo['inactivated_at'] ? Time.zone.parse(dojo['inactivated_at']) : nil
      d.created_at     = d.new_record? ? Time.zone.now : dojo['created_at'] || d.created_at
      d.updated_at     = Time.zone.now

      d.save!
    end
  end

  Rake::Task['dojos:update_db_by_yaml'].enhance(['postgresql:reset_pk_sequence'])

  # YAML にある各 Dojo データが有効かどうか検証し、無効なら raise する
  def raise_if_invalid_dojo(dojo)
    # order は６桁で、String として格納される（左ゼロ詰めに対応するため）
    invalid_order = <<~ERROR_MESSAGE
    全国地方公共団体コード (order) は必ず６桁のコード (String) になります。内容を再度ご確認ください。
    https://www.soumu.go.jp/denshijiti/code.html

    Invalid Dojo: #{dojo}

    ERROR_MESSAGE

    raise invalid_order if not dojo['order'].size.equal? 6
    raise invalid_order if not dojo['order'].is_a? String
  end

  # search order number for google spred sheets
  # 'yamlファイルのnameからorderの値を生成します'
  def search_order_number_by(pre_city)

    if /(?<city>.+)\s\(.+\)/ =~ pre_city
      table = CSV.table(Rails.root.join('db','city_code.csv'), { :converters => nil })
      row = table.find { |r| r[:city].to_s.start_with?(city) }
      row ? row[:order] : raise("Failed to detect city code by #{pre_city}
order値の自動設定ができませんでした。お手数ですが下記URLを参考に該当する全国地方公共団体コードをorder値にご入力ください。
http://www.soumu.go.jp/denshijiti/code.html

")
    else
      raise("It is not valid data for #{pre_city}")
    end
  end

  # NOTE: 2020年1月中はコメントアウトで残し、もし必要になる場面が無ければ翌月以降に削除する
  # desc '現在のyamlファイルのカラムをソートします'
  # task sort_yaml: :environment do
  #   dojos = Dojo.load_attributes_from_yaml
  #
  #   # Dojo column should start with 'name' for human-readability
  #   dojos.map! do |dojo|
  #     dojo.sort_by { |a,b| a.last }.to_h
  #   end
  #
  #   Dojo.dump_attributes_to_yaml(dojos)
  # end

  desc 'DBからyamlファイルを生成します'
  task migrate_adding_id_to_yaml: :environment do
    dojos = Dojo.load_attributes_from_yaml

    dojos.map! do |dojo|
      d = Dojo.find_by(name: dojo['name'])

      # ID など DB の内容で上書きしたいカラムを明示的に指定する。
      # YAML の各カラムの先頭に固定させたい場面などにも有効です。
      new_dojo          = {}
      new_dojo['id']    = d.id
      new_dojo['order'] = d.order
      new_dojo['created_at'] = d.created_at&.to_date&.to_s
      #new_dojo['name'] = d.name  # created の直後に固定させる場合の例

      new_dojo.merge!(dojo)
      new_dojo
    end

    Dojo.dump_attributes_to_yaml(dojos)
  end
end
