# frozen_string_literal: true

require 'spec_helper'

describe ValidatesTimeliness, 'Mongoid' do
  after(:each) do
    Mongoid.purge!
  end

  class Article
    include Mongoid::Document
    field :publish_date, type: Date
    field :publish_time, type: Time
    field :publish_datetime, type: DateTime
    validates_date :publish_date, allow_nil: true
    validates_time :publish_time, allow_nil: true
    validates_datetime :publish_datetime, allow_nil: true
  end

  let(:klass) { Article }
  let(:record) { klass.new }

  context 'validation methods' do
    it 'should be defined on the class' do
      expect(klass).to respond_to(:validates_date)
      expect(klass).to respond_to(:validates_time)
      expect(klass).to respond_to(:validates_datetime)
    end

    it 'should be defined on the instance' do
      expect(record).to respond_to(:validates_date)
      expect(record).to respond_to(:validates_time)
      expect(record).to respond_to(:validates_datetime)
    end

    it 'should validate a valid value string' do
      record.publish_date = '2012-01-01'

      record.valid?
      expect(record.errors[:publish_date]).to be_empty
    end

    it 'should validate a nil value' do
      record.publish_date = nil

      record.valid?
      expect(record.errors[:publish_date]).to be_empty
    end
  end

  it 'should determine type for attribute' do
    expect(klass.timeliness_attribute_type(:publish_date)).to eq(:date)
    expect(klass.timeliness_attribute_type(:publish_time)).to eq(:time)
    expect(klass.timeliness_attribute_type(:publish_datetime)).to eq(:datetime)
  end

  context 'attribute write method' do
    it 'should cache attribute raw value' do
      record.publish_datetime = date_string = '2010-01-01'

      expect(record.read_timeliness_attribute_before_type_cast('publish_datetime'))
        .to eq(date_string)
    end

    context 'with plugin parser' do
      let(:klass) {  ArticleWithAliasedFields }

      class ArticleWithParser
        include Mongoid::Document
        field :publish_date, type: Date
        field :publish_time, type: Time
        field :publish_datetime, type: DateTime

        validates_date :publish_date, allow_nil: true
        validates_time :publish_time, allow_nil: true
        validates_datetime :publish_datetime, allow_nil: true
      end

      context 'for a date column' do
        it 'should parse a string value' do
          expect(Timeliness::Parser).to receive(:parse)

          record.publish_date = '2010-01-01'
        end

        it 'should parse a invalid string value as nil' do
          expect(Timeliness::Parser).to receive(:parse)

          record.publish_date = 'not valid'
        end

        it 'should store a Date value after parsing string' do
          record.publish_date = '2010-01-01'

          expect(record.publish_date).to be_a(Date)
          expect(record.publish_date).to eq(Date.new(2010, 1, 1))
        end
      end

      context 'for a time column' do
        it 'should parse a string value' do
          expect(Timeliness::Parser).to receive(:parse)

          record.publish_time = '12:30'
        end

        it 'should parse a invalid string value as nil' do
          expect(Timeliness::Parser).to receive(:parse)

          record.publish_time = 'not valid'
        end

        it 'should store a Time value after parsing string' do
          record.publish_time = '12:30'

          expect(record.publish_time).to be_a(Time)
          expect(record.publish_time).to eq(Time.utc(2000, 1, 1, 12, 30))
        end
      end

      context 'for a datetime column' do
        it 'should parse a string value' do
          expect(Timeliness::Parser).to receive(:parse)

          record.publish_datetime = '2010-01-01 12:00'
        end

        it 'should parse a invalid string value as nil' do
          expect(Timeliness::Parser).to receive(:parse)

          record.publish_datetime = 'not valid'
        end

        it 'should parse string into DateTime value' do
          record.publish_datetime = '2010-01-01 12:00'

          expect(record.publish_datetime).to be_a(DateTime)
        end

        it 'should parse string as current timezone' do
          record.publish_datetime = '2010-06-01 12:00'

          expect(record.publish_datetime.utc_offset).to eq(Time.zone.utc_offset)
        end
      end
    end
  end

  context 'cached value' do
    it 'should be cleared on reload' do
      record = Article.create!
      record.publish_date = '2010-01-01'
      record.reload
      expect(record.read_timeliness_attribute_before_type_cast('publish_date'))
        .to be_nil
    end
  end

  context 'before_type_cast method' do
    it 'should be defined on class if ORM supports it' do
      expect(record).to respond_to(:publish_datetime_before_type_cast)
    end

    it 'should return original value' do
      record.publish_datetime = date_string = '2010-01-01'

      expect(record.publish_datetime_before_type_cast).to eq(date_string)
    end

    it 'should return attribute if no attribute assignment has been made' do
      time = Time.zone.local(2010, 0o1, 0o1)
      Article.create(publish_datetime: time)
      record = Article.last
      expect(record.publish_datetime_before_type_cast).to eq(time.to_datetime)
    end

    context 'with plugin parser' do
      it 'should return original value' do
        record.publish_datetime = date_string = '2010-01-31'
        expect(record.publish_datetime_before_type_cast).to eq(date_string)
      end
    end
  end

  context 'with aliased fields' do
    let(:klass) { ArticleWithAliasedFields }

    class ArticleWithAliasedFields
      include Mongoid::Document
      field :pd, as: :publish_date, type: Date
      field :pt, as: :publish_time, type: Time
      field :pdt, as: :publish_datetime, type: DateTime
      validates_date :publish_date, allow_nil: true
      validates_time :publish_time, allow_nil: true
      validates_datetime :publish_datetime, allow_nil: true
    end

    it 'should determine type for attribute' do
      expect(klass.timeliness_attribute_type(:publish_date))
        .to eq(:date)
      expect(klass.timeliness_attribute_type(:publish_time))
        .to eq(:time)
      expect(klass.timeliness_attribute_type(:publish_datetime))
        .to eq(:datetime)
    end
  end
end
