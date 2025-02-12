require 'rails_helper'

RSpec.describe Idv::ApiDocumentVerificationForm do
  subject(:form) do
    Idv::ApiDocumentVerificationForm.new(
      {
        encryption_key: encryption_key,
        front_image_url: front_image_url,
        front_image_iv: front_image_iv,
        back_image_url: back_image_url,
        back_image_iv: back_image_iv,
        selfie_image_url: selfie_image_url,
        selfie_image_iv: selfie_image_iv,
        document_capture_session_uuid: document_capture_session_uuid,
      },
      liveness_checking_enabled: liveness_checking_enabled?,
      analytics: analytics,
    )
  end

  let(:encryption_key) { 'encryption-key' }
  let(:front_image_url) { 'http://example.com/front' }
  let(:front_image_iv) { 'front-iv' }
  let(:back_image_url) { 'http://example.com/back' }
  let(:back_image_iv) { 'back-iv' }
  let(:selfie_image_url) { 'http://example.com/selfie' }
  let(:selfie_image_iv) { 'selfie-iv' }
  let!(:document_capture_session) { DocumentCaptureSession.create!(user: create(:user)) }
  let(:document_capture_session_uuid) { document_capture_session.uuid }
  let(:analytics) { FakeAnalytics.new }
  let(:liveness_checking_enabled?) { true }

  describe '#valid?' do
    context 'with all valid images' do
      it 'is valid' do
        expect(form.valid?).to eq(true)
        expect(form.errors).to be_blank
      end
    end

    context 'with valid front and back but no selfie' do
      let(:selfie_image_url) { nil }

      context 'with liveness required' do
        let(:liveness_checking_enabled?) { true }

        it 'is not valid' do
          expect(form.valid?).to eq(false)
          expect(form.errors.attribute_names).to eq([:selfie_image_url])
          expect(form.errors[:selfie_image_url]).to eq([t('doc_auth.errors.not_a_file')])
        end
      end

      context 'without liveness require' do
        let(:liveness_checking_enabled?) { false }

        it 'is valid' do
          expect(form.valid?).to eq(true)
          expect(form.errors).to be_blank
        end
      end
    end

    context 'when iv is missing' do
      let(:front_image_iv) { nil }

      it 'is not valid' do
        expect(form.valid?).to eq(false)
        expect(form.errors.attribute_names).to eq([:front_image_iv])
        expect(form.errors[:front_image_iv]).to eq(['Please fill in this field.'])
      end
    end

    context 'when encryption key is missing' do
      let(:encryption_key) { nil }

      it 'is not valid' do
        expect(form.valid?).to eq(false)
        expect(form.errors.attribute_names).to eq([:encryption_key])
        expect(form.errors[:encryption_key]).to eq(['Please fill in this field.'])
      end
    end

    context 'when url is invalid' do
      let(:front_image_url) { 'nonsense' }

      it 'is not valid' do
        expect(form.valid?).to eq(false)
        expect(form.errors.attribute_names).to eq([:front_image_url])
        expect(form.errors[:front_image_url]).to eq([t('doc_auth.errors.not_a_file')])
      end
    end

    context 'when document_capture_session_uuid param is missing' do
      let(:document_capture_session_uuid) { nil }

      it 'is not valid' do
        expect(form.valid?).to eq(false)
        expect(form.errors.attribute_names).to eq([:document_capture_session])
        expect(form.errors[:document_capture_session]).to eq(['Please fill in this field.'])
      end
    end

    context 'when document_capture_session_uuid does not correspond to a record' do
      let(:document_capture_session_uuid) { 'unassociated-test-uuid' }

      it 'is not valid' do
        expect(form.valid?).to eq(false)
        expect(form.errors.attribute_names).to eq([:document_capture_session])
        expect(form.errors[:document_capture_session]).to eq(['Please fill in this field.'])
      end
    end

    context 'when throttled from submission' do
      before do
        create(
          :throttle,
          :with_throttled,
          user: document_capture_session.user,
          throttle_type: :idv_doc_auth,
        )
        form.submit
      end

      it 'is not valid' do
        expect(form.valid?).to eq(false)
        expect(form.errors.attribute_names).to eq([:limit])
        expect(form.errors[:limit]).to eq([I18n.t('errors.doc_auth.throttled_heading')])
        expect(analytics).to have_logged_event(
          Analytics::THROTTLER_RATE_LIMIT_TRIGGERED,
          throttle_type: :idv_doc_auth,
        )
      end
    end
  end

  describe '#submit' do
    it 'includes remaining_attempts' do
      response = form.submit
      expect(response.extra[:remaining_attempts]).to be_a_kind_of(Numeric)
    end
  end
end
