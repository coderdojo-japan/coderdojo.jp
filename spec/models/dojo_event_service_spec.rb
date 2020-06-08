require 'rails_helper'

RSpec.describe DojoEventService, :type => :model do
  describe 'validation' do
    context 'name & group_id : group_id が nil でないとき、組み合わせで unique' do
      before :each do
        @dojo_1 = create(:dojo, name: 'dojo_1', prefecture_id: 14, order: '14201', created_at: '2019-11-01', tags: %w(Scratch ラズベリーパイ))
        @dojo_2 = create(:dojo, name: 'dojo_2', prefecture_id: 12, order: '12204', created_at: '2019-11-05', tags: %w(Scratch))
      end

      it 'group_id が nil ⇒ 同じ name があっても OK' do
        create(:dojo_event_service, dojo_id: @dojo_1.id, name: :doorkeeper, group_id: nil)
        des = DojoEventService.new
        des.dojo_id  = @dojo_2.id
        des.name     = :doorkeeper
        des.group_id = nil
        expect(des.valid?).to eq(true)
      end

      context 'group_id が nil でない' do
        before :each do
          create(:dojo_event_service, dojo_id: @dojo_1.id, name: :connpass, group_id: '1111')
        end

        it '同じ name あり ＆ 同じ group_id なし ⇒ OK' do
          des = DojoEventService.new
          des.dojo_id  = @dojo_2.id
          des.name     = :connpass
          des.group_id = '2222'
          expect(des.valid?).to eq(true)
        end

        it '同じ name なし ＆ 同じ group_id あり ⇒ OK' do
          des = DojoEventService.new
          des.dojo_id  = @dojo_2.id
          des.name     = :doorkeeper
          des.group_id = '1111'
          expect(des.valid?).to eq(true)
        end

        it 'name & group_id で同じ組み合わせあり ⇒ NG' do
          des = DojoEventService.new
          des.dojo_id  = @dojo_2.id
          des.name     = :connpass
          des.group_id = '1111'
          expect(des.valid?).to eq(false)
        end
      end
    end
  end
end
