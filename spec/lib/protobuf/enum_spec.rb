require 'spec_helper'

describe Protobuf::Enum do

  describe 'class dsl' do
    let(:name) { :THREE }
    let(:tag)  { 3 }

    before(:all) do
      Test::EnumTestType.define(:MINUS_ONE, -1)
      Test::EnumTestType.define(:THREE, 3)
    end

    before(:all) do
      EnumAliasTest = ::Class.new(::Protobuf::Enum) do
        set_option :allow_alias
        define :FOO, 1
        define :BAR, 1
        define :BAZ, 2
      end
    end

    describe '.aliases_allowed?' do
      it 'is false when the option is not set' do
        expect(Test::EnumTestType.aliases_allowed?).to be_false
      end
    end

    describe '.define' do
      it 'defines a constant enum on the parent class' do
        expect(Test::EnumTestType.constants).to include(name)
        expect(Test::EnumTestType::THREE).to be_a(Protobuf::Enum)
      end

      context 'when enum allows aliases' do
        before(:all) do
          DefineEnumAlias = ::Class.new(::Protobuf::Enum) do
            set_option :allow_alias
          end
        end

        it 'allows defining enums with the same tag number' do
          expect {
            DefineEnumAlias.define(:FOO, 1)
            DefineEnumAlias.define(:BAR, 1)
          }.not_to raise_error
        end
      end
    end

    describe '.enums' do
      it 'provides an array of defined Enums' do
        expect(Test::EnumTestType.enums).to eq([
          Test::EnumTestType::ONE,
          Test::EnumTestType::TWO,
          Test::EnumTestType::MINUS_ONE,
          Test::EnumTestType::THREE
        ])
      end

      context 'when enum allows aliases' do
        it 'treats aliased enums as valid' do
          expect(EnumAliasTest.enums).to eq([
            EnumAliasTest::FOO,
            EnumAliasTest::BAR,
            EnumAliasTest::BAZ
          ])
        end
      end
    end


    describe '.enums_for_tag' do
      it 'returns an array of Enums for the given tag, if any' do
        expect(EnumAliasTest.enums_for_tag(1)).to eq([ EnumAliasTest::FOO, EnumAliasTest::BAR ])
        expect(EnumAliasTest.enums_for_tag(2)).to eq([ EnumAliasTest::BAZ ])
        expect(EnumAliasTest.enums_for_tag(3)).to eq([])
      end
    end

    describe '.fetch' do
      context 'when candidate is an Enum' do
        it 'responds with the Enum' do
          expect(Test::EnumTestType.fetch(Test::EnumTestType::THREE)).to eq(Test::EnumTestType::THREE)
        end
      end

      context 'when candidate can be coerced to a symbol' do
        it 'fetches based on the symbol name' do
          expect(Test::EnumTestType.fetch("ONE")).to eq(Test::EnumTestType::ONE)
          expect(Test::EnumTestType.fetch(:ONE)).to eq(Test::EnumTestType::ONE)
        end
      end

      context 'when candidate can be coerced to an integer' do
        it 'fetches based on the integer tag' do
          expect(Test::EnumTestType.fetch(3.0)).to eq(Test::EnumTestType::THREE)
          expect(Test::EnumTestType.fetch(3)).to eq(Test::EnumTestType::THREE)
        end

        context 'when enum allows aliases' do
          it 'fetches the first defined Enum' do
            expect(EnumAliasTest.fetch(1)).to eq(EnumAliasTest::FOO)
          end
        end

        context 'when the integer value is an unknown value' do
          it 'fetches an unknown enum instance' do
            expect(Test::EnumTestType.fetch(-10)).to eq(Test::EnumTestType.unknown_enum(-10))
          end
        end
      end

      context 'when candidate is not an applicable type' do
        it 'returns a nil' do
          expect(Test::EnumTestType.fetch(EnumAliasTest::FOO)).to be_nil
          expect(Test::EnumTestType.fetch(Test::Resource.new)).to be_nil
          expect(Test::EnumTestType.fetch(nil)).to be_nil
          expect(Test::EnumTestType.fetch(false)).to be_nil
        end
      end
    end

    describe '.enum_for_tag' do
      it 'gets the Enum corresponding to the given tag' do
        expect(Test::EnumTestType.enum_for_tag(tag)).to eq(Test::EnumTestType.const_get(name))
        expect(Test::EnumTestType.enum_for_tag(-5)).to be_nil
      end
    end

    describe '.name_for_tag' do
      it 'get the name of the enum given the enum' do
        expect(Test::EnumTestType.name_for_tag(::Test::EnumTestType::THREE)).to eq(name)
      end

      it 'gets the name of the enum corresponding to the given tag' do
        expect(Test::EnumTestType.name_for_tag(tag)).to eq(name)
      end

      it 'gets the name when the tag is coercable to an int' do
        expect(Test::EnumTestType.name_for_tag("3")).to eq(name)
      end

      it 'returns nil when tag does not correspond to a name' do
        expect(Test::EnumTestType.name_for_tag(12345)).to be_nil
      end

      context 'when given name is nil' do
        it 'returns a nil' do
          expect(Test::EnumTestType.name_for_tag(nil)).to be_nil
        end
      end

      context 'when enum allows aliases' do
        it 'returns the first defined name for the given tag' do
          expect(EnumAliasTest.name_for_tag(1)).to eq(:FOO)
        end
      end
    end

    describe '.valid_tag?' do
      context 'when tag is defined' do
        specify { expect(Test::EnumTestType.valid_tag?(tag)).to be_true }
      end

      context 'when tag is not defined' do
        specify { expect(Test::EnumTestType.valid_tag?(300)).to be_false }
      end

      context 'is true for aliased enums' do
        specify { expect(EnumAliasTest.valid_tag?(1)).to be_true }
      end
    end

    describe '.unknown_enum' do
      subject { Test::EnumTestType.unknown_enum(20) }

      it 'has a nil name' do
        expect(subject.name).to be_nil
        expect(subject.to_s(:name)).to eq('')
      end

      it 'has an int value' do
        expect(subject.to_i).to eq(20)
      end
    end

    describe '.enum_for_name' do
      it 'gets the Enum corresponding to the given name' do
        expect(Test::EnumTestType.enum_for_name(name)).to eq(Test::EnumTestType::THREE)
      end
    end

    describe '.values' do
      it 'provides a hash of defined Enums' do
        expect(Test::EnumTestType.values).to eq({
          :MINUS_ONE => Test::EnumTestType::MINUS_ONE,
          :ONE       => Test::EnumTestType::ONE,
          :TWO       => Test::EnumTestType::TWO,
          :THREE     => Test::EnumTestType::THREE
        })
      end

      it 'contains aliased Enums' do
        expect(EnumAliasTest.values).to eq({
          :FOO => EnumAliasTest::FOO,
          :BAR => EnumAliasTest::BAR,
          :BAZ => EnumAliasTest::BAZ
        })
      end
    end

    describe '.all_tags' do
      it 'provides a unique array of defined tags' do
        expect(Test::EnumTestType.all_tags).to include(1, 2, -1, 3)
        expect(EnumAliasTest.all_tags).to include(1, 2)
      end
    end
  end

	subject { Test::EnumTestType::ONE }
  its(:class) { should eq(Fixnum) }
  its(:parent_class) { should eq(Test::EnumTestType) }
	its(:name) { should eq(:ONE) }
	its(:tag) { should eq(1) }
	its(:value) { should eq(1) }
	its(:to_hash_value) { should eq(1) }
	its(:to_s) { should eq("1") }

  describe '#inspect' do
    let(:enum_instance) { Test::EnumTestType::ONE }
    subject { enum_instance.inspect }

    it { should eq('#<Protobuf::Enum(Test::EnumTestType)::ONE=1>') }

    context 'unknown enum' do
      let(:enum_instance) { Test::EnumTestType.unknown_enum(100) }

      it { should eq('#<Protobuf::Enum(Test::EnumTestType)::(UNKNOWN)=100>') }
    end
  end

  specify { subject.to_s(:tag).should eq("1") }
  specify { subject.to_s(:name).should eq("ONE") }

  it "can be used as the index to an array" do
    array = [0, 1, 2, 3]
    array[::Test::EnumTestType::ONE].should eq(1)
  end

  describe '#try' do
    specify { subject.try(:parent_class).should eq(subject.parent_class) }
    specify { subject.try(:class).should eq(subject.class) }
    specify { subject.try(:name).should eq(subject.name) }
    specify { subject.try(:tag).should eq(subject.tag) }
    specify { subject.try(:value).should eq(subject.value) }
    specify { subject.try(:to_i).should eq(subject.to_i) }
    specify { subject.try(:to_int).should eq(subject.to_int) }
    specify { subject.try { |yielded| yielded.should eq(subject) } }
  end

  context 'when coercing from enum' do
    subject { Test::StatusType::PENDING }
    it { should eq(0) }
  end

  context 'when coercing from integer' do
    specify { expect(0).to eq(Test::StatusType::PENDING) }
  end
end
