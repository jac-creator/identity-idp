require 'rails_helper'

RSpec.describe 'two_factor_authentication/sms_opt_in/error.html.erb' do
  let(:phone_configuration) { build(:phone_configuration, phone: '1 888-867-5309') }
  let(:other_mfa_options_url) { nil }
  let(:cancel_url) { nil }

  let(:sp_name) { nil }
  let(:decorated_session) { instance_double('SessionDecorator', sp_name: sp_name) }

  before do
    assign(:phone_configuration, phone_configuration)
    assign(:other_mfa_options_url, other_mfa_options_url)
    assign(:cancel_url, cancel_url)
    allow(view).to receive(:decorated_session).and_return(decorated_session)
    allow(view).to receive(:user_signing_up?).and_return(false)
  end

  it 'renders the masked phone number' do
    render

    expect(rendered).to have_content('(***) ***-5309')
  end

  context 'other authentication methods' do
    context 'without an other_mfa_options_url' do
      let(:other_mfa_options_url) { nil }

      it 'omits the other auth methods section' do
        render

        expect(rendered).to_not have_content(t('two_factor_authentication.opt_in.cant_use_phone'))
        expect(rendered).to_not have_content(t('two_factor_authentication.login_options_link_text'))
      end
    end

    context 'with an other_mfa_options_url' do
      let(:other_mfa_options_url) { '/other' }

      it 'links to other options' do
        render

        expect(rendered).to have_content(t('two_factor_authentication.opt_in.cant_use_phone'))
        expect(rendered).to have_link(
          t('two_factor_authentication.login_options_link_text'),
          href: other_mfa_options_url,
        )
      end
    end
  end

  context 'troubleshooting links' do
    context 'with an sp' do
      let(:sp_name) { 'An Example SP' }

      it 'links to the sp' do
        render

        expect(rendered).to have_link(
          t('idv.troubleshooting.options.get_help_at_sp', sp_name: sp_name),
        )
      end
    end

    context 'without an sp' do
      let(:sp_name) { nil }

      it 'has a contact support but not a "Get Help At" link' do
        render

        expect(rendered).to have_link(
          t('links.contact_support', app_name: APP_NAME),
          href: MarketingSite.contact_url,
        )

        doc = Nokogiri::HTML(rendered)
        expect(doc.css('.troubleshooting-options__options li').length).to eq(1)
      end
    end
  end
end
