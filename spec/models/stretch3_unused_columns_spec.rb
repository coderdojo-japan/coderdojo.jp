require 'rails_helper'
require Rails.root.join('db/migrate/20261023150000_clear_unused_columns_in_stretch3s')

# 申請フォームで使わなくなった列の中身を空にするマイグレーション
RSpec.describe ClearUnusedColumnsInStretch3s do
  let(:dojo) { create(:dojo) }

  it '使わなくなった 4 列を空にし、道場と日時は残す' do
    old_row = Stretch3.create!(dojo: dojo)
    old_row.update_columns(email: 'a@example.com', parent_name: 'a', participant_name: 'b', dojo_name: 'c')

    ActiveRecord::Migration.suppress_messages { described_class.new.up }

    old_row.reload
    expect([old_row.email, old_row.parent_name, old_row.participant_name, old_row.dojo_name]).to all(be_nil)
    expect(old_row.dojo).to eq(dojo)
    expect(old_row.created_at).to be_present
  end
end
